package App::wmiirc::Role::Widget;
{
  $App::wmiirc::Role::Widget::VERSION = '1.000';
}
# ABSTRACT: A role for plugins which add an rbar item
use Moo::Role;
use App::wmiirc::Util;

requires 'name';

sub BUILD {}
before BUILD => sub {
  my($self) = @_;

  wmiir "/rbar/" . $self->name,
    "colors " . $self->core->main_config->{normcolors};
};

sub label {
  my($self, $text, $color) = @_;

  $color //= $self->core->main_config->{normcolors};

  wmiir "/rbar/" . $self->name, "label $text", "colors $color";
}

sub event_right_bar_click {
  my($self, $button, $item) = @_;
  return unless $item eq $self->name;

  if($self->can("widget_click")) {
    $self->widget_click($button, $item);
  }
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Role::Widget - A role for plugins which add an rbar item

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

