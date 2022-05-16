#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;
require DateTime;

use Cron::Sequencer::CLI qw(parse_argv calculate_start_end);

my $nowish = time;

{
    no warnings 'redefine';
    *DateTime::_core_time = sub { return $nowish };
}

my @today = calculate_start_end({ show => 'today' });

sub fake_pod2usage {
    die ["Called pod2usage", @_];
}

for (["no arguments", "",
      undef, 'exitval', 255],
     ["unknown arguments", "--bogus",
      qr/\AUnknown option: bogus\n\z/, 'exitval', 255, 'verbose', 1],
     ["--env and --hide-env together", "--hide-env file --env FOO=BAR",
      undef, 'exitval', 255,
      'message', "--env and --hide-env options can't be used together"],
     ["--env and --hide-env together (anywhere)",
      "--hide-env file1 -- file2 --env FOO=BAR",
      undef, 'exitval', 255,
      'message', "--env and --hide-env options can't be used together"],
     ["Output options aren't allowed after --",
      "--from 1 --to 11 -- --hide-env file",
      qr/\AUnknown option: hide-env\n\z/, 'exitval', 255, 'verbose', 1],
     ["--version isn't allowed after --",
      "file -- --version",
      qr/\AUnknown option: version\n\z/, 'exitval', 255, 'verbose', 1],
 ) {
    my ($desc, $flat, $warn, @want) = @$_;
    my @args = split ' ', $flat;
    unshift @want, "Called pod2usage";

    my @warnings;

    cmp_deeply(exception {
        local $SIG{__WARN__} = sub {
            push @warnings, \@_;
        };
        parse_argv(\&fake_pod2usage, @args);
    }, \@want, "pod2usage called for $desc");
    if (defined $warn) {
        cmp_deeply(\@warnings, [[re($warn)]], "got expected warning from $desc");
    } else {
        cmp_deeply(\@warnings, [], "no warnings from $desc");
    }
}

for my $flat ('--help', '--help --', '-- --help', '--version', '--version --') {
    my @args = split ' ', $flat;
    my @caught;
    my @warnings;

    my $sub = ucfirst($flat =~ tr/a-z//dcr) . "Message";

    cmp_deeply(exception {
        local $SIG{__WARN__} = sub {
            push @warnings, \@_;
        };
        # So, seems that some versions of Perl need this to quiet a warning:
        no warnings qw(redefine);
        local *{$Getopt::Long::{$sub}} = sub {
            # We really need to fake everything including control flow here, as
            # merely "attempting" to die reaches code paths that Getopt::Long
            # wasn't expecting to reach, and it generates numeric warnings.
            push @caught, \@_;
            goto "fake_exit";
        };
        parse_argv(\&fake_pod2usage, @args);
        die "Failed to call the mocked &$sub";
    fake_exit:
        die ["fake_exit for", @caught];
    }, ["fake_exit for", [ignore(), 1]], "&$sub called for $flat");
    cmp_deeply(\@warnings, [], "no warnings for $flat");
}

my $default_output = ['hide-env', undef, count => 1];
my $default_for_file = {env => undef, ignore => undef, source => "file"};
my @defaults = (@today, $default_output);
my @defaults2 = (@today, ['hide-env', undef, count => 2]);

for (["file", [@defaults, $default_for_file]],
     ["file --show today", [@defaults, $default_for_file]],
     ["--show today file", [@defaults, $default_for_file]],
     ["--from 1 --to 11 file", [1, 11, $default_output, $default_for_file]],

     ["--from 1 --to 11 -- file", [1, 11, $default_output, $default_for_file]],
     ["--from 1 --to 11 file --", [1, 11, $default_output, $default_for_file]],

     ["--hide-env file", [@today, ['hide-env', 1, 'count', 1], $default_for_file]],
     ["--env=FOO=BAR file --env BAZ=",
      [@defaults, {env => ["FOO=BAR", "BAZ="], ignore => undef, source => "file"}]],
     ["-- --env=FOO=BAR file --env BAZ=",
      [@defaults, {env => ["FOO=BAR", "BAZ="], ignore => undef, source => "file"}]],
     ["--env=FOO=BAR file --env BAZ= --",
      [@defaults, {env => ["FOO=BAR", "BAZ="], ignore => undef, source => "file"}]],

     ["--env=FOO=BAR file1 -- --env BAZ= file2",
      [@defaults2,
       {env => ["FOO=BAR"], ignore => undef, source => "file1"},
       {env => ["BAZ="], ignore => undef, source => "file2"},
   ]],
     ["--env=FOO=BAR file1 -- file2 --env BAZ=",
      [@defaults2,
       {env => ["FOO=BAR"], ignore => undef, source => "file1"},
       {env => ["BAZ="], ignore => undef, source => "file2"},
   ]],
     ["file1 --env=FOO=BAR -- --env BAZ= file2",
      [@defaults2,
       {env => ["FOO=BAR"], ignore => undef, source => "file1"},
       {env => ["BAZ="], ignore => undef, source => "file2"},
   ]],
     ["--env=FOO=BAR file1 -- -- file2 --env BAZ=",
      [@defaults2,
       {env => ["FOO=BAR"], ignore => undef, source => "file1"},
       {env => ["BAZ="], ignore => undef, source => "file2"},
   ]],
     ["--env=FOO=BAR file1 -- --env=GOING=NOWHERE -- file2 --env BAZ=",
      [@defaults2,
       {env => ["FOO=BAR"], ignore => undef, source => "file1"},
       {env => ["BAZ="], ignore => undef, source => "file2"},
   ]],
     ["file1 --env=FOO=BAR file2 -- file3 file4 -- file5 --env BAZ= file6",
      [@today, ['hide-env', undef, count => 6],
       {env => ["FOO=BAR"], ignore => undef, source => "file1"},
       {env => ["FOO=BAR"], ignore => undef, source => "file2"},
       {env => undef, ignore => undef, source => "file3"},
       {env => undef, ignore => undef, source => "file4"},
       {env => ["BAZ="], ignore => undef, source => "file5"},
       {env => ["BAZ="], ignore => undef, source => "file6"},
   ]],

     ["--ignore 10 file",
      [@defaults, {env => undef, ignore => [10], source => "file"}]],
     ["--ignore 10 --ignore 12 file",
      [@defaults, {env => undef, ignore => [10, 12], source => "file"}]],
     ["--ignore 12 file --ignore 10",
      [@defaults, {env => undef, ignore => [12, 10], source => "file"}]],
 ) {
    my ($flat, $want) = @$_;
    my @args = split ' ', $flat;
    my (@have, @warnings);
    is(exception {
        local $SIG{__WARN__} = sub {
            push @warnings, \@_;
        };
        @have = parse_argv(\&fake_pod2usage, @args);
    }, undef, "no exception from $flat");
    cmp_deeply(\@warnings, [], "no warnings from $flat");
    cmp_deeply(\@have, $want, "result of parse_argv $flat");
}

done_testing();
