package Plack::Middleware::Debug::Dancer::Session;
BEGIN {
  $Plack::Middleware::Debug::Dancer::Session::VERSION = '0.03';
}

# ABSTRACT: Session panel for your Dancer's application

use strict;
use warnings;
use parent qw(Plack::Middleware::Debug::Base);
use Dancer::Session;

sub run {
    my ( $self, $env, $panel ) = @_;

    return sub {
        my $session = Dancer::Session->get();
        my @settings = map { $_ => $session->{$_}} keys %$session;
        $panel->title('Dancer::Session');
        $panel->nav_subtitle("Dancer::Session");
        $panel->content( sub { $self->render_list_pairs( \@settings ) } );
    };
}

1;


__END__
=pod

=head1 NAME

Plack::Middleware::Debug::Dancer::Session - Session panel for your Dancer's application

=head1 VERSION

version 0.03

=head1 SYNOPSIS

To activate this panel:

    plack_middlewares:
      Debug:
        - panels
        -
          - Dancer::Session

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by franck cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

