#!/usr/bin/perl

# Copyright (c) Nate Wiger http://nateware.com.
# All Rights Reserved. If you're reading this, you're bored.
# 3a-source-file.t - test C::FB::Source::File support

use strict;

our $TESTING = 1;
our $DEBUG = $ENV{DEBUG} || 0;
our $LOGNAME = $ENV{LOGNAME} || '';
our $VERSION;
BEGIN { $VERSION = '3.10'; }

use Test;
use FindBin;

# use a BEGIN block so we print our plan before CGI::FormBuilder is loaded
BEGIN {
    my $numtests = 20;
    unshift @INC, "$FindBin::Bin/../lib";

    plan tests => $numtests;

    # success if we said NOTEST
    if ($ENV{NOTEST}) {
        ok(1) for 1..$numtests;
        exit;
    }
}


# Need to fake a request or else we stall
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'ticket=111&user=pete&replacement=TRUE&action=Unsubscribe&name=Pete+Peteson&email=pete%40peteson.com&extra=junk';

use CGI::FormBuilder 3.10;
use CGI::FormBuilder::Test;

# For testing sortopts in test 18
sub refsort {
    $_[0] <=> $_[1]
}
sub getopts {
    return [99,9,8,83,7,73,6,61,66,5,4,104,3,2,10,1,101];
}

