package DBIx::Class::MassAssignable;

use 5.010000;
use strict;
use warnings;
use base qw(DBIx::Class);
use Carp qw/croak carp/;

our $VERSION = '0.03';

__PACKAGE__->mk_group_accessors('inherited', qw/
        attr_accessible
        attr_protected
    /);

sub set_columns {
  my $self = shift;
  my $columns = shift;

  $self->_sanitize_mass_assignment($columns);

  return $self->next::method( $columns );
}

sub set_inflated_columns {
  my $self = shift;
  my $columns = shift;

  $self->_sanitize_mass_assignment($columns);

  return $self->next::method( $columns );
}


sub _sanitize_mass_assignment {
  my $self = shift;
  my $columns = shift;
  my $disable_warnings = shift; 

  $self->_sanitize_attr_accessible($columns, $disable_warnings);
  $self->_sanitize_attr_protected($columns, $disable_warnings);
}

sub _sanitize_attr_accessible {
  my $self = shift;
  my $columns = shift;
  my $disable_warnings = shift;   

  return unless defined $self->attr_accessible;
  croak "attr_accessible must be passed an array ref" unless ref($self->attr_accessible) eq "ARRAY";

  my %accessible = map { $_ => 1 } @{$self->attr_accessible} ;
  foreach my $key( keys %$columns ) {
    unless($accessible{$key}) {
      carp "Attempted to mass assign none whitelisted value $key" unless $disable_warnings;
      delete $columns->{$key} ;
    }
  }
  
}

sub _sanitize_attr_protected {
  my $self = shift;
  my $columns = shift;
  my $disable_warnings = shift;   

  return unless defined $self->attr_protected;
  croak "attr_protected must be passed an array ref" unless ref($self->attr_protected) eq "ARRAY";
  
  my %protected = map { $_ => 1 } @{$self->attr_protected};
  foreach my $key( keys %$columns ) {
    if($protected{$key}) {
      carp "Attempted to mass assign blacklisted value $key"  unless $disable_warnings;
      delete $columns->{$key} ;
    }
  }
  
}

sub mass_assignable_columns {
  my $self = shift;

  my %columns = map { $_ => 1 } ($self->columns());
  $self->_sanitize_mass_assignment(\%columns, 1);
  my @columns = keys %columns;
  return @columns if wantarray;
  return \@columns;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

DBIx::Class::MassAssignable - use set_columns in DBIx::Class safely in a web app

=head1 SYNOPSIS

  __PACKAGE__->load_components(qw/ MassAssignable /);
  __PACKAGE__->attr_accessible([qw( post_title post_content )]);
  __PACKAGE__->attr_protected([qw( is_admin )]);

  #Get a list of mass_assignable_columns
  $row->mass_assignable_columns()

=head1 DESCRIPTION

Load this as a component into your DBIx::Class result classes then specify either which columns
can be mass assigned (whitelist), or which ones are not allowed (blacklist) using set_columns.


=head2 EXPORT

None by default.



=head1 SEE ALSO

Concept stolen from Ruby on Rails.

=head1 AUTHOR

Jonathan Taylor, E<lt>jon@stackhaus.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jonathan Taylor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
