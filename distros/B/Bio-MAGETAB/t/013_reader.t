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
# $Id: 013_idf.t 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;
use File::Spec;

use lib 't/testlib';
use CommonTests qw( test_parse check_term );

BEGIN {
    use_ok( 'Bio::MAGETAB::Util::Reader' );
}

my $reader;

# Instantiate with none of the required attributes.
dies_ok( sub{ $reader = Bio::MAGETAB::Util::Reader->new() },
         'instantiation without attributes' );

my $idf = File::Spec->catfile(qw(t examples affymetrix.idf));

# Test parsing.
lives_ok( sub{ $reader = Bio::MAGETAB::Util::Reader->new( idf => $idf ) },
          'instantiation with idf attribute' );

is( $reader->get_document_version(), undef, 'initial document_version is undef' );

# First, in a strict mode this should fail.
dies_ok( sub{ $reader->parse() }, 'strict mode parsing' );

# Second, relaxed mode should work.
my ( $inv, $cont );
lives_ok( sub{ $reader->set_relaxed_parser(1) }, 'setting parser to relaxed mode' );
lives_ok( sub{ ( $inv, $cont ) = $reader->parse() }, 'relaxed mode parsing' );

is( $reader->get_document_version(), '1.0', 'correct MAGE-TAB document version');

is( ref $inv, 'Bio::MAGETAB::Investigation', 'returns Investigation object' );
is( ref $cont, 'Bio::MAGETAB', 'and Bio::MAGETAB top-level container' );

is( $inv->get_title(), 'University of Heidelberg H sapiens TK6', 'correct Investigation title' );

