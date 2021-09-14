package App::optex::util::filter;

use v5.10;
use strict;
use warnings;
use Carp;
use utf8;
use Encode;
use open IO => 'utf8', ':std';
use Hash::Util qw(lock_keys);
use Data::Dumper;

my($mod, $argv);

sub initialize {
    ($mod, $argv) = @_;
}

=head1 NAME

util::filter - optex filter utility module

=head1 SYNOPSIS

B<optex> -Mutil::filter [ --if/--of/--ef I<command> ] I<command>

B<optex> -Mutil::filter [ --if/--of/--ef I<&function> ] I<command>

B<optex> -Mutil::filter [ --isub/--osub/--esub/--psub I<function> ] I<command>

=head1 OPTION

=over 4

=item B<--if> I<command>

=item B<--of> I<command>

=item B<--ef> I<command>

Set input/output filter command for STDIN, STDOUT and STDERR.  If the
command start by C<&>, module function is called instead.

=item B<--isub> I<function>

=item B<--osub> I<function>

=item B<--esub> I<function>

Set filter function.  These are shortcut for B<--if> B<&>I<function>
and such.

=item B<--psub> I<function>, B<--pf> I<&function>

Set pre-fork filter function.  This function is called before
executing the target command process, and expected to return text
data, that will be poured into target process's STDIN.  This allows
you to share information between pre-fork and output filter processes.

See L<App::optex::xform> for actual use case.

=item B<--set-io-color> IO=I<color>

Set color filter to filehandle.  You can set color filter for STDERR
like this:

    --set-io-color STDERR=R

Use comma to set multiple filehandles at once.

    --set-io-color STDIN=B,STDERR=R

=item B<--io-color>

Set default color to STDOUT and STDERR.

=back

=head1 DESCRIPTION

This module is a collection of sample utility functions for command
B<optex>.

Function can be called with option declaration.  Parameters for the
function are passed by name and value list: I<name>=I<value>.  Value 1
is assigned for the name without value.

In this example,

    optex -Mutil::function(debug,message=hello,count=3)

option I<debug> has value 1, I<message> has string "hello", and
I<count> also has string "3".

=head1 FUNCTION

=over 4

=cut

######################################################################
######################################################################
sub io_filter (&@) {
    my $sub = shift;
    my %opt = @_;
    local @ARGV;
    if ($opt{PREFORK}) {
	my $stdin = $sub->();
	$sub = sub { print $stdin };
	$opt{STDIN} = 1;
    }
    my $pid = do {
	if    ($opt{STDIN})  { open STDIN,  '-|' }
	elsif ($opt{STDOUT}) { open STDOUT, '|-' }
	elsif ($opt{STDERR}) { open STDERR, '|-' }
	else  { croak "Missing option" }
    } // die "fork: $!\n";;
    return $pid if $pid > 0;
    if ($opt{STDERR}) {
	open STDOUT, '>&', \*STDERR or die "dup: $!";
    }
    $sub->();
    close STDOUT;
    close STDERR;
    exit 0;
}

sub set {
    my %opt = @_;
    for my $io (qw(PREFORK STDIN STDOUT STDERR)) {
	my $filter = delete $opt{$io} // next;
	if ($filter =~ s/^&//) {
	    if ($filter !~ /::/) {
		$filter = join '::', __PACKAGE__, $filter;
	    }
	    use Getopt::EX::Func qw(parse_func);
	    my $func = parse_func($filter);
	    io_filter { $func->call() } $io => 1;
	}
	else {
	    io_filter { exec $filter or die "exec: $!\n" } $io => 1;
	}
    }
    %opt and die "Unknown parameter: " . Dumper \%opt;
    ();
}

=item B<set>(I<io>=I<command>)

=item B<set>(I<io>=&I<function>)

Primitive function to prepare input/output filter.  All options are
implemented by this function.  Takes C<STDIN>, C<STDOUT>, C<STDERR>,
C<PREFORK> as an I<io> name and I<command> or &I<function> as a vaule.

    mode function
    option --if   &set(STDIN=$<shift>)
    option --isub &set(STDIN=&$<shift>)

=cut

######################################################################

sub unctrl {
    while (<>) {
	s/([\000-\010\013-\037\177])/'^' . pack('c', ord($1)|0100)/ge;
	print;
    }
}

=item B<unctrl>()

Visualize control characters.

=cut

######################################################################

