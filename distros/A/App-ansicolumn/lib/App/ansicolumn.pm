package App::ansicolumn;

our $VERSION = "1.19";

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
use List::Util qw(max sum);
use Hash::Util qw(lock_keys lock_keys_plus unlock_keys);
use Text::ANSI::Fold qw(ansi_fold);
use Text::ANSI::Fold::Util qw(ansi_width);
use Text::ANSI::Printf qw(ansi_printf ansi_sprintf);
use App::ansicolumn::Util;
use App::ansicolumn::Border;

use Getopt::EX::Hashed; {

    Getopt::EX::Hashed->configure( DEFAULT => [ is => 'ro' ] );

    has debug               => '         ' ;
    has help                => '    h    ' ;
    has version             => '    v    ' ;
    has width               => ' =s c    ' ;
    has fillrows            => '    x    ' ;
    has table               => '    t    ' ;
    has table_columns_limit => ' =i l    ' , default => 0 ;
    has table_right         => ' =s R    ' , default => '' ;
    has separator           => ' =s s    ' , default => ' ' ;
    has output_separator    => ' =s o    ' , default => '  ' ;
    has document            => '    D    ' ;
    has up                  => ' :i U    ' ;
    has page                => ' :i P    ' , min => 0;
    has pane                => ' =s C    ' , default => 0 ;
    has pane_width          => ' =s S pw ' , min => 1;
    has widen               => ' !  W    ' ;
    has paragraph           => ' !  p    ' ;
    has height              => ' =s      ' , default => 0 ;
    has column_unit         => ' =i   cu ' , min => 1, default => 8 ;
    has tabstop             => ' =i      ' , min => 1, default => 8 ;
    has tabhead             => ' =s      ' ;
    has tabspace            => ' =s      ' ;
    has tabstyle            => ' =s      ' ;
    has ignore_space        => ' !    is ' , default => 1 ;
    has linestyle           => ' =s   ls ' , default => '' ;
    has boundary            => ' =s      ' , default => '' ;
    has linebreak           => ' =s   lb ' , default => '' ;
    has runin               => ' =i      ' , min => 0, default => 2 ;
    has runout              => ' =i      ' , min => 0, default => 2 ;
    has pagebreak           => ' !       ' , default => 1 ;
    has border              => ' :s      ' ; has B => '' , action => sub { $_->{border} = '' } ;
    has border_style        => ' =s   bs ' , default => 'vbar' ;
    has white_space         => ' !       ' , default => 2 ;
    has isolation           => ' !       ' , default => 2 ;
    has fillup              => ' :s      ' ; has F => '' , action => sub { $_->{fillup} = '' } ;
    has fillup_str          => ' :s      ' , default => '' ;
    has ambiguous           => ' =s      ' , default => 'narrow' ;
    has discard_el          => ' !       ' , default => 1 ;
    has padchar             => ' =s      ' , default => ' ' ;
    has colormap            => ' =s@  cm ' , default => [] ;

    has '+boundary'  => any => [ qw(none word space) ] ;
    has '+linestyle' => any => [ qw(none wordwrap wrap truncate) ] ;
    has '+fillup'    => any => [ qw(pane page none), '' ] ;
    has '+ambiguous' => any => [ qw(wide narrow) ] ;

    # --2up .. --9up
    my $nup = sub { $_[0] =~ /^(\d+)/ and $_->{up} = $1 } ;
    for my $n (2..9) {
	has "${n}up" => '', action => $nup;
    }

    # for run-time use
    has span                => ;
    has panes               => ;
    has border_height       => ;

    Getopt::EX::Hashed->configure( DEFAULT => [] );

    has '+help' => sub {
	pod2usage
	    -verbose  => 99,
	    -sections => [ qw(SYNOPSIS VERSION) ];
    };

    has '+version' => sub {
	say "Version: $VERSION";
	exit;
    };

    ### RPN calc for --height, --width, --pane, --pane-width
    has [ qw(+height +width +pane +pane_width) ] => sub {
	my $obj = $_;
	my($name, $val) = @_;
	$obj->{$name} = $val !~ /\D/ ? $val : do {
	    my $init = $name =~ /height/ ? $obj->term_height : $obj->term_width;
	    rpn_calc($init, $val) // die "$val: invalid $name.\n";
	};
    };

    ### --ambiguous=wide
    has '+ambiguous' => sub {
	if ($_[1] eq 'wide') {
	    $Text::VisualWidth::PP::EastAsian = 1;
	    Text::ANSI::Fold->configure(ambiguous => 'wide');
	}
    };

    ### --tabstop, --tabstyle
    has [ qw(+tabstop +tabstyle) ] => sub {
	my($name, $val) = map "$_", @_;
	Text::ANSI::Fold->configure($name => $val);
    };

    ### --tabhead, --tabspace
    use charnames ':loose';
    has [ qw(+tabhead +tabspace) ] => sub {
	my($name, $c) = map "$_", @_;
	$c = charnames::string_vianame($c) || die "$c: invalid name\n"
	    if length($c) > 1;
	Text::ANSI::Fold->configure($name => $c);
    };

    has TERM_SIZE           => ;
    has COLORHASH           => default => {};
    has COLORLIST           => default => [];
    has COLOR               => ;
    has BORDER              => ;

} no Getopt::EX::Hashed;

sub run {
    my $obj = shift;
    local @ARGV = decode_argv(@_);
    $obj->getopt || pod2usage(2);

    $obj->setup_options;

    warn Dumper $obj if $obj->debug;

    chomp(my @lines = <>);
    @lines = insert_space @lines if $obj->paragraph;

    if ($obj->table) {
	$obj->table_out(@lines);
    } else {
	$obj->column_out(@lines);
    }

    return 0
}

