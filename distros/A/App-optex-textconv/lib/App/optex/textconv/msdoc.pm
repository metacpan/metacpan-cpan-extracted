package App::optex::textconv::msdoc;

our $VERSION = '0.10';

use v5.14;
use warnings;
use Carp;
use utf8;
use Data::Dumper;

use App::optex::textconv::Converter 'import';

our @CONVERTER = (
    [ qr/\.docx$/ => \&to_text ],
    [ qr/\.pptx$/ => \&to_text ],
    [ qr/\.xlsx$/ => \&to_text ],
    );

sub xml2text {
    local $_ = shift;
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

my $replace_reference = do {
    my %hash = qw( amp &  lt <  gt > );
    my @keys = keys %hash;
    my $re = do { local $" = '|'; qr/&(@keys);/ };
    sub { s/$re/$hash{$1}/g }
};

sub _xml2text {
    local $_ = shift;
    my $type = shift;
    my $param = $param{$type} or die;

    my @p;
    while (m{<(?<tag>[apw]:p|si)\b[^>]*>(?<para>.*?)</\g{tag}>}sg) {
	my $p = $+{para};
	my @s;
	while ($p =~ m{
	       (?<tab> <w:tab/> | <w:tabs> )
	       |
	       <(?<tag>(?:[apw]:)?t)\b[^>]*> (?<text>[^<]*?) </\g{tag}>
	       }xsg) {
	    if ($+{tab}) {
		push @s, "  ";
	    } else {
		push @s, $+{text} if $+{text} ne '';
	    }
	}
	@s or next;
	push @p, join($param->{separator}, @s) . ("\n" x $param->{space});
    }
    my $text = join '', @p;
    $replace_reference->() for $text;
    $text;
}

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

sub to_text {
    my $zipfile = shift;
    my $type = ($zipfile =~ /\.(docx|xlsx|pptx)$/)[0] or return;
    my $zip = Archive::Zip->new($zipfile) or die;
    my @contents;
    for my $entry (get_list($zip, $type)) {
	my $member = $zip->memberNamed($entry) or next;
	my $xml = $member->contents or next;
	my $text = xml2text $xml, $type or next;;
	push @contents, "[ $entry ]\n\n$text";
    }
    join "\n", @contents;
}

sub get_list {
    my($zip, $type) = @_;
    if ($type eq 'docx') {
	map { "word/$_.xml" } qw(document endnotes footnotes);
    }
    elsif ($type eq 'xlsx') {
	map { "xl/$_.xml" } qw(sharedStrings);
    }
    elsif ($type eq 'pptx') {
	map  { $_->[0] }
	sort { $a->[1] <=> $b->[1] }
	map  { m{(ppt/slides/slide(\d+)\.xml)$} ? [ $1, $2 ] : () }
	$zip->memberNames;
    }
}

1;
