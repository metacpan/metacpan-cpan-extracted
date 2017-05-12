# $Id$

use strict;


use Test::More qw/no_plan/;
BEGIN { use_ok ('CGI::Session') };

my $ses = CGI::Session->new();

eval { $ses->is_new() };
is ($@,'', "session has is_new() method");

ok( $ses->is_new(), "a brand new session is_new" ); 

my $ses_id = $ses->id();

my $ses2 = CGI::Session->load($ses_id);

ok( ! $ses2->is_new(), "a session that has been closed and re-opened is not new");


$ses->delete();
$ses2->delete();


