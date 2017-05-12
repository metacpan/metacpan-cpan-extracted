package Dancer2::Plugin::Flash;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Dancer2::Plugin;

=head1 NAME

Dancer2::Plugin::Flash - flash message for Dancer2

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.03';

=head1 CONFIGURATION

Configuration requires a secret key at a minimum.

Either put this in your F<config.yml> file:

    plugins:
      Flash:
        token_name: 'flash'
        session_hash_key: '_flash'

Or set the secret key at run time, with:

    BEGIN {
        set plugins => {
            Flash => {
                token_name => 'flash',
                session_hash_key => '_flash'
            },
        };
    }

=cut

has token_name => (
    is => 'ro',
    default => sub {
    	my ( $self ) = @_;
        return $self->config->{token_name} || 'flash';
    }
);

has session_hash_key => (
    is => 'ro',
    default => sub {
    	my ( $self ) = @_;
        return $self->config->{session_hash_key} || '_flash';
    }
);

sub BUILD {
	my $plugin = shift;

	$plugin->app->add_hook( Dancer2::Core::Hook->new(
		name => 'before_template_render',
		code => sub {
			my $tokens = shift;
			my $session = $plugin->app->session;
			my $flash = $session->read( $plugin->session_hash_key ) || {};
			# Assign it to template
			$tokens->{ $plugin->token_name } = $flash;
			# Remove from session
			$session->write( $plugin->session_hash_key, {} );
		}
	));
}

=head1 DESCRIPTION

A flash is session data with a specific life cycle. When you put something into the flash it stays then until the end of the next request. This allows you to use it for storing messages that can be accessed after a redirect, but then are automatically cleaned up.

=head1 SYNOPSIS

    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::Flash;

    BEGIN {
        set plugins => {
            Flash => {
                token_name => 'flash',
                session_hash_key => '_flash'
            },
        };
    }

    get '/different' => sub {
        flash(error => 'plop');
        template 'index', { foo => 'bar' };
    };

=head1 SUBROUTINES/METHODS

=head2 flash

C<flash(KEY, VALUE)> - Store the give key and valye and send it to template temporary.

=cut

plugin_keywords 'flash';

sub flash {
	my( $plugin, $key, $value ) = @_;

	return unless $key;

	if (   $plugin->app->request
		&& $plugin->app->session )
	{
		my $session = $plugin->app->session;
		my $flash   = $session->read( $plugin->session_hash_key ) || {};

		$flash->{$key} = $value || '';
		$session->write( $plugin->session_hash_key, $flash );
		return $value;
	}
	return;
}

=head1 AUTHOR

Rakesh Kumar Shardiwal, C<< <rakesh.shardiwal at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer2-plugin-flash at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-Flash>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::Flash


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer2-Plugin-Flash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer2-Plugin-Flash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Plugin-Flash>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer2-Plugin-Flash/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Rakesh Kumar Shardiwal.

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

1; # End of Dancer2::Plugin::Flash
