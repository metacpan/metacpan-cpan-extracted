package DBIO::Storage::DateTimeFormat;
# ABSTRACT: Strptime-backed datetime format base for driver format classes

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Base';

use DBIO::Exception;

__PACKAGE__->mk_group_accessors('inherited' => qw/
  preferred_format_class
  datetime_parse_pattern datetime_format_pattern
  date_parse_pattern date_format_pattern
/);


my %preferred_loadable;
my %strptime_cache;

sub _preferred {
  my $class = shift;

  my $preferred = $class->preferred_format_class
    or return undef;

  $preferred_loadable{$preferred} //= $class->load_optional_class($preferred) ? 1 : 0;

  return $preferred_loadable{$preferred} ? $preferred : undef;
}


sub _strptime_for {
  my ($class, $slot, $accessor) = @_;

  return $strptime_cache{"$class|$slot"} //= do {
    my $pattern = $class->$accessor
      or DBIO::Exception->throw(
        "$class defines no $accessor and no loadable preferred_format_class"
      );

    # Loaded lazily, not at compile time: a bare DBIO install that
    # never inflates datetimes carries no DateTime stack at all. Only a driver
    # format class that actually parses/formats via strptime patterns pulls it
    # in — and only at that point, so the missing-pattern guard above still
    # fires without DateTime::Format::Strptime present.
    unless (eval { require DateTime::Format::Strptime; 1 }) {
      my $err = $@;
      DBIO::Exception->throw(
        "$class needs DateTime::Format::Strptime to parse/format datetimes, "
        . "but it is not installed. Install DateTime::Format::Strptime (part "
        . "of the optional DBIO::Timestamp/DateTime feature) and retry."
        . "\n\nUnderlying error: $err"
      );
    }

    DateTime::Format::Strptime->new(
      pattern  => $pattern,
      on_error => 'croak'
    );
  };
}


sub parse_datetime {
  my ($class, $value) = @_;

  if (my $preferred = $class->_preferred) {
    return $preferred->parse_datetime($value);
  }

  return $class->_strptime_for(datetime_parse => 'datetime_parse_pattern')
    ->parse_datetime($value);
}


sub format_datetime {
  my ($class, $dt) = @_;

  if (my $preferred = $class->_preferred) {
    return $preferred->format_datetime($dt);
  }

  return $class->_strptime_for(datetime_format => 'datetime_format_pattern')
    ->format_datetime($dt);
}


sub parse_date {
  my ($class, $value) = @_;

  my $preferred = $class->_preferred;
  return $preferred->parse_date($value)
    if $preferred and $preferred->can('parse_date');

  return $class->_strptime_for(date_parse => 'date_parse_pattern')
    ->parse_datetime($value);
}


sub format_date {
  my ($class, $dt) = @_;

  my $preferred = $class->_preferred;
  return $preferred->format_date($dt)
    if $preferred and $preferred->can('format_date');

  return $class->_strptime_for(date_format => 'date_format_pattern')
    ->format_datetime($dt);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::DateTimeFormat - Strptime-backed datetime format base for driver format classes

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  package DBIO::DriverName::DateTime::Format;
  # ABSTRACT: DateTime parsing for DriverName
  use base 'DBIO::Storage::DateTimeFormat';

  __PACKAGE__->preferred_format_class('DateTime::Format::DriverName'); # optional
  __PACKAGE__->datetime_parse_pattern('%Y-%m-%d %H:%M:%S.%3N');
  __PACKAGE__->datetime_format_pattern('%Y-%m-%d %H:%M:%S.%3N');
  __PACKAGE__->date_parse_pattern('%Y-%m-%d');    # optional, enables parse_date
  __PACKAGE__->date_format_pattern('%Y-%m-%d');

  1;

Then point the storage at it:

  __PACKAGE__->datetime_parser_type('DBIO::DriverName::DateTime::Format');

See F<t/datetime_format.t> for a runnable example.

=head1 DESCRIPTION

Base class for driver datetime format classes where no (maintained) CPAN
C<DateTime::Format::*> module exists. Subclasses declare strptime patterns as
class data and may name a preferred CPAN format class: when that class is
installed it handles all calls, otherwise the declared patterns are used via
L<DateTime::Format::Strptime>.

That module is only a C<recommends> of the core distribution. It is loaded at
the first parse or format, which throws when it is missing, so a driver
distribution using the declared patterns lists it in its own prerequisites.

Patterns are read once per class and the resulting parser objects are cached —
set the class data at load time, not dynamically.

=head1 ATTRIBUTES

=head2 preferred_format_class

Optional name of a CPAN format class (e.g. C<DateTime::Format::Sybase>).
Delegated to when loadable; declare it as C<suggests> in the driver cpanfile.
The fallback patterns MUST round-trip identically to the preferred class.

=head2 datetime_parse_pattern

=head2 datetime_format_pattern

Strptime patterns backing L</parse_datetime> and L</format_datetime>.

=head2 date_parse_pattern

=head2 date_format_pattern

Optional strptime patterns backing L</parse_date> and L</format_date>.

=head1 METHODS

=head2 _strptime_for

    my $parser = $class->_strptime_for($slot, $accessor);

Internal: builds (and caches) the L<DateTime::Format::Strptime> object that
backs the public C<parse_*> / C<format_*> helpers.

The strptime dependency is loaded B<lazily>, not at compile time: a bare
DBIO install that never inflates a DateTime column carries no
C<DateTime::Format::Strptime> in C<%INC> at all. Only a driver format class
that actually parses/formats via the strptime patterns pulls it in — and
only at the point of first use, so the missing-pattern guard above still
fires without C<DateTime::Format::Strptime> being present. The
C<requires DateTime::Format::Strptime 1.2> entry in the core C<cpanfile>
is therefore C<recommends>, not C<requires>: the runtime cost lands
exactly on the install that pays it.

=head2 parse_datetime

  my $dt = $class->parse_datetime($string);

Parses a datetime string from the database into a L<DateTime> object, via the
preferred format class when loadable, otherwise via C<datetime_parse_pattern>.

=head2 format_datetime

  my $string = $class->format_datetime($dt);

Formats a L<DateTime> object for the database, via the preferred format class
when loadable, otherwise via C<datetime_format_pattern>.

=head2 parse_date

  my $dt = $class->parse_date($string);

Like L</parse_datetime> for plain dates. Delegates to the preferred format
class only when it implements C<parse_date>; otherwise requires
C<date_parse_pattern> to be set.

=head2 format_date

  my $string = $class->format_date($dt);

Like L</format_datetime> for plain dates. Delegates to the preferred format
class only when it implements C<format_date>; otherwise requires
C<date_format_pattern> to be set.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
