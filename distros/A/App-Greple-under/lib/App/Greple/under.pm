package App::Greple::under;
use 5.024;
use warnings;

our $VERSION = "1.00";

=encoding utf-8

=head1 NAME

App::Greple::under - greple under-line module

=head1 SYNOPSIS

    greple -Munder::line ...

    greple -Munder::mise ... | greple -Munder::place

=head1 DESCRIPTION

This module is intended to clarify highlighting points without ANSI
sequencing when highlighting by ANSI sequencing is not possible for
some reason.

The following command searches for a paragraph that contains all the
words specified.

    greple 'license agreements software freedom' LICENSE -p

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-under/main/images/normal.png">
</p>

By default, the emphasis should be indicated by underlining it on the
next line.

    greple -Munder::line 'license agreements software freedom' LICENSE -p

Above command will produce output like this:

 ┌───────────────────────────────────────────────────────────────────────┐
 │   The license agreements of most software companies try to keep users │
 │       ▔▔▔▔▔▔▔ ▔▔▔▔▔▔▔▔▔▔         ▔▔▔▔▔▔▔▔                             │
 │ at the mercy of those companies.  By contrast, our General Public     │
 │ License is intended to guarantee your freedom to share and change free│
 │                                       ▔▔▔▔▔▔▔                         │
 │ software--to make sure the software is free for all its users.  The   │
 │ ▔▔▔▔▔▔▔▔                   ▔▔▔▔▔▔▔▔                                   │
 │ General Public License applies to the Free Software Foundation's      │
 │ software and to any other program whose authors commit to using it.   │
 │ ▔▔▔▔▔▔▔▔                                                              │
 │ You can use it for your programs, too.                                │
 └───────────────────────────────────────────────────────────────────────┘

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-under/main/images/under-line.png">
</p>

If you want to process the search results before underlining them,
process them in the C<-Munder::mise> module and then pass them through
the C<-Munder::place> module.

    greple -Munder::mise ... | ... | greple -Munder::place

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-under/main/images/mise-place.png">
</p>

=head1 MODULE OPTION

=head2 B<--config>

Set config parameters.

    greple -Munder::line --config type=eighth -- ...

Configuable parameters:

=over 4

=item C<type>

Set under-line type.

=item C<sequence>

Set under-line sequence.  The given string is broken down into single
character sequences.

=back

=head2 B<--show-colormap>

Print custom colormaps separated by whitespace characters.  You can
read them into an array by L<bash(1)> like this:

    read -a MAP < <(greple -Munder::place --show-colormap --)

=head1 SEE ALSO

L<App::Greple>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright ©︎ 2024-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use Exporter 'import';
our @EXPORT_OK = qw(%config &config &finalize);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use App::Greple::Common qw(@color_list);
use Term::ANSIColor::Concise qw(ansi_code);
use Text::ANSI::Fold;
use Text::ANSI::Fold::Util qw(ansi_width);
use Hash::Util qw(lock_keys);
use Data::Dumper;

use Getopt::EX::Config qw(config);

my $config = Getopt::EX::Config->new(
    type              => 'overline',
    space             => ' ',
    sequence          => '',
    'custom-colormap' => 1,
    'show-colormap'   => 0,
);

sub finalize {
    our($mod, $argv) = @_;
    $config->deal_with(
	$argv,
	map("$_=s", qw(type space sequence)),
	map("$_!" , qw(custom-colormap show-colormap)),
    );
    if (not $config->{'custom-colormap'}) {
	$mod->setopt('--use-custom-colormap' => '$<ignore>');
    }
}

sub prologue {
    if ($config->{"show-colormap"}) {
	prepare();
	print "@color_list\n";
	exit 0;
    }
}

$Term::ANSIColor::Concise::NO_RESET_EL = 1;
Text::ANSI::Fold->configure(expand => 1);

