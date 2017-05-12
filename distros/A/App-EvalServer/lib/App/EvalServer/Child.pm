package App::EvalServer::Child;
BEGIN {
  $App::EvalServer::Child::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $App::EvalServer::Child::VERSION = '0.08';
}

use strict;
use warnings FATAL => 'all';
use BSD::Resource;
use POE::Filter::Reference;
use POSIX qw<setgid>;

# we need to load these here, otherwise they'll be loaded on demand
# after the chroot, which will fail
getrusage();
use Carp::Heavy;
use Storable 'nfreeze'; nfreeze([]);
use File::Glob;

my $PIPE;
my $FILTER;

sub run {
    my ($tempdir, $pipe_name, $jail, $user, $limit, $lang, $code, $unsafe)
        = @ARGV;

    open $PIPE, '>', $pipe_name or die "Can't open $pipe_name: $!";
    $FILTER = POE::Filter::Reference->new();

    # _Inline directories and such will end up here
    chdir $tempdir or _fail("Can't chdir $tempdir: $!");

    my $class = "App::EvalServer::Language::$lang";
    eval "require $class";
    chomp $@;
    _fail($@) if $@;

    _be_safe($jail, $user, $limit) if !$unsafe;

    # is this the best approach?
    for my $signal (qw<XFSZ XCPU SEGV>) {
        $SIG{$signal} = sub {
            _fail('Got a fatal signal', { signal => $signal });
        };
    }

    my $result = $class->evaluate($code);
    my ($user_time, $sys_time, $memory) = _usage();
    my $return = {
        result    => $result,
        user_time => $user_time,
        sys_time  => $sys_time,
        memory    => $memory,
    };

    print $PIPE $FILTER->put([$return])->[0];
    exit;
}

sub _usage {
    my $self_usage = [getrusage(RUSAGE_SELF)];
    my $child_usage = [getrusage(RUSAGE_CHILDREN)];
    my $user_time = $self_usage->[0];
    my $sys_time = $self_usage->[1];
    my $memory = $self_usage->[2] + $child_usage->[2];

    return ($user_time, $sys_time, $memory);
}

sub _fail {
    my ($error, $return) = @_;
    $return = { } if ref $return ne 'HASH';

    $return->{error} = $error;
    my ($user_time, $sys_time, $memory) = _usage();
    $return->{user_time} = $user_time;
    $return->{sys_time} = $sys_time;
    $return->{memory} = $memory;

    print $PIPE $FILTER->put([$return])->[0];
    exit;
}

sub _be_safe {
    my ($jail, $user, $limit) = @_;

    my $new_uid = getpwnam($user);
    _fail("Can't find uid for '$user'") if !defined $new_uid;
    
    # Set the CPU LIMIT.
    # Do this before the chroot because some of the other
    # setrlimit calls will prevent chroot from working
    # however at the same time we need to preload an autload file
    # that chroot will prevent, so do it here.
    setrlimit(RLIMIT_CPU, 10, 10);

    _fail("Not root, can't chroot or take other precautions, dying") if $< != 0;

    chdir or _fail("Failed to chdir into $jail: $!");
    chroot '.' or _fail("Failed to chroot into $jail: $!");

    # drop root privileges
    $)="$new_uid $new_uid";
    $(=$new_uid;
    $<=$>=$new_uid;
    setgid($new_uid); #We just assume the uid is the same as the gid. Hot.

    if ($> != $new_uid || $< != $new_uid) {
        _fail("Failed to drop root privileges");
    }

    my $kilo = 1024;
    my $meg = $kilo * $kilo;
    my $limit_bytes = $limit * $meg;

    (
    setrlimit(RLIMIT_DATA, $limit_bytes, $limit_bytes)
            and
    setrlimit(RLIMIT_STACK, $limit_bytes, $limit_bytes)
            and
    setrlimit(RLIMIT_NPROC, 1, 1)
            and
    setrlimit(RLIMIT_NOFILE, 0, 0)
            and
    setrlimit(RLIMIT_OFILE, 0, 0)
            and
    setrlimit(RLIMIT_OPEN_MAX, 0, 0)
            and
    setrlimit(RLIMIT_LOCKS, 0, 0)
            and
    setrlimit(RLIMIT_AS, $limit_bytes, $limit_bytes)
            and
    setrlimit(RLIMIT_VMEM, $limit_bytes, $limit_bytes)
            and
    setrlimit(RLIMIT_MEMLOCK, 100, 100)
            and
    setrlimit(RLIMIT_CPU, 10, 10)
    )
    or _fail("Failed to set resource limits: $!");

    #setrlimit(RLIMIT_MSGQUEUE,100,100);
    return;
}

1;

=encoding utf8

=head1 NAME

App::EvalServer::Child - Evaluate code in a safe child process

=head1 SYNOPSIS

 # fork, etc

 use App::EvalServer::Child;
 App::EvalServer::Child::run(
     $tempdir, $pipe_name, $jail, $user, $limit, $lang, $code, $unsafe,
 );

=head1 DESCRIPTION

This module takes various safety precautions, then executes the code you
provided.

=head1 FUNCTIONS

=head2 C<run>

Runs the code. Takes the following arguments: a temporary directory, a pipe
name, a jail path, a username, a process limit (in megabytes), a language
suffix (e.g. 'Perl' for C<App::EvalServer::Language::Perl>), the code, and
an unsafe flag. If the unsafe flag is on, C<run> will not take safety
precautions (change user, chroot, set resource limits) which require root
access.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
