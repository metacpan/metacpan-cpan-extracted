use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Version;
our $VERSION = '0.98';
use base qw (Apache::Wyrd);
use Apache::Wyrd::Services::SAK qw(token_parse);

=pod

=head1 NAME

Apache::Wyrd::Version - Designate a block for certain classes of browsers

=head1 SYNOPSIS

  <BASENAME::BrowserSwitch>
    <BASENAME::Version test="IE">
      .. version for MSIE ..
    </BASENAME::VERSION>
    <BASENAME::Version tests="Gecko, Safari">
      .. version for NS & Safari ..
    </BASENAME::VERSION>
    <BASENAME::Version test="Lynx">
      .. version for Lynx ..
    </BASENAME::VERSION>
    <BASENAME::Version test="Google" matchstring="Googlebot">
      .. version for Google ..
    </BASENAME::VERSION>
  </BASENAME::BrowserSwitch>

=head1 DESCRIPTION

A sub-wyrd of BrowserSwitch which delineates a version of a section of HTML
which must be rendered differently for different browsers.

=head2 HTML ATTRIBUTES

=over

=item test

The browser type the enclosed HTML is targeted to.  Builtin tests are ie,
gecko, safari, and lynx.  Case is not sensitive.

=item tests

An alias for test.

=item matchstring

If you are targeting one of the other browsers, this attribute provides a
substring which will be checked against the User-Agent string of the
browser.

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (scalar) C<match> (scalar)

Does the work of matching the browser type to the given version.  Returns a 1
if the browser is targeted by this version.

=cut

sub match {
	my ($self, $agent) = @_;
	if ($self->{'matchstring'}) {
		my $safestring = $self->{'matchstring'};
		$safestring =~ s/[^A-Za-z0-9\/;.]//g;
		return 1 if ($agent=~/$safestring/i);
	}
	my @tests = token_parse ($self->{'tests'} || $self->{'test'});
	my $ok = 1;
	foreach my $test (@tests) {
		$ok = 0 unless $self->_test(lc($test), $agent);
	}
	return $ok;
}

=item (scalar) C<_test> (scalar, scalar)

Internal method for comparing user-agent strings to test values.  Provides the
builtin tests.

=cut

sub _test {
	my ($self, $test, $agent) = @_;
	if ($test eq 'ie') {
		return 1 if ($agent =~ /MSIE/i);
		return 0;
	}
	if ($test eq 'ms') {
		return 1 if ($agent =~ /MSIE/i);
		return 0;
	}
	if ($test eq 'gecko') {
		return 1 if ($agent =~ /Gecko/i);
		return 0;
	}
	if ($test eq 'safari') {
		return 1 if ($agent =~ /Safari/i);
		return 0;
	}
	if ($test eq 'lynx') {
		return 1 if ($agent =~ /Lynx/i);
		return 0;
	}
	$self->_error("Test $test not defined");
	return 0;
}

=pod

=back

=head1 BUGS/CAVEATS

Reserves the _setup and _generate_output methods.

=cut

sub _setup {
	my ($self) = @_;
	$self->_raise_exception("Apache::Wyrd::Version objects belong in a Apache::Wyrd::BrowserSwitch Container.")
		unless (UNIVERSAL::can($self->_parent, '_add_version'));
	$self->_parent->_add_version($self);
}

sub _generate_output {
	return '';
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::BrowserSwitch

 Enclose a set of browser-versioned blocks

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;