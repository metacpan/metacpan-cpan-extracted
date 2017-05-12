#!/usr/bin/env perl
#
# Copyright 2008-2010 Tim Rayner
# 
# This file is part of Bio::MAGETAB.
# 
# Bio::MAGETAB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# Bio::MAGETAB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Bio::MAGETAB.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id: 003_term_source.t 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Bio::MAGETAB::TermSource' );
}

INIT {
    use lib 't/testlib';
    use CommonTests qw(test_class);
}

my %required_attr = (
    name    => 'test',
);

my %optional_attr = (
    version => 1,
    uri     => 'http://www.terms-are-us.org/listing.txt',
);

my %bad_attr = (
    name    => [],
    version => [],
    uri     => [],
);

my %secondary_attr = (
    name    => 'test2',
    version => '1.342rc',
    uri     => 'file://localhost/terms.txt',
);

my $obj = test_class(
    'Bio::MAGETAB::TermSource',
    \%required_attr,
    \%optional_attr,
    \%bad_attr,
    \%secondary_attr,
);

ok( $obj->isa('Bio::MAGETAB::BaseClass'), 'object has correct superclass' );