sub setup_options {
    my $obj = shift;

    ## --border takes optional border-style value
    if (defined(my $border = $obj->border)) {
	if ($border ne '') {
	    $obj->{border_style} = $border;
	}
	$obj->{border} = 1;
    }

    ## --linestyle
    if ($obj->linestyle eq 'wordwrap') {
	$obj->{linestyle} = 'wrap';
	$obj->{boundary} = 'word';
    }

    ## -P
    if (defined $obj->page) {
	$obj->{widen} = 1 if $obj->pane and not $obj->pane_width;
	$obj->{height} ||= $obj->page || $obj->term_height - 1;
	$obj->{linestyle} ||= 'wrap';
	$obj->{border} //= 1;
	$obj->{fillup} //= 'pane';
    }

    ## -U
    if ($obj->up) {
	$obj->{pane} = $obj->up;
	$obj->{widen} = 1;
	$obj->{linestyle} ||= 'wrap';
	$obj->{border} //= 1;
	$obj->{fillup} //= 'pane';
    }

    ## -D
    if ($obj->document) {
	$obj->{widen} = 1;
	$obj->{linebreak} ||= 'all';
	$obj->{linestyle} ||= 'wrap';
	$obj->{boundary} ||= 'word';
	$obj->{white_space} = 0 if $obj->white_space > 1;
	$obj->{isolation} = 0 if $obj->isolation > 1;
    }

    ## --colormap
    use Getopt::EX::Colormap;
    my $cm = Getopt::EX::Colormap
	->new(HASH => $obj->{COLORHASH}, LIST => $obj->{COLORLIST})
	->load_params(@{$obj->colormap});
    $obj->{COLOR} = sub { $cm->color(@_) };

    ## --border
    if ($obj->border) {
	my $style = $obj->{border_style};
	($obj->{BORDER} = App::ansicolumn::Border->new)
	    ->style($style) // die "$style: Unknown style.\n";
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
    my $width = $obj->get_width - $obj->border_width(qw(left right));
    my $max_length = max @length;
    my $unit = $obj->column_unit || 1;

    ($obj->{span}, $obj->{panes}) = do {
	my $span;
	my $panes;
	if ($obj->widen and not $obj->pane_width) {
	    my $min = $max_length + ($obj->border_width('center') || 1);
	    $panes = $obj->pane || $width / $min || 1;
	    $span = ($width + $obj->border_width('center')) / $panes;
	} else {
	    $span = $obj->pane_width ||
		roundup($max_length + ($obj->border_width('center') || 1),
			$unit);
	    $panes = $obj->pane || $width / $span || 1;
	}
	$span -= $obj->border_width('center');
	$span < 1 and die "Not enough space.\n";
	($span, $panes);
    };

    ## Fold long lines.
    (my $cell_width = $obj->span - $obj->margin_width) < 1
	and die "Not enough space.\n";
    if ($obj->linestyle and $obj->linestyle ne 'none') {
	my $sub = $obj->foldsub($cell_width) or die;
	@data = map { $sub->($_) } @data;
    }

    $obj->{border_height} = do {
	sum map { length > 0 }
	    map { $obj->get_border($_) }
	    qw(top bottom);
    };
    $obj->{height} ||=
	div(0+@data, $obj->panes) + $obj->border_height;

    die "Not enough height.\n" if $obj->effective_height <= 0;

    ## --white-space, --isolation, --fillup, top/bottom border
    $obj->layout(\@data);

    ## --border
    $obj->insert_border(\@data);

    my @data_index = 0 .. $#data;
    my $is_last_data = sub { $_[0] == $#data };
    for (my $page = 0; @data_index; $page++) {
	my @page = splice @data_index, 0, $obj->height * $obj->panes;
	my @index = 0 .. $#page;
	my @lines = grep { @$_ } do {
	    if ($obj->fillrows) {
		map { [ splice @index, 0, $obj->panes ] } 1 .. $obj->height;
	    } else {
		zip map { [ splice @index, 0, $obj->height ] } 1 .. $obj->panes;
	    }
	};
	for my $i (0 .. $#lines) {
	    my $line = $lines[$i];
	    my $pos = $i == 0 ? 0 : $i == $#lines ? 2 : 1;
	    my @panes = map {
		my $data_index = $page[${$line}[$_]];
		ansi_sprintf "%-$obj->{span}s", $data[$data_index];
	    } 0 .. $#{$line};
	    print      $obj->get_border('left',   $pos, $page);
	    print join $obj->get_border('center', $pos, $page), @panes;
	    print      $obj->get_border('right',  $pos, $page);
	    print      "\n";
	}
    }
}

sub table_out {
    my $obj = shift;
    return unless @_;
    my $split = do {
	if ($obj->separator eq ' ') {
	    $obj->ignore_space ? ' ' : qr/ /;
	} else {
	    qr/[\Q$obj->{separator}\E]/;
	}
    };
    my @lines  = map { [ split $split, $_, $obj->table_columns_limit ] } @_;
    my @length = map { [ map { ansi_width $_ } @$_ ] } @lines;
    my @max    = map { max @$_ } zip @length;
    my @align  = newlist(count => 0+@max, default => '-',
			 [ map --$_, split /,/, $obj->table_right ] => '');
    my @format = map { '%' . $align[$_] . $max[$_] . 's' } 0 .. $#max;
    for my $line (@lines) {
	next unless @$line;
	my @fmt = @format[0 .. $#{$line}];
	$fmt[$#{$line}] = '%s' if $align[$#{$line}] eq '-';
	my $format = join $obj->output_separator, @fmt;
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

