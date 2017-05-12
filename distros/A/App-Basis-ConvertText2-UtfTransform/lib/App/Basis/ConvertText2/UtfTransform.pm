# ABSTRACT: Convert ascii text into UTF8 to simulate text formatting

=head1 NAME

App::Basis::ConvertText2::UtfTransform

=head1 SYNOPSIS

    use 5.10.0 ;
    use strict ;
    use warnings ;
    use App::Basis::ConvertText2::UtfTransform

    my $string = "<b>bold text</b> 
        <i>italic text</i>
        <f>flipped upside down text and reversed</f>
        <l>Some Leet speak</l>
        <o>text in bubbles</o>
        <s>script text</s>
        <l>are you leet</l>" ;

    say utf_transform( $string) ;

    my $smile = ":beer: is food!  :) I <3 :cake: ;)" ;

    say uttf_smilies( $smile ) ;

=head1 DESCRIPTION

A number of popular websites (eg twitter) do not allow the use of HTML to create
bold/italic font effects or perform smily transformations

However we can simulate this with some clever transformations of plain ascii text
into UTF8 codes which are a different font and so effectively create the same effect.

We have transformations for flip (reverses the string and flips upside down,
bold, italic, bubbles and leet.

We can transform A-Z a-z 0-9 and ? ! ,

I have only implemented a small set of smilies, ones that I am likely to use

=head1 Note

You cannot embed one format within another, so you cannot have bold script, or 
bold italic.

=head1 See Also 

L<http://txtn.us/>

=head1 Functions

=over 4

=cut

package App::Basis::ConvertText2::UtfTransform;
$App::Basis::ConvertText2::UtfTransform::VERSION = '0.4.0';
use 5.014;
use warnings;
use strict;
use Acme::LeetSpeak;
use Text::Emoticon;
use Exporter;
use vars qw( @EXPORT @ISA);

@ISA = qw(Exporter);

# this is the list of things that will get imported into the loading packages
# namespace
@EXPORT = qw(
    utf_transform
    utf_smilies
);

# ----------------------------------------------------------------------------

# UTF8 codes to transform normal ascii to different UTF8 codes
# to perform text effects that can be used on websites that allow UTF8 but
# do not allow HTML codes

# ----------------------------------------------------------------------------

my %flip = (
    "a" => "\x{0250}",
    "b" => "q",
    "c" => "\x{0254}",
    "d" => "p",
    "e" => "\x{01DD}",
    "f" => "\x{025F}",
    "g" => "\x{0183}",
    "h" => "\x{0265}",
    "i" => "\x{0131}",
    "j" => "\x{027E}",
    "k" => "\x{029E}",
    "l" => "\x{0283}",
    "m" => "\x{026F}",
    "n" => "u",
    "o" => "o",
    "p" => "d",
    "q" => "q",
    "r" => "\x{0279}",
    "s" => "s",
    "t" => "\x{0287}",
    "u" => "n",
    "v" => "\x{028C}",
    "w" => "\x{028D}",
    "x" => "x",
    "y" => "\x{028E}",
    "z" => "z",
    "0" => "0",
    "1" => "1",
    "2" => "2",
    "3" => "3",
    "4" => "4",
    "5" => "5",
    "6" => "6",
    "7" => "7",
    "8" => "8",
    "9" => "9",
    "?" => "\x{00BF}",
    "!" => "\x{00A1}",
    "," => ",",
);

my %bold = (
    "A" => "\x{1D400}",
    "B" => "\x{1D401}",
    "C" => "\x{1D402}",
    "D" => "\x{1D403}",
    "E" => "\x{1D404}",
    "F" => "\x{1D405}",
    "G" => "\x{1D406}",
    "H" => "\x{1D407}",
    "I" => "\x{1D408}",
    "J" => "\x{1D409}",
    "K" => "\x{1D40A}",
    "L" => "\x{1D40B}",
    "M" => "\x{1D40C}",
    "N" => "\x{1D40D}",
    "O" => "\x{1D40E}",
    "P" => "\x{1D40F}",
    "Q" => "\x{1D410}",
    "R" => "\x{1D411}",
    "S" => "\x{1D412}",
    "T" => "\x{1D413}",
    "U" => "\x{1D414}",
    "V" => "\x{1D415}",
    "W" => "\x{1D416}",
    "X" => "\x{1D417}",
    "Y" => "\x{1D418}",
    "Z" => "\x{1D419}",
    "a" => "\x{1D41A}",
    "b" => "\x{1D41B}",
    "c" => "\x{1D41C}",
    "d" => "\x{1D41D}",
    "e" => "\x{1D41E}",
    "f" => "\x{1D41F}",
    "g" => "\x{1D420}",
    "h" => "\x{1D421}",
    "i" => "\x{1D422}",
    "j" => "\x{1D423}",
    "k" => "\x{1D424}",
    "l" => "\x{1D425}",
    "m" => "\x{1D426}",
    "n" => "\x{1D427}",
    "o" => "\x{1D428}",
    "p" => "\x{1D429}",
    "q" => "\x{1D42A}",
    "r" => "\x{1D42B}",
    "s" => "\x{1D42C}",
    "t" => "\x{1D42D}",
    "u" => "\x{1D42E}",
    "v" => "\x{1D42F}",
    "w" => "\x{1D430}",
    "x" => "\x{1D431}",
    "y" => "\x{1D432}",
    "z" => "\x{1D433}",
    "0" => "\x{1D7CE}",
    "1" => "\x{1D7CF}",
    "2" => "\x{1D7D0}",
    "3" => "\x{1D7D1}",
    "4" => "\x{1D7D2}",
    "5" => "\x{1D7D3}",
    "6" => "\x{1D7D4}",
    "7" => "\x{1D7D5}",
    "8" => "\x{1D7D6}",
    "9" => "\x{1D7D7}",
    "?" => "?",
    "!" => "!",
    "," => ",",
);

my %italic = (
    "A" => "\x{1D434}",
    "B" => "\x{1D435}",
    "C" => "\x{1D436}",
    "D" => "\x{1D437}",
    "E" => "\x{1D438}",
    "F" => "\x{1D439}",
    "G" => "\x{1D43A}",
    "H" => "\x{1D43B}",
    "I" => "\x{1D43C}",
    "J" => "\x{1D43D}",
    "K" => "\x{1D43E}",
    "L" => "\x{1D43F}",
    "M" => "\x{1D440}",
    "N" => "\x{1D441}",
    "O" => "\x{1D442}",
    "P" => "\x{1D443}",
    "Q" => "\x{1D444}",
    "R" => "\x{1D445}",
    "S" => "\x{1D446}",
    "T" => "\x{1D447}",
    "U" => "\x{1D448}",
    "V" => "\x{1D449}",
    "W" => "\x{1D44A}",
    "X" => "\x{1D44B}",
    "Y" => "\x{1D44C}",
    "Z" => "\x{1D44D}",
    "a" => "\x{1D622}",
    "b" => "\x{1D623}",
    "c" => "\x{1D624}",
    "d" => "\x{1D625}",
    "e" => "\x{1D626}",
    "f" => "\x{1D627}",
    "g" => "\x{1D628}",
    "h" => "\x{1d629}",
    "i" => "\x{1D62a}",
    "j" => "\x{1D62b}",
    "k" => "\x{1D62c}",
    "l" => "\x{1D62d}",
    "m" => "\x{1D62e}",
    "n" => "\x{1D62f}",
    "o" => "\x{1D630}",
    "p" => "\x{1D631}",
    "q" => "\x{1D632}",
    "r" => "\x{1D633}",
    "s" => "\x{1D634}",
    "t" => "\x{1D635}",
    "u" => "\x{1D636}",
    "v" => "\x{1D637}",
    "w" => "\x{1D638}",
    "x" => "\x{1D639}",
    "y" => "\x{1D63a}",
    "z" => "\x{1D63b}",
    "0" => "0",
    "1" => "1",
    "2" => "2",
    "3" => "3",
    "4" => "4",
    "5" => "5",
    "6" => "6",
    "7" => "7",
    "8" => "8",
    "9" => "9",
    "?" => "?",
    "!" => "!",
    "," => ",",
);

# mathematical bold script capital and small
# http://www.fileformat.info/info/unicode/category/Lu/list.htm
# http://www.fileformat.info/info/unicode/category/Ll/list.htm

my %script = (
    "A" => "\x{1d4d0}",
    "B" => "\x{1d4d1}",
    "C" => "\x{1d4d2}",
    "D" => "\x{1d4d3}",
    "E" => "\x{1d4d4}",
    "F" => "\x{1d4d5}",
    "G" => "\x{1d4d6}",
    "H" => "\x{1d4d7}",
    "I" => "\x{1d4d8}",
    "J" => "\x{1d4d9}",
    "K" => "\x{1d4da}",
    "L" => "\x{1d4db}",
    "M" => "\x{1d4dc}",
    "N" => "\x{1d4dd}",
    "O" => "\x{1d4de}",
    "P" => "\x{1d4df}",
    "Q" => "\x{1d4e0}",
    "R" => "\x{1d4e1}",
    "S" => "\x{1d4e2}",
    "T" => "\x{1D4e3}",
    "U" => "\x{1D4e4}",    ## special
    "V" => "\x{1D4e5}",
    "W" => "\x{1D4e6}",
    "X" => "\x{1D4e7}",
    "Y" => "\x{1D4e8}",
    "Z" => "\x{1D4e9}",
    "a" => "\x{1D4ea}",
    "b" => "\x{1D4eb}",
    "c" => "\x{1D4ec}",
    "d" => "\x{1D4ed}",
    "e" => "\x{1D4ee}",
    "f" => "\x{1D4ef}",
    "g" => "\x{1D4f0}",
    "h" => "\x{1d4f1}",
    "i" => "\x{1D4f2}",
    "j" => "\x{1D4f3}",
    "k" => "\x{1D4f4}",
    "l" => "\x{1D4f5}",
    "m" => "\x{1D4f6}",
    "n" => "\x{1D4f7}",
    "o" => "\x{1D4f8}",
    "p" => "\x{1D4f9}",
    "q" => "\x{1D4fa}",
    "r" => "\x{1D4fb}",
    "s" => "\x{1D4fc}",
    "t" => "\x{1D4fd}",
    "u" => "\x{1D4fe}",
    "v" => "\x{1D4ff}",
    "w" => "\x{1D500}",
    "x" => "\x{1D501}",
    "y" => "\x{1D502}",
    "z" => "\x{1D503}",
    "0" => "0",
    "1" => "1",
    "2" => "2",
    "3" => "3",
    "4" => "4",
    "5" => "5",
    "6" => "6",
    "7" => "7",
    "8" => "8",
    "9" => "9",
    "?" => "?",
    "!" => "!",
    "," => ",",
);

my %bubbles = (
    "A" => "\x{24B6}",
    "B" => "\x{24B7}",
    "C" => "\x{24B8}",
    "D" => "\x{24B9}",
    "E" => "\x{24BA}",
    "F" => "\x{24BB}",
    "G" => "\x{24BC}",
    "H" => "\x{24BD}",
    "I" => "\x{24BE}",
    "J" => "\x{24BF}",
    "K" => "\x{24C0}",
    "L" => "\x{24C1}",
    "M" => "\x{24C2}",
    "N" => "\x{24C3}",
    "O" => "\x{24C4}",
    "P" => "\x{24C5}",
    "Q" => "\x{24C6}",
    "R" => "\x{24C7}",
    "S" => "\x{24C8}",
    "T" => "\x{24C9}",
    "U" => "\x{24CA}",
    "V" => "\x{24CB}",
    "W" => "\x{24CC}",
    "X" => "\x{24CD}",
    "Y" => "\x{24CE}",
    "Z" => "\x{24CF}",
    "a" => "\x{24D0}",
    "b" => "\x{24D1}",
    "c" => "\x{24D2}",
    "d" => "\x{24D3}",
    "e" => "\x{24D4}",
    "f" => "\x{24D5}",
    "g" => "\x{24D6}",
    "h" => "\x{24D7}",
    "i" => "\x{24D8}",
    "j" => "\x{24D9}",
    "k" => "\x{24DA}",
    "l" => "\x{24DB}",
    "m" => "\x{24DC}",
    "n" => "\x{24DD}",
    "o" => "\x{24DE}",
    "p" => "\x{24DF}",
    "q" => "\x{24E0}",
    "r" => "\x{24E1}",
    "s" => "\x{24E2}",
    "t" => "\x{24E3}",
    "u" => "\x{24E4}",
    "v" => "\x{24E5}",
    "w" => "\x{24E6}",
    "x" => "\x{24E7}",
    "y" => "\x{24E8}",
    "z" => "\x{24E9}",
    "0" => "\x{24EA}",
    "1" => "\x{2460}",
    "2" => "\x{2461}",
    "3" => "\x{2462}",
    "4" => "\x{2463}",
    "5" => "\x{2464}",
    "6" => "\x{2465}",
    "7" => "\x{2466}",
    "8" => "\x{2467}",
    "9" => "\x{2468}",
    "?" => "?",
    "!" => "!",
    "," => ",",
);

# http://www.fileformat.info/info/unicode/category/So/list.htm
my %smilies = (
    '<3'           => "\x{2665}",     #heart
    ':heart:'      => "\x{2665}",     #heart
    ':)'           => "\x{1f600}",    #smile
    ':D'           => "\x{1f625}",    #grin
    '8-)'          => "\x{1f60e}",    #cool
    ':P'           => "\x{1f61b}",    #pull tounge
    ":'("          => "\x{1f62c}",    #cry
    ':('           => "\x{2639}",     #sad
    ";)"           => "\x{1f609}",    #wink
    ":sleep:"      => "\x{1f634}",    #sleep
    ":halo:"       => "\x{1f607}",    #halo
    ":devil:"      => "\x{1f608}",    #devil
    ":horns:"      => "\x{1f608}",    #devil
    "(c)"          => "\x{00a9}",     # copyright
    "(r)"          => "\x{00ae}",     # registered
    "(tm)"         => "\x{0099}",     # trademark
    ":email:"      => "\x{2709}",     # email
    ":yes:"        => "\x{2713}",     # tick
    ":no:"         => "\x{2715}",     # cross
    ":beer:"       => "\x{1F37A}",    # beer
    ":wine:"       => "\x{1f377}",    # wine
    ":wine_glass:" => "\x{1f377}",    # wine
    ":cake:"       => "\x{1f382}",    # cake
    ":star:"       => "\x{2606}",     # star
    ":ok:"         => "\x{1f44d}",    # ok = thumbsup
    ":yes:"        => "\x{1f44d}",    # yes = thumbsup
    ":thumbsup:"   => "\x{1f44d}",    # thumbsdown
    ":thumbsdown:" => "\x{1f44e}",    # thumbsup
    ":bad:"        => "\x{1f44e}",    # bad = thumbsdown
    ":no:"         => "\x{1f44e}",    # no = thumbsdown
    ":ghost:"      => "\x{1f47b}",    # ghost
    ":skull:"      => "\x{1f480}",    # skull
    ":time:"       => "\x{231a}",     # time, watch face
    ":hourglass:"  => "\x{231b}",     # hourglass
);

my $smiles = join( '|', map { quotemeta($_) } keys %smilies );

my %code_map = (
    f => \%flip,
    b => \%bold,
    i => \%italic,
    o => \%bubbles,
    s => \%script,
);

# ----------------------------------------------------------------------------
# regexp replace function
sub _transform {
    my ( $code, $string ) = @_;
    my $transform = 1;

    if ( $code eq 'f' ) {

        # needs to be reversed and in lower case for flip
        $string = reverse lc($string);
    }
    elsif ( $code eq 'l' ) {

        # leet
        $string    = leet($string);
        $transform = 0;
    }

    if ( $transform && $code_map{$code} ) {
        $string =~ s/([A-ZA-z0-9?!,])/$code_map{$code}->{$1}/gsm;
    }

    return $string;
}

# ----------------------------------------------------------------------------

=item utf_transform

transform A-ZA-z0-9!?, into UTF8 forms suitable for websites that do not allow
HTML codes for these

we use the following psuedo HTML elements

    flip     <f>text</f>      upside down and reversed
    bold     <b>text</b>
    italic   <i>text</i>
    bubbles  <o>text</o>
    script   <s>text</s>
    leet     <l>text</l>      LeetSpeak

B<Parameters>  

incoming string    

B<Returns>

transformed string

=cut

sub utf_transform {
    my ($in) = @_;

    # transform for formatting
    $in =~ s|<(\w)>(.*?)</\1>|_transform( $1, $2)|egsi;

    return $in;
}

# ----------------------------------------------------------------------------

=item utf_smilies

transform some character strings into UTF smilies

I have only implemented a small set of smilies, ones that I am likely to use

    | smilie                    | symbol      |
    |---------------------------+-------------|
    | <3. :heart:               | heart       |
    | :)                        | smile       |
    | :D                        | grin        |
    | 8-)                       | cool        |
    | :P                        | pull tongue |
    | :(                        | cry         |
    | :(                        | sad         |
    | ;)                        | wink        |
    | :halo:                    | halo        |
    | :devil:, :horns:          | devil horns |
    | (c)                       | copyright   |
    | (r)                       | registered  |
    | (tm)                      | trademark   |
    | :email:                   | email       |
    | :yes:                     | tick        |
    | :no:                      | cross       |
    | :beer:                    | beer        |
    | :wine:, :wine_glass:      | wine        |
    | :cake:                    | cake        |
    | :star:                    | star        |
    | :ok:, :thumbsup:          | thumbsup    |
    | :bad:, :thumbsdown:       | thumbsup    |
    | :ghost:                   | ghost       |
    | :skull:                   | skull       |
    | :hourglass:               | hourglass   |
    | :time:                    | watch face  |
    | :sleep:                   | sleep       |

B<Parameters>  

incoming string    

B<Returns>

transformed string

=cut

sub utf_smilies {
    my ($in) = @_;

    $in =~ s/(?<!\w)($smiles)(?!\w)/$smilies{$1}/g;

    return $in;
}

# ----------------------------------------------------------------------------

=back

=cut

# ----------------------------------------------------------------------------
1;
