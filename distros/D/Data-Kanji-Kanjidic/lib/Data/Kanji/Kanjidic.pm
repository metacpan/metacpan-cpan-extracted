# See Kanjidic.pod for documentation

package Data::Kanji::Kanjidic;
require Exporter;
use warnings;
use strict;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/parse_kanjidic
		    parse_entry
		    kanji_dictionary_order
		    grade_stroke_order
		    kanjidic_order
		    stroke_radical_jis_order
		    %codes
		    %has_dupes
		    grade
		   /;

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.16';
use strict;
use warnings;
use Encode;
use utf8;
use Carp;

our $AUTHOR;

# Parse one string from kanjidic and return it in an associative array.

our %codes = (
    'W' => 'Korean pronunciation',
    'Y' => 'Pinyin pronunciation',
    'B' => 'Bushu (radical as defined by the Nelson kanji dictionary)',
    'C' => 'Classic radical (the usual radical, where this is different from the Nelson radical)',
    'U' => 'Unicode code point as a hexadecimal number',
    'G' => 'Year of elementary school this kanji is taught',
    'Q' => 'Four-corner code',
    'S' => 'Stroke count',
    'P' => 'SKIP code', 
    'J' => 'Japanese proficiency test level',
    'N' => 'Nelson code from original Nelson dictionary',
    'V' => 'Nelson code from the "New Nelson" dictionary',
    'L' => 'Code from "Remembering the Kanji" by James Heisig',
    'O' => 'The numbers used in P.G. O\'Neill\'s "Japanese Names"',
    'K' => 'The index in the Gakken Kanji Dictionary (A New Dictionary of Kanji Usage)',
    'E' => 'The numbers used in Kenneth Henshall\'s kanji book',
    'I' => 'The Spahn-Hadamitzky book number',
    'IN' => 'The Spahn-Hadamitzky kanji-kana book number',

    'MP' => 'Morohashi volume/page',
    'MN' => 'Morohashi index number',
    'H' => 'Number in Jack Halpern dictionary',
    'F' => 'Frequency of kanji',

    'X' => 'Cross reference',
    'DA' => 'The index numbers used in the 2011 edition of the Kanji & Kana book, by Spahn & Hadamitzky',
    'DB' => 'Japanese for Busy People textbook numbers', 
    'DC' => 'The index numbers used in "The Kanji Way to Japanese Language Power" by Dale Crowley', 
    'DF' => '"Japanese Kanji Flashcards", by Max Hodges and Tomoko Okazaki',
    'DG' => 'The index numbers used in the "Kodansha Compact Kanji Guide"', 
    'DH' => 'The index numbers used in the 3rd edition of "A Guide To Reading and Writing Japanese" edited by Kenneth Hensall et al',
    'DJ' => 'The index numbers used in the "Kanji in Context" by Nishiguchi and Kono', 
    'DK' => 'The index numbers used by Jack Halpern in his Kanji Learners Dictionary',
    'DL' => 'The index numbers used in the 2013 edition of Halpern\'s Kanji Learners Dictionary',
    'DM' => 'The index numbers from the French-language version of "Remembering the kanji"',
    'DN' => 'The index number used in "Remembering The Kanji, 6th Edition" by James Heisig',
    'DP' => 'The index numbers used by Jack Halpern in his Kodansha Kanji Dictionary (2013), which is the revised version of the "New Japanese-English Kanji Dictionary" of 1990',
    'DO' => 'The index numbers used in P.G. O\'Neill\'s Essential Kanji',
    'DR' => 'The codes developed by Father Joseph De Roo, and published in his book "2001 Kanji" (Bonjinsha)',
    'DS' => 'The index numbers used in the early editions of "A Guide To Reading and Writing Japanese" edited by Florence Sakade',
    'DT' => 'The index numbers used in the Tuttle Kanji Cards, compiled by Alexander Kask',
    'XJ' => 'Cross-reference',
    'XO' => 'Cross-reference',
    'XH' => 'Cross-reference',
    'XI' => 'Cross-reference',
    'XN' => 'Nelson cross-reference',
    'XDR' => 'De Roo cross-reference',
    'T' => 'SPECIAL',
    'ZPP' => 'SKIP misclassification by position',
    'ZRP' => 'SKIP classification disagreement',
    'ZSP' => 'SKIP misclassification by stroke count',
    'ZBP' => 'SKIP misclassification by both stroke count and position',
);

