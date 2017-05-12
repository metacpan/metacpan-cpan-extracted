use strict;
use warnings;
use Test::More;
use File::Temp;
require "bin/docker-build";

my @cases = (
    {
        subject  => "template with env val only",
        env      => { foo => "bar" },
        template => "ENV foo [% foo %]",
        expected => "ENV foo bar",
    },
    {
        subject  => "template with command line arguments",
        args     => { happy => "family" },
        template => "ENV happy [% happy %]",
        expected => "ENV happy family",
    },
    {
        subject  => "template with command line arguments and env val",
        env      => { foo => "bar", here_env => 1 },
        args     => { foo => "baz", here_args => 1 },
        template => "[% foo %] - [% here_env %] - [% here_args %]",
        expected => "baz - 1 - 1",
    },
);

foreach my $case (@cases) {
    my $file = do {
        File::Temp->new( UNLINK => 1 )->filename;
    };
    if ( open my $FH, ">", $file ) {
        print $FH $case->{template};
        close $FH;
    }

    local %ENV = %{ $case->{env} || {} };

    my $got = main::_get_dockerfile_template(
        Dockerfile => $file,
        %{ $case->{args} || {} },
    );
    is $got, $case->{expected}, $case->{subject};
}

done_testing;
