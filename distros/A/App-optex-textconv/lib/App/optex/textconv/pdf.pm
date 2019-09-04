package App::optex::textconv::pdf;

our $VERSION = '0.06';

use v5.14;
use strict;
use warnings;
use Carp;

use App::optex::textconv::Converter 'import';

our @CONVERTER = (
    [ qr/\.pdf$/i => \&to_text ],
    );

our %param = (
    pagebreak => 'rule',
    width     => 78,
    mark      => '-',
    format    => '[ Page %d ]',
    );

my %pagebreak = (
    rule => sub {
	my $rule = $param{mark} x $param{width} . "\n\n";
	sub { $rule };
    },
    number => sub {
	my $n = 1;
	my $format = $param{format} . "\n\n";
	sub { sprintf $format, $n++ };
    },
    pf => sub {
	sub { "\f" };
    },
    );

sub to_text {
    my $file = shift;
    my $type = ($file =~ /\.(pdf)$/i)[0] or return;
    my $break = $pagebreak{$param{pagebreak}}->();
    local $_ = qx{ pdftotext \"$file\" - };
    s/\f/$break->()/ger;
}

sub set {
    my %opt = @_;
    while (my($k, $v) = each %opt) {
	exists $param{$k} or next;
	$param{$k} = $v;
    }
}

1;