# What options we want to use, and what we expect to see
my @test = (
    #1
    {
        str => '
fields:
    name
    email
sticky: 0
',
    },

    #2
    {
        str => '
# comment
fields:
    Upper:
        type: password
    Case: 
        value: 3
values:
    Upper: 1
    Case: 0
',
    },

    #3
    {
        str => '
# test three
fields:

    first_name

        last_name

submit: Update

  reset: 0
',
    },

    #4
    {
        str => '
fields:
   first_name
    last_name:
        type: text
submit: Update
reset: 0
header: 1
body:
    bgcolor: black
',
    },

    #5
    {
        str => '
# rewritten fields hash
    # as a set of values
fields:
    email:
        required: 0

    first_name:
        required: 1

values:
     first_name: Nate
     email: nate@wiger.org

validate:
    email: EMAIL
sticky: 0
',
    },

    #6
    {
        # utilize our query_string to test stickiness
        str => '
fields:
    ticket
    user
    part_number

method: post
keepextras: 1

validate:
    ticket: /^\d+$/

submit: Update,Delete,Cancel
',
    },

    #7
    {
        # max it out, baby
        str => '
fields: supply, demand
options:
    supply: 0=A,1=B,2=C,3,4,5,6,7=D,8=E,9=F
    demand: 0=A,1=B,2=C,3,4,5,6,7=D,8=E,9=F

values:
    supply: 0,1,2,3,4
    demand: 5,6,7,8,9

method: put
title:  Econ 101
header
name: econ
font: arial,helvetica,courier
stylesheet: 1
fieldtype: select
',
    },

    #8
    {
        str => '
fields: db:name,db:type,db:tab,ux:user,ux:name
static: 1
',
    },

    #9
    {
        # single-line search thing ala Yahoo!
        str => "fields: search \r\n submit: Go \n\r reset: 0 \r table: 0",
    },

    #10
    {
        str => '
fields:
    hostname
  domain
header: 1

# will come out (ticket,user) b/c of QUERY_STRING
keepextras: user,ticket

values: localhost,localdomain
validate:
    hostname: HOST
  domain:           DOMAIN          
',
    },
 
    #11
    {
        str => '
fields:
    email: 
        value: nate@wiger.org
    first_name:
        value: Nate

validate:
    email: EMAIL

required: first_name

javascript: 0
',
    },

    #12
    {
        str => '
fields: earth, wind, fire, water
fieldattr:
    type: TEXT
',
    },

    #13
    {
        str => '
fields:
    earth
   wind
    columns: 1
  fire
 water
notafield
options:
 wind: <Slow>, <Medium>, <Fast>
   fire: &&MURDEROUS", &&HOT", &&WARM", &&COLD", &&CHILLY", &&OUT"
values:
                            water: >>&c0ld&<<
                                                        earth: Wind >>
            fire: &&MURDEROUS", &&HOT"
',
    },

    #14 - option maxing
    {
        str => '
fields:
    multiopt

values: 
    multiopt: 1,2,6,9

options: 
    multiopt: 1 = One, 2 = Two , 3 = Three, 7 = Seven, 8 = Eight, 9 = Nine,
              4 = Four, 5 = Five,  6 = Six, 10 = Ten
sortopts: NUM,
',
    },

    #15 - obscure features
    {
        str => '
fields: plain, jane,    mane
nameopts: 1

    # Style is important
   stylesheet: /my/own/style.css
   styleclass: yo.

body:
    ignore: me
javascript: 0
jsfunc:// missing
labels:
 plain:AAA
 jane: BBB
options:
 mane: ratty,nappy,mr_happy
selectnum: 0
title: Bobby
header: On
',
    },

    #16
    {
        str => '
fields: 
   name:
        comment: Hey buddy
   email:
     comment: No email >> address??

sticky: 0
',
    },

    #17
    {
        str => '
fields:
    won:
        jsclick: taco_punch = 1, taco_salad = "yummy"
    too:
        options: 0,1,2
        jsclick: this.salami.value = "delicious"
        columns: 1
    many:
        options: 0,1,2,3,4,5,6,7,8,9
        jsclick: this.ham.value = "it\'s a pig, man!"
        columns: 1
    cb_input:
        type: checkbox
        label: Option
        options: active=Have this item active
',
    },

    #18
    {
        str => '
fields:
    refsort:
      sortopts: \&refsort
     options:  \&getopts
',
    },

    #19 - table attr and field columns
    {
        str => '
fields:
    a:
        options: 0,1,2,3
        columns: 2
        value: 1,2
    b:
        options: 4,5,6,7,8,9
        columns: 3
        comment: Please fill these in

    c

lalign: today

table:
    border: 1
td:
    taco: beef
    align: right
tr:
    valign: top
th: 
    ignore: this
selectnum: 10
',
        mod => { a => { options => [0..3], columns => 2, value => [1..2] },
                 b => { options => [4..9], columns => 3, comment => "Please fill these in" },
               },
    },

    #20 - order.cgi from manpage (big)
    {
        str => '
name: order
method: post
fields:
  first_name
  last_name
  email
  send_me_emails:
     options: 1=Yes,0=No
     columns: 1
     value: 0
  address
  state:
        options: JS,IW,KS,UW,JS,UR,EE,DJ,HI,YK,NK,TY
        sortopts: NAME
        columns: 1
  zipcode
  credit_card
  expiration

header: 1,
title:  Finalize Your Order
submit: Place Order, Cancel
reset: 0

validate:
    email: EMAIL
    zipcode: ZIPCODE
  credit_card: CARD
   expiration: MMYY

messages:
    form_invalid_text:  You fucked up. Check it:
    form_required_text: Don\'t fuck up, it causes me work. Fuck,try again, ok?
    js_invalid_input:   - Enter shit in the "%s" field

required: ALL
jsfunc: <<EOJS
    // skip validation if they clicked "Cancel"
    if (form._submit.value == \'Cancel\') return true;
EOJS
',
    },
);

# Perl is sick.
@test = @test[$ARGV[0] - 1] if @ARGV;
my $seq = $ARGV[0] || 1;

# Cycle thru and try it out
for (@test) {

    my %conf = (source => {type => 'File', source => \"$_->{str}"});
    $conf{action} = 'TEST';

    my $form = CGI::FormBuilder->new(%conf);
    $form->{title} = 'TEST' unless $form->{title};

    # just compare the output of render with what's expected
    my $ren = $form->render;
    my $out = outfile($seq++);
    my $ok = ok($ren, $out);

    if (! $ok && $LOGNAME eq 'nwiger') {

        open(O, ">/tmp/fb.1.html");
        print O $out;
        close O;

        open(O, ">/tmp/fb.2.html");
        print O $ren;
        close O;

        system "diff /tmp/fb.1.html /tmp/fb.2.html";
        exit 1;
    }
}
