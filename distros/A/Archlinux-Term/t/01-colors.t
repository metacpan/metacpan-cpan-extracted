#!/usr/bin/perl

use warnings;
use strict;

use English    qw(-no_match_vars);
use Test::More tests => 5;
use Archlinux::Term qw(:all);

my %CODE_OF = ( 'red' => 31, 'green' => 32, 'yellow' => 33, 'blue' => 34, );

sub output_of(&)
{
    my ($code_ref) = @_;

    open my $old_stdout, '>&STDOUT' or die "open: $!";
    my $out_buffer;
    close STDOUT;
    open STDOUT, '>', \$out_buffer or die "open: $!";

    $code_ref->();

    close STDOUT or die "close: $!";
    open STDOUT, '>&', $old_stdout or die "open: $!";

    return $out_buffer;
}

sub color_match
{
    my ($color) = @_;
    return qr/ \e [[] 1 ; $CODE_OF{$color} m /xms;
}

like output_of { status( 'green?' ) }, color_match( 'green' );
like output_of { substatus( 'blue?' ) }, color_match( 'blue' );

{
    my $buffer;
    local $SIG{__WARN__} = sub { $buffer = shift };

    warning( 'yellow?' );
    like $buffer, color_match( 'yellow' );
}

eval { error( 'red?' ) };
ok $EVAL_ERROR;

like $EVAL_ERROR, color_match( 'red' );
