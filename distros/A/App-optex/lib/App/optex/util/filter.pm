package App::optex::util::filter;

1;

package util::filter;

use v5.10;
use strict;
use warnings;
use utf8;
use Encode;
use Data::Dumper;

my($mod, $argv);
sub initialize { ($mod, $argv) = @_ }

binmode STDIN,  ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";

=head1 NAME

util::filter - optex fitler utility module

=head1 SYNOPSIS

B<optex> [ --if/--of I<command> ] I<command>

B<optex> [ --isub/--osub I<function> ] I<command>

B<optex> I<command> -Mutil::I<filter> [ options ]

=head1 OPTION

=over 4

=item B<--if> I<command>

=item B<--of> I<command>

Set input/output filter command.  If the command start by C<&>, module
function is called instead.

=item B<--isub> I<function>

=item B<--osub> I<function>

Set input/output function.  Tis is shortcut for B<--if> B<&>I<function>.

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
    my $open = do {
	if (delete $opt{in}) {
	    sub { open STDIN, '-|' };
	} else {
	    delete $opt{out};
	    sub { open STDOUT, '|-' }
	}
    };
    my $pid = $open->() // die "fork: $!\n";
    return $pid if $pid > 0;
    $sub->(%opt);
    exit 0;
}

#sub input_filter (&) {
#    my $sub = shift;
#    my $pid = open(STDIN, '-|') // die "fork: $!\n";
#    return $pid if $pid > 0;
#    $sub->(@_);
#    exit 0;
#}
#
#sub output_filter (&) {
#    my $sub = shift;
#    my $pid = open(STDOUT, '|-') // die "fork: $!\n";
#    return $pid if $pid > 0;
#    $sub->(@_);
#    exit 0;
#}

sub set {
    my %opt = @_;
    my $filter = $opt{in} // $opt{out};
    if ($filter =~ s/^&//) {
	if ($filter !~ /::/) {
	    $filter = join '::', __PACKAGE__, $filter;
	}
	use Getopt::EX::Func qw(parse_func);
	my $func = parse_func($filter);
	io_filter { $func->call(@_) } %opt;
    }
    else {
	io_filter { exec $filter or die "exec: $!\n" } %opt;
    }
}
	
=item B<set>()

Set input/output filter.

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

sub timestamp {
    my %opt = @_;
    my $format = $opt{format} || "%T.%f";

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
	my $time = $sub->();
	print $time, " ", $_;
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

=cut

1;

__DATA__

option --if -M__PACKAGE__::set(in=$<shift>)
option --of -M__PACKAGE__::set(out=$<shift>)

option --isub --if &$<shift>
option --osub --of &$<shift>
