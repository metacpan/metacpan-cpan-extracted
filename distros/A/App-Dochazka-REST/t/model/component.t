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
# basic unit tests for components 
#
#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $meta $site );
use Data::Dumper;
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Component qw( cid_by_path cid_exists path_exists );
use App::Dochazka::REST::Test;
use Test::Fatal;
use Test::More;
use Test::Warnings;


note( "initialize, connect to database, and set up a testing plan" );
initialize_regression_test();

note( 'spawn two component objects' );
my $comp = App::Dochazka::REST::Model::Component->spawn;
isa_ok( $comp, 'App::Dochazka::REST::Model::Component' );
my $comp2 = App::Dochazka::REST::Model::Component->spawn;
isa_ok( $comp2, 'App::Dochazka::REST::Model::Component' );

note( 'they are the same' );
ok( $comp->compare( $comp2 ) );

note( 'set a property' );
my $a = "prdy vody";
$comp->source( $a );
$comp2->source( $a );
is( $comp->source, $a );
is( $comp2->source, $a );
ok( $comp->compare( $comp2 ) );  # still the same
ok( $comp2->compare( $comp ) );

$comp2->source( "jine fody" );
ok( ! $comp->compare( $comp2 ) );  # different

note( 'reset the activities' );
$comp->reset;
$comp2->reset;
ok( $comp->compare( $comp2 ) );
foreach my $prop ( qw( cid path source acl ) ) {
    is( $comp->{$prop}, undef );
    is( $comp2->{$prop}, undef );
}

note( 'test existence and viability of initial set of components' );
note( 'this also conducts positive tests of load_by_path and load_by_cid' );
foreach my $compdef ( @{ $site->DOCHAZKA_COMPONENT_DEFINITIONS } ) {
    my $status = App::Dochazka::REST::Model::Component->load_by_path( $dbix_conn, $compdef->{path} );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' ); 
    is( $status->level, 'OK' );
    $comp = $status->payload; 
    is( $comp->path, $compdef->{path} );
    is( $comp->source, $compdef->{source} );
    is( $comp->acl, $compdef->{acl} );
    $status = App::Dochazka::REST::Model::Component->load_by_cid( $dbix_conn, $comp->cid );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' ); 
    $comp2 = $status->payload;
    is_deeply( $comp, $comp2 );
}

note( 'test some bad parameters' );
like( exception { $comp2->load_by_cid( $dbix_conn, undef ) }, 
      qr/not one of the allowed types/ );
like( exception { $comp2->load_by_path( $dbix_conn, undef ) }, 
      qr/not one of the allowed types/ );
like( exception { App::Dochazka::REST::Model::Component->load_by_cid( $dbix_conn, undef ) }, 
      qr/not one of the allowed types/ );
like( exception { App::Dochazka::REST::Model::Component->load_by_path( $dbix_conn, undef ) }, 
      qr/not one of the allowed types/ );

note( 'load non-existent component' );
my $status = App::Dochazka::REST::Model::Component->load_by_path( $dbix_conn, 'orneryFooBarred' );
is( $status->level, 'NOTICE' );
is( $status->code, 'DISPATCH_NO_RECORDS_FOUND' );
ok( ! exists( $status->{'payload'} ) );
ok( ! defined( $status->payload ) );

note( 'load existent component' );
$status = App::Dochazka::REST::Model::Component->load_by_path( $dbix_conn, 'sample/local_time.mc' );
is( $status->level, 'OK' );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
my $sample_component = $status->payload;
ok( $sample_component->cid );
ok( $sample_component->path );
is( $sample_component->path, 'sample/local_time.mc' );

my $sample_component_cid = cid_by_path( $dbix_conn, 'sample/local_time.mc' );
is( $sample_component_cid, $sample_component->cid );
like ( exception { $sample_component_cid = cid_by_path( $dbix_conn, ( 1..6 ) ); },
       qr/but 2 were expected/ );

is( cid_by_path( $dbix_conn, 'orneryFooBarred' ), undef, 'cid_by_path returns undef if path does not exist' );

note( 'insert a component (success)' );
my $non_bogus_component = App::Dochazka::REST::Model::Component->spawn(
    path => 'non/bogus',
    source => 'An componnennt',
    acl => 'passerby',
);

