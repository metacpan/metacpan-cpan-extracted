#!/usr/bin/env perl
=head1 NAME

sh.pl - runs shell in Perl virtual environment

=head1 VERSION

version 2.07

=head1 SYNOPSIS

=over

[I<environment_path>/bin/]B<sh.pl> [I<argument>]...

=back

=cut
use strict;
use warnings;
use v5.10.1;

use App::Virtualenv;


BEGIN
{
	our $VERSION     = '2.07';
}


App::Virtualenv::activate2();
exit App::Virtualenv::sh(@ARGV);
__END__
=head1 REPOSITORY

B<GitHub> L<https://github.com/orkunkaraduman/perl5-virtualenv>

B<CPAN> L<https://metacpan.org/release/App-Virtualenv>

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
