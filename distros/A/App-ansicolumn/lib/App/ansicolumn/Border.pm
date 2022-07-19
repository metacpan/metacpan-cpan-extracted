package App::ansicolumn::Border;

=encoding utf-8

=head1 NAME

App::ansicolumn::Border - App::ansicolumn Border module

=head1 DESCRIPTION

Each item has five elements; C<right>, C<center>, C<left>, C<top>,
C<bottom>.

C<top> and C<bottom> items have single string.

C<right>, C<left> and C<center> items can hold string value or list
reference, and string value is equivalent to a list of single item.
If the list has single item, it is used on all positions.  If the
second item exists, it is used on middle position.  Third item is for
bottom position.

Class method C<add_style> can be used to add new border style.

This is experimental implementation and subject to change.

=cut

use v5.14;
use warnings;
use utf8;
use Data::Dumper;

my %template = (
    DEFAULT => 'space',
    space => {
	top    => '',
	left   => '',
	center => '  ',
	right  => '',
	bottom => '',
    },
    none => {
	top    => '',
	left   => '',
	center => '',
	right  => '',
	bottom => '',
    },
    side  => { right => ' ' , left => ' ' },
    left  => { right => ''  , left => '  ' },
    line => {
	center => "│ ", # "\x{2502} "
    },
    fat_line => {
	center => [ "█ ", "░ " ], # "\x{2588} "
    },
    vbar => {
	center => [ "╷ "  , # "\x{2577} "
		    "│ "  , # "\x{2502} "
		    "╵ " ], # "\x{2575} "
    },
    thick_vbar => {
	center => [ "▗ "  , # "\x{2597} "
		    "▐ "  , # "\x{2590} "
		    "▝ " ], # "\x{259D} "
    },
    fat_vbar => {
	center => [ "▄ "  , # "\x{2584} "
		    "█ "  , # "\x{2588} "
		    "▀ " ], # "\x{2580} "
    },
    stick => {
	center => [ "╻ "  , # "\x{2577} "
		    "│ "  , # "\x{2502} "
		    "╹ " ], # "\x{2575} "
    },
    ascii_frame => {
	top    => "-",
	left   => [   "+" ,   "|" ],
	center => [ "+ +" , "| |" ],
	right  => [ "+"   , "|"   ],
	bottom => "-",
    },
    ascii_box => {
	top    =>   "-",
	left   => [ "+" , "|" ],
	center => [ "+" , "|" ],
	right  => [ "+" , "|" ],
	bottom =>   "-",
    },
    c_box => {
	top          =>   '*',
	left         => [ '/**',
			  '/* ' ],
	center       => [ '**/ /**',
			  ' */ /* ' ],
	right        => [ '**/',
			  ' */' ],
	bottom       =>   '*',
    },
    c_box2 => {
	top          =>   '*',
	left         => [ '/**',
			  ' * ',
			  ' **' ],
	center       => [ '**  /**',
			  ' *   * ',
			  '**/  **' ],
	right        => [ '** ',
			  ' * ',
			  '**/' ],
	bottom       =>   '*',
    },
    box => {
	top    =>     "─",
	left   => [  "┌─"  ,
		     "│ "  ,
		     "└─" ],
	center => [ "┐┌─"  ,
		    "││ "  ,
		    "┘└─" ],
	right  => [ "┐"    ,
		    "│"    ,
		    "┘"   ],
	bottom =>     "─",
    },
    round_box => {
	top    =>     "─",
	left   => [  "╭─"  ,
		     "│ "  ,
		     "╰─" ],
	center => [ "╮╭─"  ,
		    "││ "  ,
		    "╯╰─" ],
	right  => [ "╮"    ,
		    "│"    ,
		    "╯"   ],
	bottom =>     "─",
    },
    frame => {
	top    =>    "─",
	bottom =>    "─",
	left   => [ "┌─"  ,
		    "│ "  ,
		    "└─" ],
	center => [ "┬─"  ,
		    "│ "  ,
		    "┴─" ],
	right  => [ "┐"   ,
		    "│"   ,
		    "┘"  ],
    },
    page_frame => {
	top    =>    "─",
	left   => [ "┌─"  ,
		    "│ "  ,
		    "└─" ],
	center => [ "──"  ,
		    "  "  ,
		    "──" ],
	right  => [ "┐"   ,
		    "│"   ,
		    "┘"  ],
	bottom =>    "─",
    },
    shadow => {
	top    =>   "",
	left   => [ " "  ,
		    " "  ,
		    "▝" ],
	center => [ " ▖ " ,
		    " ▌ " ,
		    "▀▘▝" ],
	right  => [ " ▖" ,
		    " ▌" ,
		    "▀▘" ],
	bottom =>   "▀",
    },
    shadow_box => {
	top    =>   "─",
	left   => [ "┌─"  ,
		    "│ "  ,
		    "└▄" ],
	center => [ "─┐ ┌─"  ,
		    " ▐ │ "  ,
		    "▄▟ └▄" ],
	right  => [ "─┐" ,
		    " ▐" ,
		    "▄▟" ],
	bottom =>   "▄",
    },
    fat_box => {
	top    =>   "▀",
	left   => [ "█▀"  ,
		    "█ "  ,
		    "█▄" ],
	center => [ "▀█ █▀"  ,
		    " █ █ "  ,
		    "▄█ █▄" ],
	right  => [ "▀█" ,
		    " █" ,
		    "▄█" ],
	bottom =>   "▄",
    },
    very_fat_box => {
	top    =>   "█",
	left   => [ "███"  ,
		    "██ "  ,
		    "███" ],
	center => [ "███  ███"  ,
		    " ██  ██ "  ,
		    "███  ███" ],
	right  => [ "███" ,
		    " ██" ,
		    "███" ],
	bottom =>   "█",
    },
    fat_frame => {
	top    =>   "▀",
	left   => [ "█▀"  ,
		    "█ "  ,
		    "█▄" ],
	center => [ "▀█▀"  ,
		    " █ "  ,
		    "▄█▄" ],
	right  => [ "▀█" ,
		    " █" ,
		    "▄█" ],
	bottom =>   "▄",
    },
    very_fat_frame => {
	top    =>   "█",
	left   => [ "███"  ,
		    "██ "  ,
		    "███" ],
	center => [ "████"  ,
		    " ██ "  ,
		    "████" ],
	right  => [ "███" ,
		    " ██" ,
		    "███" ],
	bottom =>   "█",
    },
    comb => {
	top    =>    "─",
	left   => [ "┌─"  ,
		    "│ "  ,
		    "│ " ],
	center => [ "┬─"  ,
		    "│ "  ,
		    "│ " ],
	right  => [ "┐"   ,
		    "│"   ,
		    "│"  ],
    },
    rake => {
	left   => [ "│ "  ,
		    "│ "  ,
		    "└─" ],
	center => [ "│ "  ,
		    "│ "  ,
		    "┴─" ],
	right  => [ "│"   ,
		    "│"   ,
		    "┘"  ],
	bottom =>    "─",
    },
    mesh => {
	left   => [ "│"  ,
		    "│"  ,
		    "├" ],
	center => [ "│"  ,
		    "│"  ,
		    "┼" ],
	right  => [ "│"  ,
		    "│"  ,
		    "┤" ],
	bottom =>   "─",
    },
    hsem => {
	top    =>   "─",
	left   => [ "├"  ,
		    "│"  ,
		    "│" ],
	center => [ "┼"  ,
		    "│"  ,
		    "│" ],
	right  => [ "┤"  ,
		    "│"  ,
		    "│" ],
    },
    dumbbell => {
	center => [ "▄ "  , # "\x{2584} "
		    "│ "  , # "\x{2502} "
		    "▀ " ], # "\x{2580} "
    },
    ribbon => {
	center => [ "┌┐ "  , # "\x{250c}\x{2510}"
		    "││ "  , # "\x{2502}\x{2502}"
		    "└┘ " ], # "\x{2514}\x{2518}"
	left => ' ',
    },
    round_ribbon => {
	center => [ "╭╮ "  , # "\x{256D}\x{256E}"
		    "││ "  , # "\x{2502}\x{2502}"
		    "╰╯ " ], # "\x{2570}\x{256F}"
    },
    double_ribbon => {
	center => [ "╔╗ "  , # "\x{2554}\x{2557}"
		    "║║ "  , # "\x{2551}\x{2551}"
		    "╚╝ " ], # "\x{255A}\x{255D}"
    },
    );

