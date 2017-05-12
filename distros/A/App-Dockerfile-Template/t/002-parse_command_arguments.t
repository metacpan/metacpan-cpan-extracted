use strict;
use warnings;
use Test::More;
require "bin/docker-build";

my @cases = (
    {
        subject  => "no argument",
        expected => {},
    },
    {
        subject   => "get keys only arguments",
        arguments => [ "--force-rm", "-q", "-m", "=MFile::Slurp" ],
        expected  => {
            "--force-rm"    => qq{},
            "-q"            => qq{},
            "-m"            => qq{},
            "=MFile::Slurp" => qq{},
        },
    },
    {
        subject   => "get keys-value arguments",
        arguments => [ "=KVauthor", "Michael Vu", "=Ssome", "foobar" ],
        expected  => {
            "=KVauthor" => "Michael Vu",
            "=Ssome"    => "foobar",
        },
    },
    {
        subject   => "get keys-value pairs and single key fields arguments",
        arguments => [
            "=KVauthor", "Michael Vu", "--force-rm", "-q",
            "=Ssome",    "foobar",     "-m",         "=MFile::Slurp"
        ],
        expected => {
            "=KVauthor"     => "Michael Vu",
            "=Ssome"        => "foobar",
            "--force-rm"    => qq{},
            "-q"            => qq{},
            "-m"            => qq{},
            "=MFile::Slurp" => qq{},
        },
    },
);

foreach my $case (@cases) {
    my %got =
      main::_parse_command_arguments( @{ $case->{arguments} || [] } );
    is_deeply \%got, $case->{expected}, $case->{subject};
}

done_testing;
