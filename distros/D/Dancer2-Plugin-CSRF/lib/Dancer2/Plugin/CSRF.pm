package Dancer2::Plugin::CSRF;
use 5.010;
use strict;
use warnings;

our $VERSION = '1.01';

use Dancer2::Plugin;
use Crypt::SaltedHash;
use Data::UUID;

my $HASHER = Crypt::SaltedHash->new( algorithm => 'SHA-1' );
my $UUID = Data::UUID->new();

has session_key_name => (
	is      => 'ro',
	default => sub {
		$_[0]->config->{session_key_name} || 'plugin.csrf';
	}
);

plugin_keywords qw( get_csrf_token validate_csrf_token );

sub get_csrf_token {
	my ($self) = @_;
	my $config = $self->dsl->session( $self->session_key_name() );
	unless ($config) {
		$config = { token => $UUID->create_str(), };
		$self->dsl->session( $self->session_key_name() => $config );
	}

	( my $path = $self->dsl->request->dispatch_path ) =~ s{^/}{};
	my $form_url = $self->dsl->request->base . $path;
	my $token = $HASHER->add( $config->{token}, $form_url )->generate();
	$HASHER->clear();
	return $token;
}

sub validate_csrf_token {
	my ( $self, $got_token ) = @_;
	my $form_url = $self->dsl->request->header('referer');
	my $config = $self->dsl->session( $self->session_key_name() ) // return;
	my $expected_token
		= $HASHER->add( $config->{token}, $form_url )->generate();
	$HASHER->clear();
	return $expected_token eq $got_token;
}

1;

__END__

=head1 NAME

Dancer2::Plugin::CSRF - CSRF tokens generation and validation

=head1 VERSION

Version 1.0

=head1 SYNOPSIS

  use Dancer2::Plugin::CSRF;

	hook before => sub {
		# ..
		if ( request->is_post() ) {
			my $csrf_token = param('csrf_token');
			if ( !$csrf_token || !validate_csrf_token($csrf_token) ) {
				redirect '/?error=invalid_csrf_token';
			}
			# ...
		}
	};

	get '/someform' => sub {
		template 'someform',
			{
			csrf_token => get_csrf_token(),
			};
	};

=head1 DESCRIPTION

This module provides two methods C<get_csrf_token()> and C<validate_csrf_token($token)>.

Master token stored in session.
CSRF tokens generated using master token and page uri.

=head1 CONFIGURATION

Configuration can be done in your L<Dancer2> config file.
It requires no configuration, but you can change a key name (in session) for master token.

    plugins:
      CSRF:
        session_key_name: 'plugin.csrf'

=head1 SUBROUTINES/METHODS

=head2 get_csrf_token

Generates csrf token for a current page, returns it.

=head2 validate_csrf_token

Validates passed csrf token for a form page, returns true if token is valid.

=head1 AUTHOR

Oleg Nurtdinov, C<< <jumpercc at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer2-plugin-csrf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-CSRF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::CSRF


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer2-Plugin-CSRF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer2-Plugin-CSRF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Plugin-CSRF>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer2-Plugin-CSRF/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Oleg Nurtdinov.

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
