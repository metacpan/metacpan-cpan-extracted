package Acme::Matrix;
our $VERSION = '0.09';
use 5.006; use strict; use warnings;
use Term::ReadKey; 

our (@WORDS, @CHARS, @COLOURS);
BEGIN {
	$SIG{INT} = \&shutdown;	
	@WORDS = (
		[qw/し ゅ く う ん/],
		[qw/不 正 直/],
		[qw/き い っ ぽ ん/],
		[qw/憎 し み を 抱 く/],
		[qw/だ ら く ふ は い/],
		[qw/ふ と ど き/],
		[qw/は ち ゃ め ち ゃ/],
		[qw/た い ぎ ゃ く ひ ど う/],
		[qw/ラ ッ キ ー/],
		[qw/し り が お も い/],
		[qw/リ ス ペ ク ト/],
		[qw/ム ー ン/],
		[qw/に っ て ん/],
		[qw/か み の み こ と/],
		[qw/と く し ょ く/],
		[qw/ス キ ャ ン ダ ラ ス/],
		[qw/ぜ に か ね/],
		[qw/エ ク ス プ ロ イ テ ー シ ョ ン/],
		[qw/た く さ ん/],
		[qw/マ イ ン ド/],
		[qw/味 が 分 か る/],
		[qw/に お い が す る/],
		[qw/感 じ て/],
		[qw/リ ッ ス ン/],
		[qw/風 に た な び く/],
		[qw/シ ー ク レ ッ ト/],
		[qw/こ う ざ か か り/],
		[qw/じ つ ご と/],
		[qw/シ ー カ ー/],
		[qw/イ マ ジ ネ ー シ ョ ン/]	
	);
 	@CHARS = qw/
		あ い う え お か き く け こ さ し す せ そ た ち つ て と
		な に ぬ ね の は ひ ふ へ ほ ま み む め も ら り る れ ろ
		ア イ ウ エ オ カ キ ク ケ コ ガ ギ グ ゲ ゴ サ シ ス セ ソ
		ザ ジ ズ ゼ ゾ タ チ ツ テ ト ダ ヂ ヅ デ ド ナ ニ ヌ ネ ノ
 		ハ ヒ フ ヘ ホ バ ビ ブ ベ ボ パ ピ プ ペ ポ マ ミ ム メ モ
	/;
 	@COLOURS = ( 28, 34, 35, 40, 41, 46, 47, 48, 48, 82, 83, 0 );
}


sub start {
	my ($pkg, %args) = @_;
	@WORDS = @{$args{words}} if ($args{words});
	@CHARS = @{$args{chars}} if ($args{chars});
	my $delay = $args{delay} ? $args{delay} / 1000 : 0.01;
	my $space = " " x ($args{spacing} || 2);
	my ($wchar, $hchar) = GetTerminalSize();
	$wchar = $wchar * (0.99 / ($args{spacing} || 2));
	my %word_lines = (
		map { $_ => [] } 0 .. $wchar 
	);
	print "\033[1J";
	print "\033[48;5;232m";
	while (1) {
		for (0..$wchar) {
			if (int(rand(5) + 0.5) > 4) {
				my $i = 0;
				push @{$word_lines{$_}}, (int(rand(1) + 0.5)) 
					? sprintf("\033[38;5;%sm%s", $COLOURS[int(rand(scalar @COLOURS))], $CHARS[int(rand(scalar @CHARS))])
					: map { sprintf("\033[38;5;%sm%s", $COLOURS[$i++], $_) } @{ $WORDS[int(rand(scalar @WORDS))] }, $space;
			}
			print shift(@{$word_lines{$_}}) || $space;
		}
		print "\n";
		select(undef, undef, undef, $delay);
	}
}

sub shutdown {
	print "\033[0m";
	print "\033c";
	exit;
}

__END__

1;

=head1 NAME

Acme::Matrix - Heavenly digital rain

=head1 VERSION

Version 0.09

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use Acme::Matrix;

	Acme::Matrix->start();

	...

	タ    くと              うの  い                    う  ん不  ー        さ  グ  ャ      ッり      ゃ  ら    イ  ネ  ソ
	      ふ              かデみ  っ  あ    マ      し        正  し        ん      ン      スが      く  く    マ
	      は      オぜリ  み  こえぽ    そ  イ  シ  り    じ  直  り                ダ      ンお      ひ  ふ    ジじ
	    りい        にスじの  と  ん      スン  ー  がた  つ  ム  が  も            ラ    ね  も      どムは    ネつ
	      デ      マかペつみ      オ      キド  ク  おい  ご  ー  お    ムし        ス      ザい      うーい  バーごる
		      イねクごこモ    オ      ャ    レ  もぎ  と  ン  も  ふーゅ    ね          て          ンす    シと        風
	た    コ      ンリトとと              ン    ッ  いゃ    た    い  とンく      リ            味        る    ョと  リ    に
	く          シドス    ホ            ふダ    ト    く  シく    ぜ  ど  う      ス          ヌが      は      ンく  ッ    た
	さ          ー  ペ        も    しととラ          ひ  ーさ  シに  き  ん      ペ            分    じ        ダし  スさ  な
	ん  リ      カ  クボ            りくどス      だ  ど  カん  ーか  た          ク          バか    つ          ょリン    び
	    ッ      ー  ト              がしき        ら  う  ー    クね  く          ト  ネ    の  る    ご          くス      く
	    ス      く        シ  ま    おょ          く  マ    て  レプ  さ                      に      と      イ  ベペ      た
	    ン      え      カー        もく          ふ  イ風    にッガ  んチ                    お            にマ    ク      く
	に              イち  ク        いシ      シ  は  ンに    おト    モ              セツ    い  メ          ジ    ト      さ
	お  し      か  マ  ムレ          ー      ー  い  ドた    い            マ          ス    がら        憎  ネ            ん
	い  ゅ      みなジ  ーッ      ちヘカ      カ  憎  えな    が            イ      風  キ    す          し  ー            マ
	が  く      の  ネ  ント          ー      ー  し    び    す            ン      に  ャ    る          み  シ    ビ      イ
	す  う      み  ー  し        る  カか        み味  くた  る            ド      たつン                を  ョ    い      ン
	る  ん      こ  シ  ゅ              み  ム    をが    い  め                    な  ダ      ビ        抱  ン      フ    ド


=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-matrix at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Matrix>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Matrix

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Matrix>

=item * Search CPAN

L<https://metacpan.org/release/Acme-Matrix>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023->2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Acme::Matrix