# Fields which are allowed to have duplicates.

our @dupes = qw/
		   DA
                   O
                   Q
                   S
                   V
                   W
                   XDR
                   XH
                   XJ
                   XN
                   Y
                   ZBP
                   ZPP
                   ZRP
                   ZSP
               /;

our %has_dupes;

@has_dupes{@dupes} = @dupes;

sub parse_entry
{
    my ($input) = @_;

# Remove the English entries first.

    my @english;
    my @onyomi;
    my @kunyomi;
    my @nanori;

    # Return value

    my %values;

    # The English-language "meanings" are between { and }.

    while ($input =~ s/\{([^\}]+)\}//) {
        my $meaning = $1;

        # Mark as a "kokuji".

        if ($meaning =~ m/\(kokuji\)/) {
            $values{"kokuji"} = 1;
        }
        else {
            push (@english, $meaning);
        }
    }

    (my $kanji, $values{"jiscode"}, my @entries) = split (" ", $input);
    $values{kanji} = $kanji;
    # Flag to detect the start of nanori readings.
    my $in_nanori;
    foreach my $entry (@entries) {
        my $found;
        if ($entry =~ m/(^[A-Z]+)(.*)/ ) {
            if ($entry eq 'T1') {
                $in_nanori = 1;
                next;
            }
	    my $field = $1;
            my $value = $2;
            if ($codes{$field}) {
                if ($has_dupes{$field}) {
                    push @{$values{$field}}, $value;
                }
                else {
                    if (!$values{$field}) {
                        $values{$field} = $2;
                    }
                    else {
                        die "duplicate values for key $field.\n";
                    }
                }
		$found = 1;
            }
	    else {
		# Unknown field is ignored.
	    }

# Kanjidic contains hiragana, katakana, ".", "-" and "ー" (Japanese
# "chouon") characters.
	} 
        else {
            if ($in_nanori) {
                push @nanori, $entry;
                $found = 1;
            }
            else {
                if ($entry =~ m/^([あ-ん\.-]+)$/) {
                    push @kunyomi, $entry;
                    $found = 1;
                }
                elsif ($entry =~ m/^([ア-ンー\.-]+)$/) {
                    push @onyomi, $entry;
                    $found = 1;
                }
            }
        }
        if ($AUTHOR && ! $found) {
            die "kanjidic:$.: Mystery entry \"$entry\"\n";
        }
    }
    my %morohashi;
    if ($values{MP}) {
        @morohashi{qw/volume page/} = ($values{MP} =~ /(\d+)\.(\d+)/);
    }
    if ($values{MN}) {
        $morohashi{index} = $values{MN};
    }
    if ($values{MN} || $values{MP}) {
        $values{morohashi} = \%morohashi;
    }
    if (@english) {
        $values{"english"} = \@english;
    }
    if (@onyomi) {
        $values{"onyomi"}  = \@onyomi;
    }
    if (@kunyomi) {
        $values{"kunyomi"} = \@kunyomi;
    }
    if (@nanori) {
        $values{"nanori"} = \@nanori;
    }

    # Kanjidic uses the bogus radical numbers of Nelson rather than
    # the correct ones.

    $values{radical} = $values{B};
    $values{radical} = $values{C} if $values{C};

    # Just in case there is a problem in kanjidic, this will tell us
    # the line where the problem was:

    $values{"line_number"} = $.;
    return %values;
}

# Order of kanji in a kanji dictionary.

sub kanji_dictionary_order
{
    my ($kanjidic_ref, $a, $b) = @_;
    #    print "$a, $b,\n";
    my $valuea = $kanjidic_ref->{$a};
    my $valueb = $kanjidic_ref->{$b};
    my $radval = $$valuea{radical} - $$valueb{radical};
    return $radval if $radval;
    my $strokeval = $valuea->{S}[0] - $valueb->{S}[0];
    return $strokeval if $strokeval;
    my $jisval = hex ($$valuea{jiscode}) - hex ($$valueb{jiscode});
    return $jisval if $jisval;
    return 0;
}

# Order of kanji in a kanji dictionary.

