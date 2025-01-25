package App::Greple::charcode;

use 5.024;
use warnings;
use utf8;

our $VERSION = "0.9901";

=encoding utf-8

=head1 NAME

App::Greple::charcode - greple module to annotate unicode character data

=head1 SYNOPSIS

B<greple> B<-Mcharcode> ...

B<greple> B<-Mcharcode> [ I<module option> ] -- [ I<greple option> ] ...

  MODULE OPTIONS
    --[no-]column display column number
    --[no-]char   display character itself
    --[no-]width  display width
    --[no-]code   display character code
    --[no-]name   display character name
    --align=#     align annotation

    --config KEY[=VALUE],... (KEY: column, char, width, code, name, align)

=head1 VERSION

Version 0.9901

=head1 DESCRIPTION

C<App::Greple::charcode> displays Unicode information about the
matched characters.  It can also visualize zero-width combining or
hidden characters, which can be useful for examining text containing
such characters.

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

=begin html

<p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-charcode/refs/heads/main/images/ka-ko.png">
</p>

=end html

=head1 MODULE OPTIONS

=over 7

=item B<-->[B<no->]B<column>

Show column number.
Default B<true>.

=item B<-->[B<no->]B<char>

Show the character itself.
Default B<false>.

=item B<-->[B<no->]B<width>

Show the width.
Default B<false>.

=item B<-->[B<no->]B<code>

Show the character code in hex.
Default B<true>.

=item B<-->[B<no->]B<name>

Show the Unicode name of the character.
Default B<true>.

=item B<--align>=I<column>

Align annotation messages.  Defaults to C<1>, which aligns to the
rightmost column; C<0> means no align; if a value of C<2> or greater
is given, it aligns to that numbered column.

=back

=head1 CONFIGURATION

Configuration parameters can be set in several ways.

=head2 MODULE START FUNCTION

The start function of a module can be specified at the same time as
the module declaration.

    greple -Mcharcode::config(width,name=0)

    greple -Mcharcode::config=width,name=0

=head2 PRIVATE MODULE OPTION

Module-specific options are specified between C<-Mcharcode> and C<-->.

    greple -Mcharcode --config width,name=0 -- ...

=head1 CONFIGURATION PARAMETERS

=over 7

=item B<column>

(default 1)
Show column number.

=item B<char>

(default 0)
Show the character itself.

=item B<width>

(default 0)
Show the width.

=item B<code>

(default 1)
Show the character code in hex.

=item B<name>

(default 1)
Show the Unicode name of the character.

=item B<align>=I<column>

(default 1)
Align the description on the same column.

=back

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

use Getopt::EX::Config qw(config);
use Hash::Util qw(lock_keys);

use App::Greple::annotate;

my $config = Getopt::EX::Config->new(
    column => 1,
    char   => 0,
    width  => 0,
    code   => 1,
    name   => 1,
    align  => \$App::Greple::annotate::config->{align},
);
my %type = ( align => '=i', '*' => '!' );
lock_keys %{$config};

sub finalize {
    our($mod, $argv) = @_;
    $config->deal_with(
	$argv,
	(
	    map {
		my $type = $type{$_} // $type{'*'};
		( $_.$type => ref $config->{$_} ? $config->{$_} : \$config->{$_} ) ;
	    }
	    keys %{$config}
	),
    );
}

use Unicode::UCD qw(charinfo);
use Data::Dumper;

sub charname {
    local $_ = @_ ? shift : $_;
    s/(.)/name($1)/ger;
}

sub name {
    my $char = shift;
    "\\N{" . Unicode::UCD::charinfo(ord($char))->{name} . "}";
}

sub charcode {
    local $_ = @_ ? shift : $_;
    state $format = [ qw(\x{%02x} \x{%04x}) ];
    s/(.)/code($1)/ger;
}

sub code {
    state $format = [ qw(\x{%02x} \x{%04x}) ];
    my $ord = ord($_[0]);
    sprintf($format->[$ord > 0xff], $ord);
}

sub describe {
    local $_ = shift;
    my @s;
    push @s, "{$_}"                         if $config->{char};
    push @s, sprintf("\\w{%d}", vwidth($_)) if $config->{width};
    push @s, join '', map { charcode } /./g if $config->{code};
    push @s, join '', map { charname } /./g if $config->{name};
    join "\N{NBSP}", @s;
}

sub annotate {
    my %param = @_;
    my $annon = '';
    $annon .= sprintf("%3d ", $param{column}) if $config->{column};
    $annon .= describe($param{match});
    $annon;
}

$App::Greple::annotate::ANNOTATE = \&annotate;

1;

__DATA__

option default -Mannotate --separate --uniqcolor
