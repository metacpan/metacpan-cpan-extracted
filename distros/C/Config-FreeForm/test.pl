use strict;

use Test;
BEGIN { plan tests => 6 };

eval "use Data::Compare";
my $no_compare = $@ ? 1 : 0;

## 1. Test module compilation.
use vars qw/$loaded/;
END { print "not ok 1\n" unless $loaded; }
use Config::FreeForm dir => './conf', sets => [ qw/Foo/ ];
$loaded++;
ok(1);

## 2. Was the Foo configuration set loaded correctly?
## (Should be a hash reference.)
ok(ref $Config::FreeForm::Foo eq "HASH");

## Save the original configuration. Need to deref, then
## ref again, so that we get an actual *copy*.
my $orig_conf = { %{ $Config::FreeForm::Foo } };

## 3. Write the data out to a test file.
my $t_conf = "./t.conf";
Config::FreeForm::rewrite('Foo', $t_conf);
ok(-e $t_conf);

## 4. Now read it back in. Is it the same?
my $conf = do $t_conf;
if ($no_compare) {
    skip($no_compare, 0);
}
else {
    ok(Compare($Config::FreeForm::Foo, $conf->{Foo}));
}

## Remove test file.
unlink $t_conf or die "Can't remove $t_conf: $!";

## Make a change to the configuration, then rewrite it
## to the "real" config file.
$Config::FreeForm::Foo->{foo} = "bar";
my $saved_conf = $Config::FreeForm::Foo;
Config::FreeForm::rewrite('Foo');

## Get rid of the loaded configuration, then force reload.
$Config::FreeForm::Foo = {};
Config::FreeForm::reload('Foo');

## 5 and 6. Now test that configuration has changed.
ok(exists $Config::FreeForm::Foo->{foo});
if ($no_compare) {
    skip($no_compare, 0);
}
else {
    ok(Compare($Config::FreeForm::Foo, $saved_conf));
}

## Now restore to original.
$Config::FreeForm::Foo = $orig_conf;
Config::FreeForm::rewrite('Foo');
