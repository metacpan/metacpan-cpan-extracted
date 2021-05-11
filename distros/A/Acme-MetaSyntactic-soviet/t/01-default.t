#perl -T
#
#     Test script for Acme::MetaSyntactic::soviet
#     Copyright (C) 2008, 2012, 2016, 2021 Jean Forget
#
#     This program is distributed under the same terms as Perl 5.16.3:
#     GNU Public License version 1 or later and Perl Artistic License
#
#     You can find the text of the licenses in the F<LICENSE> file or at
#     L<https://dev.perl.org/licenses/artistic.html>
#     and L<https://www.gnu.org/licenses/gpl-1.0.html>.
#
#     Here is the summary of GPL:
#
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 1, or (at your option)
#     any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, contact the Free Software Foundation,
#     Inc., <https://www.fsf.org/>.
#
use Test::More;
use Acme::MetaSyntactic;

my $number = 20;
plan('tests', $number);
my $meta = Acme::MetaSyntactic->new( 'soviet' );
my @names = $meta->name( $number );

foreach (@names) {
  like($_, qr/^[A-Z][a-z]*_[A-Z][a-z]*$/, "An electronic device is composed of two capitalized words separated by an underscore");
}
