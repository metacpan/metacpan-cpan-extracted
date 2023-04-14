package App::optex::textconv::ooxml::regex;

our $VERSION = '1.05';

use v5.14;
use warnings;
use Carp;
use utf8;
use Encode;
use Data::Dumper;

use App::optex v0.3;
use App::optex::textconv::Converter 'import';

our @EXPORT_OK = qw(to_text get_list);

our @CONVERTER = (
    [ qr/\.doc[xm]$/ => \&to_text ],
    [ qr/\.ppt[xm]$/ => \&to_text ],
    [ qr/\.xls[xm]$/ => \&to_text ],
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
    docm => { space => 2, separator => ""   },
    xlsx => { space => 1, separator => "\t" },
    xlsm => { space => 1, separator => "\t" },
    pptx => { space => 1, separator => ""   },
    pptm => { space => 1, separator => ""   },
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
	       (?<br> <[aw]:br/> )
	       |
	       (?<tab> <w:tab/> | <w:tabs> )
	       |
	       <(?<tag>(?:[apw]:)?t)\b[^>]*> (?<text>[^<]*?) </\g{tag}>
	       }xsg) {
	    if ($+{br}) {
		push @s, "\n";
	    } elsif ($+{tab}) {
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

use Archive::Zip 1.37 qw( :ERROR_CODES :CONSTANTS );

sub to_text {
    my $file = shift;
    my $type = ($file =~ /\.((?:doc|xls|ppt)[xm])$/)[0] or return;
    my $zip = Archive::Zip->new($file) or die;
    my @contents;
    for my $entry (get_list($zip, $type)) {
	my $member = $zip->memberNamed($entry) or next;
	my $xml = $member->contents or next;
	my $text = xml2text $xml, $type or next;
	$file = encode 'utf8', $file if utf8::is_utf8($file);
	push @contents, "[ \"$file\" $entry ]\n\n$text";
    }
    join "\n", @contents;
}

sub get_list {
    my($zip, $type) = @_;
    if    ($type =~ /^doc[xm]$/) {
	map { "word/$_.xml" } qw(document endnotes footnotes);
    }
    elsif ($type =~ /^xls[xm]$/) {
	map { "xl/$_.xml" } qw(sharedStrings);
    }
    elsif ($type =~ /^ppt[xm]$/) {
	map  { $_->[0] }
	sort { $a->[1] <=> $b->[1] }
	map  { m{(ppt/slides/slide(\d+)\.xml)$} ? [ $1, $2 ] : () }
	$zip->memberNames;
    }
}

1;
