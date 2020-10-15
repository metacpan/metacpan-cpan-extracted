#! /usr/local/bin/perl

use lib qw(./t);
use warnings;
use strict;
use Test_Framework;
use Class::Generate qw(&class &subclass);

# Test some options of the constructor:
#   --	Required members.
#   --	Assertions.
#   --	"Post" code.

my @members = ( m1 => "\$", m2 => '@', m3 => '%' );

sub param_assignment($)
{
    my $member = $_[0];
    return ( m1 => 1 )          if $member == 1;
    return ( m2 => [2] )        if $member == 2;
    return ( m3 => { v => 3 } ) if $member == 3;
}

sub members(@)
{
    return map( param_assignment($_), @_ );
}

sub eval_invalid_forms($@)
{
    my ( $class, @forms ) = @_;
    for my $invalid_form (@forms)
    {
        Test_Failure { new $class map param_assignment $_, @$invalid_form };
    }
}

Test
{
    class All_Members_Required =>
        [ @members, new => { required => 'm1 m2 m3' } ];
    All_Members_Required->new( members 1, 2, 3 );
};
eval_invalid_forms 'All_Members_Required', [], [1], [2], [3], [ 1, 2 ],
    [ 1, 3 ], [ 2, 3 ];

Test
{
    class Some_Members_Required => [ @members, new => { required => 'm2 m3' } ];
    1;
};
Test { Some_Members_Required->new( members 1, 2, 3 ) };
Test { Some_Members_Required->new( members 2, 3 ) };
eval_invalid_forms 'Some_Members_Required', [], [1], [2], [3], [ 1, 2 ],
    [ 1, 3 ];

Test
{
    class Requirement_Is_Expression_Based =>
        [ @members, new => { required => 'm1 m2^m3' } ];
    1;
};
Test { Requirement_Is_Expression_Based->new( members 1, 2 ) };
Test { Requirement_Is_Expression_Based->new( members 1, 3 ) };
eval_invalid_forms 'Requirement_Is_Expression_Based', [], [1], [ 1, 2, 3 ];

Test
{
    class Assertion_That_Succeeds => [
        @members,
        new => { assert => '$m1 ne 2 && &m2_size < 1 && scalar(&m3_keys) < 2' }
    ];
    Assertion_That_Succeeds->new( members 1, 2, 3 );
};

Test
{
    class Assertion_That_Fails => [ @members, new => { assert => '$m1 ne 1' } ];
    1;
};
eval_invalid_forms 'Assertion_That_Fails', [1];

use vars qw($o);
Test
{
    class Post_Code => [
        @members,
        new => {
            required => [qw(m1 m2 m3)],
            post     => '$m1++; @m2 = ($m2[0]*2); %m3 = (v => $m3{v});'
        }
    ];
    $o = Post_Code->new( members 1, 2, 3 );
};
Test { ( $o->m1 == 2 && $o->m2(0) == 4 && $o->m3('v') == 3 ) };

Report_Results;
