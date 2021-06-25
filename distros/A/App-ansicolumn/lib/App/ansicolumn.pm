package App::ansicolumn;

our $VERSION = "1.08";

use v5.14;
use warnings;
use utf8;
use Encode;
use open IO => 'utf8', ':std';
use Pod::Usage;
use Getopt::EX::Long qw(:DEFAULT Configure ExConfigure);
ExConfigure BASECLASS => [ __PACKAGE__, "Getopt::EX" ];
Configure "bundling";

use Data::Dumper;
use List::Util qw(max);
use Hash::Util qw(lock_keys lock_keys_plus unlock_keys);
use Text::ANSI::Fold qw(ansi_fold);
use Text::ANSI::Fold::Util qw(ansi_width);
use Text::ANSI::Printf qw(ansi_printf ansi_sprintf);
use App::ansicolumn::Util;
use App::ansicolumn::Border;

sub new {
    my $class = shift;
    my $obj = bless {
	width               => undef,
	fillrows            => undef,
	table               => undef,
	table_columns_limit => 0,
	table_right         => '',
	separator           => ' ',
	output_separator    => '  ',
	page                => undef,
	height              => 0,
	column_unit         => 8,
	pane                => 0,
	pane_width          => undef,
	tabstop             => 8,
	tabhead             => undef,
	tabspace            => undef,
	tabstyle            => undef,
	ignore_space        => 1,
	fullwidth           => undef,
	linestyle           => '',
	boundary            => '',
	linebreak           => '',
	pagebreak           => 1,
	runin               => 2,
	runout              => 2,
	border              => undef,
	border_style        => 'vbar',
	document            => undef,
	insert_space        => undef,
	white_space         => 2,
	isolation           => 2,
	fillup              => undef,
	fillup_str          => '',
	ambiguous           => 'narrow',
	discard_el          => 1,
	padchar             => ' ',
	term_size           => undef,
	debug               => undef,
	version             => undef,
	colormap            => [],
	COLORHASH           => {},
	COLORLIST           => [],
	COLOR               => undef,
	BORDER              => undef,
	}, $class;
    lock_keys %{$obj};
    $obj;
}

sub use_keys {
    my $obj = shift;
    unlock_keys %{$obj};
    lock_keys_plus %{$obj}, @_;
}

sub run {
    my $obj = shift;
    local @ARGV = map { utf8::is_utf8($_) ? $_ : decode('utf8', $_) } @_;
    GetOptions(
	$obj,
	map { s/^(?=\w+_)(\w+)\K/"|".$1=~tr[_][-]r."|".$1=~tr[_][]dr/er } qw(
	width|output_width|c=s
	fillrows|x
	table|t
	table_columns_limit|l=i
	table_right|R=s
	separator|s=s
	output_separator|o=s
	page|P:i
	height=s
	column_unit|cu=i
	pane|C=i
	pane_width|pw|S=s
	tabstop=i
	tabhead=s
	tabspace=s
	tabstyle=s
	ignore_space|is!
	fullwidth|F!
	linestyle|ls=s
	boundary=s
	linebreak|lb=s runin=i runout=i
	pagebreak!
	border:s
	border_style|bs=s
	document|D
	colormap|cm=s@
	insert_space|paragraph!
	white_space!
	isolation!
	fillup:s
	fillup_str:s
	ambiguous=s
	discard_el!
	padchar=s
	debug
	version|v
	)) || pod2usage();
    $obj->{version} and do { say $VERSION; exit };
    $obj->setup_options;

    warn Dumper $obj if $obj->{debug};

    chomp(my @lines = <>);
    @lines = insert_space @lines if $obj->{insert_space};

    if ($obj->{table}) {
	$obj->table_out(@lines);
    } else {
	$obj->column_out(@lines);
    }
}

sub setup_options {
    my $obj = shift;

    ## --border takes optional border-style value
    if (defined(my $border = $obj->{border})) {
	if ($border ne '') {
	    $obj->{border_style} = $border;
	}
	$obj->{border} = 1;
    }

    ## --height, --width
    for my $param ([ 'height',      $obj->term_height ],
		   [ 'width',       $obj->term_width  ],
		   [ 'pane_width',  $obj->term_width  ]) {
	my($name, @stack) = @$param;
	my $exp = $obj->{$name} or next;
	$exp =~ /\D/ or next;
	$obj->{$name} = rpn_calc(@stack, $exp)
	    or die "$exp: invalid $name.\n";
    }

    ## --linestyle
    if ($obj->{linestyle} !~ /^(?<style>|none|wordwrap|wrap|truncate)$/) {
	die "$obj->{linestyle}: unknown style.\n";
    } elsif ($+{style} eq 'wordwrap') {
	$obj->{linestyle} = 'wrap';
	$obj->{boundary} = 'word';
    }

    ## -P
    if (defined $obj->{page}) {
	$obj->{fullwidth} = 1 if $obj->{pane} and not $obj->{pane_width};
	$obj->{height} ||= $obj->{page} || $obj->term_height - 1;
	$obj->{linestyle} ||= 'wrap';
	$obj->{border} //= 1;
	$obj->{fillup} //= 'pane';
    }

    ## -D
    if ($obj->{document}) {
	$obj->{fullwidth} = 1;
	$obj->{linebreak} ||= 'all';
	$obj->{linestyle} ||= 'wrap';
	$obj->{boundary} ||= 'word';
	$obj->{white_space} = 0 if $obj->{white_space} > 1;
	$obj->{isolation} = 0 if $obj->{isolation} > 1;
    }

    ## --colormap
    use Getopt::EX::Colormap;
    my $cm = Getopt::EX::Colormap
	->new(HASH => $obj->{COLORHASH}, LIST => $obj->{COLORLIST})
	->load_params(@{$obj->{colormap}});
    $obj->{COLOR} = sub { $cm->color(@_) };

    ## --border
    if ($obj->{border}) {
	my $style = $obj->{border_style};
	($obj->{BORDER} = App::ansicolumn::Border->new)
	    ->style($style) // die "$style: Unknown style.\n";
    }

    ## --ambiguous=wide
    if ($obj->{ambiguous} eq 'wide') {
	$Text::VisualWidth::PP::EastAsian = 1;
	Text::ANSI::Fold->configure(ambiguous => 'wide');
    }

    ## --tabstop, --tabstyle
    for my $opt (qw(tabstop tabstyle)) {
	if (my $v = $obj->{$opt}) {
	    Text::ANSI::Fold->configure($opt => $v);
	}
    }

    ## --tabhead, --tabspace
    use charnames ':loose';
    for my $opt (qw(tabhead tabspace)) {
	for ($obj->{$opt}) {
	    defined && length or next;
	    $_ = charnames::string_vianame($_) || die "$_: invalid name\n"
		if length > 1;
	    Text::ANSI::Fold->configure($opt => $_);
	}
    }

    $obj;
}

