package Rose::DB::Object::Metadata::Column::DatetimeYearToMonth;

use strict;

use Rose::DB::Object::Metadata::Column::Datetime;
our @ISA = qw(Rose::DB::Object::Metadata::Column::Datetime);

our $VERSION = '0.788';

sub type { 'datetime year to month' }

sub should_inline_value
{
  my($self, $db, $value) = @_;
  no warnings 'uninitialized';
  return (($db->validate_datetime_year_to_month_keyword($value) && $db->should_inline_datetime_keyword($value)) ||
          ($db->keyword_function_calls && $value =~ /^\w+\(.*\)$/)) ? 1 : 0;
}

sub parse_value
{
  my($self, $db) = (shift, shift);

  $self->parse_error(undef);

  my $dt = $db->parse_datetime_year_to_month(@_);

  if($dt)
  {
    $dt->set_time_zone($self->time_zone || $db->server_time_zone)
      if(UNIVERSAL::isa($dt, 'DateTime'));
  }
  else
  {
    $dt = Rose::DateTime::Util::parse_date($_[0], $self->time_zone || $db->server_time_zone);

    if(my $error = Rose::DateTime::Util->error)
    {
      $self->parse_error("Could not parse value '$_[0]' for column $self: $error")
        if(defined $_[0]);
    }
  }

  return $dt;
}

sub format_value { shift; shift->format_datetime_year_to_month(@_) }

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::DatetimeYearToMonth - Datetime year to month column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::DatetimeYearToMonth;

  $col = 
    Rose::DB::Object::Metadata::Column::DatetimeYearToMonth->new(...);

  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for "datetime year to month" columns in a database.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.

This class inherits from L<Rose::DB::Object::Metadata::Column::Datetime>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column::Datetime> documentation for more information.

The L<DateTime> objects stored by this column type automatically have the day set to the first of the month.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Date>, L<datetime|Rose::DB::Object::MakeMethods::Date/datetime>, C<type =E<gt> 'datetime year to month', interface =E<gt> 'get_set', ...>

=item C<get>

L<Rose::DB::Object::MakeMethods::Date>, L<datetime|Rose::DB::Object::MakeMethods::Date/datetime>, C<type =E<gt> 'datetime year to month', interface =E<gt> 'get', ...>

=item C<set>

L<Rose::DB::Object::MakeMethods::Date>, L<datetime|Rose::DB::Object::MakeMethods::Date/datetime>, C<type =E<gt> 'datetime year to month', interface =E<gt> 'set', ...>

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 OBJECT METHODS

=over 4

=item B<parse_value DB, VALUE>

Convert VALUE to the equivalent L<DateTime> object suitable for storage in a "datetime year to month" column.  VALUE maybe returned unmodified if it is a valid "datetime year to month" keyword or otherwise has special meaning to the underlying database.  DB is a L<Rose::DB> object that is used as part of the parsing process.  Both arguments are required.

=item B<type>

Returns "datetime year to month".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
