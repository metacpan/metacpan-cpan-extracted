package DNS::Hetzner::API;

use Moo::Role;

use Mojo::Base -strict, -signatures;
use Mojo::File;
use Mojo::Loader qw(find_modules load_class);
use Mojo::Util qw(decamelize);

our $VERSION = '0.02';

sub load_namespace ($package) {
    my @modules = find_modules $package . '::API', { recursive => 1 };

    for my $module ( @modules ) {
        load_class( $module );

        my $base = (split /::/, $module)[-1];
    
        no strict 'refs';
        *{ $package . '::' . decamelize( $base ) } = sub ($dns) {
            state $object //= $module->instance(
                token    => $dns->token,
                base_uri => $dns->base_uri,
                client   => $dns->client,
            );

            return $object;
        };
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::Hetzner::API

=head1 VERSION

version 0.02

=head1 METHODS

=head2 load_namespace

Loads all DNS::Hetzner::API::* modules.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
