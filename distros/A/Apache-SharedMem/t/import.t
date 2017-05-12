package Test::AS::import;

BEGIN
{
    use strict;
    use Test;
    plan tests => 5;
}

# under some configuration, PWD isn't defined
unless(defined $ENV{PWD} || $ENV{PWD} ne '')
{
    print STDERR "Your \$PWD environment variable is unset, I fix this.\n";
    my $pwd = `pwd`;
    chomp($pwd);
    $ENV{PWD} = $pwd;
}

use Apache::SharedMem;
ok(1);


package Test1;
use Apache::SharedMem qw(:all);
my $constest1 = 0;
foreach(qw(LOCK_EX LOCK_SH LOCK_UN LOCK_NB WAIT NOWAIT SUCCESS FAILURE))
{
    eval('$constest1 += defined('. $_ .')');
}
Test::AS::import::ok($constest1, 8, ':all tag import');

package Test2;
use Apache::SharedMem qw(:lock);
my $constest2 = 0;
foreach(qw(LOCK_EX LOCK_SH LOCK_UN LOCK_NB))
{
    eval('$constest2 += defined(' . $_ . ')');
}
Test::AS::import::ok($constest2, 4, ':lock tag import');

package Test3;
use Apache::SharedMem qw(:wait);
my $constest3 = 0;
foreach(qw(WAIT NOWAIT))
{
    eval('$constest3 += defined(' . $_ . ')');
}
Test::AS::import::ok($constest3, 2, ':wait tag import');

package Test4;
use Apache::SharedMem qw(:status);
my $constest4 = 0;
foreach(qw(SUCCESS FAILURE))
{
    eval('$constest4 += defined(' . $_ . ')');
}
Test::AS::import::ok($constest4, 2, ':status tag import');
