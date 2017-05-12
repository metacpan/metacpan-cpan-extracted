# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use Data::Password::Manager qw(
        pw_get
);

$loaded = 1;

######################### End of black magic.

$test = 1;
sub ok {print 'ok ',$test++,"\n";}

&ok;

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

umask 027;
foreach my $dir (qw(tmp)) {
  if (-d $dir) {         # clean up previous test runs
    opendir(T,$dir);
    @_ = grep($_ ne '.' && $_ ne '..', readdir(T));
    closedir T;
    foreach(@_) {
      unlink "$dir/$_";
    }
    rmdir $dir or die "COULD NOT REMOVE $dir DIRECTORY\n";
  }
  unlink $dir if -e $dir;       # remove files of this name as well
}
 
my $dir = './tmp';
mkdir $dir,0755;

my $passfile = $dir .'/password.tst';

## test 2
open(F,">$passfile") or (print "Bail out! could not open $passfile\nnot ");
&ok;

## test 3	creat dummy password file
print F q|# password test file
user1:password1
user2:password2
user3:password3
|;

close F or (print "failed to close $passfile\nnot ");
&ok;

## test 4	fetch a password
my $user = 'user2';
my $exp = 'password2';
my $error = '';
print "got: $_, exp: $exp\n$error\nnot "
	unless ($_ = pw_get($user,$passfile,\$error)) eq $exp;
&ok;

## test 5	fail miserably ;-)
$user = 'nouser';
print "unexpected password returned for $user: $_\nnot "
	if ($_ = pw_get($user,$passfile,\$error));
&ok;

## test 6	check error return
$exp = 'no such user, '. $user;
print "got: $error\nexp: $exp\nnot "
	unless $error eq $exp;
&ok;
