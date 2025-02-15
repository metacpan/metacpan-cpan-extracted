package App::Greple::charcode;

use 5.024;
use warnings;
use utf8;

our $VERSION = "0.9906";

=encoding utf-8

=head1 NAME

App::Greple::charcode - greple module to annotate unicode character data

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-charcode/refs/heads/main/images/homoglyph.png">
</p>

=head1 SYNOPSIS

B<greple> B<-Mcharcode> ...

B<greple> B<-Mcharcode> [ I<module option> ] -- [ I<command option> ] ...

  COMMAND OPTION
    --no-annotate  do not print annotation
    --[no-]align   align annotations
    --align-all    align to the same column for all lines
    --align-side   align to the longest line

  UNICODE
    --composite    find composite character (combining character sequence)
    --precomposed  find precomposed character
    --combined     find both composite and precomposed characters
    --dt=type      specify decomposition type
    --surrogate    find character in UTF-16 surrogate pair range
    --outstand     find non-ASCII combining characters
    -p/-P prop     find \p{prop} or \P{prop} characters

  ANSI
    --ansicode     find ANSI terminal control sequences

  MODULE OPTION
    --[no-]column  display column number
    --[no-]char    display character itself
    --[no-]width   display width
    --[no-]code    display character code
    --[no-]name    display character name
    --[no-]visible display character name
    --[no-]split   put annotattion for each character
    --alignto=#    align annotation to #

    --config KEY[=VALUE],...
             (KEY: column char width code name visible align)

B<greple> B<-Mcc> ...

B<greple> B<-Mcc> [ I<module option> ] -- [ I<command option> ] ...

    -Mcc           alias module for -Mcharcode

=head1 VERSION

Version 0.9906

=head1 DESCRIPTION

Greple module C<-Mcharcode> (or C<-Mcc> for short) displays
information about the matched characters.  It can also visualize
Unicode zero-width combining or hidden characters, which can be useful
for examining text containing visually indistinguishable or
imperceptible elements.

The following output, retrieved from this document for non-ASCII
characters (C<\P{ASCII}>), shows that the character C<\N{VARIATION
SELECTOR-15}> is included after the copyright character.  The same
character, presumably left over from editing, is also included after a
normal ASCII C<t> character.

    $ greple -Mcharcode '\P{ASCII}' charcode.pm

            ┌───  12 \x{fe0e} \N{VARIATION SELECTOR-15}
            │ ┌─  14 \x{a9} \N{COPYRIGHT SIGN}
            │ ├─  14 \x{fe0e} \N{VARIATION SELECTOR-15}
    Copyright︎ ©︎ 2025 Kazumasa Utashiro.

The nasal sound of the K line (カ行) in Japanese is sometimes
represented by adding a semivoiced dot to the K line character, and
since Unicode does not define a corresponding character, it is
represented by combining the original character with a combining
character.  This module allows you to see how it is done.

    ┌─────────   0 \x{30ab} \N{KATAKANA LETTER KA}
    ├─────────   0 \x{309a} \N{COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK}
    │ ┌───────   2 \x{30ad} \N{KATAKANA LETTER KI}
    │ ├───────   2 \x{309a} \N{COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK}
    │ │ ┌─────   4 \x{30af} \N{KATAKANA LETTER KU}
    │ │ ├─────   4 \x{309a} \N{COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK}
    │ │ │ ┌───   6 \x{30b1} \N{KATAKANA LETTER KE}
    │ │ │ ├───   6 \x{309a} \N{COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK}
    │ │ │ │ ┌─   8 \x{30b3} \N{KATAKANA LETTER KO}
    │ │ │ │ ├─   8 \x{309a} \N{COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK}
    カ゚キ゚ク゚ケ゚コ゚

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-charcode/refs/heads/main/images/ka-ko.png">
</p>

=head1 COMMAND OPTIONS

=over 7

=item B<--annotate>, B<--no-annotate>

Print annotation or not.  Enabled by default, so use C<--no-annotate>
to disable it.

=item B<-->[B<no->]B<align>

Align annotation or not.
Default true.

=item B<--align-all>

Align to the same column for all lines

=item B<--align-side>

Align to the longest line length, regardless of match position.

=back

=head1 PATTERN OPTIONS

If multiple patterns are given to B<greple>, it normally prints only
the lines that match all of the patterns.  However, for the purposes
of this module, it is desirable to display lines that match any of
them, so the C<--need=1> option is specified by default.

If multiple patterns are specified, the strings matching each pattern
will be displayed in a different color.

=over 7

=item B<--composite>

Search for composite characters (combining character sequence)
composed of base and combining characters.

=item B<--precomposed>

Search for precomposed characters (C<\p{Dt=Canonical}>).

=item B<--combined>

Find both B<composite> and B<precomposed> characters.

=item B<--dt>=I<type>, B<--decomposition-type>=I<type>

Specifies the C<Decomposition_Type>.  It can take three values:
C<Canonical>, C<Non_Canonical> (C<NonCanon>), or C<None>.

=item B<--outstand>

Matches outstanding characters, those are non-ASCII combining
characters.

=item B<--surrogate>

