#!/usr/bin/perl

# Copyright (c) Nate Wiger http://nateware.com.
# All Rights Reserved. If you're reading this, you're bored.
# 1b-fields.t - test Field generation/handling

use strict;

our $TESTING = 1;
our $DEBUG = $ENV{DEBUG} || 0;
our $LOGNAME = $ENV{LOGNAME} || '';
our $VERSION;
BEGIN { $VERSION = '3.20'; }

use Test;
use FindBin;
use File::Find;

# use a BEGIN block so we print our plan before CGI::FormBuilder is loaded
BEGIN { 
    unshift @INC, "$FindBin::Bin/../lib";

    my $numtests = 26;
    plan tests => $numtests;

    # success if we said NOTEST
    if ($ENV{NOTEST}) {
        ok(1) for 1..$numtests;
        exit;
    }
}

# Fake a submission request
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'ticket=111&user=pete&replacement=TRUE&action=Unsubscribe&name=Pete+Peteson&email=pete%40peteson.com&extra=junk&_submitted=1&blank=&two=&two=&other_test=_other_other_test&_other_other_test=42&other_test_2=_other_other_test_2&_other_other_test_2=nope';

use CGI::FormBuilder 3.20;
use CGI::FormBuilder::Test;

# jump to a test if specified for debugging (goto eek!)
my $t = shift;
if ($t) {
    eval sprintf("goto T%2.2d", $t);
    die;
}

