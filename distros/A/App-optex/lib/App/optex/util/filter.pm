package App::optex::util::filter;

use v5.10;
use strict;
use warnings;
use Carp;
use utf8;
use Encode;
use open IO => 'utf8', ':std';
use Data::Dumper;

my($mod, $argv);

sub initialize {
    ($mod, $argv) = @_;
}

=head1 NAME

util::filter - optex fitler utility module

=head1 SYNOPSIS

B<optex> [ --if/--of I<command> ] I<command>

B<optex> [ --if/--of I<&function> ] I<command>

B<optex> [ --isub/--osub/--psub I<function> ] I<command>

B<optex> I<command> -Mutil::I<filter> [ options ]

=head1 OPTION

=over 4

=item B<--if> I<command>

=item B<--of> I<command>

Set input/output filter command.  If the command start by C<&>, module
function is called instead.

=item B<--pf> I<&function>

Set pre-fork filter function.  This function is called before
executing the target command process, and expected to return text
data, that will be poured into target process's STDIN.  This allows
you to share information between pre-fork and output filter processes.

=item B<--isub> I<function>

=item B<--osub> I<function>

=item B<--psub> I<function>

Set filter function.  These are shortcut for B<--if> B<&>I<function>
and such.

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
	    io_filter { $func->call($io => $opt{$io}) } $io => 1;
	}
	else {
	    io_filter { exec $filter or die "exec: $!\n" } $io => 1;
	}
    }
    %opt and die "Unknown parameter: " . Dumper \%opt;
    ();
}
	
=item B<set>()

Set input/output filter.

=cut

######################################################################

=item B<rev_line>()

Reverse output.

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

=head1 SEE ALSO

L<App::optex::xform>

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
