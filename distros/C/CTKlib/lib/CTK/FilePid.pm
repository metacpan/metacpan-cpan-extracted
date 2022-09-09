package CTK::FilePid;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::FilePid - The Pid File simple interface

=head1 VERSION

Version 1.05

=head1 SYNOPSIS

    use CTK::FilePid;

    my $pidfile = CTK::FilePid->new ({
        file => '/some/file.pid',
    });

    if ( my $num = $pidfile->running ) {
        die "Already running: $num";
    } else {
        $pidfile->write;

        # ...

        $pidfile->remove;
    }

... or with autoremove:

    my $pidfile = CTK::FilePid->new ({
        file => '/some/file.pid',
        autoremove => 1,
    });

    if ( my $num = $pidfile->running ) {
        die "Already running: $num";
    } else {
        $pidfile->write;

        # ...
    }

=head1 DESCRIPTION

This software manages a pid file for you. It will create a pid file,
query the process within to discover if it's still running, and remove
the pid file.

This module is based on L<File::Pid> module

=head2 new

    my $pidfile = CTK::FilePid->new;

    my $thisfile = File::Pid->new({
        file => '/var/run/daemon.pid',
    });

    my $thisfileandpid = CTK::FilePid->new({
        file => '/var/run/daemon.pid',
        pid  => '145',
        autoremove => 1,
    });

This constructor takes three optional paramters.

C<file> - The name of the pid file to work on. If not specified, a pid
file located in C<rundir()>. So, for example, if C<$0> is F<~/bin/sig.pl>,
the pid file will be F</var/run/sig.pl.pid>.

C<pid> - The pid to write to a new pidfile. If not specified, C<$$> is
used when the pid file doesn't exist. When the pid file does exist, the
pid inside it is used.

C<autoremove> - Auto-remove flag. If this flag specified as true, then
will be removed the pid file automatically on DESTROY phase. Default: false

=head2 file

    $pidfile->file("/var/run/file.pid");
    my $pidfile = $pidfile->file;

Accessor/mutator for the filename used as the pid file.

=head2 pid

    $pidfile->pid(123);
    my $pid = $pidfile->pid;

Accessor/mutator for the pid being saved to the pid file.

=head2 remove

    $pidfile->remove or warn "Couldn't unlink pid file";

Removes the pid file from disk. Returns true on success, false on
failure.

=head2 running

    my $pid = $pidfile->running;
    die "Service already running: $pid" if $pid;

Checks to see if the pricess identified in the pid file is still
running. If the process is still running, the pid is returned. Otherwise
C<undef> is returned.

=head2 write

    my $pid = $pidfile->write;

Writes the pid file to disk, inserting the pid inside the file.
On success, the pid written is returned. On failure, C<undef> is
returned.

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<File::Pid>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = 1.05;

use File::Spec;
use File::Basename qw/basename/;
use CTK::Util qw/fload fsave rundir/;

sub new {
    my $class = shift;
    my $tst = $_[0];
    my %args = ();
    if (defined($tst) && ref($tst) eq 'HASH') {
        %args = %$tst;
    } else {
        %args = @_;
    }
    $args{autoremove} ||= 0;

    my $self  = bless {%args}, $class;
    $self->_get_pidfile;
    $self->_get_pid;
    $self->{owner} = 0;
    $self->{is_running} = -1; # Unknown (is as running)

    return $self;
}

sub file {
    my $self = shift;
    $self->{file} = shift if scalar(@_) >= 1;
    return $self->{file};
}
sub pid {
    my $self = shift;
    $self->{pid} = shift if scalar(@_) >= 1;
    return $self->{pid};
}
sub running {
    my $self = shift;
    my $pid  = $self->_get_pid_from_file || 0;
    my $r = kill(0, $pid) ? $pid : undef;
    $self->{is_running} = $r ? 1 : 0;
    return $r;
}
sub remove {
    my $self = shift;
    $self->{owner} = 0;
    my $file = $self->_get_pidfile;
    return unless -e $file;
    unlink $file;
}
sub write {
    my $self = shift;
    my $file = $self->_get_pidfile;
    my $pid  = $self->_get_pid;
    fsave($file, "$pid\n" ) or return;
    $self->{owner} = $pid;
    return $pid;
}

sub _get_pidfile {
    my $self = shift;
    $self->file(File::Spec->catfile(rundir(), sprintf("%s.pid", basename($0)))) unless $self->file;
    return $self->file;
}
sub _get_pid {
    my $self = shift;
    $self->pid($self->_get_pid_from_file || $$) unless $self->pid;
    return $self->pid;
}
sub _get_pid_from_file {
    my $self = shift;
    my $file = $self->_get_pidfile;
    return unless -e $file;
    my $pid = fload($file);
    return unless $pid;
    chomp $pid;
    return $pid;
}

sub DESTROY {
    my $self = shift;
    return unless $self;
    return unless $self->{autoremove};
    return $self->remove unless $self->{is_running};
    return unless $self->{owner};
    return unless $self->{owner} == $self->_get_pid;
    $self->remove;
}

1;

__END__
