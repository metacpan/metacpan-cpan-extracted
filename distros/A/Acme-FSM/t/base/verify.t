# $Id: verify.t 484 2013-05-09 20:56:46Z whynot $
# Copyright 2012, 2013 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v2.3.2 );

use t::TestSuite qw| :diag :wraps |;
use Test::More;

plan tests => 38;

use Acme::FSM;

our( %st, $bb, $rc, $stderr );
our @flags =
qw| The_Night_We_Died                Zaia
    Muh                            Ka_III
    Zombies              De_Zeuhl_Undazir
    Eliphas_Levi        Maneh_Fur_Da_Zess
    Troller_Tanz           Ek_Sun_Da_Zess
    C_est_la_Vie_Qui_les_A_Menes_La  Nono
    Do_The_Music   Da_Zeuhl_Worts_Mekanik
    Thaud                        Wainsaht
    The_Last_Seven_Minutes Nebehr_Gudahtt
    Udu_Wudu                  Kohntarkosz |;

my $method     = q|verify|;
my $tag;
my( $mf, $wt ) = qw| {Pearl} {Tanya} |;

AFSMTS_class_wrap { debug_level => -t STDOUT ? 10 : 1 }, \%st;
isa_ok $bb, q|Acme::FSM|, q|constructed object|;

$tag = q|undefined|;
AFSMTS_method_wrap $method, undef, q|Hillary|, $wt, $mf, '';
like $@, qr.\Q{Hillary}({Tanya}): {Pearl} !isa defined., AFSMTS_croakson $tag;

my @tdata =
([ ''           =>               q|Matt| ],
 [ SCALAR       =>                 \$tag ], 
 [ HASH         => { Mr_Cola => q|Cobb| }],
 [ ARRAY        => [qw|      Erwin A_J |]],
 [ CODE         => sub {               } ],
 [ q|Acme::FSM| =>                   $bb ] );

foreach my $outer ( @tdata )                            {
    foreach my $inner ( @tdata )                       {
        if( $outer->[0] eq $inner->[0] )              {
            $tag = sprintf q|%s isa %s|,
              map { $_ eq '' ? q|scalar| : qq|($_)| }
                $outer->[0], $inner->[0];
            AFSMTS_method_wrap
              $method, $outer->[1], q|Sid|, $wt, $mf, $inner->[0];
            is $rc, $outer->[1], qq|unaffected ($tag)| }
        else                                          {
            $tag = sprintf q|%s !isa %s|,
              map { $_ eq '' ? q|scalar| : qq|($_)| }
                $outer->[0], $inner->[0];
                AFSMTS_method_wrap $method,
                  $outer->[1], q|Matt|, $wt, $mf, $inner->[0];
            like $@,
              qr.(?x)
                \h\{Matt\}\(\{Tanya\}\):\h\{Pearl\}\hisa\h \($outer->[0]\),
                \hshould\hbe\h\($inner->[0]\)\h.,
              AFSMTS_croakson $tag                     }}}

# vim: set filetype=perl
