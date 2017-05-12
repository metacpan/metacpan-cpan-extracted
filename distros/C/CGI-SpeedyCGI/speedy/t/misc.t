
# Misc tests

# #1: "speedy /dev/null" wouldn't work
# #2: if backendprog is not executable, should get an error message, not
# a coredump

print "1..2\n";

my $out = `$ENV{SPEEDY} /dev/null`;
my $ok = $out eq '' && $? == 0;
print $ok ? "ok\n" : "not ok\n";

utime time, time, 't/scripts/basic.1';
sleep 1;

my $save = $ENV{SPEEDY_BACKENDPROG};
$ENV{SPEEDY_BACKENDPROG} = '/bin/ls';
$out = `$ENV{SPEEDY} t/scripts/basic.1 2>&1`;
$ok = $? != 0 && $out =~ /cannot spawn/i;
#print STDERR "out=$out status=$?\n";
print $ok ? "ok\n" : "not ok\n";
$ENV{SPEEDY_BACKENDPROG} = $save;
