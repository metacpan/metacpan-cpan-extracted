
=head1 NAME

Apache::OutputChain - chain stacked Perl handlers

=cut

package Apache::OutputChain;
use 5.004;
use strict;
use vars qw( $VERSION $DEBUG );
$VERSION = '0.11';

use Apache::Constants ':common';
$DEBUG = 0;
sub DEBUG()	{ $DEBUG; }
sub handler
	{
	my $r = shift;
	my $class = shift;
	$class = __PACKAGE__ unless defined $class;

	my $tied = tied *STDOUT;
	my $reftied = ref $tied;
	print STDERR "    Apache::OutputChain tied $class -> ",
		$reftied ? $reftied : 'STDOUT', "\n" if DEBUG;

	local $^W = 0;
	### undef *STDOUT;
	untie *STDOUT;
	tie *STDOUT, $class, $r;

	if ($reftied eq 'Apache')	{ tie *STDOUT, $class, $r; }
	else			{ tie *STDOUT, $class, $r, $tied; }
	return DECLINED;
	}
sub TIEHANDLE
	{
	my ($class, @opt) = @_;
	my $self = [ @opt ];
		# @opt should be set up to $r (request structure
		# reference) and optionally the next handler in the row
	print STDERR "    Apache::OutputChain::TIEHANDLE $self\n"
		if DEBUG;
	bless $self, $class;
	}
sub PRINT
	{
	my $self = shift;
	print STDERR "    Apache::OutputChain::PRINT $self\n"
		if DEBUG;

	if (defined $self->[1])		{ $self->[1]->PRINT(@_); }
	elsif (defined $self->[0])	{ $self->[0]->print(@_); }
	}

1;

=head1 SYNOPSIS

You need reasonably new version of Apache httpd, compiled with
mod_perl with PERL_STACKED_HANDLERS enabled. In the conf/access.conf
file of your Apache installation, add lines like

	<Files *.html>
	SetHandler perl-script
	PerlHandler Apache::OutputChain Apache::SSIChain Apache::PassHtml
	</Files>

Also, this module can be used as a base for other Apache::*Chain
handlers -- inherit from it to get the chaining features.

=head1 DESCRIPTION

This module allows chaining perl of handlers in Apache, which allows you
to make filter modules that take output from previous handlers, make
some modifications, and pass the output to the next handler or out to
browser.

Normal handler modules specify functions I<handler> that do the job --
authenticate, log, or send back the response. With chaining modules,
the I<handler> function only registers the handler into chain. It is
done by tie of STDOUT. The module then catches output of other
handlers in its function I<PRINT>, that gets called whenever something
is printed to tied handle, can modify or otherwise process the output
and send it further on.

The C<PerlHandler> above shows the typical configuration: first,
B<Apache::OutputChain> starts the chaining feature. Then, there is
a list of chaining modules, in reverse order. Here shown is
B<Apache::SSIChain>; if you would also want to gzip the output, you
would write something like

	Apache::OutputChain Apache::GzipChain Apache::SSIChain

Note that you probably want to do SSI first and gzip the result,
that's why the modules are written in that (reverse) order in the
configuration file.

As the last in the chaining chain, there should be some module that
actually produces the data: B<Apache::PassHtml>, B<Apache::PassFile>,
B<Apache::PassExec>, or even B<Apache::Registry>.

=head1 INTERNALS

I will try to explain how this feature is achieved, because I hope
you could help me to make it better and mature.

When the I<handler> function is called, it checks if it gets
a reference to a class. If this is true, then this function was called
from some other handler that wants to be put into the chain. If not,
it's probably an initialization (first call) of this package
(B<Apache::OutputChain>) and we will supply name of this package.
Note that other chaining modules should call inherited I<handler>
from their own I<handler>s.

Now we check, where is STDOUT tied. If it is Apache, we are the first
one trying to be put into the chain. If it is not, there is somebody
in the chain already. We call tie on the STDOUT, steal it from anybody
who had it before -- either Apache or the other class.

When later anybody prints into STDOUT, it will call function I<PRINT>
of the first class in the chain (the last one that registered). If
there is not other class behind, the I<print> method of Apache will be
called. If this is not the last user defined handler in the chain, we
will call I<PRINT> method of the next class.

=head1 VERSION

0.11

=head1 AUTHOR

(c) 1997--2002 Jan Pazdziora, adelton@fi.muni.cz,
http://www.fi.muni.cz/~adelton/ at Faculty of Informatics, Masaryk
University, Brno, Czech Republic

=head1 SEE ALSO

Apache::GzipChain(3) by Andreas Koenig for solution that gzips the output
on the fly; Apache::SSIChain(3) for SSI parsing module; mod_perl(1)
by Doug MacEachern for the great Perl in Apache project.

Apache::MakeCapital(3) for a simple example of inheriting from this
module.

www.apache.org, www.perl.com.

=cut
