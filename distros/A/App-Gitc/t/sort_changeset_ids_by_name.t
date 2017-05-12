# vim: ft=perl

use strict;
use warnings;

#    Copyright 2012 Grant Street Group, All Rights Reserved.
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

use Test::More;
use App::Gitc::Util qw( sort_changesets_by_name );

my @tests = (
    [
        q{Nolan's original test case},
        [qw( e7386 e758 e7583 e7583a e7583c e758b e758c )],
        [qw( e758 e758b e758c e7386 e7583 e7583a e7583c )],
    ],
    [
        'A little more variety',
        [qw( no_numbers quickfix9 quickfix10 1234 e1234a e1234 )],
        [qw( 1234 e1234 e1234a no_numbers quickfix9 quickfix10 )],
    ],
);

plan tests => scalar @tests;

for my $test (@tests) {
    my ($message, $start, $expect) = @$test;
    sort_changesets_by_name($start);
    is_deeply( $start, $expect, $message );
}
