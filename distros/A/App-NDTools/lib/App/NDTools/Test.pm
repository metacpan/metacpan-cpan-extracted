package App::NDTools::Test;

use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);

use Capture::Tiny qw(capture);
use Data::Dumper;
use Scalar::Util qw(blessed);
use Test::More;

our @EXPORT = qw(
    run_ok
    t_ab_cmp
    t_dir
    t_dump
);

sub run_ok {
    my %t = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    if (exists $t{skip} and $t{skip}->()) {
        pass("Test '$t{name}' cancelled by 'skip' opt");
        return;
    }

    my @envs = exists $t{env} ? %{$t{env}} : ();
    SET_ENV: # can't use loop here - env vars will be localized in it's block
    @envs and local $ENV{$envs[0]} = $envs[1];
    if (@envs) {
        splice @envs, 0, 2;
        goto SET_ENV;
    }

    if (exists $t{pre} and not $t{pre}->()) {
        fail("Pre hook for '$t{name}' failed");
        return;
    }

    my ($out, $err, $exit);
    if (eval { $t{cmd}->[0]->isa('App::NDTools::NDTool') }) {
        my $tool = shift @{$t{cmd}};

        ($out, $err) = capture {
            local $Log::Log4Cli::LEVEL = 0; # reset loglevel
            eval { $tool->new(@{$t{cmd}})->exec() }
        };

        if (blessed($@) and $@->isa('Log::Log4Cli::Exception')) {
            $err .= $@->{LOG_MESSAGE};
            $exit = $@->{EXIT_CODE};
        } else {
            $err .= $@;
            $exit = 255;
        }

        unshift @{$t{cmd}}, $tool;
    } else { # assume it's binary
        ($out, $err, $exit) = capture { system(@{$t{cmd}}) };
        $exit = $exit >> 8;
    }

    subtest $t{name} => sub {

        for my $std ('stdout', 'stderr') {
            next if (exists $t{$std} and not defined $t{$std}); # set to undef to skip test
            $t{$std} = '' unless (exists $t{$std});             # silence expected by default

            my $desc = uc($std) . " check for $t{name}: [@{$t{cmd}}]";
            my $data = $std eq 'stdout' ? $out : $err;

            if (ref $t{$std} eq 'CODE') {
                ok($t{$std}->($data), $desc);
            } elsif (ref $t{$std} eq 'Regexp') {
                like($data, $t{$std}, $desc);
            } else {
                is($data, $t{$std}, $desc);
            }
        }

        if (not exists $t{exit} or defined $t{exit}) {  # set to undef to skip test
            $t{exit} = 0 unless exists $t{exit};        # defailt exit code
            is(
                $exit, $t{exit},
                "Exit code check for $t{name}: [@{$t{cmd}}]"
            );
        }

        $t{test}->() if (exists $t{test});

        if (exists $t{post} and not $t{post}->()) {
            fail("Post hook for '$t{name}' failed");
            return;
        }

        if (not exists $t{clean} or defined $t{clean}) { # set to undef to skip
            @{$t{clean}} = "$t{name}.got" unless exists $t{clean};
            map { unlink $_ if (-f $_) } @{$t{clean}};
        }

        done_testing();
    }
}

sub t_ab_cmp {
    return "GOT: " . t_dump(shift) . "\nEXP: " . t_dump(shift);
}

sub t_dir {
    my $tfile = shift || (caller)[1];
    substr($tfile, 0, length($tfile) - 1) . "d";
}

sub t_dump {
    return Data::Dumper->new([shift])->Terse(1)->Sortkeys(1)->Quotekeys(0)->Indent(0)->Deepcopy(1)->Dump();
}

1;
