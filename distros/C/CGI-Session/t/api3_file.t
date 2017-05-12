# $Id: api3_file.t,v 1.3.4.1 2003/07/26 13:37:36 sherzodr Exp $

use strict;


BEGIN {     
    use Test::More;
    plan(tests => 17); 
    use_ok('CGI::Session');
};

my $s = CGI::Session->new("dr:File;ser:Default;id:MD5", undef, {Directory=>"t"} );

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

my $s2 = CGI::Session->new(undef, $sid, {Directory=>'t'});
ok($s2);

ok($s2->id() eq $sid);

ok( $s2->param('email'),  "found email param in session");
ok( $s2->param('author'), "found author param in session");
ok( $s2->expire() );

eval { $s2->clear('email'); };
is($@, '', '$s->clear("name") survives eval');
ok(($s2->param('email') ? 0 : 1), "email param is cleared from session");
ok($s2->param('author'), "author param is still in session");

$s2->delete();