sub column_out {
    my $obj = shift;
    @_ or return;

    my @data;
    my @length;
    for (@_) {
	my($expanded, $dmy, $length) = ansi_fold($_, -1, expand => 1);
	push @data, $expanded;
	push @length, $length;
    }

    use integer;
    my $width = $obj->width - $obj->border_width(qw(left right));
    my $max_length = max @length;
    my $unit = $obj->{column_unit} || 1;

    $obj->use_keys(qw(span panes));
    ($obj->{span}, $obj->{panes}) = do {
	my $span;
	my $panes;
	if ($obj->{fullwidth} and not $obj->{pane_width}) {
	    my $min = $max_length + ($obj->border_width('center') || 1);
	    $panes = $obj->{pane} || $width / $min || 1;
	    $span = ($width + $obj->border_width('center')) / $panes;
	} else {
	    $span = $obj->{pane_width} ||
		roundup($max_length + ($obj->border_width('center') || 1),
			$unit);
	    $panes = $obj->{pane} || $width / $span || 1;
	}
	$span -= $obj->border_width('center');
	$span < 1 and die "Not enough space.\n";
	($span, $panes);
    };

    ## Fold long lines.
    (my $cell_width = $obj->{span} - $obj->margin_width) < -1
	and die "Not enough space.\n";
    if ($obj->{linestyle} and $obj->{linestyle} ne 'none') {
	my $sub = $obj->foldsub($cell_width) or die;
	@data = map { $sub->($_) } @data;
    }

    $obj->use_keys(qw(border_height));
    $obj->{border_height} = grep length, map $obj->border($_), qw(top bottom);
    $obj->{height} ||= div(0+@data, $obj->{panes}) + $obj->{border_height};

    ## --white-space, --isolation, --fillup, top/bottom border
    $obj->layout(\@data);

    ## --border
    $obj->insert_border(\@data);

    my @data_index = 0 .. $#data;
    my $is_last_data = sub { $_[0] == $#data };
    for (my $page = 0; @data_index; $page++) {
	my @page = splice @data_index, 0, $obj->{height} * $obj->{panes};
	my @index = 0 .. $#page;
	my @lines = grep { @$_ } do {
	    if ($obj->{fillrows}) {
		map { [ splice @index, 0, $obj->{panes} ] } 1 .. $obj->{height};
	    } else {
		zip map { [ splice @index, 0, $obj->{height} ] } 1 .. $obj->{panes};
	    }
	};
	for my $i (0 .. $#lines) {
	    my $line = $lines[$i];
	    my $pos = $i == 0 ? 0 : $i == $#lines ? 2 : 1;
	    my @panes = map {
		my $data_index = $page[${$line}[$_]];
		ansi_sprintf "%-$obj->{span}s", $data[$data_index];
	    } 0 .. $#{$line};
	    print      $obj->border('left',   $pos, $page);
	    print join $obj->border('center', $pos, $page), @panes;
	    print      $obj->border('right',  $pos, $page);
	    print      "\n";
	}
    }
}

sub table_out {
    my $obj = shift;
    return unless @_;
    my $split = do {
	if ($obj->{separator} eq ' ') {
	    $obj->{ignore_space} ? ' ' : qr/ /;
	} else {
	    qr/[\Q$obj->{separator}\E]/;
	}
    };
    my @lines  = map { [ split $split, $_, $obj->{table_columns_limit} ] } @_;
    my @length = map { [ map { ansi_width $_ } @$_ ] } @lines;
    my @max    = map { max @$_ } zip @length;
    my @align  = newlist(count => 0+@max, default => '-',
			 [ map --$_, split /,/, $obj->{table_right} ] => '');
    my @format = map { '%' . $align[$_] . $max[$_] . 's' } 0 .. $#max;
    for my $line (@lines) {
	next unless @$line;
	my @fmt = @format[0 .. $#{$line}];
	$fmt[$#{$line}] = '%s' if $align[$#{$line}] eq '-';
	my $format = join $obj->{output_separator}, @fmt;
	ansi_printf $format, @$line;
    } continue {
	print "\n";
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

ansicolumn - ANSI sequence aware column command

=head1 DESCRIPTION

Document is included in executable script.
Use `perldoc ansicolumn`.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2020- Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

