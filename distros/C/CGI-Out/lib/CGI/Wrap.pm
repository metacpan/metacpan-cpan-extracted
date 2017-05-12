
# Copyright (c) 1996, David Muir Sharnoff

package CGI::Wrap;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(out dout flushout savequery run);
@EXPORT_OK = qw($out);

$VERSION = 2004.1023;

use strict;

use vars qw($out $mailto $usedby);

my $error = 0;
my @saveA;
my $pwd;
my $zero;
my %e;
my $query;
my $debug = '';

use Cwd;

BEGIN	{
	$out = '';
	@saveA = @ARGV;
	$pwd = getcwd();
	$zero = $0;
	%e = %ENV;

	# idiom.com specific feature:
	$pwd = "$Chroot::has_chrooted$pwd"
		if defined $Chroot::has_chrooted;

	$usedby = join(':',(caller(2))[1,2]);

	if (defined @CGI::Out::EXPORT) {
		require CGI::BigDeath;
		bigdeath('', '', "Cannot combine CGI::Wrap ($usedby) with CGI::Out ($CGI::Out::usedby)",
			\%e, $query, $pwd, $zero, \@saveA, $debug, $mailto);
		exit(1);
	}
}

sub savequery
{
	($query) = (@_);
}

sub debug	
{
	$debug .= join('',@_);
	return '';
}	

sub out	
{
	$out .= join('',@_);
	return '';
}	

sub flushout
{
	$out = '';
}

sub run
{
	my ($func, @args) = @_;

	my $r;
	my @r;
	if (ref $func) {
		if (wantarray) {
			@r = eval { &$func(@args) };
		} else {
			$r = eval { &$func(@args) };
		}
	} else {
		if (wantarray) {
			@r = eval "$func @args";
		} else {
			$r = eval "$func @args";
		}
	}
	if ($@) {
		my $pe = $@;
		my $se = $!;
		require CGI::BigDeath;
		require CGI::Carp;
		bigdeath('see above', $se, $pe, $out, 
			\%e, $query, $pwd, $zero, 
			\@saveA, $debug, $mailto);
	}
	print $out;
	return @r if wantarray;
	return $r;
}

1;

__END__

=head1 NAME

CGI::Wrap - buffer output when building CGI programs

=head1 SYNOPSIS

	use CGI;
	use CGI::Croak;
	use CGI::Wrap;

	$query = new CGI;
	savequery $query;		# to reconstruct input
	$CGI::Out::mailto = 'fred';	# override default of $<

	run \&myfunc, @myargs		# a function
	run sub { code }		# an inline function
	run 'code'			# something to eval

	sub myfunc {
		out $query->header();
		out $query->start_html(
			-title=>'A test',
			-author=>'muir@idiom.com');
	}
	$CGI::Out::out			# is the buffer

=head1 DESCRIPTION

This is a helper routine for building CGI programs.  It buffers
stdout until you're completed building your output.  If you should
get an error before you are finished, then it will display a nice
error message (in HTML), log the error, and send email about the
problem.

To use it, you must condense your program down to a single 
function call and then use CGI::Wrap::run to call it.

Instead of print, use C<out>.

=head1 AUTHOR

David Muir Sharnoff <muir@idiom.com>

=head1 SEE ALSO

Carp, CGI::Carp, CGI::Out,  CGI

=head1 BUGS

No support for C<format>s is provided by CGI::Wrap.

