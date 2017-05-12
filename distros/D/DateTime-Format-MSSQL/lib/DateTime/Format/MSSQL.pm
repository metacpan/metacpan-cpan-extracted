package DateTime::Format::MSSQL;
$DateTime::Format::MSSQL::VERSION = '1.001000';
# ABSTRACT: parse and format MSSQL DATETIME's
use strict;
use warnings;
use DateTime::Format::Strptime;

sub new {
   shift;
   DateTime::Format::Strptime->new(
     @_,
     pattern => '%Y-%m-%d %H:%M:%S.%3N'
   )
}

sub parse_datetime   { shift->new->parse_datetime(@_) }

sub format_datetime  { shift->new->format_datetime(@_) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::MSSQL - parse and format MSSQL DATETIME's

=head1 VERSION

version 1.001000

=head1 SYNOPSIS

  use DateTime::Format::MSSQL;

  my $dt = DateTime::Format::MSSQL->parse_datetime(
    '2004-08-21 14:36:48.080'
  );

  DateTime::Format::MSSQL->format_datetime($dt); # '2004-08-21 14:36:48.080'

=head1 DESCRIPTION

This is just a basic module to help parse dates formatted from SQL Server.

=head1 METHODS

=head2 new

Instantiate a new C<DateTime::Format::MSSQL>.  You can override the
C<time_zone> that the parsed date is returned as by passing it as an argument:

 DateTime::Format::MSSQL->new(
    time_zone => 'local',
 )->parse_datetime($str)

=head2 parse_datetime

Parse a string returned by SQL Server for a C<DATETIME> column in the default
format.

=head2 format_datetime

Format a L<DateTime> object into a string in the SQL Server expected format.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
