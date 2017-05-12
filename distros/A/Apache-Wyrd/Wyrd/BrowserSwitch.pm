use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::BrowserSwitch;
our $VERSION = '0.98';
use base qw (Apache::Wyrd);

=pod

=head1 NAME

Apache::Wyrd::BrowserSwitch - Enclose a set of browser-versioned blocks

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

Encloses a set of Version wyrds for a browser-dependent section of HTML.

=head2 HTML ATTRIBUTES

NONE

=head2 FLAGS

NONE

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (scalar) C<_add_version> (void)

Internal method for Version wyrds to register themselves to their parent.

=cut

sub _add_version {
	my ($self, $version) = @_;
	$self->raise_exception('Only Apache::Wyrd::Version-derived objects should call _add_version()')
		unless UNIVERSAL::isa($version, 'Apache::Wyrd::Version');
	push @{$self->{'versions'}}, $version;
}

=pod

=back

=head1 BUGS/CAVEATS

Reserves the setup and _generate_output methods.

=cut

sub _setup {
	my ($self) = @_;
	$self->{'versions'} = [];
}

sub _generate_output {
	my ($self) = @_;
	my $agent = $self->dbl->req->headers_in->{'User-Agent'};
	my $out = '';
	foreach my $version (@{$self->{'versions'}}) {
		$out = $version->_data if ($version->match($agent));
	}
	$out ||= $self->_data;
	return $out;
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Version

Container for a browser-dependent version of a block of HTML

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;