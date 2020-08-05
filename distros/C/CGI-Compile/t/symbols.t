#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use CGI::Compile;
use Capture::Tiny 'capture_stdout';
use Test::Requires 'Sub::Identify';

use Sub::Identify qw/sub_name stash_name/;

my $cgi =<<'EOL';
#!/usr/bin/perl

print "Content-Type: text/plain\015\012\015\012", <DATA>;

__DATA__
Hello
World
EOL

my $sub = CGI::Compile->compile(\$cgi);

is sub_name($sub),   '__CGI0__';
is stash_name($sub), 'main';

$sub = CGI::Compile->compile('t/hello.cgi');

is sub_name($sub), 'hello_2ecgi';

like stash_name($sub), qr/^CGI::Compile::ROOT::[A-Za-z0-9_]*t_hello_2ecgi\z/;

$sub = CGI::Compile->compile(\$cgi);

is sub_name($sub),   '__CGI1__';
is stash_name($sub), 'main';

my $out = capture_stdout { $sub->() };

like $out, qr/Hello\nWorld/;

done_testing;

