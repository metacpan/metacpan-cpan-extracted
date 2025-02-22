package Rose::DB::Object::Metadata::Column::Datetime;

use strict;

use Rose::DB::Object::MakeMethods::Date;

use Rose::DB::Object::Metadata::Column::Date;
our @ISA = qw(Rose::DB::Object::Metadata::Column::Date);

our $VERSION = '0.788';

__PACKAGE__->add_common_method_maker_argument_names
(
  qw(time_zone)
);

Rose::Object::MakeMethods::Generic->make_methods
(
  { preserve_existing => 1 },
  scalar => [ __PACKAGE__->common_method_maker_argument_names ]
);

foreach my $type (__PACKAGE__->available_method_types)
{
  __PACKAGE__->method_maker_type($type => 'datetime');
}

sub type { 'datetime' }

sub should_inline_value
{
  my($self, $db, $value) = @_;
  no warnings 'uninitialized';
  return (($db->validate_datetime_keyword($value) && $db->should_inline_datetime_keyword($value)) ||
          ($db->keyword_function_calls && $value =~ /^\w+\(.*\)$/)) ? 1 : 0;
}

sub parse_value
{
  my($self, $db) = (shift, shift);

  $self->parse_error(undef);

  my $dt = (defined $_[0]) ? $db->parse_datetime(@_) : undef;

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

sub format_value { shift; shift->format_datetime(@_) }

1;

__END__

=head1 NAME

Rose::DB::Object::Metadata::Column::Datetime - Datetime column metadata.

=head1 SYNOPSIS

  use Rose::DB::Object::Metadata::Column::Datetime;

  $col = Rose::DB::Object::Metadata::Column::Datetime->new(...);
  $col->make_methods(...);
  ...

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for datetime columns in a database.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.

This class inherits from L<Rose::DB::Object::Metadata::Column::Date>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column::Date> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Date>, L<datetime|Rose::DB::Object::MakeMethods::Date/datetime>, C<type =E<gt> 'datetime', interface =E<gt> 'get_set', ...>

=item C<get>

L<Rose::DB::Object::MakeMethods::Date>, L<datetime|Rose::DB::Object::MakeMethods::Date/datetime>, C<type =E<gt> 'datetime', interface =E<gt> 'get', ...>

=item C<set>

L<Rose::DB::Object::MakeMethods::Date>, L<datetime|Rose::DB::Object::MakeMethods::Date/datetime>, C<type =E<gt> 'datetime', interface =E<gt> 'set', ...>

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 OBJECT METHODS

=over 4

=item B<parse_value DB, VALUE>

Convert VALUE to the equivalent L<DateTime> object.  VALUE maybe returned unmodified if it is a valid datetime keyword or otherwise has special meaning to the underlying database.  DB is a L<Rose::DB> object that is used as part of the parsing process.  Both arguments are required.

=item B<time_zone [TZ]>

Get or set the time zone of the values stored in this column.  TZ should be a time zone name that is understood by L<DateTime::TimeZone>.

=item B<type>

Returns "datetime".

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
