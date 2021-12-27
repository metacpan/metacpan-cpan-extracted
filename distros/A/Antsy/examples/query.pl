#!perl

use v5.32;
use experimental qw(signatures);
require Term::ReadKey;
chomp( my $tty = `tty` );
say "TTY is $tty";

open my $terminal, '+<', $tty;
my $old = select( $terminal );
$|++;
select( $old );
$|++;

#query( "\x1b]4;-2;?\x1b\\" );


sub query ( $string ) {
	print { $terminal } $string;
	Term::ReadKey::ReadMode('raw');
	my $response;
	my $key;
	while( defined ($key = Term::ReadKey::ReadKey(0)) ) {
		$response .= $key;
		last if ord( $key ) == 7;
	}
	Term::ReadKey::ReadMode('restore');
	$response;
	}

my $response = query( "\x1b]4;-1;?\x1b\\" );
	say "<" .
		($response =~ s/(.)/ sprintf "%02X ", ord($1) /ger)
		. ">";

	say "<" .
		($response =~ s/\x1b/(ESC)/gr =~ s/\007/(BELL)/gr )
		. ">";

my $OSC = qr/ ( \007 | \x1b \\ ) /xn;

my( $r, $g, $b ) = $response =~ m|rgb:(.+?)/(.+?)/(.+?)$OSC|;
say "R: $r G: $g B: $b";
