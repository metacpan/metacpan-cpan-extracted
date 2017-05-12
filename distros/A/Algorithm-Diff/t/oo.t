# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl oo.t'
use strict;
BEGIN { $^W++; }
use lib qw( blib lib );
use Algorithm::Diff qw( compact_diff );
use Data::Dumper;
use Test qw( plan ok $ntest );

BEGIN
{
    $|++;
    plan( tests => 969 );
    $SIG{__DIE__} = sub # breakpoint on die
    {
        $DB::single = 1
            if  ! $^S;
        die @_;
    };
    $SIG{__WARN__} = sub # breakpoint on warn
    {
        $DB::single = 1;
        warn @_;
    };
}

sub Ok($$) { @_= reverse @_; goto &ok }

my( $first, $a, $b, $hunks );
for my $pair (
    [ "a b c   e  h j   l m n p",
      "  b c d e f  j k l m    r s t", 9 ],
    [ "", "", 0 ],
    [ "a b c", "", 1 ],
    [ "", "a b c d", 1 ],
    [ "a b", "x y z", 1 ],
    [ "    c  e   h j   l m n p r",
      "a b c d f g  j k l m      s t", 7 ],
    [ "a b c d",
      "a b c d", 1 ],
    [ "a     d",
      "a b c d", 3 ],
    [ "a b c d",
      "a     d", 3 ],
    [ "a b c d",
      "  b c  ", 3 ],
    [ "  b c  ",
      "a b c d", 3 ],
) {
    $first= $ntest;
    ( $a, $b, $hunks )= @$pair;
    my @a = split ' ', $a;
    my @b = split ' ', $b;

    my $d = Algorithm::Diff->new( \@a, \@b );

    if(  @ARGV  ) {
        print "1: $a$/2: $b$/";
        while( $d->Next() ) {
            printf "%10s %s %s$/",
                join(' ',$d->Items(1)),
                $d->Same() ? '=' : '|',
                join(' ',$d->Items(2));
        }
    }

    Ok( 0, $d->Base() );
    Ok( 0, $d->Base(undef) );
    Ok( 0, $d->Base(1) );
    Ok( 1, $d->Base(undef) );
    Ok( 1, $d->Base(0) );

    ok( ! eval { $d->Diff(); 1 } );
    ok( $@, qr/\breset\b/i );
    ok( ! eval { $d->Same(); 1 } );
    ok( $@, qr/\breset\b/i );
    ok( ! eval { $d->Items(1); 1 } );
    ok( $@, qr/\breset\b/i );
    ok( ! eval { $d->Range(2); 1 } );
    ok( $@, qr/\breset\b/i );
    ok( ! eval { $d->Min(1); 1 } );
    ok( $@, qr/\breset\b/i );
    ok( ! eval { $d->Max(2); 1 } );
    ok( $@, qr/\breset\b/i );
    ok( ! eval { $d->Get('Min1'); 1 } );
    ok( $@, qr/\breset\b/i );

    ok( ! $d->Next(0) );
    ok( ! eval { $d->Same(); 1 } );
    ok( $@, qr/\breset\b/i );
    Ok( 1, $d->Next() )         if  0 < $hunks;
    Ok( 2, $d->Next(undef) )    if  1 < $hunks;
    Ok( 3, $d->Next(1) )        if  2 < $hunks;
    Ok( 2, $d->Next(-1) )       if  1 < $hunks;
    ok( ! $d->Next(-2) );
    ok( ! eval { $d->Same(); 1 } );
    ok( $@, qr/\breset\b/i );

    ok( ! $d->Prev(0) );
    ok( ! eval { $d->Same(); 1 } );
    ok( $@, qr/\breset\b/i );
    Ok( -1, $d->Prev() )        if  0 < $hunks;
    Ok( -2, $d->Prev(undef) )   if  1 < $hunks;
    Ok( -3, $d->Prev(1) )       if  2 < $hunks;
    Ok( -2, $d->Prev(-1) )      if  1 < $hunks;
    ok( ! $d->Prev(-2) );

    Ok( 1, $d->Next() )         if  0 < $hunks;
    ok( ! $d->Prev() );
    Ok( 1, $d->Next() )         if  0 < $hunks;
    ok( ! $d->Prev(2) );
    Ok( -1, $d->Prev() )        if  0 < $hunks;
    ok( ! $d->Next() );
    Ok( -1, $d->Prev() )        if  0 < $hunks;
    ok( ! $d->Next(5) );

    Ok( 1, $d->Next() )         if  0 < $hunks;
    Ok( $d, $d->Reset() );
    ok( ! $d->Prev(0) );
    Ok( 3, $d->Reset(3)->Next(0) )  if  2 < $hunks;
    Ok( -3, $d->Reset(-2)->Prev() ) if  2 < $hunks;
    Ok( $hunks || !1, $d->Reset(0)->Next(-1) );

    my $c = $d->Copy();
    ok( $c->Base(), $d->Base() );
    ok( $c->Next(0), $d->Next(0) );
    ok( $d->Copy(-4)->Next(0),
        $d->Copy()->Reset(-4)->Next(0) );

    $c = $d->Copy( undef, 1 );
    Ok( 1, $c->Base() );
    ok( $c->Next(0), $d->Next(0) );

    $d->Reset();
    my( @A, @B );
    while( $d->Next() ) {
        if( $d->Same() ) {
            Ok( 0, $d->Diff() );
            ok( $d->Same(), $d->Range(2) );
            ok( $d->Items(2), $d->Range(1) );
            ok( "@{[$d->Same()]}",
                "@{[$d->Items(1)]}" );
            ok( "@{[$d->Items(1)]}",
                "@{[$d->Items(2)]}" );
            ok( "@{[$d->Items(2)]}",
                "@a[$d->Range(1)]" );
            ok( "@a[$d->Range(1,0)]",
                "@b[$d->Range(2)]" );
            push @A, $d->Same();
            push @B, @b[$d->Range(2)];
        } else {
            Ok( 0, $d->Same() );
            ok( $d->Diff() & 1, 1*!!$d->Range(1) );
            ok( $d->Diff() & 2, 2*!!$d->Range(2) );
            ok( "@{[$d->Items(1)]}",
                "@a[$d->Range(1)]" );
            ok( "@{[$d->Items(2)]}",
                "@b[$d->Range(2,0)]" );
            push @A, @a[$d->Range(1)];
            push @B, $d->Items(2);
        }
    }
    ok( "@A", "@a" );
    ok( "@B", "@b" );

    next   if  ! $hunks;

    Ok( 1, $d->Next() );
    { local $^W= 0;
    ok( ! eval { $d->Items(); 1 } ); }
    ok( ! eval { $d->Items(0); 1 } );
    { local $^W= 0;
    ok( ! eval { $d->Range(); 1 } ); }
    ok( ! eval { $d->Range(3); 1 } );
    { local $^W= 0;
    ok( ! eval { $d->Min(); 1 } ); }
    ok( ! eval { $d->Min(-1); 1 } );
    { local $^W= 0;
    ok( ! eval { $d->Max(); 1 } ); }
    ok( ! eval { $d->Max(9); 1 } );

    $d->Reset(-1);
    $c= $d->Copy(undef,1);
    ok( "@a[$d->Range(1)]",
        "@{[(0,@a)[$c->Range(1)]]}" );
    ok( "@b[$c->Range(2,0)]",
        "@{[(0,@b)[$d->Range(2,1)]]}" );
    ok( "@a[$d->Get('min1')..$d->Get('0Max1')]",
        "@{[(0,@a)[$d->Get('1MIN1')..$c->Get('MAX1')]]}" );

    ok( "@{[$c->Min(1),$c->Max(2,0)]}",
        "@{[$c->Get('Min1','0Max2')]}" );
    ok( ! eval { scalar $c->Get('Min1','0Max2'); 1 } );
    ok( "@{[0+$d->Same(),$d->Diff(),$d->Base()]}",
        "@{[$d->Get(qq<same Diff BASE>)]}" );
    ok( "@{[0+$d->Range(1),0+$d->Range(2)]}",
        "@{[$d->Get(qq<Range1 rAnGe2>)]}" );
    { local $^W= 0;
    ok( ! eval { $c->Get('range'); 1 } );
    ok( ! eval { $c->Get('min'); 1 } );
    ok( ! eval { $c->Get('max'); 1 } ); }

} continue {
    if(  @ARGV  ) {
        my $tests= $ntest - $first;
        print "$hunks hunks, $tests tests.$/";
    }
}

# $d = Algorithm::Diff->new( \@a, \@b, {KeyGen=>sub...} );

# @cdiffs = compact_diff( \@seq1, \@seq2 );
