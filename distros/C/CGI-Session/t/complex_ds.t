# $Id: complex_ds.t,v 1.2 2002/11/22 13:09:21 sherzodr Exp $

use strict;


BEGIN { 
    use Test::More tests => 10;
};


# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
use CGI::Session;

my $s = CGI::Session->new('driver:File',undef, {Directory=>"t"} ) or die $CGI::Session::errstr;

ok($s);
ok($s->id());

my $d1 = [qw(1 2 3 4 5 6)];
my $d2 = {1 => "Bir", 2 => "Ikki", 3=>"Uch", 4=>"To'rt", 5=>"Besh", 6=>"Olti"};
my $d3 = {
        d1 => $d1,
        d2 => $d2
};

$s->param(d3 => $d3);

ok($s->param('d3'));

ok( $s->param('d3')->{d1}->[0], 'Test 1');

ok( $s->param('d3')->{d1}->[1], 'Test 2');

ok( $s->param('d3')->{d2}->{1}, 'Bir');

my $sid = $s->id();

$s->flush();

eval { 
    my $s1 = CGI::Session->new('driver:File',$sid, {Directory=>"t"})
        or die $CGI::Session::errstr;

    ok($s1->param('d3'));

    ok( $s1->param('d3')->{d1}->[0], 'Test 1');

    ok( $s1->param('d3')->{d1}->[1], 'Test 2');

    ok( $s1->param('d3')->{d2}->{1}, 'Bir');

    $s1->delete();
};
warn $@ if $@;

