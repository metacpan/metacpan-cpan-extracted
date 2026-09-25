use strict;
use warnings;
use Test::More;
use POSIX ();
use Storable qw(dclone freeze thaw);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

# Each case runs in a child so a crash shows up as a failed test.

sub in_child (&) {
    my ($code) = @_;
    my $pid = fork // die $!;
    if (!$pid) { my $out = eval { $code->() } // "died: $@"; print STDERR $out; POSIX::_exit(length $out ? 1 : 0) }
    waitpid $pid, 0;
    return $?;
}

my %copy = (
    dclone => sub { dclone($_[0]) },
    thaw   => sub { thaw(freeze($_[0])) },
);
$copy{clone} = sub { Clone::clone($_[0]) } if eval { require Clone; 1 };

for my $how (sort keys %copy) {
    for my $class (qw(Data::ReqRep::Shared Data::ReqRep::Shared::Int)) {
        my $status = in_child {
            my $s = $class =~ /Int/ ? $class->new_memfd('c', 4, 2) : $class->new_memfd('c', 4, 2, 64);
            my $c = ($class =~ /Int/ ? 'Data::ReqRep::Shared::Int::Client' : 'Data::ReqRep::Shared::Client')
                ->new_from_fd($s->memfd);
            my $copies = $copy{$how}->({ s => $s, c => $c });
            my $usable = eval { $copies->{s}->capacity; 1 } || eval { $copies->{c}->capacity; 1 };
            undef $copies;
            die "a copy was usable as a handle\n" if $usable;
            die "the original stopped working\n" unless $s->capacity == 4 && $c->capacity == 4;
            ref($c)->new_from_fd($s->memfd);
            '';
        };
        is $status, 0, "$how of a $class handle and its client neither crashes nor breaks the original";
    }
}

for my $class (qw(Data::ReqRep::Shared Data::ReqRep::Shared::Int)) {
    my $s = $class =~ /Int/ ? $class->new_memfd('u', 4, 2) : $class->new_memfd('u', 4, 2, 64);
    my $copy = dclone($s);
    ok !eval { $copy->unlink; 1 }, "unlink on a copy of a $class handle croaks";
    like $@, qr/^\Q$class\E object is a copy/, '  saying what it is';
}

done_testing;
