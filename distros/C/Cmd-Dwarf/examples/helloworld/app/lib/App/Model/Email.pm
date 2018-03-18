package App::Model::Email;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use Dwarf::DSL;
use Dwarf::Util qw/load_class/;
use Email::MIME;
use Email::Sender::Simple 'sendmail';
use Encode qw/decode encode decode_utf8 encode_utf8/;
use List::Util qw/max/;

use Dwarf::Accessor {
	ro => [qw//],
	rw => [qw/on_error/]
};

sub _build_on_error { warn @_ }

# テンプレートファイルを使ってメールを送信する
# 成功すると 0 が、失敗すると 1 が返る
sub send_file {
	my ($self, $params, $path, $vars, $opts) = @_;
	my $body = c->render($path, $vars, $opts);
	$params->{body} = $body;
	return self->send($params);
}

# メールを送信する
# 成功すると 0 が、失敗すると 1 が返る
sub send {
	my ($self, $params) = @_;

	die '$params->{from} must be specified.' unless $params->{from};
	die '$params->{to} must be specified.' unless $params->{to};
	die '$params->{subject} must be specified.' unless $params->{subject};
	die '$params->{body} must be specified.' unless $params->{body};

	$params->{envelop_from} ||= $params->{from};
	$params->{reply_to}     ||= $params->{from};
	$params->{host}         ||= 'localhost';
	$params->{port}         ||= 465;

	my $body = Encode::is_utf8($params->{body}) ? $params->{body} : decode_utf8($params->{body});
	$body =~ tr/[\x{ff5e}\x{2225}\x{ff0d}\x{ffe0}\x{ffe1}\x{ffe2}]/[\x{301c}\x{2016}\x{2212}\x{00a2}\x{00a3}\x{00ac}]/;

	my $transport_class = "Email::Sender::Transport::" . ucfirst($params->{transport} || 'Sendmail');
	load_class($transport_class);

	my $transport = $transport_class->new({
		host => $params->{host},
		port => $params->{port},
	});

	my $subject = encode('MIME-Header-ISO_2022_JP', $params->{subject});
	$subject =~ s/\n/ /g;

	my $error = 0;

	$params->{to}
	->split(',')
	->map(sub {
		my $to = shift;
		$to =~ s/^\s*(.*?)\s*$/$1/;

		my $row = { to => [ $to ] };
		$row->{email} = Email::MIME->create(
			header => [
				'From'     => encode('MIME-Header-ISO_2022_JP', $params->{from}),
				'To'       => encode('MIME-Header-ISO_2022_JP', $to),
				'Subject'  => $subject,
				'Reply-To' => encode('MIME-Header-ISO_2022_JP', $params->{reply_to}),
			],
			_mime_body_attributes($body)
		);
		return $row;
	})
	->foreach(sub {
		my $row = shift;

		eval {
			sendmail($row->{email}, {
				transport => $transport,
				to        => $row->{to},
				from      => $params->{envelop_from}
			});
		};
		if ($@) {
			$error = 1;
			self->on_error("sendmail() failed: $@");
		}
	});

	return $error;
}

sub _is_jis {
	my $str = shift;
	return decode('iso-2022-jp', encode('iso-2022-jp', $str)) eq $str;
}

sub _mime_body_attributes {
	my ($body) = @_;
	my ($charset, $encoding) = ('ISO-2022-JP', '7bit');
	
	# ISO-2022-JP で表現できない文字がある場合は UTF-8 なメールにする
	if (_is_jis($body)) {
		my $jis = encode('iso-2022-jp', $body);
		my $maxlen = max map { length($_) } split(/\n/, $jis);

		# Postfix のデフォルトでは 990 バイトで改行が入ってしまうので、
		# その場合は Quoted-Printable にする。
		if ($maxlen > 950) {
			$encoding = 'quoted-printable';
		}
		$body = $jis;
	} else {
		$charset = 'UTF-8';
		$encoding = 'base64';
		$body = encode('utf-8', $body);
	}
	
	return (
		body       => $body,
		attributes => {
			content_type => 'text/plain',
			charset      => $charset,
			encoding     => $encoding,
		},
	);
}

1;