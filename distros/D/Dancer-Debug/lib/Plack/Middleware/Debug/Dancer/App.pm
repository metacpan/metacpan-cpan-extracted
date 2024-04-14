package Plack::Middleware::Debug::Dancer::App;
$Plack::Middleware::Debug::Dancer::App::VERSION = '0.04';
use strict;
use warnings;

use parent qw/Plack::Middleware::Debug::Base/;
use Dancer::App;

sub run {
    my ( $self, $env, $panel ) = @_;

    return sub {
        my $applications;

        foreach my $app ( Dancer::App->applications ) {
            $applications->{ $app->{name} } = $app->{settings};
        }

        $panel->title('Applications');
        $panel->nav_title('Applications');
        $panel->content(
            sub { $self->render_hash( $applications, [ keys %$applications ] ) }
        );
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Debug::Dancer::App

=head1 VERSION

version 0.04

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by franck cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
