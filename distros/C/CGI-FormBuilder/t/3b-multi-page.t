#!/usr/bin/perl

# Copyright (c) Nate Wiger http://nateware.com.
# All Rights Reserved. If you're reading this, you're bored.
# 3b-multi-page.t - test C::FB::Multi support

package Stub;
sub new { return bless {}, shift }
sub AUTOLOAD { 1 }

package main;

use strict;

our $TESTING = 1;
our $DEBUG = $ENV{DEBUG} || 0;
our $LOGNAME = $ENV{LOGNAME} || '';
our $VERSION;
BEGIN { $VERSION = '3.20'; }

use Test;
use FindBin;

# use a BEGIN block so we print our plan before CGI::FormBuilder is loaded
BEGIN { 
    unshift @INC, "$FindBin::Bin/../lib";
    my $numtests = 42;

    plan tests => $numtests;

    # success if we said NOTEST
    if ($ENV{NOTEST}) {
        ok(1) for 1..$numtests;
        exit;
    }
}


# Fake a submission request
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'ticket=111&user=pete&replacement=TRUE&action=Unsubscribe&name=Pete+Peteson&email=pete%40peteson.com&extra=junk&_submitted=1&blank=&two=&two=&_page=2&_submitted_p2=2';

use CGI::FormBuilder 3.20;
use CGI::FormBuilder::Multi;
use CGI::FormBuilder::Test;

# separate forms
my $form1 = {
    name  => 'p1',
    title => 'Page 1',
    fields => [qw(name email phone address city state zip extra)],
};
my $form2 = {
    name  => 'p2',
    title => 'Numero Dos',
    fields => 'ticket',
};
my $form3 = {
    name  => 'p3',
    title => 'Tres Tacos',
    fields => [qw(replacement ticket action)],
    # undocumented hooks
    fieldopts => {
        replacement => {
            options => [qw(TRUE FALSE MAYBE)],
            value   => 'FALSE',
            label   => 'MikeZ is Da"Bomb"'
        },
        ticket => {
            comment => 'master mister',
            value   => '-1million',
            force   => 1,
        },
        action => {
            label   => ' JackSUN ',
            value   => "Your mom if I'm lucky",
            type    => 'PASSWORD',
            misc    => 'ellaneous',
        },
    },
    header => 1,
};

my $multi = CGI::FormBuilder::Multi->new(
                 $form1, $form2, $form3,

                 header => 0,
                 method => 'Post',
                 action => '/page.pl',
                 debug  => $DEBUG,
                 columns => 1,

                 navbar => 0,
            );

my $form = $multi->form;
ok($form->name, 'p2');  #1

ok($multi->page, 2);    #2
ok($multi->pages, 3);   #3
ok(--$multi->page, 1);  #4

$form = $multi->form;
ok($form->name, 'p1');          #5
ok($form->title, 'Page 1');     #6
ok(keys %{$form->field}, 8);    #7
ok($form->field('email'), 'pete@peteson.com');  #8
ok($form->submitted, 0);        # 9
ok($form->action, '/page.pl');  #10
ok($form->field('blank'), undef);  #11

ok($multi->page++, 1);      #12
ok($multi->page,   2);      #13
ok($form = $multi->form);   #14
ok(++$multi->page, $multi->pages); #15
ok($form = $multi->form);   #16
ok(++$multi->page, $multi->pages+1); #17
eval { $form = $multi->form };  # should die
ok($@);                     #18 ^^^ from die
ok($multi->page = $multi->pages, 3);    #19

ok($form = $multi->form);   #20
ok($form->field('replacement'), 'TRUE');  # 21

# hack
my $ren = $form->render;
if ($LOGNAME eq 'nwiger') {
    open(REN, ">/tmp/fb.2.html");
    print REN $ren;
    close(REN);
}

ok($ren, outfile(22));  #22
ok($form->field('action'), 'Unsubscribe');  #23
ok($form->field('ticket'), '-1million');    #24
ok(--$multi->page, 2);      #25
ok($form = $multi->form);   #26
ok($form->field('ticket'), 111);    #27
ok($form->field('extra'), undef);   #28 - not a form field

ok($multi->page(1), 1);     #29
ok($form = $multi->form);   #30
ok($form->field('ticket'), undef);  #31 - not a form field
ok($form->field('extra'), 'junk');  #32 

# Session twiddling - must use page 3
ok($multi->page(3), 3);     #33
ok($form = $multi->form);   #34

# Try to bootstrap CGI::Session and skip otherwise
my $session;
eval <<'EOE';
use Cwd;
my $pwd = cwd;
require CGI::Session;
$session = CGI::Session->new("driver:File", undef, {Directory => $pwd});
EOE

# Placeholders so code can continue
$session ||= new Stub;
our $NOSESSION = $@ ? 'skip: CGI::Session not installed here' : 0;

skip($NOSESSION, $form->sessionid($session->id), $session->id);     #35

# Trick ourselves into producing a header w/ cookie
my $c;
{ local $TESTING = 0; ($c) = $form->header =~ /Set-Cookie: (\S+)/; }
skip($NOSESSION, $c, '_sessionid='.$session->id.';');               #36

# Empty return value?
$session->save_param($form) unless $NOSESSION;

skip($NOSESSION, $session->param('ticket'), $form->field('ticket'));#37

skip($NOSESSION, $session->param('name'), $form->field('name'));    #38

# reset name forcibly
ok($form->field(name => 'name', value => 'Tater Salad', force => 1));   #39
skip($NOSESSION, $session->param('name', $form->field('name')));    #40
skip($NOSESSION, $session->param('name'), 'Tater Salad');    #41

skip($NOSESSION, $session->param('email'), undef);      #42

# cleanup
undef $session;
system 'rm -f cgisess*';
