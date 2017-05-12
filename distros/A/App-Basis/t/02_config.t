#!/usr/bin/perl -w

=head1 NAME

config.t

=head1 DESCRIPTION

test App::Basis::Config

=head1 AUTHOR

kevin mulholland, moodfarm@cpan.org

=cut

use v5.10 ;
use strict ;
use warnings ;

use Test::More tests => 19 ;
use Path::Tiny ;

BEGIN { use_ok('App::Basis::Config') ; }

my @cleanup ;

# write out some config, then read it back and check it
# YAML should have blank line at the end
my $config_str = <<EOF;
name: fred
block: 
    bill: 
        item: one
last: item

EOF

my $config_file = "/tmp/$$.test" ;
push @cleanup, $config_file ;
path( $config_file)->spew( $config_str ) ;

# if the config is not processed properly, we will end the test with a die
my $cfg = App::Basis::Config->new( filename => $config_file, die_on_error => 1 ) ;
isa_ok( $cfg, 'App::Basis::Config' ) ;
my $data = $cfg->raw ;

# test that the data was read in OK
ok( $data->{name}                  eq 'fred', 'name field' ) ;
ok( $data->{block}->{bill}->{item} eq 'one',  'deep nested field' ) ;
ok( $data->{last}                  eq 'item', 'item field' ) ;

# now test that the path based access works
my $name = $cfg->get('name') ;
ok( $cfg->get('name')             eq 'fred', 'get name field' ) ;
ok( $cfg->get('/block/bill/item') eq 'one',  'get deep nested field' ) ;
ok( $cfg->get('last')             eq 'item', 'get item field' ) ;

# now test setting
$cfg->set( 'test1', 123 ) ;
$data = $cfg->raw ;
ok( $cfg->get('test1') == 123, 'set basic' ) ;
$cfg->set( 'test2/test3/test4', 124 ) ;
ok( $cfg->get('test2/test3/test4') == 124, 'set deep nested' ) ;

# test path sepator variants
ok( $cfg->get(':test2:test3:test4') == 124, 'allow colon path separators' ) ;
ok( $cfg->get('test2.test3.test4.') == 124, 'allow period path separators' ) ;

# test saving
my $new_file = "$config_file.new" ;
push @cleanup, $new_file ;
my $status   = $cfg->store($new_file) ;
ok( $status == 1, 'store' ) ;

# was it saved correctly
my $new = App::Basis::Config->new( filename => $new_file, nostore => 1 ) ;
is_deeply( $cfg->raw, $new->raw, 'Save and reload' ) ;

# make sure something has changed, otherwise there will be no store
$new->set( 'another/item', 27 ) ;

# new config should not save
$status = $new->store() ;
ok( $status == 0, 'nostore' ) ;

# test creation of config from scratch
my $another_file = "$config_file.scratch" ;
push @cleanup, $another_file ;
$new = App::Basis::Config->new( filename => $another_file) ;
$new->set( "/one/two/three", "four") ;
ok( $new->get("/one/two/three") eq "four", 'set deep path' ) ;
$new->store() ;
ok( -f $another_file, "Stored new file") ;

# store and retrive hashes
$data = { fred => 'one', bill => 2, barney => { value => 'three'} } ;
$new->set( "/complex", $data) ;
is_deeply( $new->raw->{complex}, $data, 'Store complex' ) ;
my $complex = $new->get( '/complex') ;
is_deeply( $complex, $data, 'retrieve complex' ) ;

# and clean up the files we have created
map { unlink $_ ; } @cleanup ;

# -----------------------------------------------------------------------------
# completed all the tests
