package Test::AS::zdestroy;

BEGIN
{
    use strict;
    use Test;
    plan tests => 3;
}

# under some configuration, PWD isn't defined
unless(defined $ENV{PWD} || $ENV{PWD} ne '')
{
    print STDERR "Your \$PWD environment variable is unset, I fix this.\n";
    my $pwd = `pwd`;
    chomp($pwd);
    $ENV{PWD} = $pwd;
}

package Test1;
use Apache::SharedMem qw(:status);
{
    my $share = new Apache::SharedMem;
    $share->set('test'=>'teststring');
    Test::AS::zdestroy::ok($share->status, SUCCESS);
}

package Test2;
use Apache::SharedMem qw(:status);
{
    my $share = new Apache::SharedMem;
    $share->set('test2'=>'teststring');
    Test::AS::zdestroy::ok($share->status, SUCCESS);
}

package Test3;
use Apache::SharedMem qw(:status);
{
    my $share = new Apache::SharedMem;
    $share->destroy;
    Test::AS::zdestroy::ok($share->status, SUCCESS);
}
