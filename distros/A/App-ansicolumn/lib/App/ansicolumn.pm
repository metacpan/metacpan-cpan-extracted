package App::ansicolumn;

our $VERSION = "1.2801";

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
use List::Util qw(max sum);
use Hash::Util qw(lock_keys lock_keys_plus unlock_keys);
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
    has table_right         => ' =s R    ' , default => '' ;
    has separator           => ' =s s    ' , default => ' ' ;
    has output_separator    => ' =s o    ' , default => '  ' ;
    has document            => '    D    ' ;
    has parallel            => ' !  V    ' ;
    has pages               => ' !       ' ;
    has up                  => ' :i U    ' ;
    has page                => ' :i P    ' , min => 0;
    has pane                => ' =s C    ' , default => 0 ;
    has pane_width          => ' =s S pw ' ;
    has widen               => ' !  W    ' ;
    has paragraph           => ' !  p    ' ;
    has height              => ' =s      ' , default => 0 ;
    has column_unit         => ' =i   cu ' , min => 1, default => 8 ;
    has margin              => ' =i      ' , min => 0, default => 1 ;
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
    has run                 => ' =i      ' ;
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

    ### RPN calc for --height, --width, --pane, --pane-width
    has [ qw(+height +width +pane +pane_width) ] => sub {
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

    ### --run
    has '+run' => sub {
	$_->runin = $_->runout = $_[1];
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
    has COLORHASH           => default => { %DEFAULT_COLORMAP };
    has COLORLIST           => default => [];
    has COLOR               => ;
    has BORDER              => ;

} no Getopt::EX::Hashed;

sub perform {
    my $obj = shift;
    local @ARGV = decode_argv(@_);
    $obj->getopt || pod2usage(2);

    $obj->setup_options;

    warn Dumper $obj if $obj->debug;

    my @files = $obj->read_files(@ARGV ? @ARGV : '-');

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
    $obj->set_contents($_->{data}) for @files;

    while (@files) {
	my @rows = splice @files, 0, $obj->pane;
	my $max_length = max map { int @{$_->{data}} } @rows;
	$obj->column_out(map {
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
	$obj->set_contents($data)
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
	my $content = do { local $/; <$fh> };
	my @data = $obj->pages ? split(/\f/, $content) : $content;
	for my $data (@data) {
	    my @line = split /\n/, $data;
	    @line = insert_space @line if $obj->paragraph;
	    my @length;
	    my $length = do {
		if ($obj->table) {
		    max map length, @line;
		} else {
		    $obj->expand_tab(\@line, \@length);
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
	($_, my($dmy, $length)) = ansi_fold($_, -1, expand => 1);
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
    if ($obj->widen and not $obj->pane_width) {
	my $min = $max_data_length + ($obj->border_width('center') || 1);
	$panes = $obj->pane || $width / $min || 1;
	$span = ($width + $obj->border_width('center')) / $panes;
    } else {
	$span = $obj->pane_width ||
	    roundup($max_data_length + ($obj->border_width('center') || $obj->margin),
		    $unit);
	$panes = $obj->pane || $width / $span || 1;
    }
    $span -= $obj->border_width('center');
    $span < 1 and die "Not enough space.\n";

    ($obj->span, $obj->panes) = ($span, $panes);

    return $obj;
}

sub set_contents {
    my $obj = shift;
    my $dp = shift;
    (my $cell_width = $obj->span - $obj->margin_width) < 1
	and die "Not enough space.\n";
    # Fold long lines
    if ($obj->linestyle and $obj->linestyle ne 'none') {
	my $fold = $obj->foldsub($cell_width) or die;
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
    my($bdr_top, $bdr_btm) = do {
	map { $obj->color('BORDER', $_) }
	map { $obj->get_border($_) x $obj->span }
	qw(top bottom);
    };
    map { unshift @$_, $bdr_top } @_ if $bdr_top;
    map { push    @$_, $bdr_btm } @_ if $bdr_btm;
    my $max = max(map { int @$_ } @_) - 1;
    for my $i (0 .. $max) {
	my $pos = $i == 0 ? 0 : $i == $max ? 2 : 1;
	my @panes = map {
	    @$_ ? ansi_sprintf("%-$obj->{span}s", shift @$_) : ();
	} @_;
	print      $obj->color_border('left',   $pos, $obj->current_page);
	print join $obj->color_border('center', $pos, $obj->current_page),
	    map { $obj->color('TEXT', $_) } @panes;
	print      $obj->color_border('right',  $pos, $obj->current_page);
	print      "\n";
    }
    return $obj;
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
    my @max    = map { max @$_ } xpose @length;
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

