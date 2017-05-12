package Plack::Middleware::Debug::Dancer::Version;
BEGIN {
  $Plack::Middleware::Debug::Dancer::Version::VERSION = '0.03';
}

# ABSTRACT: Show Dancer's version

use strict;
use warnings;
use parent qw(Plack::Middleware::Debug::Base);

sub run {
    my ( $self, $env, $panel ) = @_;

    return sub {
        $panel->title('Dancer::Version');
        $panel->nav_title('Dancer::Version');
        $panel->nav_subtitle($Dancer::VERSION);
    };
}

1;


__END__
=pod

=head1 NAME

Plack::Middleware::Debug::Dancer::Version - Show Dancer's version

=head1 VERSION

version 0.03

=head1 SYNOPSIS

To activate this panel:

    plack_middlewares:
      Debug:
        - panels
        -
          - Dancer::Version

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by franck cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

