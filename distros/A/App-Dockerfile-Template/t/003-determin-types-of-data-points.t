use strict;
use warnings;
use Test::More;
use Sub::Override;
require "bin/docker-build";

my @cases = (
    {
        subject  => "all docker args",
        args     => [ "-t", "abc", "-q", "--force-rm" ],
        expected => {
            for_docker => {
                -t           => qq{abc},
                -q           => qq{},
                "--force-rm" => qq{},
            },
            for_template => {},
        },
    },
    {
        subject => "all template args",
        args =>
          [ "=MIO::File", "=Shello", "shift . qq{ - world}", "=KVfoo", "bar" ],
        expected => {
            for_docker   => {},
            for_template => {
                "IO::File" => length("IO::File"),
                hello      => "TESTME - world",
                foo        => "bar",
            },
        },
    },
    {
        subject => "mix both",
        args    => [
            "-t", "abc", "-q", "--force-rm",
            "=MIO::File", "=Shello", "shift . qq{ - world}",
            "=KVfoo", "bar"
        ],
        expected => {
            for_docker => {
                -t           => qq{abc},
                -q           => qq{},
                "--force-rm" => qq{},
            },
            for_template => {
                "IO::File" => length("IO::File"),
                hello      => "TESTME - world",
                foo        => "bar",
            },
        },
    }
);

my $sub_rewritter = Sub::Override->new;

{
    $SIG{__WARN__} = sub { };
    ## Old version using &load directly
    eval {
        $sub_rewritter->replace( "Module::Load::load" => sub { length shift } );
    };
    ## New version using &_load wrapper
    eval {
        $sub_rewritter->replace( "Module::Load::_load" => sub { length shift }
        );
    };
}

foreach my $case (@cases) {
    my %args =
      main::_parse_command_arguments( @{ $case->{args} || [] } );

    subtest $case->{subject} => sub {
        my %docker_args = main::_get_args_from_docker(%args);
        is_deeply
          \%docker_args,
          $case->{expected}{for_docker},
          "docker args";

        my %template_args = main::_get_args_for_template(%args);
        is_deeply
          map( { { _flat_hash(%$_) } } \%template_args,
            $case->{expected}{for_template} ),
          "template args";
    };
}

sub _flat_hash {
    my %hash = @_;
    while ( my ( $key, $value ) = each %hash ) {
        if ( ref $value eq "CODE" ) {
            $hash{$key} = $value->("TESTME");
        }
    }
    return %hash;
}

done_testing;
