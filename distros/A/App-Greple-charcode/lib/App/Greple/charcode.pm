package App::Greple::charcode;

use 5.024;
use warnings;
use utf8;

our $VERSION = "0.99";

=encoding utf-8

=head1 NAME

App::Greple::charcode - greple module to annotate unicode character data

=head1 SYNOPSIS

B<greple> B<-Mcharcode> ...

B<greple> B<-Mcharcode> [ I<module option> ] -- [ I<greple option> ] ...

  MODULE OPTIONS
    --[no-]col    display column number
    --[no-]char   display character itself
    --[no-]width  display width
    --[no-]code   display character code
    --[no-]name   display character name
    --[no-]align  align annotation

    --config KEY[=VALUE],... (KEY: col, char, width, code, name, align)

=head1 VERSION

Version 0.99

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

=head1 CONFIGURATION

Configuration parameters can be set in several ways.

=head2 MODULE START FUNCTION

The start function of a module can be specified at the same time as
the module declaration.

    greple -Mcharcode::config(width,name=0)

    greple -Mcharcode::config=width,name=0

=head2 MODULE PRIVATE OPTION

Module-specific options are specified between C<-Mcharcode> and C<-->.

    greple -Mcharcode --config width,name=0 -- ...

=head2 COMMAND LINE OPTION

Command line option C<--charcode::config> and C<--config> can be used.
The long option is to avoid option name conflicts when multiple
modules are used.

    greple -Mcharcode --charcode::config width,name=0

    greple -Mcharcode --config width,name=0

=head1 CONFIGURATION PARAMETERS

=over 7

=item B<col>

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

=item B<align>

(default 1)
Align the description on the same column.

=back

=head1 MODULE OPTIONS

The configuration parameters above have corresponding module options.
For example, the name parameter can be switched by the C<--name> and
C<--no-name> options.

=over 7

=item B<--col>, B<--no-col>

=item B<--char>, B<--no-char>

=item B<--width>, B<--no-width>

=item B<--code>, B<--no-code>

=item B<--name>, B<--no-name>

=item B<--align>, B<--no-align>

=back

=head1 INSTALL

cpanm -n B<App::Greple::charcode>

=head1 SEE ALSO

L<App::Greple>

=head1 LICENSE

Copyright︎ ©︎ 2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kazumasa Utashiro

=cut

use Getopt::EX::Config qw(config);
use Hash::Util qw(lock_keys);

my $config = Getopt::EX::Config->new(
    col   => 1,
    char  => 0,
    width => 0,
    code  => 1,
    name  => 1,
    align => 1,
);
lock_keys %{$config};

sub finalize {
    our($mod, $argv) = @_;
    $config->deal_with(
	$argv,
	map { ( "$_!" => \$config->{$_} ) } keys %{$config}
    );
}

use Text::ANSI::Fold::Util qw(ansi_width);
Text::ANSI::Fold->configure(expand => 1);
*vwidth = \&ansi_width;
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

package Local::Annon {
    sub new {
	my $class = shift;
	@_ == 3 or die;
	bless [ @_ ], $class;
    }
    sub start         { shift->[0] }
    sub end           { shift->[1] }
    sub annon :lvalue { shift->[2] }
}

sub prepare {
    our @annotation;
    my $grep = shift;
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	my @slice = $grep->slice_result($r);
	my $start = 0;
	my $progress = '';
	my $indent = '';
	my @annon;
	while (my($i, $slice) = each @slice) {
	    my $end = $slice eq '' ? $start : vwidth($progress . $slice);
	    my $gap = $end - $start;
	    my $indent_mark = '';
	    if ($i % 2) {
		$indent_mark = '│';
		my $head = '┌';
		if ($gap == 0) {
		    if (@annon > 0 and $annon[-1]->end == $start) {
			$head = '├';
			$start = $annon[-1]->start;
			substr($indent, $start) = '';
		    } elsif ($start > 0) {
			$start = vwidth($progress =~ s/\X\z//r);
			substr($indent, $start) = '';
		    }
		}
		my $column = $config->{col} ? sprintf("%3d ", $start) : '';
		my $out = sprintf("%s%s─ %s%s",
				  $indent,
				  $head,
				  $column,
				  describe($slice));
		push @annon, Local::Annon->new($start, $end, $out);
	    }
	    $indent .= sprintf("%-*s", $end - $start, $indent_mark);
	    $progress .= $slice;
	    $start = $end;
	}
	@annon or next;
	if ($config->{align} and (my $max_pos = $annon[-1][0])) {
	    for (@annon) {
		if ((my $extend = $max_pos - $_->[0]) > 0) {
		    $_->annon =~ s/(?=([─]))/$1 x $extend/e;
		}
	    }
	}
	push @annotation, map $_->annon, @annon;
    }
}

sub annotate {
    our @annotation;
    say shift(@annotation) if @annotation > 0;
    undef;
}

1;

__DATA__

option default --separate --annotate --uniqcolor

option --annotate \
    --postgrep '&__PACKAGE__::prepare' \
    --callback '&__PACKAGE__::annotate'

option --charcode::config \
    --prologue &__PACKAGE__::config($<shift>)

option --config --charcode::config
