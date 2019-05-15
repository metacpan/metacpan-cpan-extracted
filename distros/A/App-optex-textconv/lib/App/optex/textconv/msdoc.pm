package App::optex::textconv::msdoc;

our $VERSION = '0.04';

use strict;
use warnings;
use v5.14;
use Carp;
use utf8;

use App::optex::textconv::Converter 'import';

our @CONVERTER = (
    [ qr/\.docx$/ => \&to_text ],
    [ qr/\.pptx$/ => \&to_text ],
    [ qr/\.xlsx$/ => \&to_text ],
    );

sub extract_text {
    local *_ = shift;
    my $type = shift;
    my $xml_re = qr/<\?xml\b[^>]*\?>\s*/;
    return $_ unless /$xml_re/;

    my @xml  = grep { length } split /$xml_re/;
    my @text = map  { _xml2text($_, $type) } @xml;
    join "\n", @text;
}

my %param = (
    docx => { space => 2, separator => ""   },
    xlsx => { space => 1, separator => "\t" },
    pptx => { space => 1, separator => ""   },
    );

sub _xml2text {
    local $_ = shift;
    my $type = shift;
    my $param = $param{$type} or die;

    my @p;
    while (m{<(?<tag>[apw]:p|si)\b[^>]*>(?<para>.*?)</\g{tag}>}sg) {
	my $p = $+{para};
	my @s;
	while ($p =~ m{
	       <(?<tag>(?:[apw]:)?t)\b[^>]*> (?<text>[^<]*?) </\g{tag}>
	       }xsg) {
	    push @s, $+{text} if $+{text} ne '';
	}
	@s or next;
	push @p, join($param->{separator}, @s) . ("\n" x $param->{space});
    }
    join '', @p;
}

sub retrieve_contents {
    my $file = shift;
    my $suffix = shift;
    my @command = do {
	if ($suffix eq 'docx') {
	    "unzip -p \"$file\" word/document.xml";
	}
	elsif ($suffix eq 'xlsx') {
	    "unzip -p \"$file\" xl/sharedStrings.xml";
	}
	elsif ($suffix eq 'pptx') {
	    map  { "unzip -p \"$file\" $_" }
	    map  { $_->[0] }
	    sort { $a->[1] <=> $b->[1] }
	    map  { m{(ppt/slides/slide(\d+)\.xml)} ? [ $1, $2 ] : () }
	    `unzip -l \"$file\" ppt/slides/slide*`;
	}
    };
    join '', map `$_`, @command;
}

sub to_text {
    my $file = shift;
    my $type = ($file =~ /\.(docx|xlsx|pptx)$/)[0] or return;
    my $text = retrieve_contents $file, $type;
    extract_text \$text, $type;
}

1;
