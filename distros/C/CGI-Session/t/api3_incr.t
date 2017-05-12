# $Id: api3_incr.t,v 1.2 2002/11/22 22:54:41 sherzodr Exp $

use strict;


BEGIN {
    require Test::More;
    Test::More->import();
    
    plan(tests => 14); 
};

use File::Spec;
use CGI::Session qw/-api3/;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $dr_args = {Directory=>'t', IDFile=>File::Spec->catfile('t', 'cgisess.id')};
my $args    = "id:Incr";

my $s = CGI::Session->new($args, undef, $dr_args );

ok($s);
ok($s->id);

$s->param(author=>'Sherzod Ruzmetov', name => 'CGI::Session', version=>'1'   );

ok($s->param('author'));
ok($s->param('name'));
ok($s->param('version'));


$s->param(-name=>'email', -value=>'sherzodr@cpan.org');

ok($s->param(-name=>'email'));
ok(!$s->expire() );

$s->expire("+10m");

ok($s->expire());

my $sid = $s->id();

$s->flush();

my $s2 = CGI::Session->new($args, $sid, $dr_args);

ok($s2);
ok($s2->id() eq $sid);
ok($s2->param('email'));
ok($s2->param('author'));
ok($s2->expire());

$s2->delete();

