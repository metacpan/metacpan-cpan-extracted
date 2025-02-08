package App::cat::v;

our $VERSION = "1.03";

use 5.024;
use warnings;
use open IO => ':utf8', ':std';

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
    nul  => [ 'm', "\x00", { s => "\x{2400}",      # ␀ SYMBOL FOR NULL
			     m => "\x{2205}", } ], # ∅ EMPTY SET
    soh  => [ 's', "\x01", { s => "\x{2401}", } ], # ␁ SYMBOL FOR START OF HEADING
    stx  => [ 's', "\x02", { s => "\x{2402}", } ], # ␂ SYMBOL FOR START OF TEXT
    etx  => [ 's', "\x03", { s => "\x{2403}", } ], # ␃ SYMBOL FOR END OF TEXT
    eot  => [ 's', "\x04", { s => "\x{2404}", } ], # ␄ SYMBOL FOR END OF TRANSMISSION
    enq  => [ 's', "\x05", { s => "\x{2405}", } ], # ␅ SYMBOL FOR ENQUIRY
    ack  => [ 's', "\x06", { s => "\x{2406}", } ], # ␆ SYMBOL FOR ACKNOWLEDGE
    bel  => [ 's', "\x07", { s => "\x{2407}",      # ␇ SYMBOL FOR BELL
			     m => "\x{237E}", } ], # ⍾ BELL SYMBOL
    bs   => [ 's', "\x08", { s => "\x{2408}", } ], # ␈ SYMBOL FOR BACKSPACE
    ht   => [ 's', "\x09", { s => "\x{2409}", } ], # ␉ SYMBOL FOR HORIZONTAL TABULATION
    nl   => [ 'm', "\x0a", { s => "\x{240A}",      # ␊ SYMBOL FOR LINE FEED
			     m => "\x{23CE}", } ], # ⏎ RETURN SYMBOL
    vt   => [ 's', "\x0b", { s => "\x{240B}", } ], # ␋ SYMBOL FOR VERTICAL TABULATION
    np   => [ 'm', "\x0c", { s => "\x{240C}",    , # ␌ SYMBOL FOR FORM FEED
			     m => "\x{2398}", } ], # ⎘ NEXT PAGE
    cr   => [ 's', "\x0d", { s => "\x{240D}", } ], # ␍ SYMBOL FOR CARRIAGE RETURN
    so   => [ 's', "\x0e", { s => "\x{240E}", } ], # ␎ SYMBOL FOR SHIFT OUT
    si   => [ 's', "\x0f", { s => "\x{240F}", } ], # ␏ SYMBOL FOR SHIFT IN
    dle  => [ 's', "\x10", { s => "\x{2410}", } ], # ␐ SYMBOL FOR DATA LINK ESCAPE
    dc1  => [ 's', "\x11", { s => "\x{2411}", } ], # ␑ SYMBOL FOR DEVICE CONTROL ONE
    dc2  => [ 's', "\x12", { s => "\x{2412}", } ], # ␒ SYMBOL FOR DEVICE CONTROL TWO
    dc3  => [ 's', "\x13", { s => "\x{2413}", } ], # ␓ SYMBOL FOR DEVICE CONTROL THREE
    dc4  => [ 's', "\x14", { s => "\x{2414}", } ], # ␔ SYMBOL FOR DEVICE CONTROL FOUR
    nak  => [ 's', "\x15", { s => "\x{2415}", } ], # ␕ SYMBOL FOR NEGATIVE ACKNOWLEDGE
    syn  => [ 's', "\x16", { s => "\x{2416}", } ], # ␖ SYMBOL FOR SYNCHRONOUS IDLE
    etb  => [ 's', "\x17", { s => "\x{2417}", } ], # ␗ SYMBOL FOR END OF TRANSMISSION BLOCK
    can  => [ 's', "\x18", { s => "\x{2418}", } ], # ␘ SYMBOL FOR CANCEL
    em   => [ 's', "\x19", { s => "\x{2419}", } ], # ␙ SYMBOL FOR END OF MEDIUM
    sub  => [ 's', "\x1a", { s => "\x{241A}", } ], # ␚ SYMBOL FOR SUBSTITUTE
    esc  => [ '0', "\x1b", { s => "\x{241B}",      # ␛ SYMBOL FOR ESCAPE
			     m => "\x{21B0}", } ], # ↰ UPWARDS ARROW WITH TIP LEFTWARDS
    fs   => [ 's', "\x1c", { s => "\x{241C}", } ], # ␜ SYMBOL FOR FILE SEPARATOR
    gs   => [ 's', "\x1d", { s => "\x{241D}", } ], # ␝ SYMBOL FOR GROUP SEPARATOR
    rs   => [ 's', "\x1e", { s => "\x{241E}", } ], # ␞ SYMBOL FOR RECORD SEPARATOR
    us   => [ 's', "\x1f", { s => "\x{241F}", } ], # ␟ SYMBOL FOR UNIT SEPARATOR
    sp   => [ 'm', "\x20", { s => "\x{2420}",      # ␠ SYMBOL FOR SPACE
			     m => "\x{00B7}", } ], # · MIDDLE DOT
    del  => [ 'm', "\x7f", { s => "\x{2421}",    , # ␡ SYMBOL FOR DELETE
			     m => "\x{232B}", } ], # ⌫ ERASE TO THE LEFT
    nbsp => [ 's', "\xa0", { s => "\x{2423}", } ], # ␣ OPEN BOX
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