use Clone qw(clone);

for my $style (qw(line vbar box round_box shadow_box frame page_frame comb rake mesh
		  dumbbell ribbon)) {
    $template{$style} // next;
    my $new = $template{"heavy_$style"} = clone $template{$style};
    while (my($k, $v) = each %$new) {
	for (ref $v ? @$v : $new->{$k}) {
	    $_ = heavy($_);
	}
    }
}

sub heavy {
    $_[0] =~ tr[─│┌┐└┘├┤┬┴┼╴╵╶╷][━┃┏┓┗┛┣┫┳┻╋╸╹╺╻]r;
}

# handle alias styles
for my $style (keys %template) {
    while (not ref (my $alias = $template{$style})) {
	($template{$style} = $template{$alias}) // last;
    }
}

sub new {
    my $class = shift;
    my $style = @_ ? shift : 'DEFAULT';
    (bless { %template }, $class)->style($style);
}

sub style {
    my $obj = shift;
    my $style = do {
	if (@_) {
	    $obj->{__STYLE__} = +shift =~ tr[-][_]r;
	} else {
	    return $obj->{__STYLE__};
	}
    };
    $obj->{$style} or return undef;
    $obj->{CURRENT} //= {};
    # %{$obj->{CURRENT}} = %{$obj->{$style}}
    %{$obj->{CURRENT}} =
	map { $_ => $obj->{$style}->{$_} } keys %{$obj->{$style}};
    $obj;
}

sub get {
    my $obj = shift;
    $obj->get_by_style('CURRENT', @_) // $obj->get_by_style('DEFAULT', @_)
	// die;
}

sub add_style {
    my $obj = shift;
    die if @_ % 2;
    while (my($name, $style) = splice @_, 0, 2) {
	$template{$name} = $style;
    }
    $obj;
}

sub get_by_style ($ $$;$$) {
    my $obj = shift;
    my($style, $place, $position, $page) = (shift, shift, shift//0, shift//0);
    my $hash = $obj->{$style} // return undef;
    my $entry = $hash->{$place} // return undef;
    if (not ref $entry) {
	return $entry;
    } elsif (@$entry == 0) {
	return undef;
    } else {
	my $target = ref $entry->[0] ? $entry->[$page / @$entry] : $entry;
	return $target->[$position % @$target];
    }
}

1;
