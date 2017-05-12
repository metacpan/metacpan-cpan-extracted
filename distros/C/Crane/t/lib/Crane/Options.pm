# -*- coding: utf-8 -*-


package t::lib::Crane::Options;


use Crane::Base qw( Exporter );
use Crane::Options qw( :DEFAULT &load_options );

use Test::More;


our @EXPORT = qw(
    &test_load
);


sub test_load {
    
    plan('tests' => 2);
    
    subtest('Options' => \&test_load_options);
    subtest('Args' => \&test_load_args);
    
    return done_testing();
    
}


sub test_load_options {
    
    plan('tests' => 10);
    
    local @ARGV = qw(
        --opt1=string
        --opt2=a
        --opt2=b
        --opt3
        --no-opt5
        --opt6=string
        --opt8
        a
        b
        c
    );
    
    my $options = load_options(
        [ 'opt1=s',   'One' ],
        [ 'opt2=s@',  'Two' ],
        [ 'opt3!',    'Three' ],
        [ 'opt4|O=i', 'Four' ],
        [ 'opt5!',    'Five' ],
        [ 'opt6=s',   'Six',   { 'default'  => 'number' } ],
        [ 'opt7=s',   'Seven', { 'default'  => 'number' } ],
        [ 'opt8!',    'Eight', { 'required' => 1 } ],
    );
    
    is($options->{'opt1'}, 'string', 'String');
    is_deeply($options->{'opt2'}, [ qw( a b ) ], 'Multiple strings');
    ok($options->{'opt3'}, 'True');
    ok(!exists $options->{'opt4'}, 'Unexistent');
    ok(exists $options->{'opt5'}, 'Existent');
    ok(!$options->{'opt5'}, 'False');
    is($options->{'opt6'}, 'string', 'Default override');
    is($options->{'opt7'}, 'number', 'Default');
    ok($options->{'opt8'}, 'Required');
    ok(!try { load_options([ 'opt10', 'Ten', { 'required' => 1 } ]) }, 'Required not exists');
    
    return done_testing();
    
}


sub test_load_args {
    
    plan('tests' => 1);
    
    my @args = qw( a b c );
    
    local @ARGV = (
        qw(
            -a
            --b=42
        ),
        
        @args,
    );
    
    my $options = load_options(
        [ 'a!' ],
        [ 'b=s' ],
    );
    
    is_deeply(args(), \@args, 'Is equal');
    
    return done_testing();
    
}


1;
