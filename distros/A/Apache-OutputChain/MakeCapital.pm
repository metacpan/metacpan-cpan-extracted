
=head1 NAME

Apache::MakeCapital - convert server output to uppercase

=cut

package Apache::MakeCapital;
use strict;
use Apache::OutputChain;
use vars qw( @ISA );
@ISA = qw( Apache::OutputChain );
sub handler
	{
	my $r = shift;
	Apache::OutputChain::handler($r, __PACKAGE__);
	}

sub PRINT
	{
	shift->Apache::OutputChain::PRINT(uc join '', @_);
	}
1;

=head1 SYNOPSIS

In the conf/access.conf file of your Apache installation, add lines
like

	<Files *.html>
	SetHandler perl-script
	PerlHandler Apache::OutputChain Apache::MakeCapital Apache::PassHtml
	</Files>

=head1 DESCRIPTION

This is a module to show the use of module B<Apache::OutputChain>.
The function I<handler> simply inserts this module into the chain,
calling

	Apache::OutputChain::handler($r, __PACKAGE__);

This is the initialization stage. The second parameter in the call to
I<Apache::OutputChain::handler> must be a name of this class, so that
B<Apache::OutputChain> will know, whom to put into the chain.

The package also must define function I<PRINT>, that will be called in
the chain. In this example, it capitalized all output being sent. It
will mess up the links (A HREF's) so is really just for illustration ;-)

=head1 AUTHOR

(c) 1997--1998 Jan Pazdziora, adelton@fi.muni.cz,
http://www.fi.muni.cz/~adelton/ at Faculty of Informatics, Masaryk
University, Brno, Czech Republic

=cut
