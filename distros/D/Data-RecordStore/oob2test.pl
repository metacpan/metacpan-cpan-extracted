#!/usr/bin/perl

use strict;
#use warnings;

use Data::Dumper;

my( %tmap );
my( @letters ) = ( 'A'..'Z' );

my( %tseq, @seq, @transi );
my $seq_pos = 1;

sub addtoseq {
    my( $pid, @vals ) = @_;
    my $letter = $tmap{$pid};
    unless( $letter ) {
        my $cur = scalar(keys %tmap);
        $letter = $letters[$cur];
        $tmap{$pid} = $letter;
    }
    my $cur_seq = $tseq{$letter} //= [];
    push @$cur_seq, [ $seq_pos, @vals ];
    $seq[$seq_pos] = $letter;
    if( $seq[$seq_pos-1] ne $letter ) {
        push @transi, $seq_pos;
    }
    $seq_pos++;
}

open( my $in, '<', 'oobana.txt' );
while( <$in> ) {

    if( /STOW (\(\d+\)) (.*), (.*)/ ) {
        addtoseq( $1, 'stow', "'$3'", $2 );
    }
    elsif( /NEXT ID (\(\d+\))/ ) {
        addtoseq( $1, 'next_id' );
    }
    elsif( /USE TRANSACATION (\(\d+\))/ ) {
        addtoseq( $1, 'use_transaction' );
    }
    elsif( /FETCH (\(\d+\)) (\d+)/ ) {
        addtoseq( $1, 'fetch', $2 );
    }
    elsif( /COMMIT TRANSACATION (\(\d+\))/ ) {
        addtoseq( $1, 'commit_transaction' );
    }
    elsif( /START TRANSACATION (\(\d+\))/ ) {
        addtoseq( $1, 'start_transaction' );
    }
    elsif( /LOCK (\(\d+\)) (.*)/ ) {
        addtoseq( $1, 'lock', "'$2'" );
    }
    elsif( /UNLOCK (\(\d+\))/ ) {
        addtoseq( $1, 'unlock' );
    }
}
#print STDERR Data::Dumper->Dump([\@seq,\%tseq,\@transi]);

for my $letter (sort keys %tseq ) {
    print "my \$$letter = fork;\nunless( \$$letter ) {\n";
    print '   $provider = $rs_factory->reopen( $provider );'."\n";
    my $spushed = 0;
    my $seq = $tseq{$letter};
    for my $act (@$seq) {
        my( $tick, @args ) = @$act;

        for my $pos (@transi) {
            last if $pos > $tick;
            if( $pos > $spushed ) {
                my $tpos = $pos > 1 ? $pos -1 : $pos;
                if( $seq[$pos] eq $letter ) {
                    print "   expect( '$tpos' );\n";
                } else {
                    print "   spush( '$tpos' );\n";
                }
            }
        }
        ( my $action, @args ) = @args;
        my $act = "\$provider->$action\( ".join( ',', @args )." );";
        my $show_act = $act;
        $show_act =~ s/'/"/gs;
        print "   diag( '($$) $show_act' );\n";
        print "   $act\n";
        $spushed = $tick;
        for my $pos (@transi) {
            if( $pos == (1+$spushed) ) {
                $spushed = $pos;
                print "   put( '$tick' );\n";
                last;
            }
        }
        
    }
    
    print "    exit;\n}\n";
}
