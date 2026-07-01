use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'Linux /proc required' unless -d '/proc/self/fd';
use POSIX qw(_exit);
use Data::Intern::Shared;

# An unrelated process accesses a memfd-backed table it did NOT inherit, via
# /proc/<creator-pid>/fd/<n>, and resolves ids/strings consistently.
pipe(my $R, my $W) or die "pipe: $!";
my $pid = fork // die "fork: $!";
if (!$pid) {                       # creator builds the table AFTER fork
    close $R;
    my $in = Data::Intern::Shared->new_memfd('xproc', 1000, 4096);
    $in->intern("word-$_") for 0 .. 19;
    syswrite $W, $$ . ' ' . $in->memfd . "\n";
    close $W;
    select undef, undef, undef, 5;            # stay alive so /proc/$$/fd/N persists
    _exit(0);
}
close $W;
my ($cpid, $cfd) = split ' ', scalar(<$R>);
open my $fh, '+<', "/proc/$cpid/fd/$cfd" or die "open /proc/$cpid/fd/$cfd: $!";
my $in2 = Data::Intern::Shared->new_from_fd(fileno $fh);

is $in2->count, 20, "unrelated process sees the creator's 20 strings";
is $in2->string(5), "word-5", 'string() agrees across the passed memfd';
is $in2->id_of("word-7"), 7, 'id_of() agrees across the passed memfd';
is $in2->intern("word-3"), 3, 're-intern an existing string via the passed fd -> same id';
is $in2->intern("brand-new"), 20, 'a new intern via the passed fd -> next id';

kill 'TERM', $cpid;
waitpid $cpid, 0;
done_testing;
