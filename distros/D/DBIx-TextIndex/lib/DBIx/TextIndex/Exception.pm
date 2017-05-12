package DBIx::TextIndex::Exception;

use strict;
use warnings;

our $VERSION = '0.26';

use Exception::Class (
  'DBIx::TextIndex::Exception',

  'DBIx::TextIndex::Exception::Fatal' =>
  { isa => 'DBIx::TextIndex::Exception',
    fields => [ 'detail' ] },

  'DBIx::TextIndex::Exception::Fatal::General' =>
  { isa => 'DBIx::TextIndex::Exception::Fatal',
    fields => [ 'detail' ],
    alias => 'throw_gen' },

  'DBIx::TextIndex::Exception::Query' =>
  { isa => 'DBIx::TextIndex::Exception',
    fields => [ 'detail' ],
    alias => 'throw_query' },
);

require Exporter;
*import = \&Exporter::import;

our @EXPORT_OK = qw(throw_gen throw_query);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

1;
__END__

=head1 NAME

DBIx::TextIndex::Exception - OO Exceptions for DBIx::TextIndex


=head1 SYNOPSIS

 use DBIx::TextIndex::Exception qw(throw_gen throw_query)

 throw_gen("Error");
 throw_query("Bad query");


=head1 DESCRIPTION

Contains a hierarchy of exceptions by subclassing L<Exception::Class>.
Used internally by L<DBIx::TextIndex>.


=head1 AUTHOR

Daniel Koch, dkoch@cpan.org.


=head1 COPYRIGHT

Copyright 1997-2007 by Daniel Koch.
All rights reserved.


=head1 LICENSE

This package is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, i.e., under the terms of the "Artistic
License" or the "GNU General Public License".


=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut

