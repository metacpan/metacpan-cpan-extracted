package App::cat::v;

our $VERSION = "1.01";

use 5.024;
use warnings;

use utf8;
use Encode;
use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
}
use open IO => 'utf8', ':std';
use charnames ':loose';
use Pod::Usage;
use List::Util qw(max pairmap);
use Hash::Util qw(lock_keys);
use Getopt::EX;
use Text::ANSI::Tabs qw(ansi_expand);

my %control = (
    nul  => [ 'm', "\000", { s => "\x{2400}",      # ␀ SYMBOL FOR NULL
			     m => "\x{2205}", } ], # ∅ EMPTY SET
    soh  => [ 's', "\001", { s => "\x{2401}", } ], # ␁ SYMBOL FOR START OF HEADING
    stx  => [ 's', "\002", { s => "\x{2402}", } ], # ␂ SYMBOL FOR START OF TEXT
    etx  => [ 's', "\003", { s => "\x{2403}", } ], # ␃ SYMBOL FOR END OF TEXT
    eot  => [ 's', "\004", { s => "\x{2404}", } ], # ␄ SYMBOL FOR END OF TRANSMISSION
    enq  => [ 's', "\005", { s => "\x{2405}", } ], # ␅ SYMBOL FOR ENQUIRY
    ack  => [ 's', "\006", { s => "\x{2406}", } ], # ␆ SYMBOL FOR ACKNOWLEDGE
    bel  => [ 's', "\007", { s => "\x{2407}",      # ␇ SYMBOL FOR BELL
			     m => "\x{237E}", } ], # ⍾ BELL SYMBOL
    bs   => [ 's', "\010", { s => "\x{2408}", } ], # ␈ SYMBOL FOR BACKSPACE
    ht   => [ 's', "\011", { s => "\x{2409}", } ], # ␉ SYMBOL FOR HORIZONTAL TABULATION
    nl   => [ 'm', "\012", { s => "\x{240A}",      # ␊ SYMBOL FOR LINE FEED
			     m => "\x{23CE}", } ], # ⏎ RETURN SYMBOL
    vt   => [ 's', "\013", { s => "\x{240B}", } ], # ␋ SYMBOL FOR VERTICAL TABULATION
    np   => [ 'm', "\014", { s => "\x{240C}",    , # ␌ SYMBOL FOR FORM FEED
			     m => "\x{2398}", } ], # ⎘ NEXT PAGE
    cr   => [ 's', "\015", { s => "\x{240D}", } ], # ␍ SYMBOL FOR CARRIAGE RETURN
    so   => [ 's', "\016", { s => "\x{240E}", } ], # ␎ SYMBOL FOR SHIFT OUT
    si   => [ 's', "\017", { s => "\x{240F}", } ], # ␏ SYMBOL FOR SHIFT IN
    dle  => [ 's', "\020", { s => "\x{2410}", } ], # ␐ SYMBOL FOR DATA LINK ESCAPE
    dc1  => [ 's', "\021", { s => "\x{2411}", } ], # ␑ SYMBOL FOR DEVICE CONTROL ONE
    dc2  => [ 's', "\022", { s => "\x{2412}", } ], # ␒ SYMBOL FOR DEVICE CONTROL TWO
    dc3  => [ 's', "\023", { s => "\x{2413}", } ], # ␓ SYMBOL FOR DEVICE CONTROL THREE
    dc4  => [ 's', "\024", { s => "\x{2414}", } ], # ␔ SYMBOL FOR DEVICE CONTROL FOUR
    nak  => [ 's', "\025", { s => "\x{2415}", } ], # ␕ SYMBOL FOR NEGATIVE ACKNOWLEDGE
    syn  => [ 's', "\026", { s => "\x{2416}", } ], # ␖ SYMBOL FOR SYNCHRONOUS IDLE
    etb  => [ 's', "\027", { s => "\x{2417}", } ], # ␗ SYMBOL FOR END OF TRANSMISSION BLOCK
    can  => [ 's', "\030", { s => "\x{2418}", } ], # ␘ SYMBOL FOR CANCEL
    em   => [ 's', "\031", { s => "\x{2419}", } ], # ␙ SYMBOL FOR END OF MEDIUM
    sub  => [ 's', "\032", { s => "\x{241A}", } ], # ␚ SYMBOL FOR SUBSTITUTE
    esc  => [ '0', "\033", { s => "\x{241B}", } ], # ␛ SYMBOL FOR ESCAPE
    fs   => [ 's', "\034", { s => "\x{241C}", } ], # ␜ SYMBOL FOR FILE SEPARATOR
    gs   => [ 's', "\035", { s => "\x{241D}", } ], # ␝ SYMBOL FOR GROUP SEPARATOR
    rs   => [ 's', "\036", { s => "\x{241E}", } ], # ␞ SYMBOL FOR RECORD SEPARATOR
    us   => [ 's', "\037", { s => "\x{241F}", } ], # ␟ SYMBOL FOR UNIT SEPARATOR
    sp   => [ 'm', "\040", { s => "\x{2420}",      # ␠ SYMBOL FOR SPACE
			     m => "\x{00B7}", } ], # · MIDDLE DOT
    del  => [ 'm', "\177", { s => "\x{2421}",    , # ␡ SYMBOL FOR DELETE
			     m => "\x{232B}", } ], # ⌫ ERASE TO THE LEFT
    nbsp => [ 's', "\240", { s => "\x{2423}", } ], # ␣ OPEN BOX
);

package #
Visibility {
    use v5.24;
    use warnings;
    sub default { $_[0]->[0] }
    sub code    { $_[0]->[1] }
    sub cmap    { $_[0]->[2] }
    sub visible {
	my($c, $type) = @_;
	$c->cmap->{$type} // $c->cmap->{$c->default || 's'};
    }
};
bless $_, 'Visibility' for values %control;

my %code = pairmap { $a => $b->code } %control;

our $DEFAULT_TABSTYLE = 'needle';
if ($DEFAULT_TABSTYLE) {
    Text::ANSI::Tabs->configure(tabstyle => $DEFAULT_TABSTYLE);
}

sub list_tabstyle {
    my %style = %Text::ANSI::Fold::TABSTYLE;
    my $max = max map length, keys %style;
    for my $name (sort keys %style) {
	my($head, $space) = $style{$name}->@*;
	my $tab = $head . $space x 7;
	printf "%*s %s\n", $max, $name, $tab x 3;
    }
}

use Getopt::EX::Hashed; {
    Getopt::EX::Hashed->configure(DEFAULT => [ is => 'rw' ]);
    has visible    => ' c  =s@ ' ;
    has reset      => ' n      ' ;
    has expand     => ' t  :1  ' , default => 1 ;
    has no_expand  => ' T  !   ' ;
    has repeat     => ' r  =s  ' , default => 'nl,np' ;
    has replicate  => ' R      ' ;
    has debug      => ' d      ' ;
    has tabstop    => ' x  =i  ' , default => 8, min => 1 ;
    has tabhead    => '    =s  ' ;
    has tabspace   => '    =s  ' ;
    has tabstyle   => ' ts :s  ' , default => $DEFAULT_TABSTYLE ;
    has help       => ' h      ' ;
    has version    => ' v      ' ;

    # -n
    has '+reset' => sub {
	for my $name (keys $_->flags->%*) {
	    $_->flags->{$name} = '0';
	}
	$_->repeat = '';
    };

    has '+expand' => sub {
	$_->expand = $_[1];
	if ($_[1] > 1) {
	    $_->tabstop = $_[1];
	    Text::ANSI::Tabs->configure(tabstop => $_->tabstop);
	}
    };

    #  -T negate -t
    has '+no_expand' => sub {
	$_->expand = ! $_[1];
    };

    has '+repeat' => sub {
	my($name, $c) = ("$_[0]", $_[1]);
	if ($c =~ s/^\++//) {
	    $_->$name .= ",$c";
	} else {
	    $_->$name = $c;
	}
    };

    # individual char option
    has [ keys %control ] => ':s', action => sub {
	my($name, $c) = ("$_[0]", $_[1]);
	if ($c =~ s/^\+//) {
	    $_->repeat .= ",$name";
	}
	$c = '1' if $c eq '';
	if (length($c) > 1 and my $u = charnames::string_vianame($c)) {
	    $c = $u;
	}
	$_->flags->{$name} = $c;
    };

    ### --tabstop, --tabstyle
    has [ qw(+tabstop +tabstyle) ] => sub {
	my($name, $val) = map "$_", @_;
	if ($val eq '') {
	    list_tabstyle();
	    exit;
	}
	Text::ANSI::Tabs->configure($name => $val);
    };

    ### --tabhead, --tabspace
    has [ qw(+tabhead +tabspace) ] => sub {
	my($name, $c) = map "$_", @_;
	$c = charnames::string_vianame($c) || die "$c: invalid name\n"
	    if length($c) > 1;
	Text::ANSI::Tabs->configure($name => $c);
    };

    has '+visible' => sub {
	my $param = $_[1];
	$param =~ s{ \ball\b }{ join('=', keys $_->flags->%*) }xe;
	push @{$_->visible}, $param;
    };

    has '+help' => sub {
	pod2usage
	    -verbose  => 99,
	    -sections => [ qw(SYNOPSIS VERSION) ];
    };

    has '+version' => sub {
	say "Version: $VERSION";
	exit;
    };

    # internal use

    has flags   => default => { pairmap { $a => $b->default } %control };
    has convert => default => {};

} no Getopt::EX::Hashed;

sub run {
    my $app = shift;
    local @ARGV = splice @_;
    $app->options->setup->doit;
    return 0;
}

sub options {
    my $app = shift;
    for (@ARGV) {
	$_ = decode 'utf8', $_ unless utf8::is_utf8($_);
    }
    use Getopt::EX::Long qw(:DEFAULT ExConfigure Configure);
    ExConfigure BASECLASS => [ __PACKAGE__, 'Getopt::EX' ];
    Configure qw(bundling);
    $app->getopt || pod2usage();

    Getopt::EX::LabeledParam
	->new(HASH => $app->flags, NEWLABEL => 0, DEFAULT => 1)
	->load_params($app->visible->@*);

    return $app;
}

sub setup {
    my $app = shift;
    my $convert = $app->convert;
    my $flags = $app->flags;
    for my $name (keys $flags->%*) {
	my $flag = $flags->{$name} or next;
	my $char = $control{$name};
	my $code = $char->code;
	if ($flag eq 'c') {
	    $convert->{$code} = '^' . pack('c',ord($code)+64);
	}
	elsif ($flag =~ /^([a-z\d])$/i) {
	    $convert->{$code} = $char->visible($flag);
	}
	else {
	    $convert->{$char->code} = $flag;
	}
    }
    return $app;
}

sub doit {
    my $app = shift;
    my $convert = $app->convert;
    my $replace = join '', sort keys $convert->%*;
    my $repeat_re = do {
	if (my @c = map { $code{$_} } $app->repeat =~ /\w+/g) {
	    local $" = "";
	    qr/[@c]/;
	} else {
	    qr/(?!)/;
	}
    };
    while (<>) {
	print if $app->replicate;
	$_ = ansi_expand($_) if $app->expand;
	s{(?=(${repeat_re}?))([$replace]|(?#bug?)(?!))}{$convert->{$2}$1}g
	    if $replace ne '';
	print;
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

App::cat::v - cat-v command implementation

=head1 SYNOPSIS

    use  App::cat::v;
    exit App::cat::v->new->run(splice @ARGV);

    perl -MApp::cat::v -E 'App::cat::v->new->run(@ARGV)' --

=head1 DESCRIPTION

Document is included in the executable script.
Use `perldoc cat-v`.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright ©︎ 2024- Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

