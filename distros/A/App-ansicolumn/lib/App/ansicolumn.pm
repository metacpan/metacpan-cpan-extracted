package App::ansicolumn;

our $VERSION = "1.4101";

use v5.14;
use warnings;
use utf8;
use Encode;
use open IO => 'utf8', ':std';
use Pod::Usage;
use Getopt::EX::Long qw(:DEFAULT Configure ExConfigure);
ExConfigure BASECLASS => [ __PACKAGE__, "Getopt::EX" ];
Configure qw(bundling);

use Data::Dumper;
use List::Util qw(max sum min);
use Text::ANSI::Fold qw(ansi_fold);
use Text::ANSI::Fold::Util qw(ansi_width);
use Text::ANSI::Printf qw(ansi_printf ansi_sprintf);
use App::ansicolumn::Util;
use App::ansicolumn::Border;
use Getopt::EX::RPN qw(rpn_calc);

my %DEFAULT_COLORMAP = (
    BORDER => '',
    TEXT   => '',
);

use Getopt::EX::Hashed 1.05; {

    Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );

    has debug               => '         ' ;
    has help                => '    h    ' ;
    has version             => '    v    ' ;
    has width               => ' =s w c  ' ;
    has fillrows            => '    x    ' ;
    has table               => '    t    ' ;
    has table_columns_limit => ' =i l    ' , default => 0 ;
    has table_align         => ' !  A    ' ;
    has table_tabs          => ' !  T    ' ;
    has table_right         => ' =s R    ' , default => '' ;
    has separator           => ' =s s    ' , default => ' ' ;
    has regex_sep           => '    r    ' ;
    has output_separator    => ' =s o    ' , default => '  ' ;
    has document            => '    D    ' ;
    has parallel            => ' !  V    ' ;
    has filename            => ' !  H    ' ;
    has filename_format     => ' =s      ' , default => ': %s';
    has pages               => ' !       ' ;
    has up                  => ' :s U    ' ;
    has page                => ' :i P    ' , min => 0;
    has pane                => ' =s C    ' , default => 0 ;
    has cell                => ' =s X    ' ;
    has pane_width          => ' =s S pw ' ;
    has widen               => ' !  W    ' ;
    has paragraph           => ' !  p    ' ;
    has height              => ' =s      ' , default => 0 ;
    has column_unit         => ' =i   cu ' , min => 1, default => 8 ;
    has margin              => ' =i      ' , min => 0, default => 1 ;
    has tabstop             => ' =i      ' , min => 1, default => 8 ;
    has tabhead             => ' =s      ' ;
    has tabspace            => ' =s      ' ;
    has tabstyle            => ' :s   ts ' ;
    has ignore_space        => ' !    is ' , default => 1 ;
    has linestyle           => ' =s   ls ' , default => '' ;
    has boundary            => ' =s      ' , default => '' ;
    has linebreak           => ' =s   lb ' , default => '' ;
    has runin               => ' =i      ' , min => 0, default => 2 ;
    has runout              => ' =i      ' , min => 0, default => 2 ;
    has runlen              => ' =i      ' ;
    has pagebreak           => ' !       ' , default => 1 ;
    has border              => ' :s      ' ; has B => '' , action => sub { $_->border = '' } ;
    has border_style        => ' =s   bs ' , default => 'box' ;
    has white_space         => ' !       ' , default => 2 ;
    has isolation           => ' !       ' , default => 2 ;
    has fillup              => ' :s      ' ; has F => '' , action => sub { $_->fillup = '' } ;
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
    my $nup = sub { $_[0] =~ /^(\d+)/ and $_->up = $1 } ;
    for my $n (2..9) {
	has "${n}up" => '', action => $nup;
    }

    # for run-time use
    has span          => ;
    has panes         => ;
    has border_height => ;
    has current_page  => ;

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

    ### RPN calc for --height, --width, --pane, --up, --pane-width
    has [ qw(+height +width +pane +up +pane_width) ] => sub {
	my $obj = $_;
	my($name, $val) = @_;
	$obj->$name = $val !~ /\D/ ? $val : do {
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

    ### --runlen
    has '+runlen' => sub {
	$_->runin = $_->runout = $_[1];
    };
    # for backward compatibility, would be deplicated
    has run => '=i';
    has '+run' => sub {
	$_->runin = $_->runout = $_[1];
    };

    ### --tabstop, --tabstyle
    has [ qw(+tabstop +tabstyle) ] => sub {
	my($name, $val) = map "$_", @_;
	if ($val eq '') {
	    list_tabstyle();
	    exit;
	}
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

    ### -A, -T
    has '+table_align' => sub {
	if ($_->table_align = $_[1]) {
	    $_->table = $_[1];
	}
    };
    has '+table_tabs' => sub {
	if ($_->table_tabs = $_[1]) {
	    $_->table = $_->table_align = $_[1];
	}
    };

    has TERM_SIZE           => ;
    has COLORHASH           => default => { %DEFAULT_COLORMAP };
    has COLORLIST           => default => [];
    has COLOR               => ;
    has BORDER              => ;

} no Getopt::EX::Hashed;

sub list_tabstyle {
    my %style = %Text::ANSI::Fold::TABSTYLE;
    my $max = max map length, keys %style;
    for my $name (sort keys %style) {
	my($head, $space) = @{$style{$name}};
	printf "%*s %s%s\n", $max, $name, $head, $space x 7;
    }
}

sub perform {
    my $obj = shift;
    local @ARGV = decode_argv(@_);
    $obj->getopt || pod2usage(2);

    $obj->setup_options;

    warn Dumper $obj if $obj->debug;

    my @files = $obj->read_files(@ARGV ? @ARGV : '-') or return 1;

    if ($obj->table) {
	my @lines = map { @{$_->{data}} } @files;
	$obj->table_out(@lines);
    }
    elsif ($obj->parallel) {
	$obj->parallel_out(@files);
    }
    else {
	$obj->nup_out(@files);
    }

    return 0
}

sub setup_options {
    my $obj = shift;

    ## --parallel or @ARGV > 1
    if ($obj->parallel //= @ARGV > 1) {
	$obj->linestyle ||= 'wrap';
	$obj->widen //= 1;
	$obj->border //= '';
    }

    ## --border takes optional border-style value
    if (defined(my $border = $obj->border)) {
	if ($border ne '') {
	    $obj->border_style = $border;
	}
	$obj->border = 1;
	$obj->fillup //= 'pane';
    }

    ## --linestyle
    if ($obj->linestyle eq 'wordwrap') {
	$obj->linestyle = 'wrap';
	$obj->boundary = 'word';
    }

    ## -P
    if (defined $obj->page) {
	$obj->widen = 1 if $obj->pane and not $obj->pane_width;
	$obj->height ||= $obj->page || $obj->term_height - 1;
	$obj->linestyle ||= 'wrap';
	$obj->border //= 1;
	$obj->fillup //= 'pane';
    }

    ## -U
    if ($obj->up) {
	$obj->pane = $obj->up;
	$obj->widen = 1;
	$obj->linestyle ||= 'wrap';
	$obj->border //= 1;
	$obj->fillup //= 'pane';
    }

    ## -D
    if ($obj->document) {
	$obj->widen = 1;
	$obj->linebreak ||= 'all';
	$obj->linestyle ||= 'wrap';
	$obj->boundary ||= 'word';
	$obj->white_space = 0 if $obj->white_space > 1;
	$obj->isolation = 0 if $obj->isolation > 1;
    }

    ## --colormap
    use Getopt::EX::Colormap;
    my $cm = Getopt::EX::Colormap
	->new(HASH => $obj->{COLORHASH}, LIST => $obj->{COLORLIST})
	->load_params(@{$obj->colormap});
    $obj->{COLOR} = sub { $cm->color(@_) };

    ## --border
    if ($obj->border) {
	my $style = $obj->border_style;
	($obj->{BORDER} = App::ansicolumn::Border->new)
	    ->style($style) // die "$style: Unknown style.\n";
    }

    $obj;
}

sub color {
    my $obj = shift;
    $obj->{COLOR}->(@_);
}

sub parallel_out {
    my $obj = shift;
    my @files = @_;

    my $max_line_length = max map { $_->{length} } @files;
    $obj->pane ||= @files;
    $obj->set_horizontal($max_line_length);

    # calculate span and set for each file
    if (my $cell = $obj->cell) {
	my @spans = split /,+/, $cell;
	for my $i (keys @files) {
	    my $span = $spans[$i] // $spans[-1];
	    if ($span =~ /^[-+]/) {
		$span += $obj->{span};
		$span < 0 and die "Invalid number: $cell\n";
	    }
	    elsif ($span =~ s/^(<=|[<=])//) {
		my $length = $files[$i]->{length};
		$span = $span ? min($length, $span) : $length;
	    }
	    elsif ($span !~ /^\d+$/) {
		die "Invalid number: $cell\n";
	    }
	    $files[$i]->{span} = $span;
	}
    }
    $obj->set_contents($_) for @files;
    while (@files) {
	my @rows = splice @files, 0, $obj->pane;
	my $max_length = max map { int @{$_->{data}} } @rows;
	my @span = map { $_->{span} // $obj->span } @rows;
	if ($obj->filename) {
	    my $w = $obj->span + $obj->border_width('center');
	    my $format = join '', (
		(map {
		    my $w = $_ + $obj->border_width('center');
		    "%-${w}.${w}s";
		} @span[0..$#span-1]),
		"%s\n");
	    ansi_printf $format, map {
		ansi_sprintf $obj->filename_format, $_->{name};
	    } @rows;
	}
	$obj->column_out(
	    { span => \@span },
	    map {
		my $data = $_->{data};
		my $length = @$data;
		push @$data, (($obj->fillup_str) x ($max_length - $length));
		$data;
	    } @rows);
    }
    return $obj;
}

sub nup_out {
    my $obj = shift;
    my @files = @_;
    my $max_length = max map { $_->{length} } @files;
    $obj->set_horizontal($max_length);
    my $reset = do { my @o = %$obj; sub { %$obj = @o } };
    for my $file (@files) {
	my $data = $file->{data};
	next if @$data == 0;
	$obj->set_contents($file)
	    ->set_vertical($data)
	    ->set_layout($data)
	    ->page_out(@$data);
	$reset->();
    }
    return $obj;
}

sub read_files {
    my $obj = shift;
    my @files;
    for my $file (@_) {
	open my $fh, $file or die "$file: $!";
	my $content = do { local $/; <$fh> } // do {
	    warn "$file: $!\n" if $!;
	    next;
	};
	my @data = $obj->pages ? split(/\f/, $content) : $content;
	for my $data (@data) {
	    my @line = split /\n/, $data;
	    @line = insert_space @line if $obj->paragraph;
	    my $length = do {
		if ($obj->table) {
		    max map length, @line;
		} else {
		    $obj->expand_tab(\@line, \my @length);
		    max @length;
		}
	    };
	    push @files, {
		name   => $file,
		length => $length // 0,
		data   => \@line,
	    };
	}
    }
    @files;
}

sub expand_tab {
    my $obj = shift;
    my($dp, $lp) = @_;
    for (@$dp) {
	($_, my($dmy, $length)) = ansi_fold $_, -1, expand => 1;
	push @$lp, $length;
    }
}

sub set_horizontal {
    my $obj = shift;
    my $max_data_length = shift;

    use integer;
    my $width = $obj->get_width - $obj->border_width(qw(left right));
    my $unit = $obj->column_unit // 1;

    my $span;
    my $panes;
    my $claim = sum($max_data_length,
		    $obj->runin_margin,
		    $obj->border_width('center') || $obj->margin);
    if ($obj->widen and not $obj->pane_width) {
	$panes = $obj->pane || $width / $claim || 1;
	$span = ($width + $obj->border_width('center')) / $panes;
    } else {
	$span = $obj->pane_width || roundup($claim, $unit);
	$panes = $obj->pane || $width / $span || 1;
    }
    $span -= $obj->border_width('center');
    $span < 1 and die "Not enough space.\n";

    ($obj->span, $obj->panes) = ($span, $panes);

    return $obj;
}

sub set_contents {
    my $obj = shift;
    my $fp = shift;
    my $dp = $fp->{data};
    (my $cell_width = $obj->span - $obj->runin_margin) < 1
	and die "Not enough space.\n";
    # Fold long lines
    if ($obj->linestyle and $obj->linestyle ne 'none') {
	my $w = $fp->{span} // $cell_width;
	my $fold = $obj->foldsub($w) or die;
	@$dp = map { $fold->($_) } @$dp;
    }
    return $obj;
}

sub set_vertical {
    my $obj = shift;
    my $dp = shift;
    $obj->border_height = do {
	sum map { length > 0 }
	    map { $obj->get_border($_) }
	    qw(top bottom);
    };
    $obj->height ||= div(int @$dp, $obj->panes) + $obj->border_height;
    die "Not enough height.\n" if $obj->effective_height <= 0;
    return $obj;
}

sub page_out {
    my $obj = shift;
    for ($obj->current_page = 0; @_; $obj->current_page++) {
	my @columns = grep { @$_ } do {
	    if ($obj->fillrows) {
		xpose map { [ splice @_, 0, $obj->panes ] } 1 .. $obj->effective_height;
	    } else {
		map { [ splice @_, 0, $obj->effective_height ] } 1 .. $obj->panes;
	    }
	};
	$obj->column_out(@columns);
    }
    return $obj;
}

sub color_border {
    my $obj = shift;
    $obj->color('BORDER', $obj->get_border(@_));
}

sub column_out {
    my $obj = shift;
    my $opt = ref $_[0] eq 'HASH' ? shift : {};

    # span list is given in parallel view mode
    my @span = $opt->{span} ? @{$opt->{span}} : (($obj->{span}) x @_);
    @span == @_ or die;

    # insert top/bottom border
    my %bd = map { $_ => $obj->get_border($_) } qw(top bottom);
    if ($bd{top} or $bd{bottom}) {
	while (my($i, $e) = each @_) {
	    unshift @$e, $obj->color('BORDER', $bd{top} x $span[$i]) if $bd{top};
	    push @$e, $obj->color('BORDER', $bd{bottom} x $span[$i]) if $bd{bottom};
	}
    }

    my $max = max map $#{$_}, @_;
    for my $i (0 .. $max) {
	my $pos = $i == 0 ? 0 : $i == $max ? 2 : 1;
	my @span = @span;
	my @panes = map {
	    @$_ ? ansi_sprintf("%-*s", shift @span, shift @$_) : ();
	} @_;
	print      $obj->color_border('left',   $pos, $obj->current_page);
	print join $obj->color_border('center', $pos, $obj->current_page),
	    map { $obj->color('TEXT', $_) } @panes;
	print      $obj->color_border('right',  $pos, $obj->current_page);
	print      "\n";
    }
    return $obj;
}

sub _numbers {
    require Getopt::EX::Numbers;
    Getopt::EX::Numbers->new(min => 1, @_);
}

sub table_out {
    my $obj = shift;
    return unless @_;
    my $split = do {
	if ($obj->separator eq ' ') {
	    $obj->ignore_space ? ' ' : qr/\s+/;
	} elsif ($obj->regex_sep) {
	    qr($obj->{separator});
	} else {
	    qr/[\Q$obj->{separator}\E]/;
	}
    };
    my @lines  = map { [ split $split, $_, $obj->table_columns_limit ] } @_;
    my @length = map { [ map { ansi_width $_ } @$_ ] } @lines;
    my @max = map { max @$_ } xpose @length;
    if ($obj->table_align) {
	my @tabs = map { roundup $_, $obj->column_unit, $obj->margin } @max;
	#
	# --table-tabs
	#
	if ($obj->table_tabs) {
	    my $cu = $obj->column_unit;
	    while (my($lx, $l) = each @lines) {
		while (my($fx, $f) = each @$l) {
		    print $f;
		    if ($fx == $#{$l}) {
			print "\n";
		    } else {
			use integer;
			print "\t" x div($tabs[$fx] - $length[$lx][$fx], $cu);
		    }
		}
	    }
	    return $obj;
	}
	@max = map { $_ - $obj->margin } @tabs;
	$obj->output_separator = ' ' x $obj->margin;
    }
    my @align  = newlist(count => int @max, default => '-',
			 [ map --$_, map {
			     _numbers(max => int @max)->parse($_)->sequence
			 } split /,/, $obj->table_right ] => '');
    my @format = map "%$align[$_]$max[$_]s", keys @max;
    for my $line (@lines) {
	next unless @$line;
	my @fmt = @format[keys @$line];
	$fmt[$#fmt] = '%s' if $align[$#fmt] eq '-';
	my $format = join($obj->output_separator, @fmt) . "\n";
	ansi_printf $format, @$line;
    }
    return $obj;
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

