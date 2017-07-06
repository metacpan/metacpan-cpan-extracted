use strict;
use warnings;
use Test::More;

use AWS::CLI::Config;

subtest 'From credentials file' => sub {
    my $output = '__format__';
    no strict 'refs';
    no warnings 'redefine';
    *AWS::CLI::Config::credentials = sub {
        return AWS::CLI::Config::Profile->new({
                output => $output,
            });
    };
    is(AWS::CLI::Config::output, $output, 'set by credentials');
};

subtest 'From config file' => sub {
    my $output = '__format__';
    no strict 'refs';
    no warnings 'redefine';
    *AWS::CLI::Config::credentials = sub {
        return undef;
    };
    *AWS::CLI::Config::config = sub {
        return AWS::CLI::Config::Profile->new({
                output => $output,
            });
    };
    is(AWS::CLI::Config::output, $output, 'set by config');
};

done_testing;

__END__
# vi: set ts=4 sw=4 sts=0 et ft=perl fenc=utf-8 ff=unix :
