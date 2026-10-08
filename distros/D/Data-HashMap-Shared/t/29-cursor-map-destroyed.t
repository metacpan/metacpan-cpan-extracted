use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();

# A cursor holds raw handle pointers, so an explicit $map->DESTROY frees the
# handle under it; cursor and map must detect the zeroed owner IV.
# The risky sequences run in a forked child so a regression fails a test
# instead of taking the harness down with SIGSEGV.

my @variants = qw(II IS SI SS I16 I16S I32 I32S SI16 SI32);
my $dir = tempdir(CLEANUP => 1);

# anchored: croak appends this file's name, which contains "destroyed"
my $MAP_GONE    = qr/^Attempted to use a destroyed \S+ object/;
my $CURSOR_GONE = qr/^Attempted to use a \S+ cursor whose map was destroyed/;

sub in_child {
    my ($body) = @_;
    my $pid = fork // die "fork: $!";
    unless ($pid) { $body->(); POSIX::_exit(0) }
    waitpid $pid, 0;
    return $?;
}

sub make_key { my ($v, $i) = @_; $v =~ /^I/ ? $i : "cursor-key-longer-than-inline-$i" }
sub make_val { my ($v, $i) = @_; $v =~ /S$/ ? "value-longer-than-inline-$i" : $i }

for my $v (@variants) {
    my $class = "Data::HashMap::Shared::$v";
    unless (eval "require $class; 1") { fail("load $class: $@"); next }

    my $status = in_child(sub {
        my $m = $class->new("$dir/$v.hm", 1024);
        $m->put(make_key($v, $_), make_val($v, $_)) for 1 .. 8;
        my $c = $m->cursor;
        $c->next;
        $m->DESTROY;
        eval { $c->next; 1 } and POSIX::_exit(20);       # no croak at all
        POSIX::_exit($@ =~ $CURSOR_GONE ? 0 : 21);
    });
    is $status, 0, "$class: cursor method after explicit map DESTROY croaks cleanly"
        or diag sprintf('child status 0x%04x (signal %d, exit %d)',
                        $status, $status & 127, $status >> 8);

    my $mstat = in_child(sub {
        my $m = $class->new("$dir/$v-map.hm", 1024);
        $m->put(make_key($v, 1), make_val($v, 1));
        $m->DESTROY;
        eval { $m->size; 1 } and POSIX::_exit(22);
        POSIX::_exit($@ =~ $MAP_GONE ? 0 : 23);
    });
    is $mstat, 0, "$class: map method after explicit map DESTROY croaks cleanly"
        or diag sprintf('child status 0x%04x (signal %d, exit %d)',
                        $mstat, $mstat & 127, $mstat >> 8);

    my $drop = in_child(sub {
        my $m = $class->new("$dir/$v-drop.hm", 1024);
        $m->put(make_key($v, $_), make_val($v, $_)) for 1 .. 8;
        my $c = $m->cursor;
        $c->next;
        $m->DESTROY;
        undef $c;
    });
    is $drop, 0, "$class: dropping a cursor after explicit map DESTROY is safe"
        or diag sprintf('child status 0x%04x (signal %d, exit %d)',
                        $drop, $drop & 127, $drop >> 8);
}

done_testing;
