package Crypt::SMIME;
use warnings;
use strict;
use Exporter 'import';
use XSLoader;

our %EXPORT_TAGS = (
    constants => [qw(
        NO_CHECK_CERTIFICATE

        FORMAT_ASN1
        FORMAT_PEM
        FORMAT_SMIME
       )]
   );
Exporter::export_ok_tags('constants');

our $VERSION = '0.23';

XSLoader::load(__PACKAGE__, $VERSION);

1;

sub sign {
	my $this = shift;
	my $mime = shift;

	if(!defined($mime)) {
		die __PACKAGE__."#sign: ARG[1] is not defined.\n";
	} elsif(ref($mime)) {
		die __PACKAGE__."#sign: ARG[1] is a Ref. [$mime]\n";
	}

	$this->_moveHeaderAndDo($mime, '_sign');
}

sub signonly {
	my $this = shift;
	my $mime = shift;

	if(!defined($mime)) {
		die __PACKAGE__."#signonly: ARG[1] is not defined.\n";
	} elsif(ref($mime)) {
		die __PACKAGE__."#signonly: ARG[1] is a Ref. [$mime]\n";
	}

	# suppose that $mime is prepared.
	my $result = $this->_signonly($mime);
	$result =~ s/\r?\n|\r/\r\n/g;
	$result;
}

sub encrypt {
	my $this = shift;
	my $mime = shift;

	if(!defined($mime)) {
		die __PACKAGE__."#encrypt: ARG[1] is not defined.\n";
	} elsif(ref($mime)) {
		die __PACKAGE__."#encrypt: ARG[1] is a Ref. [$mime]\n";
	}

	$this->_moveHeaderAndDo($mime, '_encrypt');
}

sub isSigned {
	my $this = shift;
	my $mime = shift;

	if(!defined($mime)) {
		die __PACKAGE__."#isSigned: ARG[1] is not defined.\n";
	} elsif(ref($mime)) {
		die __PACKAGE__."#isSigned: ARG[1] is a Ref. [$mime]\n";
	}

	my $ctype = $this->_getContentType($mime);
	if($ctype =~ m!^application/(?:x-)?pkcs7-mime! && $ctype =~ m!smime-type="?signed-data"?!) {
		# signed-data署名
		1;
	} elsif($ctype =~ m!^multipart/signed! && $ctype =~ m!protocol="?application/(?:x-)?pkcs7-signature"?!) {
		# 分離署名 (クリア署名)
		1;
	} else {
		undef;
	}
}

sub isEncrypted {
	my $this = shift;
	my $mime = shift;

	if(!defined($mime)) {
		die __PACKAGE__."#isEncrypted: ARG[1] is not defined.\n";
	} elsif(ref($mime)) {
		die __PACKAGE__."#isEncrypted: ARG[1] is a Ref. [$mime]\n";
	}

	my $ctype = $this->_getContentType($mime);
	if($ctype =~ m!^application/(?:x-)?pkcs7-mime!
	&& ($ctype !~ m!smime-type=! || $ctype =~ m!smime-type="?enveloped-data"?!)) {
		# smime-typeが存在しないか、それがenveloped-dataである。
		1;
	} else {
		undef;
	}
}

sub _moveHeaderAndDo {
	my $this = shift;
	my $mime = shift;
	my $method = shift;

	# Content- または MIME- で始まるヘッダはそのままに、
	# それ以外のヘッダはmultipartのトップレベルにコピーしなければならない。
	# (FromやTo、Subject等)
	($mime,my $headers) = $this->prepareSmimeMessage($mime);

	my $result = $this->$method($mime);
	$result =~ s/\r?\n|\r/\r\n/g;

	# コピーしたヘッダを入れる
	$result =~ s/\r\n\r\n/\r\n$headers\r\n/;
	$result;
}

sub _getContentType {
	my $this = shift;
	my $mime = shift;

	my $headkey;
	my $headline = '';

	$mime =~ s/\r?\n|\r/\r\n/g;
	foreach my $line (split /\r\n/, $mime) {
		if(!length($line)) {
			return $headline;
		} elsif($line =~ m/^([^\s:][^:]*?):\s?(.*)/) {
			my ($key, $value) = ($1, $2);
			$headkey = $key;

			if($key =~ m/^Content-Type$/i) {
				$headline = $value;
			}
		} else {
			if($headkey =~ m/^Content-Type$/i) {
				$headline .= "\r\n$line";
			}
		}
	}

	return $headline;
}

# -----------------------------------------------------------------------------
# my ($message,$movedheader) = $smime->prepareSmimeMessage($mime);
#
sub prepareSmimeMessage {
	my $this = shift;
	my $mime = shift;

	$mime =~ s/\r?\n|\r/\r\n/g;

	my $move = '';
	my $rest = '';
	my $is_move = 0;
	my $is_rest = 1;
	while($mime=~/(.*\n?)/g) {
		my $line = $1;
		if($line eq "\r\n") { # end of header.
			$rest .= $line . substr($mime,pos($mime));
			last;
		}
		if($line=~/^(Content-|MIME-)/i) {
			($is_move, $is_rest) = (0,1);
		} elsif( $line =~ /^(Subject:)/i ) {
			($is_move, $is_rest) = (1,1);
		} elsif( $line =~ /^\S/ ) {
			($is_move, $is_rest) = (1,0);
		}
		$is_move and $move .= $line;
		$is_rest and $rest .= $line;
	}
	($rest,$move);
}
