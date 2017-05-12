package DBIx::Class::Storage::DBI::ODBC::OPENEDGE;

our $VERSION = '0.02';

use strict;
use warnings;

use base qw/
  DBIx::Class::Storage::DBI::ODBC
  DBIx::Class::Storage::DBI::OpenEdge
/;
use mro 'c3';

sub datetime_parser_type {
  'DBIx::Class::Storage::DBI::ODBC::OPENEDGE::DateTime::Format'
}

package # hide from PAUSE
  DBIx::Class::Storage::DBI::ODBC::OPENEDGE::DateTime::Format;

my $datetime_format = '%Y-%m-%d %H:%M:%S'; # %F %T, no fractional part
my $datetime_parser;

sub parse_datetime {
  shift;
  require DateTime::Format::Strptime;
  $datetime_parser ||= DateTime::Format::Strptime->new(
    pattern  => $datetime_format,
    on_error => 'croak',
  );
  return $datetime_parser->parse_datetime(shift);
}

sub format_datetime {
  shift;
  require DateTime::Format::Strptime;
  $datetime_parser ||= DateTime::Format::Strptime->new(
    pattern  => $datetime_format,
    on_error => 'croak',
  );
  return $datetime_parser->format_datetime(shift);
}

1;

__END__

=head1 NAME

DBIx::Class::Storage::DBI::ODBC::OPENEDGE - Support specific for OpenEdge over ODBC

=head1 DESCRIPTION

This class implements support specific to access Progress Softwares OpenEdge
Advance Server over ODBC.

It is a subclass of L<DBIx::Class::Storage::DBI::ODBC> and
L<DBIx::Class::Storage::DBI::OpenEdge>, see those classes for more
information.

It is loaded automatically by by L<DBIx::Class::Storage::DBI::ODBC> when it
detects a OpenEdge back-end.

=head1 EXAMPLE DSN

  dbi:ODBC:DSN=<database name>

=head1 AUTHOR

Kevin L. Esteb, C<< <kesteb at wsipc.org> >>

=head1 BUGS

Certainly many, since this is a cut and paste job. It's primmary mission
is to remove annoying warnings from DBIx::Class. But please report any bugs
or feature requests to C<bug-dbix-class-storage-dbi-odbc-openedge at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Storage-DBI-ODBC-OPENEDGE>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Storage::DBI::ODBC::OPENEDGE

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Storage-DBI-ODBC-OPENEDGE>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-Storage-DBI-ODBC-OPENEDGE>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Storage-DBI-ODBC-OPENEDGE>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-Storage-DBI-ODBC-OPENEDGE/>

=back

=head1 ACKNOWLEDGEMENTS

Modeled after the DBIx::Class::Storage::DBI::ODBC::ACCESS module.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Kevin L. Esteb.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
