use strict;
use warnings;

use File::Find qw(find);
use Test2::V0;
use Alien::ngtcp2;

if (Alien::ngtcp2->install_type ne 'share') {
    plan skip_all => 'core-only artifact check applies to share builds';
}

my $dist_dir = Alien::ngtcp2->dist_dir;
my @crypto_helpers;

find(
    {
        no_chdir => 1,
        wanted   => sub {
            my ($name) = $_ =~ m{([^/\\]+)\z};

            return unless defined $name;
            return unless $name =~ /^libngtcp2_crypto_/;

            push @crypto_helpers, $File::Find::name;
        },
    },
    $dist_dir,
);

is(
    \@crypto_helpers,
    [],
    'share build contains no ngtcp2 crypto helper artifacts',
);

done_testing;
