package CGI::HTMLError;

use strict;

use vars qw($VERSION %CONF $CSS $OLD_HANDLER);

BEGIN {
	$VERSION = '1.00';
	$CONF{trace} = 0;
}

$CSS = '<style type="text/css">
body {
	background-color: white;
	color: black;
}
pre {
	background-color:	#ffffe0;
}
strong {
	color:	red;
}
.region {
	color: #404040;
}
</style>
';

sub import {
	shift @_;
	return unless $ENV{GATEWAY_INTERFACE} and $ENV{GATEWAY_INTERFACE} =~ /CGI/;
	%CONF = ( %CONF, @_ );
	$OLD_HANDLER = $SIG{__DIE__} if defined $SIG{__DIE__} and $SIG{__DIE__} ne 'IGNORE' and $SIG{__DIE__} ne 'DEFAULT';
	$SIG{__DIE__} = \ &show_source;
}

sub show_source {


	#
	# First we try to establish if this exception might yet be cought.
	# we try to do this by examining the stack trace for (eval) frames
	#
	# In a case of a fatal error inside an eval, this code gets 
	# called twice: the first time with the (eval) frame, the
	# second time without. 
	#

	my $i;
	my ($filename_from_stack,$number_from_stack);
	while (1) {
		my @caller = caller($i++);
		if (defined $caller[3]) {
			$filename_from_stack ||= $caller[1];
			$number_from_stack   ||= $caller[2];
			return if $caller[3] eq '(eval)';
		}
		else {
			last;
		}
	}


	#
	# now get the error string (we ignore exception objects, and just
	# pray they will be stringified to a useful string)
	#

	my ($error) = @_;

	my ($filename,$number,$rest_of_error);
	if ($error =~ s/^(.*?\s+at\s+(.*?)\s+line\s+(\d+)[^\n]*)//s) {
		$rest_of_error = $error;
		$error = $1;
		$filename = $2;
		$number = $3;
	}


	#
	# If we haven't found the file and line in the string, just use
	# the one found in the stack-trace.
	# 

	unless ($filename) {
		$filename = $filename_from_stack;
		$number = $number_from_stack;
		$rest_of_error .= "Exception caused at $filename line $number";
	}



	#
	# use the default css section or a link to another stylesheet
	#

	my $css = $CONF{css} ? "<link rel='stylesheet' type='text/css' href='$CONF{css}'>" : $CSS;


	#
	# Setting status header and title..
	# 

	encode($error, $rest_of_error);
	

	print "Status: 500 Server Error
Content-type: text/html

<html><head><title>500 Internal Server Error</title>
$css
</head>
<body>
<h2>500 Internal Server Error</h2>
<hr>
<strong>$error</strong>$rest_of_error<br>
<hr>
";

	if ($filename and $number) {

	#
	# try to open the sourcefile where the error occured,
	# fastforward to the apropiate line and print the section
	#

		if ( open SOURCE,"< $filename" ) {
			my $startline = $number - 10 >= 0 ? $number - 10 : 0;
			my $endline = $startline + 20;
			print '<em>Source:</em><pre><code>';
			print "....\n" if ($startline > 1);
			while (<SOURCE>) {
				last if $. > $endline;
				chomp;
				if ($. > $startline) {
					encode($_);
					if ($. == $number) {
						$_ = "<strong>$_</strong>";
					}
						elsif ($. > $number - 5 and $. < $number + 5) {
						$_ = "<span class='region'>$_</span>";
					}
					printf "%04d| %s\n",$.,$_;
				}
			}
			print '....' if not eof SOURCE;
			close SOURCE;
			print "</code></pre>";
		}
		else {
			print "<em>Could not open $filename: $!</em>";
		}
	}
	else {
		print "<em>No filename or line number found in the error message</em>";
	}

	#
	# show stacktrace if a tracelevel is specified.
	#

	if ($CONF{trace}) {
		print '<hr><em>Stacktrace:</em><pre><code>';
		my $i;
		while (1) {
			my ($pack,$file,$number,$sub) = caller($i) or last;
			printf "%02d| \&$sub called at $file line $number\n",$i++;
		}
		print '</code></pre>';
	}

	#
	# end with a version identifier.
	#

	print "<hr><div align=right><em>CGI::HTMLError $VERSION</em></div></body></html>";

	if ($OLD_HANDLER) {
		$SIG{__DIE__} = $OLD_HANDLER;
		goto &$OLD_HANDLER;
	}
}

