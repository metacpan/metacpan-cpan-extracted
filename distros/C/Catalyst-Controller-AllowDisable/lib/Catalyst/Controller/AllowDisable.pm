package Catalyst::Controller::AllowDisable;

use warnings;
use strict;

our $VERSION = '0.08';

use base qw/Catalyst::Controller/;
use strict;
use warnings;

sub new {
    my $class = shift;
    my ($app) = @_;
    my $self = $class->next::method(@_);

    if ( $app->config->{on_controller_disable} ) {
        return bless {}, 'Catalyst::Controller::AllowDisable::Disabled';
    }

    return $self;
}

1;

=head1 NAME

Catalyst::Controller::AllowDisable - DEPRECATED.

=head1 WARNINGS

this module is DEPRECATED.

because equivalent mechanism is supported on Catalyst.
http://lumberjaph.net/blog/index.php/2009/06/25/how-to-prevent-some-components-to-be-loaded-by-catalyst/

=head1 SYNOPSIS

    Package App::Web::Controller::Devel;

    use base qw/Catalyst::Controller::AllowDisable/;

    sub make_10000_users : Local {

    }

    1;


myapp.yml

 on_controller_disable:1


=head1 DESCRIPTION

I sometime create controller only for developers which I do not want to ship it to production but I do not want to remove it also. So I create this controller module. You can disable controller which using this module using on_controller_disable=1 at config.

=head1 METHOD

=head2 new

=head1 AUTHOR

Tomohiro Teranishi, C<< <tomohiro.teranishi at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Tomohiro Teranishi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

