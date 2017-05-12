# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

use Test::More tests => 24;
use Clownfish::CFC;

my $parcel = Clownfish::CFC::Model::Parcel->new( name => 'Eep' );

my @exposures = qw( public private parcel local );
for my $exposure (@exposures) {
    my $thing = new_symbol( exposure => $exposure );
    ok( $thing->$exposure, "exposure $exposure" );
    my @not_exposures = grep { $_ ne $exposure } @exposures;
    ok( !$thing->$_, "$exposure means not $_" ) for @not_exposures;
}

my $public_exposure = new_symbol( exposure => 'public' );
my $parcel_exposure = new_symbol( exposure => 'parcel' );
ok( !$public_exposure->equals($parcel_exposure),
    "different exposure spoils equals"
);

for ( qw( 1foo * 0 ), "\x{263a}" ) {
    eval { my $thing = new_symbol( name => $_ ); };
    like( $@, qr/name/, "reject bad name" );
}

my $ooga  = new_symbol( name => 'ooga' );
my $booga = new_symbol( name => 'booga' );
ok( !$ooga->equals($booga), "Different name spoils equals()" );

my $eep = new_symbol( name => 'ah_ah' );
my $ork = Clownfish::CFC::Model::Class->create(
    parcel     => $parcel,
    class_name => 'Op::Ork',
);
is( $eep->short_sym($ork), "Ork_ah_ah",     "short_sym" );
is( $eep->full_sym($ork),  "eep_Ork_ah_ah", "full_sym" );

sub new_symbol {
    return Clownfish::CFC::Model::Symbol->new(
        name     => 'sym',
        exposure => 'parcel',
        @_
    );
}

