use strict;
use warnings;
use Test::More;

use Command::Run;

# with stdin
my $result = Command::Run->new("cat")
    ->with(stdin => "hello")
    ->run;
is $result->{data}, "hello", 'with stdin';

# with stdout reference
my $out;
Command::Run->new("echo", "world")
    ->with(stdout => \$out)
    ->run;
is $out, "world\n", 'with stdout reference';

# with stdin and stdout
my $data;
Command::Run->new("cat", "-n")
    ->with(stdin => "foo\nbar\n", stdout => \$data)
    ->run;
like $data, qr/1.*foo/, 'with stdin and stdout - line 1';
like $data, qr/2.*bar/, 'with stdin and stdout - line 2';

# with stderr reference
my ($stdout, $stderr);
Command::Run->new("sh", "-c", "echo out; echo err >&2")
    ->with(stdout => \$stdout, stderr => \$stderr)
    ->run;
is $stdout, "out\n", 'with stdout and stderr - stdout';
is $stderr, "err\n", 'with stdout and stderr - stderr';

# with stderr => 'redirect'
my $merged;
Command::Run->new("sh", "-c", "echo out; echo err >&2")
    ->with(stdout => \$merged, stderr => 'redirect')
    ->run;
like $merged, qr/out/, 'with stderr redirect - contains out';
like $merged, qr/err/, 'with stderr redirect - contains err';

done_testing;
