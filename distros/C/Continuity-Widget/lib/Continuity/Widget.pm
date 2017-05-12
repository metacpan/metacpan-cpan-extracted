package Continuity::Widget;

our $VERSION = '0.01';

=head1 NAME

Continuity::Widget - Handy Moose-based Widget Thingie for Continuity Apps

=head1 SYNOPSIS

  use Continuity::Widget;

=head1 DESCRIPTION

Don't quite know what this will be yet.

=cut

use Data::UUID;
use Moose;
with 'Continuity::Coro::Moose';

# List of callbacks, buttons for now
has callback => ( is => 'rw', default => sub {{}} );

has renderer => ( is => 'rw', isa => 'HashRef', default => sub {{}});

has 'uuid'   => (
  is      => 'ro', 
  isa     => 'Str', 
  default => sub { Data::UUID->new->create_str }
);

# Given a name generate a unique field ID
sub field_name {
  my ($self, $name) = @_;
  return $self->uuid . '-' . $name;
}

# This renders an input form. Need to make the renderer selection dynamic
sub render_edit {
  my ($self) = @_;
  my $out = '<div class="editform">';
  my %attrmap = %{ $self->meta->get_attribute_map };
  while( my ($name, $attr) = each %attrmap ) {
    my $reader = $attr->get_read_method;
    my $val = $self->$reader || '';
    my $field_name = $self->field_name($name);
    $out .= qq|
      <div class=fieldholder>
        <div class=label> @{[$attr->label]} </div>
        <div class=field>
          <input type=text id="$field_name" name="$field_name" value="@{[$val]}">
        </div>
      </div>
    |;
  }
  $out .= $self->render_buttons;
  $out .= '</div>';
  return $out;
}

sub render_view {
  my ($self) = @_;
  my $out = '<div class="view">';
  my %attrmap = %{ $self->meta->get_attribute_map };
  while( my ($name, $attr) = each %attrmap ) {
    my $reader = $attr->get_read_method;
    my $val = $self->$reader || '';
    my $field_name = $self->field_name($name);
    $out .= qq|
      <div class=fieldholder>
        <div class=label> @{[$attr->label]} </div>
        <div class=field>
          @{[$val]}
        </div>
      </div>
    |;
  }
  $out .= $self->render_buttons;
  $out .= '</div>';
  return $out;
}

sub set_from_hash {
  my ($self, $f) = @_;
  my %attrmap = %{ $self->meta->get_attribute_map };
  while( my ($name, $attr) = each %attrmap ) {
    my $field_name = $self->field_name($name);
    if(defined $f->{$field_name}) {
      my $writer = $attr->get_write_method;
      $self->$writer($f->{$field_name});
    }
  }
}

sub add_button {
  my ($self, $name, $callback) = @_;
  $self->callback->{$name} = $callback;
}

sub render_buttons {
  my ($self) = @_;
  my $out = '';
  foreach my $name (keys %{$self->callback}) {
    my $btn_name = $self->field_name($name);
    $out .= qq{
      <br>
      <input type="submit" name="@{[$btn_name]}" value="$name">
    };
  }
  return $out;
}

sub exec_buttons {
  my ($self, $f) = @_;
  foreach my $name (keys %{$self->callback}) {
    my $btn_name = $self->field_name($name);
    if($f->{$btn_name}) {
      $self->callback->{$name}->($f);
    }
  }
}

sub main {
  my ($self) = @_;
  $self->renderer->{view} = \&render_view;
  $self->renderer->{edit} = \&render_edit;
  while(1) {
    my $out = $self->renderer->{view}->($self);
    my $f = $self->next($out);
    $self->set_from_hash($f);
    $self->exec_buttons($f);
  }
}

=head1 SEE ALSO

L<Continuity>, http://continuity.tlt42.org/

=head1 AUTHOR

awwaiid, E<lt>awwaiid@thelackthereof.orgE<gt>, L<http://thelackthereof.org/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Brock Wilcox

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

