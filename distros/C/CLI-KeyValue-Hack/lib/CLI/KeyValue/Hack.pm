package CLI::KeyValue::Hack;

use 5.006;
use strict;
use warnings;

=head1 NAME

CLI::KeyValue::Hack - Provides CLI commands for key-value text data files in TSV.

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

 This module provides the following utility CLI commands for Key-Value type TSV data.
 
 1. wisejoin : combines 2 files using the key columns. Similar to Unix join and SQL join.
 2. keyvalues : how many different VALUES each KEY has? 
 3. kvcmp : Are the relation between the key and the value is same/different over 2 files?
 4. polar : combines many files using each key column each of the files has.

=head1 EXPORT

 Nothing would be exported.
 (The CLI program files each is stand-alone Perl script are provided.)

=head1 LICENSE AND COPYRIGHT

Copyright 2018 "Toshiyuki Shimono".

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

1; # End of CLI::KeyValue::Hack
