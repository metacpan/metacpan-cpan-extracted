#!/usr/bin/perl 

# Copyright (c) Nate Wiger http://nateware.com.
# All Rights Reserved. If you're reading this, you're bored.
# 2e-template-ssi.t - test CGI::SSI support

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
    my $numtests = 5;
    unshift @INC, "$FindBin::Bin/../lib";

    plan tests => $numtests;

    # try to load template engine so absent template does
    # not cause all tests to fail
    eval "require CGI::SSI";
    $SKIP = $@ ? 'skip: CGI::SSI not installed here' : 0;   # eval failed, skip all tests

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

# Grab our template from our test00.html file
my $template = outfile(0);
my $kurtlidl = outfile(99);

# What options we want to use, and what we expect to see
my @test = (
    {
        opt => { fields => [qw/name color/], 
                 submit => 0, 
                 reset  => 'No esta una button del submito',
                 template => { type=>'CGI_SSI', string => $template },
                 validate => { name => 'NAME' },
                 
               },
        mod => { color => { options => [qw/red green blue/], nameopts => 1 },
                 size  => { value => 42 } },

    },
    {
        opt => { fields => [qw/name color size/],
                 template => { type=>'CGI_SSI', string => $template },
                 values => {color => [qw/purple/], size => 8},
                 reset => 'Start over, boob!',
                 validate => {},    # should be empty
               },

        mod => { color => { options => [qw/white black other/] },
                 name => { size => 80 } },

    },
    {
        opt => { fields => [qw/name color email/], submit => [qw/Update Delete/], reset => 0,
                 template => { type=>'CGI_SSI', string => $template },
                 values => {color => [qw/yellow green orange/]},
                 validate => { color => [qw(red blue yellow pink)] },
               },

        mod => { color => {options => [[red => 1], [blue => 2], [yellow => 3], [pink => 4]] },
                 size  => {value => '(unknown)' } 
               },

    },
    {
        opt => { fields => [qw/field1 field2/], method => 'post',
                 title => 'test form page', header => 0,
                 template => { type=>'CGI_SSI', string => $kurtlidl },
               },
        mod => {
            field1 => { value => 109, comment => '<i>Hello</i>' },
            field2 => { type => 'submit', value => "1 < 2 < 3", label => "Reefer", comment => '<i>goodbyE@</i>' },
            field3 => { type => 'button', value => "<<PUSH>>", comment => '<i>onSubmit</i>' },
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
    my $ren = $SKIP ? '' : $form->render;
    my $ok = skip($SKIP, $ren, $out);

    if (! $ok && $LOGNAME eq 'nwiger') {
        #use Data::Dumper;
        #die Dumper($form);
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
                    template => { type=>'CGI_SSI', string => '<!--#echo var="test" -->' }
                );
    $form2->tmpl_param(test => "this message should appear");
    eval '$form2->render';
}, 'this message should appear');

