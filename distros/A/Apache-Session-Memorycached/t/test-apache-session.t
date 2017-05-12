#====================================================================
# Test script for Apache::Session::Memorycached
#
# 2006 (c) Eric German
#====================================================================

#====================================================================
# Perl test modules
#====================================================================
use Test::More tests => 3;

#====================================================================
# Module loading
#====================================================================
BEGIN{ use_ok( Apache::Session::Memorycached ); }
BEGIN{ print "--> Version : ".$Apache::Session::Memorycached::VERSION."\n"; }

#====================================================================
# Object creation
#====================================================================
my $id;
my %session;
tie %session, 'Apache::Session::Memorycached', $id,
                                {
                         'servers' => ["localhost:11211"],
                                };

$id=  $session{"_session_id"};
ok( $id,"session ID : $id" );
$session{'test'}='memcached daemon running' ;
$session{'test2'}='ericgerman' ;
untie %session ;
tie %session, 'Apache::Session::Memorycached', $id,
                                {
                         'servers' => ["localhost:11211"],
                                };
$session{test} = 'memcached daemon not running' unless $session{test};
is($session{test},'memcached daemon running',"memcached ready"); 
untie %session;

