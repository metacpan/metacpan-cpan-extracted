package Dwarf::Plugin::Text::CSV_XS;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method write_file/;
use Encode qw/encode/;
use Text::CSV_XS;
use Unicode::Normalize;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};
	$conf->{eol}            //= "\r\n";
	$conf->{encode_charset} //= "utf-8";

	# CSV ファイルを Perl オブジェクトに読み込み
	add_method($c, read_csv => sub {
		my ($self, $filepath) = @_;
		my $csv = Text::CSV_XS->new ({ binary => 1, eol => $conf->{eol} });

		open my $fh, "<:encoding(" . $conf->{encode_charset} . ")", $filepath or die "Couldn't open $filepath: $!";

		my @rows;
		while (my $row = $csv->getline($fh)) {
			push @rows, $row;
		}
		$csv->eof or $csv->error_diag();
		close $fh;

		$csv->eol ("\r\n");

		return wantarray ? @rows : \@rows;
	});

	# Perl オブジェクトを CSV ファイルに書き込み
	add_method($c, write_csv => sub {
		my ($self, $filepath, @rows) = @_;
		my $content = $self->encode_csv(@rows);
		write_file($filepath, $content);
	});

	# CSV 文字列 ---> Perl オブジェクト
	add_method($c, decode_csv => sub {
		my ($self, $str) = @_;
		my $csv = Text::CSV_XS->new ({ binary => 1 });

		my @rows = split(/(?:\r\n|\r|\n)/, $str);
		for my $row (@rows) {
			if ($csv->parse($row)) {
				$row = [ $csv->fields ];
			}
		}

		return wantarray ? @rows : \@rows;
	});

	# Perl オブジェクト ---> CSV 文字列
	add_method($c, encode_csv => sub {
		my ($self, @rows) = @_;
		my $csv = Text::CSV_XS->new ({ binary => 1, eol => $conf->{eol}, always_quote => 1 });

		my $content = '';
		for my $row (@rows) {
			if ($csv->combine(@$row)) {
				$content .= $csv->string;
			}
		}

		$content = NFKC($content);
		$content = encode($conf->{encode_charset}, $content);
		return $content;
	});

	$c->add_trigger(AFTER_DISPATCH => sub {
		my ($self, $res) = @_;
		return unless ref $res->body eq 'ARRAY';

		if ($res->content_type =~ /text\/csv/) {
			$self->call_trigger(BEFORE_RENDER => $self->handler, $self, $res->body);
			my $encoded = $self->encode_csv(@{ $res->body });
			$self->call_trigger(AFTER_RENDER => $self->handler, $self, \$encoded);
			$res->body(encode_utf8($encoded));
		}
	});
}

1;
