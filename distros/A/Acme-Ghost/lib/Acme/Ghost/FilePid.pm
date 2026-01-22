package Acme::Ghost::FilePid;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

Acme::Ghost::FilePid - The Pid File simple interface

=head1 SYNOPSIS

    use Acme::Ghost::FilePid;

    my $fp = Acme::Ghost::FilePid->new (
        file => '/some/file.pid',
    );

    if ( my $num = $fp->running ) {
        die "Already running: $num";
    } else {
        $fp->save;
        # . . .
        $fp->remove;
    }

... or with autoremove:

    my $fp = Acme::Ghost::FilePid->new (
        file => '/some/file.pid',
        autoremove => 1,
    );
    die "Already running" if $fp->running;
    $fp->save;
    # . . .

... or with autosave and autoremove

    my $fp = Acme::Ghost::FilePid->new (
        file => '/some/file.pid',
        auto => 1,
    );
    die "Already running" if $fp->running;
    # . . .

=head1 DESCRIPTION

This software manages a pid file for you. It will create a pid file,
query the process within to discover if it's still running, and remove
the pid file.

=head2 new

    my $fp = Acme::Ghost::FilePid->new;

    my $fp = Acme::Ghost::FilePid->new(
        file => '/var/run/daemon.pid',
    );

    my $fp = Acme::Ghost::FilePid->new(
        file => '/var/run/daemon.pid',
        pid  => '145',
        autoremove => 1,
    );

This constructor takes three optional paramters.

C<file> - The name of the pid file to work on. If not specified, a pid
file located in C<tempdir()>. So, for example, if C<$0> is F<~/bin/sig.pl>,
the pid file will be F</tmp/sig.pl.pid>.

C<pid> - The pid to write to a new pidfile. If not specified, C<$$> is
used when the pid file doesn't exist. When the pid file does exist, the
pid inside it is used.

C<autoremove> - Auto-remove flag. If this flag specified as true, then
will be removed the pid file automatically on DESTROY phase. Default: false

C<autosave> - Auto-save flag. If this flag specified as true, then
will be saved the pid file automatically while instance create. Default: false

C<auto> - this flag forced sets C<autoremove> and C<autosave> flags. Default: false

=head2 file

    $fp->file("/var/run/file.pid");
    my $pidfile = $fp->file;

Accessor/mutator for the filename used as the pid file.

=head2 load

    $fp->load;

Load owner pid from file.
On success, the object is returned. On failure, C<undef> is
returned.

=head2 owner

    $fp->owner(123);
    my $owner = $fp->owner;

Accessor/mutator for the pid being saved to the pid file.

=head2 pid

    $fp->pid(123);
    my $pid = $fp->pid;

Accessor/mutator for the pid being saved to the pid file.

=head2 remove

    $fp->remove;

Removes the pid file from disk. Returns true on success, false on
failure.

=head2 running

    my $pid = $fp->running;
    die "Service already running: $pid" if $pid;

Checks to see if the pricess identified in the pid file is still
running. If the process is still running, the pid is returned. Otherwise
C<undef> is returned.

=head2 save

    $fp->save;

Writes the pid file to disk, inserting the pid inside the file.
On success, the object is returned. On failure, C<undef> is
returned.

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<CTK::FilePid>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2026 D&D Corporation

=head1 LICENSE

This program is distributed under the terms of the Artistic License Version 2.0

See the C<LICENSE> file or L<https://opensource.org/license/artistic-2-0> for details

=cut

use Carp qw/croak/;
use File::Spec;
use File::Basename qw//;
use IO::File qw//;

sub new {
    my $class = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    my $self  = bless {%$args}, $class;
    $self->{autoremove} ||= $args->{auto} ? 1 : 0;
    $self->{autosave}   ||= $args->{auto} ? 1 : 0;;
    $self->{file}       //= File::Spec->catfile(File::Spec->tmpdir(), sprintf("%s.pid", File::Basename::basename($0)));
    $self->{pid}        ||= $$; # Current PID
    $self->{owner}      ||= 0; # Owner PID
    $self->{is_running} = -1; # Unknown (is as running)
    if ($self->{autosave}) {
        return $self->running ? $self : $self->save;
    }
    return $self->load;
}

sub file {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{file} = shift;
        return $self;
    }
    return $self->{file};
}
sub pid {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{pid} = shift;
        return $self;
    }
    return $self->{pid};
}
sub owner {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{owner} = shift;
        return $self;
    }
    return $self->{owner};
}
sub running {
    my $self = shift;
    my $owner  = $self->load->owner || 0; # Get PID from file
    my $r = kill(0, $owner) ? $owner : undef;
    $self->{is_running} = $r ? 1 : 0;
    return $r; # Is running?
}
sub remove {
    my $self = shift;
    my $file = $self->file;
    return $self unless -e $file;
    unlink $file;
    $self->owner(0); # Set owner PID to 0
    return $self;
}
sub save {
    my $self = shift;
    my $file = $self->file;
    my $pid  = $self->pid || $$;
       $self->owner($pid); # Set owner PID as current PID

    # Save PID to file
    my $fh = IO::File->new($file, "w");
    croak qq/Can't open file "$file": $!/ unless defined $fh;
    $fh->write("$pid\n") or croak qq/Can't write to file "$file": $!/;
    undef $fh; # automatically closes the file

    # Returns self
    return $self;
}
sub load {
    my $self = shift;
    my $file = $self->file;
    return $self unless -e $file;

    # Read file
    my $ret = my $content = '';
    my $fh = IO::File->new($file, "r");
    croak qq/Can't open file "$file": $!/ unless defined $fh;
    while ($ret = $fh->read(my $buf, 255)) { $content .= $buf }
    croak qq/Can't read from file "$file": $!/ unless defined $ret;
    undef $fh; # automatically closes the file

    # Set loaded PID as owner
    chomp $content;
    $self->owner(($content || 0) * 1) if $content =~ /^\d+$/;

    # Returns object
    return $self;
}
sub DESTROY {
    my $self = shift;
    return unless $self;
    return unless $self->{autoremove};
    return $self->remove unless $self->{is_running};
    return unless $self->{owner};
    $self->remove if $self->{owner} == $self->{pid};
}

1;

__END__
