#!/usr/bin/perl

# Copyright (c) Nate Wiger http://nateware.com.
# All Rights Reserved. If you're reading this, you're bored.
# 2d-template-fast.t - test CGI::FastTemplate support

use strict;

our $TESTING = 1;
our $DEBUG = $ENV{DEBUG} || 0;
our $LOGNAME = $ENV{LOGNAME} || '';
our $VERSION;
BEGIN { $VERSION = '3.20'; }

use Test;
use FindBin;

# use a BEGIN block so we print our plan before CGI::FormBuilder is loaded
our $SKIP;
BEGIN {
    my $numtests = 4;
    unshift @INC, "$FindBin::Bin/../lib";

    plan tests => $numtests;

    # try to load template engine so absent template does
    # not cause all tests to fail
    eval "require CGI::FastTemplate";
    $SKIP = $@ ? 'skip: CGI::FastTemplate not installed here' : 0;

    # success if we said NOTEST
    if ($ENV{NOTEST}) {
        ok(1) for 1..$numtests;
        exit;
    }
}


# Need to fake a request or else we stall
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'ticket=111&user=pete&replacement=TRUE';

use CGI::FormBuilder 3.20;
use CGI::FormBuilder::Test;

# Create our template and store it in a scalarref
my $template = <<'EOT';
<html>
<title>User Info</title>
Please update your info and hit "Submit".
$JS_HEAD
$START_FORM
$FIELDS
$SUBMIT
$FORM_END
EOT

my $fieldtmpl = <<'EOT';
<tr class="$REQUIRED"><th>$LABEL</th><td>$FIELD $COMMENT</td></tr>
EOT

my $fieldinv = <<'EOT';
<tr class="$REQUIRED invalid"><th>$LABEL</th><td>$FIELD $COMMENT $ERROR</td></tr>
EOT

# What options we want to use, and what we expect to see
my @test = (
    {
        opt => { fields => [qw/name color/],
                 submit => 'No esta una button del resetto',
                 template => {
                        type => 'Fast',
                        define_nofile => {
                            form => $template,
                            field => $fieldinv,
                            field_invalid => $fieldinv,
                        }
                 },
                 validate => { name => 'NAME' },
               },
        mod => { color => { options => [qw/red green blue/],
                            label => 'Best Color', value => 'red' },
                 size  => { value => 42 },
                 sex   => { options => [[M=>'Male'],[F=>'Female']] }
               },
    },

    {
        opt => { fields => [qw/name color size/],
                 template => {
                        type => 'Fast',
                        define_nofile => {
                            form => $template,
                            field => $fieldinv,
                            field_invalid => $fieldinv,
                        }
                 },
                 values => {color => [qw/purple/], size => 8},
                 submit => 'Start over, boob!',
               },

        mod => { color => { options => [[white=>'White'],[black=>'Black'],[red=>'Green']],
                            label => 'Mom', },
                 name => { size => 80, maxlength => 80, comment => 'Fuck off' },
                 sex   => { options => [[1=>'Yes'], [0=>'No'], [2=>'Maybe']],
                            label => 'Fuck me?<br>' },
               },
    },

    {
        opt => { fields => [qw/name color email/], submit => [qw/Update Delete/], reset => 0,
                 template => {
                        type => 'Fast',
                        define_nofile => {
                            form => $template,
                            field => $fieldinv,
                            field_invalid => $fieldinv,
                        }
                 },
                 values => {color => [qw/yellow green orange/]},
                 validate => { sex => [qw(1 3 5)] },
               },

        mod => { color => {options => [[red => 1], [blue => 2], [yellow => 3], [pink => 4]] },
                 size  => {comment => '(unknown)', value => undef, force => 1 } ,
                 sex   => {label => 'glass EYE fucker', options => [[1,2],[3,4],[5,6]] },
               },
    },


);

# Perl 5 is sick sometimes.
@test = @test[$ARGV[0] - 1] if @ARGV;
my $seq = $ARGV[0] || 1;

# Cycle thru and try it out
for my $test_item (@test) {
    my $form = CGI::FormBuilder->new(
                    debug => $DEBUG,
                    action => 'TEST',
                    title  => 'TEST',
                    %{ $test_item->{opt} },
               );

    # the ${mod} key twiddles fields
    for my $field ( sort keys %{ $test_item->{mod} || {} } ) {
        my $object = $test_item->{mod}->{$field};
        $object->{name} = $field;
        $form->field( %{ $object } );
    }

    #
    # Just compare the output of render with what's expected
    # the correct string output is now in external files.
    # The seemingly extra eval is required so that failures
    # to import the template modules do not kill the tests.
    # (since render is called regardless of whether $SKIP is set)
    #
    my $out = outfile($seq++);
    my $ren;
    eval '$ren = $form->render';
    warn $@ if $@ && ! $SKIP;
    my $ok = skip($SKIP, $ren, $out);

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

# MORE TESTS DOWN HERE

# from eszpee for tmpl_param
skip($SKIP, do{
    my $form2 = CGI::FormBuilder->new(
                     template => {
                        type => 'Fast',
                        define_nofile => {
                            form => '$TEST',
                        }
                     },
                );
    $form2->tmpl_param(TEST => "this message should appear");
    eval '$form2->render';
}, 'this message should appear');

