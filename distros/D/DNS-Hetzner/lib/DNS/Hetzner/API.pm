package DNS::Hetzner::API;

use Moo::Role;

use Mojo::Base -strict, -signatures;
use Mojo::File;
use Mojo::Util qw(decamelize);

use Module::Runtime qw(require_module);

sub load_namespace ($package) {
    my $files = Mojo::File->new(
        __FILE__
    )->dirname->child('API')->list->each( sub {
        my $base = $_->basename;
        return if '.pm' ne substr $base, -3;

        $base =~ s{\.pm\z}{};
        my $module = $package . '::API::' . $base;

        require_module $module;

        no strict 'refs';
        *{ $package . '::' . decamelize( $base ) } = sub ($cloud) {
            my $object = $module->instance(
                token    => $cloud->token,
                base_uri => $cloud->base_uri,
                client   => $cloud->client,
            );

            return $object;
        };
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::Hetzner::API

=head1 VERSION

version 0.01

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
