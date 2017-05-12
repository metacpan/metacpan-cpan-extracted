#!perl

use strict;
use warnings;

use Chess::FIDE;
use Test::More tests => 106;

sub test_header ($$) {

	my $fide = shift;
	my $header = shift;

	isa_ok($fide->{meta}, 'HASH');
	my $back_header = '';
	for my $field (sort { $fide->{meta}{$a}[0] <=> $fide->{meta}{$b}[0]}  keys %{$fide->{meta}}) {
		my $f = $fide->{meta}{$field};
		isa_ok($f, 'ARRAY');
		is(scalar(@{$f}), 2, "2 members in array $field");
		like(substr($header, $f->[0], 1), qr/[a-z]/i, "start of field $field caught");
		is(substr($header, $f->[0]-1, 1), ' ', 'end of previous field caught') if $f->[0];
		$back_header .= $field . (' ' x ($f->[1] - length($field)));
	}
	is(length($back_header), length($header), 'header reconstructed successfully');
}

my $fide = Chess::FIDE->new();

my $old_header = 'ID number Name                              TitlFed  Mar11 GamesBorn  Flag';
$fide->parseHeader($old_header);
$old_header =~ s/titlfed/tit fed/i;
$old_header =~ s/gamesborn/game born/i;
test_header($fide, $old_header);
$fide->{meta} = {};
my $new_header = 'ID Number      Name                                                         Fed Sex Tit  WTit OTit           SRtng SGm SK RRtng RGm Rk BRtng BGm BK B-day Flag';
$fide->parseHeader($new_header);
test_header($fide, $new_header);
