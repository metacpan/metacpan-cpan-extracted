package Dancer2::Plugin::Routing;

use 5.10.0;
use strict;
use warnings;
use Dancer2::Plugin;
use Ref::Util qw/is_hashref/;
use base qw/Dancer2::Plugin::RootURIFor/;

=head1 NAME

Dancer2::Plugin::Routing - A dancer2 plugin for configurable routing.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

my ( $_settings, $_routings, $_packages ) = undef;

# -----------------------------------------------
# Preloaded methods go here.
# -----------------------------------------------
# Encapsulated class data.

{

    sub _load_settings {
        return $_settings if $_settings;
        $_settings = plugin_setting;
        return $_settings;
    }

    sub _routings {
        return $_routings if $_routings;
        my $stg = _load_settings->{routes};
        $_routings->{$_} = is_hashref $stg->{$_} && $stg->{$_}->{route} ? $stg->{$_}->{route} : $stg->{$_} foreach keys %$stg;
        return $_routings;
    }

    sub _packages {
        return $_packages if $_packages;
        my $stg = _load_settings->{routes};
        foreach ( keys %$stg ) {
            next if ( !is_hashref $stg->{$_} || !$stg->{$_}->{package} );
            $_packages->{$_} = $stg->{$_}->{package};
        }
        return $_packages;
    }

    sub _routing_for {
        return undef unless $_[1];
        return _routings->{ $_[1] };
    }

    sub _package_for {
        return undef unless $_[1];
        my $packages = _packages();
        return $packages->{ $_[1] } if $packages;
    }

    sub _redirect {
        my $dsl = shift;
        return $dsl->app->redirect( $dsl->SUPER::root_uri_for(@_) );
    }
}

=head1 SUBROUTINES/METHODS

=head2 routing_for

Get route from a given route key

=cut

register routing_for => \&_routing_for;

=head2 package_for

Get package name from a given route key

=cut

register package_for => \&_package_for;

=head2 routings

Returns a list of all configured routes to mount

=cut

register routings => \&_routings;

=head2 packages

Returns a list of all configured packages to mount

=cut

register packages => \&_packages;

=head2 root_redirect

overloaded sub to redirect to root uri from
C<Dancer2::Plugin::RootURIFor>

=cut

register root_redirect => \&_redirect;

on_plugin_import {
    $_[0]->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before_template',
            code => sub {
                my $key = _load_settings()->{template_key};
                $_[0]->{$key} = \%{ _routings() };
                $_ =~ s~^/$~~ig foreach ( values %{ $_[0]->{$key} } );
            }
        )
    );
};

register_plugin for_versions => [2];

1;

__END__

=head1 SYNOPSIS

Configuration:

    plugins:
        Routing:
            template_key: routing
            routes:
                main:
                  route: '/'
                  package: MyApp
                api:
                  route: '/api'
                  package: MyApp::API
                moderation:
                  route: '/mod'
                  package: MyApp::Moderation
                admin: '/~admin'
                assets:
                  route: '/assets'
                  package:  MyApp::Assets
Code:

    use Dancer2;
    use Dancer2::Plugin::Routing;
    use Plack::Builder;
    use MyApp;
    ...
    builder {
        mount routing_for('main')       => MyApp->to_app             if mount routing_for('main');
        mount routing_for('api')        => MyApp::API->to_app        if mount routing_for('api');
        mount routing_for('moderation') => MyApp::Moderation->to_app if mount routing_for('moderation');
        mount routing_for('admin')      => MyApp::Admin->to_app      if mount routing_for('admin');
        mount routing_for('assets')     => MyApp::Assets->to_app     if mount routing_for('assets');
    };

    ...

    use Dancer2;
    use Dancer2::Plugin::Routing;

    get '/do/stuff' => sub {
        return root_redirect '/';
    };

Template:

    <a href="[% routing.admin %]/page">To some admin page</a>


=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer2-plugin-routing at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-Routing>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::Routing


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer2-Plugin-Routing>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer2-Plugin-Routing>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Plugin-Routing>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer2-Plugin-Routing/>

=back

=head1 SEE ALSO
 
The L<Plack::Builder> used to mount different routes.

The L<Dancer2> framework which is the plugin written for.
 
The L<Dancer2::Plugin::RootURIFor> is used for some functionalities.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Mario Zieschang.

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
