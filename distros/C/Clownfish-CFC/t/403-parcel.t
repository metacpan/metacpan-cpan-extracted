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
use lib 'buildlib';

use Clownfish::CFC::Test::TestUtils qw( test_files_dir );
use Test::More tests => 32;
use File::Spec::Functions qw( catdir );

BEGIN { use_ok('Clownfish::CFC::Model::Prereq') }

{
    my $version = Clownfish::CFC::Model::Version->new( vstring => 'v34.5.67' );
    my $prereq  = Clownfish::CFC::Model::Prereq->new(
        name    => 'Flour',
        version => $version,
    );
    ok( $prereq, "new prereq" );
    is( $prereq->get_name, 'Flour', 'prereq get_name' );
    is( $prereq->get_version->compare_to($version), 0, 'prereq get_version');
}

BEGIN { use_ok('Clownfish::CFC::Model::Parcel') }

my $foo = Clownfish::CFC::Model::Parcel->new( name => "Foo" );
isa_ok( $foo, "Clownfish::CFC::Model::Parcel", "new" );
ok( !$foo->included, "not included" );
$foo->register;

my $same_name = Clownfish::CFC::Model::Parcel->new( name => "Foo" );
eval { $same_name->register; };
like( $@, qr/parcel .* already registered/i,
      "can't register two parcels with the same name" );

my $same_nick = Clownfish::CFC::Model::Parcel->new(
    name     => "OtherFoo",
    nickname => "Foo",
);
eval { $same_nick->register; };
like( $@, qr/parcel with nickname .* already registered/i,
      "can't register two parcels with the same nickname" );

my $foo_file_spec = Clownfish::CFC::Model::FileSpec->new(
    source_dir  => '.',
    path_part   => 'Foo',
    ext         => '.cfp',
    is_included => 1,
);
my $included_foo = Clownfish::CFC::Model::Parcel->new(
    name      => "IncludedFoo",
    file_spec => $foo_file_spec,
);
ok( $included_foo->included, "included" );
$included_foo->register;

my $parcels = Clownfish::CFC::Model::Parcel->all_parcels;
my @names = sort(map { $_->get_name } @$parcels);
is_deeply( \@names, [ "Foo", "IncludedFoo" ], "all_parcels" );

$foo->add_inherited_parcel($included_foo);
my @inh_names = sort(map { $_->get_name } @{ $foo->inherited_parcels });
is_deeply( \@inh_names, [ "IncludedFoo" ], "inherited_parcels" );

my $json = qq|
        {
            "name": "Crustacean",
            "nickname": "Crust",
            "version": "v0.1.0"
        }
|;
isa_ok(
    Clownfish::CFC::Model::Parcel->new_from_json( json => $json ),
    "Clownfish::CFC::Model::Parcel",
    "new_from_json"
);

isa_ok(
    Clownfish::CFC::Model::Parcel->new_from_file(
        file_spec => Clownfish::CFC::Model::FileSpec->new(
            source_dir => catdir( test_files_dir(), 'cfbase' ),
            path_part  => 'Animal',
            ext        => '.cfp',
        ),
    ),
    "Clownfish::CFC::Model::Parcel",
    "new_from_file"
);

# Register singleton.
my $parcel = Clownfish::CFC::Model::Parcel->new(
    name     => 'Crustacean',
    nickname => 'Crust',
);
$parcel->register;
is( $parcel->get_version->get_vstring, 'v0', "get_version" );

Clownfish::CFC::Model::Parcel->reap_singletons();

{
    my $json = qq|
        {
            "name": "Crustacean",
            "version": "v0.1.0",
            "prerequisites": {
                "Clownfish": null,
                "Arthropod": "v30.104.5"
            }
        }
    |;
    my $parcel = Clownfish::CFC::Model::Parcel->new_from_json( json => $json );

    my $prereqs = $parcel->get_prereqs;
    isa_ok( $prereqs, 'ARRAY', 'prereqs' );
    is( scalar(@$prereqs), 2, 'number of prereqs' );

    my $cfish = $prereqs->[0];
    isa_ok( $cfish, 'Clownfish::CFC::Model::Prereq', 'prereqs[0]');
    is( $cfish->get_name, 'Clownfish', 'prereqs[0] name');
    my $v0 = Clownfish::CFC::Model::Version->new( vstring => 'v0' );
    is( $cfish->get_version->compare_to($v0), 0, 'prereqs[0] version' );

    my $apod = $prereqs->[1];
    isa_ok( $apod, 'Clownfish::CFC::Model::Prereq', 'prereqs[1]');
    is( $apod->get_name, 'Arthropod', 'prereqs[1] name');
    my $v30_104_5 = Clownfish::CFC::Model::Version->new(
        vstring => 'v30.104.5',
    );
    is( $apod->get_version->compare_to($v30_104_5), 0, 'prereqs[1] version' );
}

{
    my $foo_file_spec = Clownfish::CFC::Model::FileSpec->new(
        source_dir  => '.',
        path_part   => 'Foo',
        ext         => '.cfp',
        is_included => 1,
    );
    my $foo = Clownfish::CFC::Model::Parcel->new(
        name      => 'Foo',
        file_spec => $foo_file_spec,
    );
    $foo->register;

    my $cfish_version = Clownfish::CFC::Model::Version->new(
        vstring => 'v0.8.7',
    );
    my $cfish_file_spec = Clownfish::CFC::Model::FileSpec->new(
        source_dir  => '.',
        path_part   => 'Clownfish',
        ext         => '.cfp',
        is_included => 1,
    );
    my $cfish = Clownfish::CFC::Model::Parcel->new(
        name      => 'Clownfish',
        version   => $cfish_version,
        file_spec => $cfish_file_spec,
    );
    $cfish->register;

    my $json = qq|
        {
            "name": "Crustacean",
            "version": "v0.1.0",
            "prerequisites": {
                "Clownfish": "v0.8.5",
            }
        }
    |;
    my $crust = Clownfish::CFC::Model::Parcel->new_from_json( json => $json );
    $crust->register;

    my $prereq_parcels = $crust->prereq_parcels;
    isa_ok( $prereq_parcels, 'ARRAY', 'prereq_parcels' );
    is( scalar(@$prereq_parcels), 1, 'number of prereq_parcels' );
    is( $prereq_parcels->[0]->get_name, 'Clownfish', 'prereq_parcels[0]');

    ok( $crust->has_prereq($cfish), 'has_prereq' );
    ok( $crust->has_prereq($crust), 'has_prereq self' );
    ok( !$crust->has_prereq($foo), 'has_prereq false' );

    $cfish->add_struct_sym('Swim');
    $crust->add_struct_sym('Pinch');
    $foo->add_struct_sym('Bar');
    my $found;
    $found = $crust->lookup_struct_sym('Swim');
    is( $found->get_name, 'Clownfish', 'lookup_struct_sym prereq' );
    $found = $crust->lookup_struct_sym('Pinch');
    is( $found->get_name, 'Crustacean', 'lookup_struct_sym self' );
    $found = $crust->lookup_struct_sym('Bar');
    ok( !$found, 'lookup_struct_sym other' );

    Clownfish::CFC::Model::Parcel->reap_singletons();
}