sub encode {
	for (@_) {
		s/</&lt;/g;
		s/>/&gt;/g;
		s/\n/<br>\n/g;
	}
}
	
1;
__END__

=head1 NAME

CGI::HTMLError - Perl extension for reporting fatal errors to the browser

=head1 SYNOPSIS

  use CGI::HTMLError;

  die "Error!"; # throw runtime error

  # or ..

  use CGI::HTMLError trace => 1, css => '/css/error.css';

  10 = 40; # redefine the number system (compile error).

=head1 DESCRIPTION

This module is supposed to be a debugging tool for CGI programmers. If C<use>'d in a program it will send nice looking fatal errors to the browser including a view of the offending source and an optional stacktrace.

You can supply options to the module by supplying name => value pairs to the C<use> statement. Currently there are 2 options:

=over 4

=item trace

If true, show the stacktrace on the error page.

=item css

The URL of a stylesheet to use in the error page instead of the standard style.

=back

=head1 SECURITY ALERT

B<Do not use this module in a production environment!> Exposing the weaknesses of your program is very useful for the programmer when debugging, but it doesn't help to advertise them to every person wandering on the net.

=head2 EXPORT

This module does not export anything in the usual sense: it installs a C<$SIG{__DIE__}> handler instead. See also L</GOTCHAS>

=head1 GOTCHAS

=over 4

=item Finding the right filename and line number

By default, C<CGI::HTMLError> expects the filename and line number to be in the error message handed to the handler (normally this is $@). This gives application writers the chance to point to another file as the actual cause of the problem (for instance, using C<Carp>). However, when no filename and line number are found in the error message, the module will try to get the information from C<caller(0)>.

If no filename can be found, only the error message and the optional stacktrace will be shown.

=item Security

B<Do not use this in a production environment!> This code is strictly for debugging. Read the L<SECURITY ALERT> secion.

=item Other DIE handlers

The $SIG{__DIE__} handler installed by this program will attempt to call earlier installed $SIG{__DIE__} handlers after its own. Some other modules (i.e. C<CGI::Carp>) do not do this, if so try using C<CGI::HTMLError> after the other module has installed its handler. See also L</CGI::Carp>

=item CGI::Carp

If you use CGI::Carp and CGI::HTMLError, you MUST C<use CGI::Carp> before this module in order to get them both working together.

	use CGI::Carp qw(croak);
	use CGI::HTMLError trace => 1;

This program also will not play nice when combined with C<CGI::Carp qw(-fatalsToBrowser)>, but it's meant as a replacement anyway, so I don't think that will be much of a problem.

Other uses of CGI::Carp should still be working as usual. See also L</Other DIE handlers>.

=item Catching exceptions

The installed handler will attempt to detect if it is called during C<eval> by walking the caller stack and testing for an c<(eval)> frame, so programs can still use the c<eval { die () }> constructs to catch exeptions.

Because the stack has to tested for every exception, using this module in code that makes a lot of use of C<eval { die() }> constructs will probably slow the program down.

=item mod_perl

Module is not written for, or tested with, mod_perl, but it I<should> work if run under C<Apache::Registry>.

=item Conflicting output

If the offending code already has output sent to the browser, the results might look horrible. Solution: gather the output before sending it or use a templating mechinism that does this for you.

=item Running outside a CGI environment

CGI::HTMLError checks the GATEWAY_INTERFACE environment variable to see whether to actually print HTML code. It assumes a CGI environment when C<$ENV{GATEWAY_INTERFACE} =~ /CGI/> (which will also be true under C<Apache::Registry>). Otherwise the handler will not be installed. This is meant as a feature, especially when running CGI programs from the command line.

=back

=head1 AUTHOR

Joost Diepenmaat E<lt>jdiepen@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2002 - 2005 Joost Diepenmaat

This module is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>. L<CGI>, L<CGI::Carp>, L<Carp>, L<Apache::Registry> and L<perlfunc/die>.

=cut

