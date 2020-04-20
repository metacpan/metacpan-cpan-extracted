#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;

use Path::Tiny qw/ path tempdir tempfile cwd /;
use App::rshasum ();

my $cwd = cwd;
my $dir = $cwd->child( "t", "data", "1" );

sub _test_rshasum
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $args        = shift;
    my $worker_args = $args->{worker_args} // {};
    my $lines       = $args->{lines}
        or die "foo";
    my $blurb = $args->{blurb};

    {
        my @res;
        App::rshasum->_worker(
            {
                digest    => 'SHA-256',
                output_cb => sub {
                    push @res, shift()->{str};
                },
                %{$worker_args},
            }
        );
        pop @res;

        is_deeply( \@res, [ ( map { "$_\n" } $lines =~ /([^\n\r]+)/g ) ],
            $blurb, );
    }
    chdir $cwd;
    return;
}

chdir $dir;

# TEST
_test_rshasum(
    {
        worker_args => +{},
        lines       => <<"EOF",
d5579c46dfcc7f18207013e65b44e4cb4e2c2298f4ac457ba8f82743f31e930b  0.txt
7ea4c2a1c490e653b0ea37bb1a087553380ba642536dabbb2f3b4eb3a2bd6fdf  2.txt
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  foo/empty
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  zempty
EOF
        blurb => "Right results",
    }
);

chdir $dir;

# TEST
_test_rshasum(
    {
        worker_args => +{
            prune_re => [qr#2\.txt/?\z#ims],
        },
        lines => <<"EOF",
d5579c46dfcc7f18207013e65b44e4cb4e2c2298f4ac457ba8f82743f31e930b  0.txt
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  foo/empty
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  zempty
EOF
        blurb => "Right results with prune",
    }
);

# TEST
_test_rshasum(
    {
        worker_args => +{
            prune_re   => [qr#2\.txt/?\z#ims],
            start_path => $dir,
        },
        lines => <<"EOF",
d5579c46dfcc7f18207013e65b44e4cb4e2c2298f4ac457ba8f82743f31e930b  0.txt
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  foo/empty
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  zempty
EOF
        blurb => "Right results with start_path",
    }
);