# Now manually try a whole bunch of things
#1
T01: ok(do {
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => [qw/user name email/]);
    if ($form->submitted) {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#2
T02: ok(do {
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields   => [qw/user name email/],
                                     validate => { email => 'EMAIL' } );
    if ($form->submitted && $form->validate) {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#3
T03: ok(do {
    # this should fail since we are saying our email should be a netmask
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => [qw/user name email/],
                                     validate => { email => 'NETMASK' } );
    if ($form->submitted && $form->validate) {
        0;  # failure
    } else {
        1;
    }
}, 1);
exit if $t;

#4
T04: ok(do {
    # this should also fail since the submission key will be _submitted_magic,
    # and our query_string only has _submitted in it
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => [qw/user name email/],
                                     name   => 'magic');
    if ($form->submitted) {
        0;  # failure
    } else {
        1;
    }
}, 1);
exit if $t;

#5
T05: ok(do {
    # CGI should override default values
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => [qw/user name email/],
                                     values => { user => 'jim' } );
    if ($form->submitted && $form->field('user') eq 'pete') {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#6
T06: ok(do {
    # test a similar thing, by with mixed-case values
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => [qw/user name email Addr/],
                                     values => { User => 'jim', ADDR => 'Hello' } );
    if ($form->submitted && $form->field('Addr') eq 'Hello') {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#7
T07: ok(do {
    # test a similar thing, by with mixed-case values
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => { User => 'jim', ADDR => 'Hello' } );
    if ($form->submitted && ! $form->field('Addr') && $form->field('ADDR') eq 'Hello') {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#8
T08: ok(do {
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => []);   # no fields!
    if ($form->submitted) {
        if ($form->field('name') || $form->field('extra')) {
            # if we get here, this means that the restrictive field
            # masking is not working, and all CGI params are available
            -1;
        } elsif ($form->cgi_param('name')) {
            1;
        } else {
            0;
        }
    } else {
            0;
    }
}, 1);
exit if $t;

#9
T09: ok(do {
    # test if required does what v1.97 thinks it should (should fail)
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => { user => 'nwiger', pass => '' },
                                     validate => { user => 'USER' },
                                     required => [qw/pass/]);
    if ($form->submitted && $form->validate) {
        0;
    } else {
        1;
    }
}, 1);
exit if $t;

#10
T10: ok(do {
    # YARC (yet another 'required' check)
    my $form = CGI::FormBuilder->new(
                    debug => $DEBUG,
                    fields => [qw/name email phone/],
                    validate => {email => 'EMAIL', phone => 'PHONE'},
                    required => [qw/name email/],
               );
    if ($form->submitted && $form->validate) {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#11
T11: ok(do {
    # test of proper CGI precendence when manually setting values
    my $form = CGI::FormBuilder->new(
                    debug => $DEBUG,
                    fields => [qw/name email action/],
                    validate => {email => 'EMAIL'},
                    required => [qw/name email/],
               );
    $form->field(name => 'action', options => [qw/Subscribe Unsubscribe/],
                 value => 'Subscribe');
    if ($form->submitted && $form->validate && $form->field('action') eq 'Unsubscribe') {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#12
T12: ok(do {
    # test of proper CGI precendence when manually setting values
    my $form = CGI::FormBuilder->new(
                    debug => $DEBUG,
                    fields => [qw/name email blank notpresent/],
                    values => {blank => 'DEF', name => 'DEF'}
               );
    if (defined($form->field('blank'))
        && ! $form->field('blank') 
        && $form->field('name') eq 'Pete Peteson'
        && ! defined($form->field('notpresent'))
    ) {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#13
T13: ok(do {
    # test of proper CGI precendence when manually setting values
    my $form = CGI::FormBuilder->new(
                    debug => $DEBUG,
                    fields => [qw/name email blank/],
                    keepextras => 0,    # should still get value
                    action => 'TEST',
               );
    if (! $form->field('extra') && 
        $form->cgi_param('extra') eq 'junk') {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#14
T14: ok(do{
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => [qw/name color dress_size taco:punch/]);
    $form->field(name => 'blank', value => 175, force => 1);
    $form->field(name => 'user', value => 'bob');

    if ($form->field('blank') eq 175 && $form->field('user') eq 'pete') {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#15
T15: ok(do{
    my $form = CGI::FormBuilder->new(
                        debug => $DEBUG,
                        smartness  => 0,
                        javascript => 0,
                   );

    $form->field(name => 'blank', value => 'aoe', type => 'text'); 
    $form->field(name => 'extra', value => '24', type => 'hidden', override => 1);
    $form->field(name => 'two', value => 'one');

    my @v = $form->field('two');
    if ($form->submitted && $form->validate && defined($form->field('blank')) && ! $form->field('blank')
        && $form->field('extra') eq 24 && @v == 2) {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#16
T16: ok(do{
    my $form = CGI::FormBuilder->new(debug => $DEBUG);
    $form->fields([qw/one two three/]);
    my @v;
    if (@v = $form->field('two') and @v == 2) {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#17
T17: ok(do{
    my $form = CGI::FormBuilder->new(
                    debug => $DEBUG,
                    fields => [qw/one two three/],
                    fieldtype => 'TextAREA',
               );
    $form->field(name => 'added_later', label => 'Yo');
    my $ok = 1;
    for ($form->fields) {
        $ok = 0 unless $_->render =~ /textarea/i;
    }
    $ok;
}, 1);
exit if $t;

#18
T18: ok(do{
    my $form = CGI::FormBuilder->new(
                    debug => $DEBUG,
                    fields => [qw/a b c/],
                    fieldattr => {type => 'TOMATO'},
                    values => {a => 'Ay', b => 'Bee', c => 'Sea'},
               );
    $form->values(a => 'a', b => 'b', c => 'c');
    my $ok = 1;
    for ($form->fields) {
        $ok = 0 unless $_->value eq $_;
    }
    $ok;
}, 1);
exit if $t;

#19
T19: ok(do{
    my $form = CGI::FormBuilder->new(
                    fields  => [qw/name user/],
                    required => 'ALL',
                    sticky  => 0,
               );
    my $ok = 1;
    my $name = $form->field('name');
    $ok = 0 unless $name eq 'Pete Peteson';
    my $user = $form->field('user');
    $ok = 0 unless $user eq 'pete';
    for ($form->fields) {
        $ok = 0 unless $_->tag eq qq(<input id="$_" name="$_" type="text" />);
    }
    $ok;
}, 1);
exit if $t;

#20 - other field values
T20: ok(do{
    my $form = CGI::FormBuilder->new;
    $form->field(name => 'other_test', other => 1, type => 'select');
    $form->field(name => 'other_test_2', other => 0, value => 'nope');
    my $ok = 1;
    $ok = 0 unless $form->field('other_test') eq '42';
    $ok = 0 unless $form->field('other_test_2') eq '_other_other_test_2';
    $ok;
}, 1);
exit if $t;

#21 - inflate coderef
T21: ok(do{
    my $form = CGI::FormBuilder->new;
    $form->field(
        name    => 'inflate_test', 
        value   => '2003-04-05 06:07:08', 
        inflate => sub { return [ split /\D+/, shift ] },
    );
    my $ok = 1;
    my $val = $form->field('inflate_test');
    $ok = 0 unless ref $val eq 'ARRAY';
    my $i = 0;
    $ok = 0 if grep { ($val->[$i++] != $_) } 2003, 4, 5, 6, 7, 8;
    $ok;
}, 1);

#22 - don't tell anyone this works
T22: ok(do{
    my $form = CGI::FormBuilder->new;
    my $val  = $form->field(
        name    => 'forty-two', 
        value   => 42
    );
    $val == 42;
}, 1);


#23 - try to catch bad \%opt destruction errors
T23: ok(do{
    my $opt = {
        source  => {type => 'File',
                    source => \"name: one\nfields:a,b"},
        values  => {a=>1,b=>2,c=>3,d=>4},
        options => {a=>[1,2,3], d=>[4..10]},
        submit  => 'Yeah',
    };
    my $form1 = CGI::FormBuilder->new($opt);
    my $render1 = $form1->render;
    my $form2 = CGI::FormBuilder->new($opt);
    my $render2 = $form2->render;

    $opt->{source} = {
        type => 'File',
        source => \"name: two\nmethod:post\nfields:c,d",
    };
    my $form3 = CGI::FormBuilder->new($opt);

    $render1 eq $render2
        && ! $form3->{fieldrefs}{a} && ! $form3->{fieldrefs}{b};
    #warn "RENDER1 = $render1";
    #warn "RENDER3 = " . $form3->render;
}, 1);


#24 - fucking rt.cpan shit
T24: ok(do{
    my $form = CGI::FormBuilder->new;
    $form->field(name => 'other_test', other => 1, type => 'select',
                 options => [1..5],    value => 6);
    my $ok = 1;
    # you know what? fuck Perl
    $form->script;  # internals thing
    my($f) = grep /^other_test$/, $form->field;
    my $h = $f->tag . "\n";
    $h eq outfile(24) ? 1 : 0;
}, 1);

#25 - fucking rt.cpan shit
T25: ok(do{
    my $form = CGI::FormBuilder->new;
    $form->field(name => 'butter_test', other => 1, type => 'select',
                 options => [1..5]);    # no value
    my $ok = 1;
    # you know what? fuck Perl
    $form->script;  # internals thing
    my($f) = grep /^butter_test$/, $form->field;
    my $h = $f->tag . "\n";
    $h eq outfile(25) ? 1 : 0;
}, 1);

#26 - fucking rt.cpan shit
T26: ok(do{
    my $form = CGI::FormBuilder->new;
    $form->field(name => 'butter_test', other => 1, type => 'select',
                 options => [1..5], value => undef);    # undef value
    my $ok = 1;
    # you know what? fuck Perl
    $form->script;  # internals thing
    my($f) = grep /^butter_test$/, $form->field;
    my $h = $f->tag . "\n";
    $h eq outfile(26) ? 1 : 0;
}, 1);

