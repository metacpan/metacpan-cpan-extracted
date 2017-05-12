# ************************************************************************* 
# Copyright (c) 2014-2015, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 
#
# unit tests for Model.pm
#

#!perl

use 5.012;
use strict;
use warnings;

use Data::Dumper;
use Test::Fatal;
use Test::More;

use App::Dochazka::Common::Model;

BEGIN {
    no strict 'refs';
    *{"spawn"} = App::Dochazka::Common::Model::make_spawn;
    *{"filter"} = App::Dochazka::Common::Model::make_filter( 'naivetest' );
    *{"reset"} = App::Dochazka::Common::Model::make_reset( 'naivetest' );
    *{"naivetest"} = App::Dochazka::Common::Model::make_accessor( 'naivetest' );
    *{"TO_JSON"} = App::Dochazka::Common::Model::make_TO_JSON( 'naivetest' );
    *{"compare"} = App::Dochazka::Common::Model::make_compare( 'naivetest' );
    *{"clone"} = App::Dochazka::Common::Model::make_clone( 'naivetest' );
}

# make_spawn
like( exception{ __PACKAGE__->spawn( 1 ); }, qr/Odd number of parameters/ );
like( exception{ __PACKAGE__->spawn( foo => 'bar' ); }, qr/not listed in the validation options: foo/ );
my $object = __PACKAGE__->spawn( naivetest => 'Huh?' );
is( ref $object, __PACKAGE__ );
is( $object->naivetest, 'Huh?' );

# make_filter
# - filter routine takes a PROPLIST and returns a filtered PROPLIST
my %fp = filter( bogusprop => 'totally bogus', naivetest => 'kosher' );
is_deeply( \%fp, { naivetest => 'kosher' } );
like( exception{ filter( 1 ); }, qr/Odd number of parameters/ );

# make_reset
$object->reset;
ok( ! defined( $object->naivetest ) );
$object->reset( naivetest => 'Bohuslav' );
is( $object->naivetest, 'Bohuslav' );

# make_accessor
$object->naivetest( 'Fandango' );
is( $object->naivetest, 'Fandango' );

# make_TO_JSON
$object = __PACKAGE__->spawn( naivetest => 'Huh?' );
is_deeply( $object->TO_JSON, { naivetest => 'Huh?' } );

# make_compare
my $object1 = __PACKAGE__->spawn( naivetest => 'Huh?' );
my $object2 = __PACKAGE__->spawn( naivetest => 'Huh?' );
is_deeply( $object1, $object2 );
ok( $object1->compare( $object2 ) );

# make_clone
my $object3 = $object1->clone;
is_deeply( $object1, $object3 );
is_deeply( $object2, $object3 );
ok( $object1->compare( $object3 ) );
ok( $object2->compare( $object3 ) );

done_testing;