my %control = (
    nul => [ 's', "\000", "\x{2400}" ], # ␀ SYMBOL FOR NULL
    soh => [ 's', "\001", "\x{2401}" ], # ␁ SYMBOL FOR START OF HEADING
    stx => [ 's', "\002", "\x{2402}" ], # ␂ SYMBOL FOR START OF TEXT
    etx => [ 's', "\003", "\x{2403}" ], # ␃ SYMBOL FOR END OF TEXT
    eot => [ 's', "\004", "\x{2404}" ], # ␄ SYMBOL FOR END OF TRANSMISSION
    enq => [ 's', "\005", "\x{2405}" ], # ␅ SYMBOL FOR ENQUIRY
    ack => [ 's', "\006", "\x{2406}" ], # ␆ SYMBOL FOR ACKNOWLEDGE
    bel => [ 's', "\007", "\x{2407}" ], # ␇ SYMBOL FOR BELL
    bs  => [ 's', "\010", "\x{2408}" ], # ␈ SYMBOL FOR BACKSPACE
    ht  => [ 's', "\011", "\x{2409}" ], # ␉ SYMBOL FOR HORIZONTAL TABULATION
    nl  => [  '', "\012", "\x{240A}" ], # ␊ SYMBOL FOR LINE FEED
    vt  => [ 's', "\013", "\x{240B}" ], # ␋ SYMBOL FOR VERTICAL TABULATION
    np  => [ 's', "\014", "\x{240C}" ], # ␌ SYMBOL FOR FORM FEED
    cr  => [ 's', "\015", "\x{240D}" ], # ␍ SYMBOL FOR CARRIAGE RETURN
    so  => [ 's', "\016", "\x{240E}" ], # ␎ SYMBOL FOR SHIFT OUT
    si  => [ 's', "\017", "\x{240F}" ], # ␏ SYMBOL FOR SHIFT IN
    dle => [ 's', "\020", "\x{2410}" ], # ␐ SYMBOL FOR DATA LINK ESCAPE
    dc1 => [ 's', "\021", "\x{2411}" ], # ␑ SYMBOL FOR DEVICE CONTROL ONE
    dc2 => [ 's', "\022", "\x{2412}" ], # ␒ SYMBOL FOR DEVICE CONTROL TWO
    dc3 => [ 's', "\023", "\x{2413}" ], # ␓ SYMBOL FOR DEVICE CONTROL THREE
    dc4 => [ 's', "\024", "\x{2414}" ], # ␔ SYMBOL FOR DEVICE CONTROL FOUR
    nak => [ 's', "\025", "\x{2415}" ], # ␕ SYMBOL FOR NEGATIVE ACKNOWLEDGE
    syn => [ 's', "\026", "\x{2416}" ], # ␖ SYMBOL FOR SYNCHRONOUS IDLE
    etb => [ 's', "\027", "\x{2417}" ], # ␗ SYMBOL FOR END OF TRANSMISSION BLOCK
    can => [ 's', "\030", "\x{2418}" ], # ␘ SYMBOL FOR CANCEL
    em  => [ 's', "\031", "\x{2419}" ], # ␙ SYMBOL FOR END OF MEDIUM
    sub => [ 's', "\032", "\x{241A}" ], # ␚ SYMBOL FOR SUBSTITUTE
    esc => [  '', "\033", "\x{241B}" ], # ␛ SYMBOL FOR ESCAPE
    fs  => [ 's', "\034", "\x{241C}" ], # ␜ SYMBOL FOR FILE SEPARATOR
    gs  => [ 's', "\035", "\x{241D}" ], # ␝ SYMBOL FOR GROUP SEPARATOR
    rs  => [ 's', "\036", "\x{241E}" ], # ␞ SYMBOL FOR RECORD SEPARATOR
    us  => [ 's', "\037", "\x{241F}" ], # ␟ SYMBOL FOR UNIT SEPARATOR
    sp  => [ 's', "\040", "\x{2420}" ], # ␠ SYMBOL FOR SPACE
    del => [ 's', "\177", "\x{2421}" ], # ␡ SYMBOL FOR DELETE
);

use List::Util qw(pairmap);
my %symbol = pairmap { $b->[1] => $b->[2] } %control;
my %char   = pairmap { $a => $b->[1] } %control;

my $keep_after = qr/[\n]/;

use Text::ANSI::Tabs qw(ansi_expand);

