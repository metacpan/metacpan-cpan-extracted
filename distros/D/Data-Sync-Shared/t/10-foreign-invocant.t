use strict;
use warnings;
use Test::More;
use Config;
use POSIX ();
use Data::Sync::Shared::Semaphore;

# DESTROY takes its invocant and dereferences it as our handle struct. Guarding
# with SvROK/SvOBJECT alone accepts ANY blessed reference, so a foreign object
# reached INT2PTR and was read through as our struct -- a hard SIGSEGV, not a
# Perl exception. The guard has to be sv_derived_from against this class.
# Isolated in a forked child so a regression is reported rather than taking the
# whole test run down with it.
plan skip_all => 'fork required' unless $Config{d_fork};

my $pid = fork;
plan skip_all => "fork: $!" unless defined $pid;
unless ($pid) {
    my $foreign = bless \( my $x = 0x5 ), 'Some::Foreign::Class';
    # A destructor must not throw, so surviving -- not croaking -- is the
    # contract here; eval only keeps a future croak from confusing the exit code.
    eval { Data::Sync::Shared::Semaphore::DESTROY($foreign) };
    POSIX::_exit(0);
}
waitpid $pid, 0;
my $st = $?;

ok !( $st & 127 ), 'DESTROY on a foreign blessed ref does not crash'
    or diag 'died from signal ' . ( $st & 127 );
is $st >> 8, 0, '... and the child exits cleanly';

done_testing;
