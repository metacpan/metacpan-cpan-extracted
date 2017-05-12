package Acme::PETEK::Testkit::modperl1;

use strict;
use vars qw($VERSION);

use Acme::PETEK::Testkit;
use Apache::Constants qw(OK);
use Apache::Request;

=head1 NAME

Acme::PETEK::Testkit::modperl1 - mod_perl 1 handler for Tester's Toolkit

=head1 VERSION

Version 1.00

=cut

$VERSION = '1.00';

=head1 SYNOPSIS

This Perl module is intended to be a collection of sample code for
the Tester's Toolkit presentation at YAPC::NA 2005 by the author.

=cut

=head1 HANDLER

=head2 handler($r)

Called by Apache.

=cut

sub handler {
	my $r = Apache::Request->new(shift);

	my $val = $r->param('value') || 0;
	my $dec = $r->param('decrval') || 1;
	my $inc = $r->param('incrval') || 1;

	my $t = Acme::PETEK::Testkit->new();
	if (valid_int($val)) {
		$t->reset($val);
	}

	if ($r->param('decrn') && valid_int($dec)) {
		$t->decr($dec);
	}
	elsif ($r->param('decr1')) {
		$t->decr;
	} 
	elsif ($r->param('reset')) {
		$t->reset;
	}
	elsif ($r->param('incr1')) {
		$t->incr;
	}
	elsif ($r->param('incrn') && valid_int($inc)) {
		$t->incr($inc);
	}

	$r->send_http_header('text/html');
	$r->print(gen_page($t->value));

	return OK;
}

=head1 HANDLER HELPERS

=head2 gen_page($value)

Generates the page HTML with a given value.

=cut

sub gen_page {
	my $value = shift;

	return <<HTML;
<html><head><title>Counter: $value</title></head>
<body><form method="post"><input type="hidden" name="cur" value="$value">
<div align="center">
	<p><big>Current Value: <u>$value</u></big></p>
	<p><input type="text" name="decrval" value="1" size="3" maxlength="3"
		/><input type="submit" name="decrn" value="&lt;&lt;"
		/><input type="submit" name="decr1" value="&lt;"
		/><input type="submit" name="reset" value="-0-" 
		/><input type="submit" name="incr1" value="&gt;"
		/><input type="submit" name="incrn" value="&gt;&gt;"
		/><input type="text" name="incrval" value="1" size="3" maxlength="3"
		/></p>
</div>
</body></html>
HTML
}

=head2 valid_int

Returns true if the supplied argument is a valid integer.

=cut

sub valid_int {
	my $int = shift;
	return 1 if $int =~ /^-?\d+$/;
	return;
}

=head1 AUTHOR

Pete Krawczyk, C<< <petek@cpan.org> >>

=head1 BUGS

Fix 'em yourself! :-)

=head1 ALSO SEE

Slides from the presentation are available at L<http://www.bsod.net/~petek/slides/>.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Pete Krawczyk, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This library has also been released under a Creative Commons license
at the request of the YAPC::NA 2005 organizers. See
L<http://creativecommons.org/licenses/by/2.0/ca/> for more information;
in short, please give credit to the author should you use this code
elsewhere.
=cut

1; # End of Acme::PETEK::Testkit::modperl1
