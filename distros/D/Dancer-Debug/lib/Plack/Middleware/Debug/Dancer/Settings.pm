package Plack::Middleware::Debug::Dancer::Settings;
BEGIN {
  $Plack::Middleware::Debug::Dancer::Settings::VERSION = '0.03';
}

# ABSTRACT: Settings panel of your Dancer's application

use strict;
use warnings;
use parent qw(Plack::Middleware::Debug::Base);
use Class::Method::Modifiers qw/install_modifier/;
use Dancer::Config;

sub run {
    my ( $self, $env, $panel ) = @_;

    return sub {
        my $res = shift;
        my $settings = Dancer::Config->settings();
        $panel->title('Dancer::Settings');
        $panel->nav_subtitle('Dancer::Settings');
        my @settings = map { $_ => $settings->{$_}} keys %$settings;
        $panel->content( sub { $self->render_list_pairs( \@settings ) } );
    };
}

1;


__END__
=pod

=head1 NAME

Plack::Middleware::Debug::Dancer::Settings - Settings panel of your Dancer's application

=head1 VERSION

version 0.03

=head1 SYNOPSIS

To activate this panel:

    plack_middlewares:
      Debug:
        - panels
        -
          - Dancer::Settings

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by franck cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

