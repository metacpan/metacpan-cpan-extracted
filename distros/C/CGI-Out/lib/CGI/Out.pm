
# Copyright (c) 1996, David Muir Sharnoff

package CGI::Out;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(out dout flushout croak carp confess savequery);
@EXPORT_OK = qw(carpout $out);

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

sub error
{
	my (@bomb) = @_;
	my $pe = $@;
	my $se = $!;
	$error = 1;
	require CGI::BigDeath;
	bigdeath($pe, $se, "@bomb", $out, 
		\%e, $query, $pwd, $zero, 
		\@saveA, $debug, $mailto);
}

BEGIN	{
	require Carp;
	require CGI::Carp;

	*warn = \&{CGI::Carp::warn};
	*carpout = \&{CGI::Carp::carpout};
	$main::SIG{'__DIE__'}= \&CGI::Out::fakedie;

	$out = '';
	@saveA = @ARGV;
	$pwd = getcwd();
	$zero = $0;
	%e = %ENV;

	# idiom.com specific feature:
	$pwd = "$Chroot::has_chrooted$pwd"
		if defined $Chroot::has_chrooted;

	$usedby = join(':',(caller(2))[1,2]);

	&error("Cannot combine CGI::Out ($usedby) and CGI::Wrap ($CGI::Wrap::usedby)")
		if defined @CGI::Wrap::EXPORT;
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

sub croak
{
	error Carp::shortmess @_;
	CGI::Carp::die(Carp::shortmess @_);
}

sub confess
{	
	error Carp::longmess @_;
	CGI::Carp::die(Carp::longmess @_);
}

sub fakedie
{
	return if $;
	delete $main::SIG{'__DIE__'};
	exit(1) if $error;
	error Carp::shortmess @_;
	goto &CGI::Carp::die;
}

END	{
	print $out unless $error;
}

1;

__END__

=head1 NAME

CGI::Out - buffer output when building CGI programs

=head1 SYNOPSIS

	use CGI;
	use CGI::Out;

	$query = new CGI;
	savequery $query;		# to reconstruct input

	$CGI::Out::mailto = 'fred';	# override default of $<

	out $query->header();
	out $query->start_html(
		-title=>'A test',
		-author=>'muir@idiom.com');

	croak "We're outta here!";
	confess "It was my fault: $!";
	carp "It was your fault!";
	warn "I'm confused";
	die  "I'm dying.\n";

	use CGI::Out qw(carpout $out);
	carpout(\*LOG);
	$CGI::Out::out			# is the buffer


=head1 DESCRIPTION

This is a helper routine for building CGI programs.  It buffers
stdout until you're completed building your output.  If you should
get an error before you are finished, then it will display a nice
error message (in HTML), log the error, and send email about the
problem.

It wraps all of the functions provided by CGI::Carp and Carp.  Do
not "use" them directly, instead just "use CGI::Out".

Instead of print, use C<out>.

=head1 AUTHOR

David Muir Sharnoff <muir@idiom.com>

=head1 SEE ALSO

Carp, CGI::Carp, CGI, CGI::Wrap

=head1 BUGS

No support for C<format>s is provided by CGI::Out.