sub stroke_radical_jis_order
{
    my ($kanjidic_ref, $a, $b) = @_;
    #    print "$a, $b,\n";
    my $valuea = $kanjidic_ref->{$a};
    my $valueb = $kanjidic_ref->{$b};
    my $strokeval = $valuea->{S}[0] - $valueb->{S}[0];
    return $strokeval if $strokeval;
    my $radval = $$valuea{radical} - $$valueb{radical};
    return $radval if $radval;
    my $jisval = hex ($$valuea{jiscode}) - hex ($$valueb{jiscode});
    return $jisval if $jisval;
    # They must be the same kanji.
    return 0;
}

# Comparison function to sort by grade and then stroke order, then JIS
# code value if those are both the same.

sub grade_stroke_order
{
    my ($kanjidic_ref, $a, $b) = @_;
    #    print "$a, $b,\n";
    my $valuea = $kanjidic_ref->{$a};
    my $valueb = $kanjidic_ref->{$b};
    if ($valuea->{G}) {
        if ($valueb->{G}) {
            my $gradeval = $$valuea{G} - $$valueb{G};
            return $gradeval if $gradeval;
        }
        else {
            return -1;
        }
    }
    elsif ($valueb->{G}) {
        return 1;
    }
    my $strokeval = $$valuea{S} - $$valueb{S};
    return $strokeval if $strokeval;
    my $jisval = hex ($$valuea{jiscode}) - hex ($$valueb{jiscode});
    return $jisval if $jisval;
    return 0;
}

sub parse_kanjidic
{
    my ($file_name) = @_;
    if (! $file_name) {
        croak "Please supply a file name";
    }
    my $KANJIDIC;

    my %kanjidic;

    if (! -f $file_name) {
        croak "No such file '$file_name'";
    }

    open $KANJIDIC, "<:encoding(euc-jp)", $file_name
        or die "Could not open '$file_name': $!";
    while (<$KANJIDIC>) {
        # Skip the comment line.
        next if ( m/^\#/ );
        my %values = parse_entry ($_);
        my @skip = split ("-", $values{P});
        $values{skip} = \@skip;
        $kanjidic{$values{kanji}} = \%values;
    }
    close $KANJIDIC;
    return \%kanjidic;
}

sub kanjidic_order
{
    my ($kanjidic_ref) = @_;
    my @kanjidic_order = 
        sort {
            hex ($kanjidic_ref->{$a}->{jiscode}) <=> 
            hex ($kanjidic_ref->{$b}->{jiscode})
        }
            keys %$kanjidic_ref;
    my $count = 0;
    for my $kanji (@kanjidic_order) {
        $kanjidic_ref->{$kanji}->{kanji_id} = $count;
        $count++;
    }
    return @kanjidic_order;
}

sub new
{
    my ($package, $file) = @_;
    my $kanjidic = {};
    $kanjidic->{file} = $file;
    undef $file;
    $kanjidic->{data} = parse_kanjidic ($kanjidic->{file});
    bless $kanjidic;
    return $kanjidic;
}

# Make indices going from each type of key back to the data.

sub make_indices
{
    my ($kanjidic) = @_;
    my %indices;
    my $data = $kanjidic->{data};
    for my $kanji (keys %$data) {
        my $kdata = $data->{$kanji};
        for my $key (keys %$kdata) {
            $indices{$key}{$kdata->{$key}} = $kdata;
        }
    }
    $kanjidic->{indices} = \%indices;
}

sub find_key
{
    my ($kanjidic, $key, $value) = @_;
    if (! $kanjidic->{indices}) {
        make_indices ($kanjidic);
    }
    my $index = $kanjidic->{indices}{$key};
    return $index->{$value};
}

sub kanji_to_order
{
    my ($kanjidic, $kanji) = @_;
    if (! $kanjidic->{order}) {
        my @order = kanjidic_order ($kanjidic->{data});
        my %index;
        my $count = 0;
        for my $k (@order) {
            $index{$k} = $count;
            $count++;
        }
        $kanjidic->{order} = \@order;
        $kanjidic->{index} = \%index;
    }
    return $kanjidic->{index}->{$kanji};
}

sub grade
{
    my ($kanjidic, $grade) = @_;
    my @grade_kanjis;
    for my $k (keys %$kanjidic) {
        my $kgrade = $kanjidic->{$k}->{G};
        next unless $kgrade;
        push @grade_kanjis, $k if $kgrade == $grade;
    }
    return \@grade_kanjis;
}

1;

