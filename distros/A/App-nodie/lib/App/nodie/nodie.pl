#!/usr/bin/env perl
=head1 NAME

nodie.pl - runs command again when its dead

=head1 VERSION

version 1.02

=head1 SYNOPSIS

=over

B<nodie.pl> [ -e|--exitcodes=0,2 ] [ -l|--log='&STDERR' ] command arg1 arg2 ...

B<nodie.pl> -h|--help

=back

=head1 DESCRIPTION

B<nodie.pl> is a part of App::nodie package that runs command again when its dead.

=head2 Arguments

=head3 --exitcodes

B<--exitcodes> or B<-e> specifies that expected exit codes for graceful termination of command in comma separated string.
By default '0,2'.

=head3 --log

B<--log> or B<-l> enables printing logs and specifies log file name/descriptor.
If log file name/descriptor isn't specified in argument, default is '&STDERR'.
'-' is synonym with '&STDOUT'. File descriptors must start with '&', eg '&2'.

=cut
use strict;
use warnings;
use v5.10.1;

use App::nodie;


BEGIN {
	our $VERSION     = '1.02';
}


run;
__END__
=head1 REPOSITORY

B<GitHub> L<https://github.com/orkunkaraduman/App-nodie>

B<CPAN> L<https://metacpan.org/release/App-nodie>

=head1 AUTHOR

Orkun Karaduman (ORKUN) <orkun@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017  Orkun Karaduman <orkunkaraduman@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
