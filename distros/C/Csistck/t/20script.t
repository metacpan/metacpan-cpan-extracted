use Test::More;
use Test::Exception;
use Csistck;
use File::Temp;
use File::stat;

# Find target for script
my $cmdpass = pop @{[ grep { -e -x $_ }
  @{['/bin/true', '/usr/bin/true']} ]};
my $cmdfail = pop @{[ grep { -e -x $_ }
  @{['/bin/false', '/usr/bin/false']} ]};

if ($cmdpass and $cmdfail) {
    plan tests => 10;
}
else {
    plan skip_all => "OS unsupported";
}

# Passing test
my $t = script($cmdpass);
isa_ok($t, Csistck::Test);
ok($t->can('check'));
ok($t->check, "Manual check" );
isa_ok($t->check, Csistck::Test::Return, "Manual check return" );
is($t->check->passed, 1, 'Check passed');
isnt($t->check->failed, 'Check did not fail');
is($t->execute('check')->passed, 1, 'Full check');
is($t->execute('repair')->passed, 1, 'Full repair');

# Failing test
$t = script($cmdfail);
is($t->execute('check')->failed, 1, 'Full check on failing');
is($t->execute('repair')->failed, 1, 'Full repair on failing');

1;