# setup 'e' map
for my $v (values %control) {
    my %map = (
	"\t" => '\t',
	"\n" => '\n',
	"\r" => '\r',
	"\f" => '\f',
	"\b" => '\b',
	"\a" => '\a',
	"\e" => '\e',
    );
    my $code = $v->code;
    $v->cmap->{e} = $map{$code} // sprintf "\\x%02x", ord($code);
}

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
    has original   => ' o  +   ' , default => 0 ;
    has debug      => ' d      ' ;
    has tabstop    => ' x  =i  ' , default => 8, min => 1 ;
    has tabhead    => '    =s  ' ;
    has tabspace   => '    =s  ' ;
    has tabstyle   => ' ts :s  ' , default => $DEFAULT_TABSTYLE ;
    has help       => ' h      ' ;
    has version    => ' v      ' ;
    has escape_backslash => 'E!' ;

    # -n
    has '+reset' => sub {
	for my $name (keys $_->flags->%*) {
	    $_->flags->{$name} = '0';
	}
	$_->repeat = '';
	$_->expand = 0;
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
	if ($param !~ /^\w+=/) {
	    $param = "all=$param";
	}
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
	    if ($code =~ /[\x00-\x1f]/) {
		$convert->{$code} = '^' . pack('c',ord($code)+64);
	    }
	}
	elsif ($flag =~ /^([a-z\d])$/i) {
	    $convert->{$code} = $char->visible($flag);
	}
	else {
	    $convert->{$char->code} = $flag;
	}
    }
    $convert->{"\\"} = "\\\\" if $app->escape_backslash;
    return $app;
}

sub doit {
    my $app = shift;
    my $convert = $app->convert;
    my $replace = join '', sort keys $convert->%*;
    my $repeat_re = do {
	if (my @c = map { $code{$_} } $app->repeat =~ /\w+/g) {
	    local $" = "";
	    qr/[\Q@c\E]/;
	} else {
	    qr/(?!)/;
	}
    };
    while (<>) {
	my $orig = $_;
	$_ = ansi_expand($_) if $app->expand;
	s{(?=(${repeat_re}?))([\Q$replace\E]|(?#bug?)(?!))}{$convert->{$2}$1}g
	    if $replace ne '';
	if ($app->original > 1 or
	    ($app->original and $_ ne $orig)) {
	    print $orig;
	}
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

Copyright ©︎ 2024-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