my %marks  = (
    eighth   => [ "\N{UPPER ONE EIGHTH BLOCK}" ],
    half     => [ "\N{UPPER HALF BLOCK}" ],
    overline => [ "\N{OVERLINE}" ],
    macron   => [ "\N{MACRON}" ],
    caret    => [ "^" ],
    ring     => [ "\N{NBSP}\N{COMBINING RING ABOVE}" ],
    sign     => [ qw( + - ~ ) ],
    number   => [ "0" .. "9" ],
    alphabet => [ "a" .. "z", "A" .. "Z" ],
    block => [
	"\N{UPPER ONE EIGHTH BLOCK}",
	"\N{UPPER HALF BLOCK}",
	"\N{FULL BLOCK}",
    ],
    vertical => [
	"\N{BOX DRAWINGS LIGHT VERTICAL}",
	"\N{BOX DRAWINGS LIGHT DOUBLE DASH VERTICAL}",
	"\N{BOX DRAWINGS LIGHT TRIPLE DASH VERTICAL}",
	"\N{BOX DRAWINGS LIGHT QUADRUPLE DASH VERTICAL}",
	"\N{BOX DRAWINGS HEAVY VERTICAL}",
	"\N{BOX DRAWINGS HEAVY DOUBLE DASH VERTICAL}",
	"\N{BOX DRAWINGS HEAVY TRIPLE DASH VERTICAL}",
	"\N{BOX DRAWINGS HEAVY QUADRUPLE DASH VERTICAL}",
    ],
    up => [
	"\N{BOX DRAWINGS LIGHT UP}",
	"\N{BOX DRAWINGS LIGHT UP AND HORIZONTAL}",
	"\N{BOX DRAWINGS UP LIGHT AND HORIZONTAL HEAVY}",
	"\N{BOX DRAWINGS HEAVY UP}",
	"\N{BOX DRAWINGS HEAVY UP AND HORIZONTAL}",
	"\N{BOX DRAWINGS UP HEAVY AND HORIZONTAL LIGHT}",
	"\N{BOX DRAWINGS UP SINGLE AND HORIZONTAL DOUBLE}",
	"\N{BOX DRAWINGS UP DOUBLE AND HORIZONTAL SINGLE}",
	"\N{BOX DRAWINGS DOUBLE UP AND HORIZONTAL}",
    ],
);

my $re;
my %index;
my @marks;

sub prepare {
    @color_list == 0 and die "color table is not available.\n";

    my @ansi = map { ansi_code($_) } @color_list;
    my @ansi_re = map { s/\\\e/\\e/gr } map { quotemeta($_) } @ansi;
    %index = map { $ansi[$_] => $_ } keys @ansi;
    my $reset_re = qr/(?:\e\[[0;]*[mK])+/;
    $re = do {
	local $" = '|';
	qr/(?<ansi>@ansi_re) (?<text>[^\e]*) (?<reset>$reset_re)/x;
    };
    if (my $s = $config->{sequence}) {
	@marks = grep { ! /\A\s\z/ } $s =~ /\X/g;
    }
    elsif (my $mark = $marks{$config->{type}}) {
	@marks = $mark->@*;
    }
    else {
	die "$config->{type}: invalid type.\n";
    }
}

sub line {
    prepare() if not $re;
    while (<>) {
	local @_;
	my @under;
	my $pos;
	while (/\G (?<pre>.*?) $re /xgp) {
	    push @_, $+{pre}, $+{text};
	    my $mark = $marks[$index{$+{ansi}} % @marks];
	    push @under,
		$config->{space} x ansi_width($+{pre}),
		$mark  x ansi_width($+{text});
	    $pos = pos;
	}
	if (not defined $pos) {
	    print;
	    next;
	}
	if ($pos < length($_)) {
	    push @_, substr($_, $pos);
	}
	print join '', @_;
	print join '', @under, "\n";
    }
}

1;

__DATA__

option default \
    --prologue &__PACKAGE__::prologue

option --place-line \
    $<move> \
    --pf &__PACKAGE__::line

option --use-custom-colormap \
    $<move> \
    --cm @ \
    --cm {SGR26;1},{SGR26;2},{SGR26;3} \
    --cm {SGR26;4},{SGR26;5},{SGR26;6} \
    --cm {SGR26;7},{SGR26;8},{SGR26;9}
