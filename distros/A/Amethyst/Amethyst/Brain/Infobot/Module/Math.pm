package Amethyst::Brain::Infobot::Module::Math;

use strict;
use vars qw(@ISA %BASES %DIGITS @DIGITS);
use Math::Trig;
use Math::BaseCalc;
use Amethyst::Message;
use Amethyst::Store;
use Amethyst::Brain::Infobot;
use Amethyst::Brain::Infobot::Module;

@ISA = qw(Amethyst::Brain::Infobot::Module);
%BASES = (
	binary		=> 2,
	ternary		=> 3,
	octal		=> 8,
	decimal		=> 10,
	hex			=> 16,
	hexadecimal	=> 16,
		);
%DIGITS = (
	first	=> 1,
	second	=> 2,
	third	=> 3,
	fourth	=> 4,
	fifth	=> 5,
	sixth	=> 6,
	seventh	=> 7,
	eighth	=> 8,
	ninth	=> 9,
	tenth	=> 10,
	one		=> 1,
	two		=> 2,
	three	=> 3,
	four	=> 4,
	five	=> 5,
	six		=> 6,
	seven	=> 7, 
	eight	=> 8,
	nine	=> 9,
	ten		=> 10,
		);
@DIGITS = ( 0 .. 9, 'A' .. 'Z' );

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(
					Name		=> 'Math',
					Usage		=> 'Evaluates mathematical expressions',
					Description	=> "Math handler",
					@_
						);

	return bless $self, $class;
}

sub process {
    my ($self, $message) = @_;

	my $content = $message->content;
	my $base = 10;

	$content =~ s/^what\s+is\s+//i;
	$content =~ s/[.?!]$//g;

	my $basename = undef;
	if ($content =~ s/\s+in\s+(.*)$//) {
		$basename = $1;

		# print STDERR "Parsing base $basename\n";

		if ($BASES{$basename}) {
			$base = $BASES{$basename};
		}
		elsif ($basename =~ /^base\s+(\d+)$/i) {
			$base = $1;
		}
		else {
			$base = 0;
		}

		# print STDERR "Identified base $base\n";
	}

	foreach (keys %DIGITS) {
		$content =~ s/\b$_\b/ $DIGITS{$_} /g;
	}

	# Conver to decimal
	$content =~ s/\b0x([a-fA-F0-9]*)/ hex($1) /ge;
	# $content =~ s/\bh([a-fA-F0-9]*)/ hex($1) /ge;
	# $content =~ s/\bb([a-fA-F0-9]*)/ unpack("L", pack("B*", $1)) /ge;
	$content =~ s/\bpi\b/ pi /ge;

	$content =~ s/^\s*//g;
	$content =~ s/\s*$//g;
	$content =~ s/\s+/ /g;

	# print STDERR "Math: Premunge: '$content'\n";

	# Perform usual infobot substitutions
    $content =~ s/ to the / ** /g;
    $content =~ s/\btimes\b/\*/g;
    $content =~ s/\bdiv(ided by)? /\/ /g;
    $content =~ s/\bover /\/ /g;
    $content =~ s/\bsquared/\*\*2 /g;
    $content =~ s/\bcubed/\*\*3 /g;
    # $content =~ s/\bto\s+(the\s+)?(\d+)(r?st|nd|rd|th)?( power)?/\*\*$1 /ig;
    $content =~ s/\bpercent of/*0.01*/ig;
    $content =~ s/\bpercent/*0.01/ig;
    $content =~ s/\% of\b/*0.01*/g;
    $content =~ s/\%/*0.01/g;
    $content =~ s/\bsquare root of (\d+)/sqrt($1)/ige;
    $content =~ s/\bsqrt\s*(\d+)/sqrt($1)/ige;
    # $content =~ s/\bcubed? root of (\d+)/$1 **(1.0\/3.0) /ig;
    $content =~ s/ of / * /;
    $content =~ s/(bit(-| )?)?xor(\'?e?d(\s+with))?/\^/g;
    $content =~ s/(bit(-| )?)?or(\'?e?d(\s+with))?/\|/g;
    $content =~ s/bit(-| )?and(\'?e?d(\s+with))?/\& /g;
    $content =~ s/(plus|and)/+/ig;

	# print STDERR "Math: Postmunge: '$content'\n";

	$content =~ s/^\s*//g;
	$content =~ s/\s*$//g;
	$content =~ s/\s+/ /g;

	# print STDERR "Math: Final stage: '$content'\n";

	# Now for the throw outs:
	return undef if $content !~ /\S/;				# Empty
	return undef if									# Not an exp
			$content !~ /^[-+\/\*\d*\.\s()^\|\&]+$/;
	return undef if $content !~ /\d/;				# Boring
	return undef if									# Trivial
			(($content =~ /^\(?\d+\.?\d*\)?$/) && ($base == 10));
	return undef if $content =~ /&\s*[^\d]/;		# Subroutine call
	return undef if $content =~ /&\s*\d+\s*\(/;		# Subroutine call

	if ($base == 0) {
		my $reply = $self->reply_to($message, "I don't think " .
						"$basename is a valid base for " .
						"computation.");
		$reply->send;
		return 1;
	}

	if (($base > 36) || ($base < 2)) {
		my $reply = $self->reply_to($message, "Are you trying to " .
						"mess with my head by using base $base?");
		$reply->send;
		return 1;
	}

	my $result;
	eval qq{ \$result = $content; };
	if ($@) {
		my $err = $@;
		chomp($err);
		my $reply = $self->reply_to($message, "Math error: $err" .
						" (probably your fault)");
		$reply->send;
		return 1;
	}

	if ($base != 10) {
		my $calc = new Math::BaseCalc(
						digits => [ @DIGITS[0..($base - 1)] ],
							);
		$result = $calc->to_base($result);
	}

	my $reply = $self->reply_to($message, "Math: $result");
	$reply->send;

	return 1;
}

1;