Matches to characters in UTF-16 surragate pair range (U+10000 to
U+10FFFF).

=item B<-p> I<prop>, B<-P> I<prop>

Short cut for C<-E '\p{prop}'> and  C<-E '\P{prop}'>.

You will not be able to use greple's C<-p> option, but it probably
won't be a problem.  If you must use it, use C<--pargraph>.

=item B<--ansicode>

Search ANSI terminal control sequence.  Automatically disables C<name>
and C<code> parameter and activates C<visible>.  Colorized output is
disabled too.

To be precise, it searches for CSI Control sequences defined in
ECMA-48.  Pattern is defined as this.

    (?x)
    # see ECMA-48 5.4 Control sequences
    (?: \e\[ | \x9b ) # csi
    [\x30-\x3f]*      # parameter bytes
    [\x20-\x2f]*      # intermediate bytes
    [\x40-\x7e]       # final byte

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-charcode/refs/heads/main/images/ansicode.png">
</p>

=back

=head1 MODULE OPTIONS and PARAMS

Module-specific options are specified between C<-Mcharcode> and C<-->.

    greple -Mcharcode --config width,name=0 -- ...

Parameters can be set in two ways, one using the C<--config> option
and the other using dedicated options.  See the L</CONFIGURATION>
section for more information.

=over 7

=item B<--config>=I<params>

Set configuration parameters.

=item B<column>

=item B<-->[B<no->]B<column>

Show column number.
Default C<1>.

=item B<char>

=item B<-->[B<no->]B<char>

Show the character itself.
Default C<0>.

=item B<width>

=item B<-->[B<no->]B<width>

Show the width.
Default C<0>.

=item B<code>

=item B<-->[B<no->]B<code>

Show the character code in hex.
Default C<1>.

=item B<name>

=item B<-->[B<no->]B<name>

Show the Unicode name of the character.
Default C<1>.

=item B<visible>

=item B<-->[B<no->]B<visible>

Display invisible characters in a visible string representation.
Default C<0>.

=item B<alignto>=I<column>

=item B<--alignto>=I<column>

Align annotation messages.  Defaults to C<1>, which aligns to the
rightmost column; C<0> means no align; if a value of C<2> or greater
is given, it aligns to that numbered column.

I<column> can be negative; if C<-1> is specified, align to the same
column for all lines.  If C<-2> is specified, align to the longest
line length, regardless of match position.

=item B<split>

=item B<-->[B<no->]B<split>

If a pattern matching multiple characters is given, annotate each
character independently.

=back

=head1 CONFIGURATION

Configuration parameters can be set in several ways.

=head2 MODULE START FUNCTION

The start function of a module can be specified at the same time as
the module declaration.

    greple -Mannotate::config(alignto=0)

    greple -Mannotate::config=alignto=80

=head2 PRIVATE MODULE OPTION

Module-specific options are specified between C<-Mannotate> and C<-->.

    greple -Mannotate --config alignto=80 -- ...

    greple -Mannotate --alignto=80 -- ...

=head2 GENERIC MODULE OPTION

Module-specific C<---config> option can be called by normal command
line option C<--annotate::config>.

    greple -Mannotate --annotate::config alignto=80 ...

=head1 EXAMPLES

=head2 HOMOGLYPH

    greple -Mcc -P ASCII --align-side --cm=S t/homoglyph

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-charcode/refs/heads/main/images/homoglyph.png">
</p>

=head2 BOX DRAWINGS

    perldoc -m App::ansicolumn::Border | greple -Mline -Mcc --code -- --outstand --mc=10,

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-charcode/refs/heads/main/images/box-drawing.png">
</p>

=head2 AYNU ITAK

    greple -Mcc --outstand --split t/ainu.txt

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-charcode/refs/heads/main/images/aynu.png">
</p>

=head1 INSTALL

    cpanm -n App::Greple::charcode

=head1 SEE ALSO

L<App::Greple>

L<App::Greple::charcode>

L<App::Greple::annotate>

=head1 LICENSE

Copyright︎ ©︎ 2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kazumasa Utashiro

=cut

use Exporter 'import';
our @EXPORT_OK = qw(config);
our %EXPORT_TAGS = (alias => \@EXPORT_OK);

use Encode qw(encode decode);
use Getopt::EX::Config;
use Hash::Util qw(lock_keys);
use Data::Dumper;
use Text::ANSI::Fold::Util qw(ansi_width);

use App::Greple::annotate;

our $config = Getopt::EX::Config->new(
    column  => 1,
    visible => 1,
    char    => 0,
    width   => 0,
    utf8    => 0,
    utf16   => 0,
    code    => 0,
    name    => 1,
    alignto => \$App::Greple::annotate::config->{alignto},
    split   => \$App::Greple::annotate::config->{split},
);
my %type = ( alignto => '=i', '*' => '!' );
lock_keys %{$config};

our %CONFIG_TAGS = (
    field => [ qw(column visible char width utf8 utf16 code name) ],
);

sub finalize {
    our($mod, $argv) = @_;
    $config->deal_with(
	$argv,
	(
	    map {
		my $type = $type{$_} // $type{'*'};
		my $ref = ref $config->{$_} ? $config->{$_} : \$config->{$_};
		( $_.$type => $ref ) ;
	    }
	    keys %{$config}
	),
	'all:1' => sub {
	    for ($CONFIG_TAGS{field}->@*) {
		my $ref = ref $config->{$_} ? $config->{$_} : \$config->{$_};
		$$ref = $_[1];
	    }
	},
    );
}

use Unicode::UCD qw(charinfo);

sub charname {
    local $_ = @_ ? shift : $_;
    s/(.)/name($1)/sger;
}

sub name {
    my $char = shift;
    "\\N{" . Unicode::UCD::charinfo(ord($char))->{name} . "}";
}

sub charcode {
    local *_ = @_ ? \$_[0] : \$_;
    s/(.)/code($1)/ger;
}

sub utf8 {
    utf('UTF-8', @_);
}

sub utf16 {
    utf('UTF-16', @_);
}

sub utf {
    my $code = shift;
    local $_ = encode($code, @_ ? shift : $_);
    s/(.)/code($1)/ger;
}

sub code {
    state $format = [ qw(\x{%02x} \x{%04x}) ];
    my $ord = ord($_[0]);
    sprintf($format->[$ord > 0xff], $ord);
}

my %cmap = (
    "\t" => '\t',
    "\n" => '\n',
    "\r" => '\r',
    "\f" => '\f',
    "\b" => '\b',
    "\a" => '\a',
    "\e" => '\e',
);

sub control {
    local $_ = @_ ? $_[0] : $_;
    if (s/\A([\t\n\r\f\b\a\e])/$cmap{$1}/e) {
	$_;
    } elsif (s/\A([\x00-\x1f])/sprintf "\\c%c", ord($1)+0x40/e) {
	$_;
    } else {
	code($_);
    }
}

my $invisible_re = $ENV{INVISIBLE_RE} = qr/[^\pL\pN\pP\pS]/;

sub visible {
    local *_ = @_ ? \$_[0] : \$_;
    s{($invisible_re)}{control($1)}ger;
}

sub width {
    local *_ = @_ ? \$_[0] : \$_;
    ansi_width($_);
}

sub describe {
    my %param = @_;
    my $column = $param{column};
    local $_   = $param{match};
    my @s;
    push @s, sprintf("%3d ", $column)     if $config->{column};
    push @s, sprintf("%s", visible)       if $config->{visible};
    push @s, sprintf("raw=\"%s\"", $_)    if $config->{char};
    push @s, sprintf("w=%d", width)       if $config->{width};
    push @s, sprintf("utf8=%s", utf8)     if $config->{utf8};
    push @s, sprintf("utf16=%s", utf16)   if $config->{utf16};
    push @s, sprintf("code=%s", charcode) if $config->{code};
    push @s, sprintf("name=%s", charname) if $config->{name};
    join "\N{NBSP}", @s;
}

$App::Greple::annotate::ANNOTATE = \&describe;

1;

__DATA__

option default \
    -Mannotate \
    --need=1 \
    --fs=once --ls=separate $<move>

option --charcode::config \
    --prologue &__PACKAGE__::config($<shift>)

option --config --charcode::config

option --surrogate -E '[\N{U+10000}-\N{U+10FFFF}]'

define \p{CombinedChar} \p{Format}\p{Mark}
define \p{Combined}     [\p{CombinedChar}]
define \p{Base}         [^\p{CombinedChar}]

option --composite -E '(?#composite)(\p{Base})(\p{Combined}+)'

option --decomposition-type -E '(?#canonical)\p{Decomposition_Type=$<shift>}'
option --dt --decomposition-type

option --precomposed --decomposition-type=Canonical
option --noncanon    --decomposition-type=NonCanon

option --combined \
    --precomposed --composite

option --INVISIBLE --cm=N -E '$ENV{INVISIBLE_RE}'
option --invisible --cm=N -E '(?!\p{Blank}|\R)$ENV{INVISIBLE_RE}'

option --outstand \
    --combined -E '(?#outstand)(?=\P{ASCII})\X'

define ANSI-CSI <<EOL
    (?xn)
    # see ANSI-48 5.4 Control sequences
    ( \e\[ | \x9b )	# csi
    [\x30-\x3f]*+	# parameter bytes
    [\x20-\x2f]*+	# intermediate bytes
    [\x40-\x7e]		# final byte
EOL

define ANSI-RESET <<EOL
    (?xn)
    ( ( \e\[ | \x9b ) [0;]* m )+
    ( ( \e\[ | \x9b ) [0;]* K )*
EOL

expand --visible-option \
    --charcode::config code=0,name=0,visible=1 \
    --cm=N

option --ansicode-raw \
    -E '(?#ansicode)(?:ANSI-RESET)+|(?:ANSI-CSI)'

option --ansicode \
    --visible-option --ansicode-raw

option --ansicode-each \
    --visible-option -E ANSI-CSI

option --ansicode-seq \
    --visible-option -E '(?:ANSI-CSI)+'

option -p -E '\p{$<shift>}'
option -P -E '\P{$<shift>}'
