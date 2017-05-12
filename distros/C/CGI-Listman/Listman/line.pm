# line.pm - this file is part of the CGI::Listman distribution
#
# CGI::Listman is Copyright (C) 2002 iScream multimédia <info@iScream.ca>
#
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>

use strict;

package CGI::Listman::line;

use Carp;

=pod

=head1 NAME

CGI::Listman::line - the internal representation of a database row

=head1 SYNOPSIS

    use CGI::Listman::line;

=head1 DESCRIPTION

A I<CGI::Listman::line> represents a row of database stored in a way that
permits I<CGI::Listman> and the developer to easily manage some aspects of
it. For example, it also contains data on when the row was created, if it
was exported through a I<CGI::Listman::exporter>, if it was listed or
displayed in some way within a web interface.

The order in which the fields are specified or used should be the same
throughout the use of the same instance of I<CGI::Listman>.

=head1 API

=head2 new

This method is to instantiate a I<CGI::Listman::line>. It optionnally
takes an array ref as argument which will be the database row this
instance will represent in the framework of I<CGI::Listman>.

=over

=item Parameters

The parameter "data" is optional with this method.

=over

=item data

A reference to an ARRAY representing a database record. This parameter is
optional.

=back

=item Return values

This method returns a blessed reference to a I<CGI::Listman::line>.

=back

=cut

# line format: (number, timestamp, seen, exported, fields...)
sub new {
  my $class = shift;

  my $self = {};
  $self->{'number'} = 0;
  $self->{'timestamp'} = 0;
  $self->{'seen'} = 0;
  $self->{'exported'} = 0;
  $self->{'data'} = shift;

  $self->{'_updated'} = 1;
  $self->{'_new_line'} = 1;
  $self->{'_deleted'} = 0;

  bless $self, $class;
}

=pod

=head2 mark_seen

This method should be called whenever the line is considered as being
displayed on a user interface.

=over

=item Parameters

This method takes no parameter.

=item Return values

This method returns nothing.

=back

=cut

sub mark_seen {
  my $self = shift;

  $self->{'seen'} = 1;
  $self->{'_updated'} = 1;
}

=pod

=head2 mark_exported

This method is called internally by I<CGI::Listman> whenever the line is
added to an instance of I<CGI::Listman::exporter>. It should not
otherwise be used directly by the developer, except when using its own
implementation of an exporter, but please choose to extend the
I<CGI::Listman::exporter> API instead.

=over

=item Parameters

This method takes no parameter.

=item Return values

This method returns nothing.

=back

=cut

sub mark_exported {
  my $self = shift;

  $self->{'exported'} = 1;
  $self->{'_updated'} = 1;
}

=pod

=head2 number

This method returns the integer representing its position in the database
table. This number will be assigned only if the instance get added to a
I<CGI::Listman>, otherwise it will stay at 0.

=over

=item Parameters

This method takes no parameter.

=item Return values

An integer representing the position of this line.

=back

=cut

sub number {
  my $self = shift;

  return $self->{'number'};
}

=pod

=head2 set_fields

This will set the actual data row of this instance if not previously set
by new or this method.

=over

=item Parameters

=over

=item fields

A reference to an ARRAY representing a database record.

=back

=item Return values

This method returns nothing.

=back

=cut

sub set_fields {
  my ($self, $fields_ref) = @_;

  croak "Fields already defined for line.\n"
    if (defined $self->{'data'});

  $self->{'data'} = $fields_ref;
  $self->{'_updated'} = 1;
}

=pod

=head2 update_fields

Since I<set_fields> can only be called once and updating a row requires
some internal handling, you need to use this method whenever you update
a line's data.

=over

=item Parameters

=over

=item fields

A reference to an ARRAY representing a database record.

=back

=item Return values

This method returns nothing.

=back

=cut

sub update_fields {
  my ($self, $fields_ref) = @_;

  delete $self->{'data'}
    if (defined $self->{'data'});

  $self->{'data'} = $fields_ref;
  $self->{'_updated'} = 1;
}

=pod

=head2 line_fields

Use this method whenever you want to access the data encapsulated within
this object. Be careful to not modify the resulting fields unless you
want to do so since it returns the actual data and not a copy.

=over

=item Parameters

This method takes no parameter.

=item Return values

A reference to an ARRAY representing the instance of I<CGI::Listman::line>.

=back

=cut

sub line_fields {
  my $self = shift;

  return $self->{'data'};
}

### private methods

sub _build_from_listman_data {
  my ($self, $listman_data_ref) = @_;

  my @backend_data = @$listman_data_ref;

  my $number = shift @backend_data;
  $number =~ m/^([0-9]*)$/;
  $number = $1 or croak 'Wrong number ("'.$number
    .'") containing non-digit characters'."\n";

  $self->{'number'} = $number;
  $self->{'timestamp'} = shift @backend_data;
  $self->{'seen'} = shift @backend_data;
  $self->{'exported'} = shift @backend_data;
  $self->{'data'} = \@backend_data;

  $self->{'_updated'} = 0;
  $self->{'_new_line'} = 0;
}

1;
__END__

=pod

=head1 AUTHOR

Wolfgang Sourdeau, E<lt>Wolfgang@Contre.COME<gt>

=head1 COPYRIGHT

Copyright (C) 2002 iScream multimédia <info@iScream.ca>

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Listman::selection(3)> L<CGI::Listman::exporter(3)>

=cut
