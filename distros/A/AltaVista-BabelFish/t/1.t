# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 17;
BEGIN { use_ok('AltaVista::BabelFish') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $noarg = AltaVista::BabelFish->new();
ok( $noarg->get_source() eq 'en', 'empty new() source is ' . $noarg->get_english('en') ); 
ok( $noarg->get_target() eq 'es', 'empty new() target is ' . $noarg->get_english('es') );


my $trarg = AltaVista::BabelFish->new({ target => 'fr' });
ok( $trarg->get_source() eq 'en', 'target new() source is ' . $noarg->get_english('en') ); 
ok( $trarg->get_target() eq 'fr', 'target new() target is ' . $noarg->get_english('fr') );

my $srarg = AltaVista::BabelFish->new({ source => 'fr' });
ok( $srarg->get_source() eq 'fr', 'source new() source is ' . $noarg->get_english('fr') );
ok( $srarg->get_target() eq 'en', 'source new() target is ' . $noarg->get_english('en') );

my $btarg = AltaVista::BabelFish->new({ source => 'fr', target => 'nl' });
ok( $btarg->get_source() eq 'fr', 'both new() source is ' . $noarg->get_english('fr') );
ok( $btarg->get_target() eq 'nl', 'both new() target is ' . $noarg->get_english('nl') );

my $trarg_inv = AltaVista::BabelFish->new({ target => 'xx' }); 
ok( $trarg_inv->get_source() eq 'en', 'target new() with invalid target src: ' . $noarg->get_english('en') );
ok( $trarg_inv->get_target() eq 'es', 'target new() with invalid target trg: ' . $noarg->get_english('es') );

my $srarg_inv = AltaVista::BabelFish->new({ source => 'xx' });
ok( $srarg_inv->get_source() eq 'en', 'source new() with invalid source src: ' . $noarg->get_english('en') );
ok( $srarg_inv->get_target() eq 'es', 'source new() with invalid source trg: ' . $noarg->get_english('es') );

my $btarg_inv = AltaVista::BabelFish->new({ source => 'nl', target => 'es' }); # Dutch does not translate into Spanish
ok( $btarg_inv->get_source() eq 'nl', 'target mismatch new() src: ' . $noarg->get_english('nl') );
ok( $btarg_inv->get_target() eq 'en', 'target mismatch new() trg: ' . $noarg->get_english('en') );

my $btarg_inv_x = AltaVista::BabelFish->new({ source => 'xx', target => 'es' }); 
ok( $btarg_inv_x->get_source() eq 'en', 'invalid source new() keeps trg - src: ' . $noarg->get_english('en') );
ok( $btarg_inv_x->get_target() eq 'es', 'invalid source new() keeps trg - trg: ' . $noarg->get_english('es') );
