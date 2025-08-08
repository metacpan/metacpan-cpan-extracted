use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempfile);

use_ok('CGI::Info');

# Simulate a config file
my ($fh, $filename) = tempfile(UNLINK => 1);
print $fh <<'EOF';
---
CGI__Info:
  logger:
    file: /tmp/from_config_file.log
EOF
close $fh;

my $info = CGI::Info->new(config_file => $filename);
ok($info->{'logger'}->{'file'} eq '/tmp/from_config_file.log');

# Set an ENV variable that should override the config file
local $ENV{'CGI__Info__logger__file'} = '/tmp/from_env_variable.log';

$info = new_ok('CGI::Info');
ok($info->{'logger'}->{'file'} eq '/tmp/from_env_variable.log');

done_testing();