sub visible {
    my %opt = @_;
    my %flag = pairmap { $a => $b->[0] } %control;
    lock_keys %flag;
    if (my $all = delete $opt{all}) {
	$flag{$_} = $all for keys %flag;
    }
    my($tabstyle, $s_char, $c_char) = ('bar', '', '');
    if (exists $opt{tabstyle} and $tabstyle = delete $opt{tabstyle}) {
	Text::ANSI::Tabs->configure(tabstyle => $tabstyle);
    }
    %flag = (%flag, %opt);
    for my $name (keys %flag) {
	if    ($flag{$name} eq 'c') { $c_char .= $char{$name} }
	elsif ($flag{$name})        { $s_char .= $char{$name} }
    }
    while (<>) {
	if ($tabstyle) {
	    $_ = ansi_expand($_);
	}
	s{(?=(${keep_after}?))([$s_char]|(?#bug?)(?!))}{$symbol{$2}$1}g
	    if $s_char ne '';
	s{(?=(${keep_after}?))([$c_char]|(?#bug?)(?!))}{
	    '^'.pack('c',ord($2)+64).$1
	}ge if $c_char ne '';
	print;
    }
}

=item B<visible>(I<name>=I<flag>)

Make control and space characters visible.

By default, ESCAPE and NEWLINE is not touched.  Other control
characters and space are shown in unicode symbol.  Tab character and
following space is visualized in unicode mark.

When newline character is visualized, it is not deleted and shown with
visible representation.

=over 7

=item I<name>

Name is C<tabstyle>, C<all>, or one of these: [ nul soh stx etx eot
enq ack bel bs ht nl vt np cr so si dle dc1 dc2 dc3 dc4 nak syn etb
can em sub esc fs gs rs us sp del ].

If the name is C<all>, the value is set for all characters.
Default is equivalent to:

    visible(tabstyle=bar,all=s,esc=0,nl=0)

As for C<tabstyle>, use anything defined in L<Text::ANSI::Fold>.

=item I<flag>

If the flag is empty or 0, the character is displayed as is.  If flag
is C<c>, it is shown in C<^c> format.  Otherwise shown in unicode
symbol.

=back

=cut

######################################################################

sub rev_line {
    print reverse <STDIN>;
}

=item B<rev_line>()

Reverse output.

=cut

######################################################################

sub rev_char {
    while (<>) {
	print reverse /./g;
	print "\n" if /\n\z/;
    }
}

=item B<rev_char>()

Reverse characters in each line.

=cut

######################################################################

use List::Util qw(shuffle);

sub shuffle_line {
    print shuffle <>;
}

=item B<shuffle_line>()

Shuffle lines.

=cut

######################################################################

use Getopt::EX::Colormap qw(colorize);

sub io_color {
    my %opt = @_;
    for my $io (qw(STDIN STDOUT STDERR)) {
	my $color = $opt{$io} // next;
	io_filter {
	    while (<>) {
		print colorize($color, $_);
	    }
	} $io => 1;
    }
    ();
}

=item B<io_color>( B<IO>=I<color> )

Colorize text. B<IO> is either of C<STDOUT> or C<STDERR>.  Use comma
to set both at a same time: C<STDOUT=C,STDERR=R>.

=cut

######################################################################

sub splice_line {
    my %opt = @_;
    my @line = <>;
    if (my $length = $opt{length}) {
	print splice @line, $opt{offset} // 0, $opt{length};
    } else {
	print splice @line, $opt{offset} // 0;
    }
}

=item B<splice_line>( offset=I<n>, [ length=I<m> ] )

Splice lines.

=cut

######################################################################

use Time::Piece;
use Getopt::EX::Colormap qw(colorize);

sub timestamp {
    my %opt = @_;
    my $format = $opt{format} || "%T.%f";
    my $color = $opt{color} || 'Y';

    my $sub = do {
	my $re_subsec = qr/%f|(?<milli>%L)|%(?<prec>\d*)N/;
	if ($format =~ /$re_subsec/) {
	    require Time::HiRes;
	    my $prec = $+{milli} ? 3 : $+{prec} || 6;
	    sub {
		my($sec, $usec) = Time::HiRes::gettimeofday();
		$usec /= (10 ** (6 - $prec)) if 0 < $prec and $prec < 6;
		(my $time = $format)
		    =~ s/$re_subsec/sprintf("%0${prec}d", $usec)/ge;
		localtime($sec)->strftime($time);
	    }
	} else {
	    sub {
		localtime(time)->strftime($format);
	    }
	}
    };

    while (<>) {
	print colorize($color, $sub->()), " ", $_;
    }
}

=item B<timestamp>( [ format=I<strftime_format> ] )

Put timestamp on each line of output.

Format is interpreted by C<strftime> function.  Default format is
C<"%T.%f"> where C<%T> is 24h style time C<%H:%M:%S>, and C<%f> is
microsecond.  C<%L> means millisecond. C<%nN> can be used to specify
precision.

=cut

######################################################################

sub gunzip { exec "gunzip -c" }

sub gzip   { exec "gzip -c" }

=item B<gunzip>()

Gunzip standard input.

=item B<gzip>()

Gzip standard input.

=cut

######################################################################
######################################################################

=back

=head1 EXAMPLE

Next command print C<ping> command output with timestamp.

    optex -Mutil::filter --osub timestamp ping -c 10 localhost

Put next line in your F<~/.optex.d/optex.rc>.  Then for any command
executed by optex, standard error output will be shown in visible and
colored.  This is convenient or debug.

    option default -Mutil::filter --io-color --esub visible

Above setting is not effective for command executed through symbolic
link.  You can set F<~/.optex.d/default.rc>, but it sometime calls
unexpected behavior.  This is a future issue.

=head1 SEE ALSO

L<App::optex::xform>

L<https://qiita.com/kaz-utashiro/items/2df8c7fbd2fcb880cee6>

=cut

1;

__DATA__

mode function

option --if &set(STDIN=$<shift>)
option --of &set(STDOUT=$<shift>)
option --ef &set(STDERR=$<shift>)
option --pf &set(PREFORK=$<shift>)

option --isub &set(STDIN=&$<shift>)
option --osub &set(STDOUT=&$<shift>)
option --esub &set(STDERR=&$<shift>)
option --psub &set(PREFORK=&$<shift>)

option --set-io-color &io_color($<shift>)
option --io-color --set-io-color STDERR=555/201;E

#  LocalWords:  optex STDIN filehandle STDERR STDOUT strftime
