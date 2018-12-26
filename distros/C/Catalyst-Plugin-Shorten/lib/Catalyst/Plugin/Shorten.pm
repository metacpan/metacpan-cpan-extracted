package Catalyst::Plugin::Shorten;
use 5.006; use strict; use warnings; our $VERSION = '0.04';

use Bijection qw/all/;
use Scalar::Util qw/reftype/;
use Carp;

our ($pkey, $ukey, $short);

sub setup {
	my $c = shift;

	my $config = $c->config->{'Plugin::Shorten'};

	if ($config->{set}) {
		$c->shorten_bijection_set(@{$config->{set}});
	}

	if ($config->{offset}) {
		$c->shorten_offset_set($config->{offset});
	}

	$pkey = $config->{map}->{params} || 'params';
	$ukey = $config->{map}->{uri} || 'uri';
	$short = $config->{map}->{s} || 's';

	1;
}

sub shorten {
	my ($c, %args) = @_;

	my $id = $c->shorten_set_data(
		($args{uri}
			? (
				$ukey => $args{uri},
				$pkey => $args{uri}->query_form_hash
			)
			: (
				$ukey => $c->req->uri,
				$pkey => $c->req->params,
			)
		),
		($args{store} ? %{$args{store}} : ())
	);

	my $string = biject($id);
	return $args{as_uri}
		? $args{uri}
			? do { $args{uri}->query_form($short => $string); $args{uri} }
			: $c->uri_for_action($c->action->private_path, { $short => $string })
		: $string;
}

sub shorten_delete {
	my ($c, %args) = @_;

	if (!$args{$short}) {
		unless ($args{$short} = $c->req->param($short)) {
			Catalyst::Exception->throw(sprintf 'Unable to find %s to delete', $short);
		}
	}

	my $id = inverse($args{$short});
	return $c->shorten_delete_data($id);
}

sub shorten_extract {
	my ($c, %args) = @_;

	$args{params} = $c->req->params unless $args{params}; # 100% the conditionals, ||= would always be true :)
	$args{allow_missing} = 1;
	if (my $sparams = $c->shorten_params(%args)) {
		delete $args{params}->{$short};
		$sparams = {%{$sparams}, %{$args{params}}} unless $args{no_merge};
		$c->req->parameters($sparams);
	}

	1;
}
use Data::Dumper;
sub shorten_params {
	my ($c, %args) = @_;
	$args{params} = $c->req->params || {} unless $args{params};
	if ($args{params}->{$short}) {
		my $id = inverse($args{params}->{$short});
		my $shorten = $c->shorten_get_data($id);
		if (exists $args{cb}) {
			$shorten = $args{cb}->($c, $shorten);
		}
		return $shorten->{$pkey} if $shorten; # reftype for blessed
		Catalyst::Exception->throw(sprintf 'Unable to find params for: %s -> %s : %s',
			$args{params}->{$short}, $id, $pkey);
	}
	Catalyst::Exception->throw(sprintf 'Unable to find short in params for: %s', $short)
			unless ( $args{allow_missing} );
	undef;
}

sub shorten_redirect {
	my ($c, %args) = @_;
	my $id = inverse($args{$short});
	my $shorten = $c->shorten_get_data($id);
	if (exists $args{cb}) {
		$shorten = $args{cb}->($c, $shorten);
	}
	return $c->res->redirect($shorten->{$ukey}) if $shorten;
	Catalyst::Exception->throw(sprintf 'Unable to find uri to redirect for: %s -> %s', $args{$short}, $id);
}

sub shorten_bijection_set {
	my ($c, @set) = @_;
	bijection_set(@set);
}

sub shorten_offset_set {
	my ($c, @set) = @_;
	offset_set(@set);
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Shorten - The great ancient URI shortner!

=for html
<a href="https://travis-ci.org/ThisUsedToBeAnEmail/Catalyst-Plugin-Shorten"><img src="https://travis-ci.org/ThisUsedToBeAnEmail/Catalyst-Plugin-Shorten.svg?branch=master" alt="Build Status"></a>
<a href="https://coveralls.io/r/ThisUsedToBeAnEmail/Catalyst-Plugin-Shorten?branch=master"><img src="https://coveralls.io/repos/ThisUsedToBeAnEmail/Catalyst-Plugin-Shorten/badge.svg?branch=master" alt="Coverage Status"></a>
<a href="https://metacpan.org/pod/Catalyst-Plugin-Shorten"><img src="https://badge.fury.io/pl/Catalyst-Plugin-Shorten.svg" alt="CPAN version"></a>

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	use Catalyst qw/
		Shorten
		Shorten::Store::Dummy
	/;

	sub auto :Path :Args(0) {
		my ($self, $c) = @_;
		$c->shorten_extract; # checks whether the shorten param exists if it does merges the stored params into the request
	}

	........

	sub endpoint :Chained('base') :PathPart('ending') :Args('0') {
		my ($self, $c) = @_;

		my $str = $c->shorten(); # returns bijection references to an ID in the store.
		my $url = $c->shorten(as_uri => 1); # return a url to the current endpoint replacing all params with localhost:300/ending?s=GH
	}

	-------

	use Catalyst qw/
		Shorten
		Shorten::Store::Dummy
	/;

	__PACKAGE__->config(
		......
		'Plugin::Shorten' => {
			set => [qw/c b a ..../],
			map => {
				params => 'data',
				uri => 'url',
				s => 'g'
			}
		}
	);

	package TestApp::Controller::Shorten;

	use Moose;
	use namespace::autoclean;

	BEGIN {
		extends 'Catalyst::Controller';
	}

	sub g :Chained('/') :PathPart('g') :Args('1') {
		my ($self, $c, $cap) = @_;
		$c->shorten_redirect(g => $cap);
	}

	__PACKAGE__->meta->make_immutable;

	1;

=head1 SUBROUTINES/METHODS

=head2 shorten (as_uri => 1|0, uri => URI, store => {} )

Take the current request uri and store, returns an Bijective string.

=cut

=head2 shorten_delete (s => '')

Delete from storage.

=cut

=head2 shorten_extract (params => { s => ...}, cb => sub)

Check for the param (default is 's'), if defined attempt to inverse and then right merge with the current requests params.

This always returns true and you can later access the merged params using -

	$c->req->params;

=cut

=head2 shorten_params (params => { s => ...}, cb => sub)

Check for the param (default is 's'), if defined attempt to inverse and then return the params retrieved from storage.

=cut

=head2 shorten_redirect (s => '', cb => sub)

Redirect the clients browser to the uri retrieved from the storage.

=cut

=head2 shorten_bijection_set (@set)

=cut

=head2 shorten_offset_set ($offset)

=cut

=head2 setup

=cut

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-plugin-shorten at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-Shorten>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::Shorten


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-Shorten>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-Shorten>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-Shorten>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-Shorten/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 LNATION.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Catalyst::Plugin::Shorten
