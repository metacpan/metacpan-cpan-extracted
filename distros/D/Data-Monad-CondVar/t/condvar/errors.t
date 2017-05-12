use strict;
use warnings;
use AnyEvent;
use Data::Monad::CondVar;
use Test::More;

my $cv = do {
    my $cv = AE::cv;
    my $t; $t = AE::timer 0, 0 => sub { $cv->("OK"); undef $t };
    $cv;
};

eval { $cv->map(sub {die "END"})->recv };
like $@, qr/^END/;

eval { $cv->flat_map(sub {die "END"})->recv };
like $@, qr/^END/;

eval { (cv_map_multi { die "END" } $cv)->recv };
like $@, qr/^END/;

done_testing;