note( "About to insert non_bogus_component" );
$status = $non_bogus_component->insert( $faux_context );
if ( $status->not_ok ) {
    diag( Dumper $status );
    BAIL_OUT(0);
}
is( $status->level, 'OK' );
ok( defined( $non_bogus_component->cid ) );
ok( $non_bogus_component->cid > 0 );
is( $non_bogus_component->path, 'non/bogus' );
is( $non_bogus_component->source, "An componnennt" );
is( $non_bogus_component->acl, 'passerby' );

note( 'try to insert the same component again (fail with DOCHAZKA_DBI_ERR)' );
$status = $non_bogus_component->insert( $faux_context );
ok( $status->not_ok );
is( $status->level, 'ERR' );
is( $status->code, 'DOCHAZKA_DBI_ERR' );
like( $status->text, qr#Key \(path\)\=\(non/bogus\) already exists# );

note( 'update the component (success)' );
$non_bogus_component->{path} = "bogosITYVille";
$non_bogus_component->{source} = "A bogus component that doesn't belong here";
$non_bogus_component->{acl} = 'inactive';
#diag( "About to update non_bogus_component" );
$status = $non_bogus_component->update( $faux_context );
if ( $status->not_ok ) {
    diag( Dumper $status );
    BAIL_OUT(0);
}
is( $status->level, 'OK' );

note( 'test accessors' );
is( $non_bogus_component->path, 'bogosITYVille' );
is( $non_bogus_component->source, "A bogus component that doesn't belong here" );
is( $non_bogus_component->acl, 'inactive' );

note( 'update without affecting any records' );
$status = $non_bogus_component->update( $faux_context );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

note( 'load it and compare it' );
$status = App::Dochazka::REST::Model::Component->load_by_path( $dbix_conn, $non_bogus_component->path );
is( $status->code, 'DISPATCH_RECORDS_FOUND' );
my $bc2 = $status->payload;
is( $bc2->path, 'bogosITYVille' );
is( $bc2->source, "A bogus component that doesn't belong here" );
is( $bc2->acl, 'inactive' );

my $cid_of_non_bogus_component = $non_bogus_component->cid; 
my $path_of_non_bogus_component = $non_bogus_component->path; 

ok( cid_exists( $dbix_conn, $cid_of_non_bogus_component ) );
ok( path_exists( $dbix_conn, $path_of_non_bogus_component ) );

note( 'CLEANUP: delete the bogus component' );
#diag( "About to delete non_bogus_component" );
$status = $non_bogus_component->delete( $faux_context );
if ( $status->not_ok ) {
    diag( Dumper $status );
    BAIL_OUT(0);
}
is( $status->level, 'OK' );

ok( ! cid_exists( $dbix_conn, $cid_of_non_bogus_component ) );
ok( ! path_exists( $dbix_conn, $path_of_non_bogus_component ) );

note( 'attempt to load the bogus component - no longer there' );
$status = App::Dochazka::REST::Model::Component->load_by_cid( $dbix_conn, $cid_of_non_bogus_component );
is( $status->level, 'NOTICE' );
is( $status->code, 'DISPATCH_NO_RECORDS_FOUND' );
$status = App::Dochazka::REST::Model::Component->load_by_path( $dbix_conn, $path_of_non_bogus_component );
is( $status->level, 'NOTICE' );
is( $status->code, 'DISPATCH_NO_RECORDS_FOUND' );
$status = App::Dochazka::REST::Model::Component->load_by_path( $dbix_conn, 'boguS' );
is( $status->level, 'NOTICE' );
is( $status->code, 'DISPATCH_NO_RECORDS_FOUND' );
$status = App::Dochazka::REST::Model::Component->load_by_path( $dbix_conn, 'bogosITYVille' );
is( $status->level, 'NOTICE' );
is( $status->code, 'DISPATCH_NO_RECORDS_FOUND' );

note( 'generate method on invalid components' );
$comp = App::Dochazka::REST::Model::Component->spawn(
    path => 'blabular_tells',
    source => 'oike mldfield',
    acl => 'passerby',
);
like( $comp->generate, qr/blabular_tells does not exist/ );

$status = $comp->insert( $faux_context );
is( $status->level, 'OK' );
is( $status->code, 'DOCHAZKA_CUD_OK' );

like( $comp->generate, qr/blabular_tells is not a top-level component/ );

done_testing;
