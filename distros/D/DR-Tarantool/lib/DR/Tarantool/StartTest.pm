use utf8;
use strict;
use warnings;

package DR::Tarantool::StartTest;
use Carp;
use File::Temp qw(tempfile tempdir);
use File::Path 'rmtree';
use File::Spec::Functions qw(catfile rel2abs);
use Cwd;
use IO::Socket::INET;
use POSIX ();
use List::MoreUtils 'any';


=head1 NAME

DR::Tarantool::StartTest - finds and starts Tarantool on free port.

=head1 SYNOPSIS

 my $t = run DR::Tarantool::StartTest ( cfg => $file_spaces_cfg );

=head1 DESCRIPTION

The module tries to find and then to start B<tarantool_box>.

The module is used inside tests.


=head1 METHODS

=head2 run

Constructor. Receives the following arguments:

=over

=item cfg

path to tarantool.cfg

=back

=cut


sub compare_versions($$) {
    my ($v1, $v2) = @_;
    my @v1 = split /\./, $v1;
    my @v2 = split /\./, $v2;

    for (0 .. (@v1 < @v2 ? $#v1 : $#v2)) {
        return 'gt' if $v1[$_] > $v2[$_];
        return 'lt' if $v1[$_] < $v2[$_];
    }
    return 'gt' if @v1 > @v2;
    return 'lt' if @v1 < @v2;
    return 'eq';
}


=head2 is_version(VERSION[, FAMILY])

return true if tarantool_box is found and its version is more than L<VERSION>.

FAMILY can be:

=over

=item B<1> (default)

For tarantool < 1.6.

=item B<2>

For tarantool >= 1.6.

=back

=cut

sub is_version($;$) {
    my ($version, $family) = @_;

    my $box;
    $family ||= 1;

    croak "Unknown family: $family" unless any { $family == $_ } 1, 2;

    if ($family == 1) {
        $box = $ENV{TARANTOOL_BOX} || 'tarantool_box';
    } else {
        $box = $ENV{TARANTOOL_BOX} || 'tarantool';
    }
   
    my $str;
    {
        local $SIG{__WARN__} = sub {  };
        $str = `$box -V`;
    }

    return 0 unless $str;
    return 0 if $str =~ /^tarantool client, version/;
    my ($vt) = $str =~ /^Tarantool:?\s+(\d(?:\.\d+)+).*\s*$/s;
    return 0 unless $vt;
    my $res = compare_versions $version, $vt;
    return 0 unless any { $_ eq $res } 'eq', 'lt';
    return 1;
}

sub run {
    my ($module, %opts) = @_;

    my $cfg_file = delete $opts{cfg} or croak "config file not defined";
    croak "File not found" unless -r $cfg_file;
    open my $fh, '<:encoding(UTF-8)', $cfg_file or die "$@\n";
    local $/;
    my $cfg = <$fh>;

    my $family = $opts{family} || 1;
    croak "Unknown family: $family" unless any { $family == $_ } 1, 2;

    my %self = (
        admin_port      => $module->_find_free_port,
        primary_port    => $module->_find_free_port,
        secondary_port  => $module->_find_free_port,
        cfg_data        => $cfg,
        master          => $$,
        cwd             => getcwd,
        add_opts        => \%opts,
        family          => $family,
    );

    $opts{script_dir} = rel2abs $opts{script_dir} if $opts{script_dir};

    my $self = bless \%self => $module;
    $self->_start_tarantool;
    $self;
}


sub family {
    my ($self) = @_;
    return $self->{family};
}


=head2 started

Return true if Tarantool is found and started

=cut

sub started {
    my ($self) = @_;
    return $self->{started};
}


=head2 log

Return Tarantool logs

=cut

sub log {
    my ($self) = @_;
    return '' unless $self->{log} and -r $self->{log};
    open my $fh, '<encoding(UTF-8)', $self->{log};
    local $/;
    my $l = <$fh>;
    return $l;
}

sub admin {
    my ($self, @cmd) = @_;
    $cmd[-1] =~ s/\s*$/\n/;
    my $cmd = join ' ' => @cmd;

    my $s = IO::Socket::INET->new(
                PeerHost    => '127.0.0.1',
                PeerPort    => $self->admin_port,
                Proto       => 'tcp',
                (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
            );

    croak "Can't connect to admin port: $!" unless $s;
    print $s $cmd;
    my @lines;
    while(<$s>) {
        s/\s*$//;
        next if $_ eq '---';
        last if $_ eq '...';
        push @lines => $_;
    }
    close $s;
    return @lines;
}

sub _start_tarantool {
    my ($self) = @_;
    if ($ENV{TARANTOOL_TEMPDIR}) {
        $self->{temp} = $ENV{TARANTOOL_TEMPDIR};
        $self->{dont_unlink_temp} = 1;
        rmtree $self->{temp} if -d $self->{temp};
        mkdir $self->{temp};
    } else {
        $self->{temp} = tempdir;
    }

    if ($self->family) {
        $self->{cfg} = catfile $self->{temp}, 'tarantool.cfg';
    } else {
        $self->{cfg} = catfile $self->{temp}, 'box.lua';
    }
    $self->{log} = catfile $self->{temp}, 'tarantool.log';
    $self->{pid} = catfile $self->{temp}, 'tarantool.pid';
    $self->{core} = catfile $self->{temp}, 'core';



    if ($self->family == 1) {
        croak "Available tarantool is not valid (is_version '1.4.0')"
            unless is_version '1.4.0', $self->family;
    } else {
        croak "Available tarantool is not valid (is_version '1.4.0')"
            unless is_version '1.6.0', $self->family;
    }


    $self->{config_body} = $self->{cfg_data};
    if ($self->family == 1) {
        $self->{config_body} .= "\n\n";
        $self->{config_body} .= "slab_alloc_arena = 1.1\n";
        $self->{config_body} .= sprintf "pid_file = %s\n", $self->{pid};
        $self->{box} = $ENV{TARANTOOL_BOX} || 'tarantool_box';

        $self->{config_body} .= sprintf "%s = %s\n", $_, $self->{$_}
            for (qw(admin_port primary_port secondary_port));

        $self->{config_body} .=
            sprintf qq{logger = "cat >> %s"\n}, $self->{log};

        for (keys %{ $self->{add_opts} }) {
            my $v = $self->{add_opts}{ $_ };

            if ($v =~ /^\d+$/) {
                $self->{config_body} .= sprintf qq{%s = %s\n}, $_, $v;
            } else {
                $self->{config_body} .= sprintf qq{%s = "%s"\n}, $_, $v;
            }
        }
    } else {
        $self->{box} = $ENV{TARANTOOL_BOX} || 'tarantool';
        for ($self->{config_body}) {
            if (/primary_port\s*=/) {
                s{listen\s*=\s*['"]?\d+['"]}
                    /listen = @{[$self->primary_port]}/;
            } else {
                s<box\.cfg\s*\(?\s*\{>
                    /$& listen = '127.0.0.1:@{[$self->primary_port]}',/;
            }

            $_ .= "\n\nrequire('console')".
                ".listen('127.0.0.1:@{[$self->admin_port]}')";
        }
    }

    return unless open my $fh, '>:encoding(UTF-8)', $self->{cfg};

    print $fh $self->{config_body};

    close $fh;

    chdir $self->{temp};

    if ($self->family == 1) {
        system "$self->{box} -c $self->{cfg} ".
            "--check-config >> $self->{log} 2>&1";
        goto EXIT if $?;

        system "$self->{box} -c $self->{cfg} --init-storage ".
            ">> $self->{log} 2>&1";
        goto EXIT if $?;
    }
    $self->_restart;
    EXIT:
        chdir $self->{cwd};

}

sub _restart {
    my ($self) = @_;

    unless ($self->{child} = fork) {
        chdir $self->{temp};
        die "Can't fork: $!" unless defined $self->{child};
        POSIX::setsid();
        if ($self->family == 1) {
            exec "ulimit -c unlimited; ".
                "exec $self->{box} -c $self->{cfg} >> $self->{log} 2>&1";
        } else {
            exec "ulimit -c unlimited; ".
                "exec $self->{box} $self->{cfg} >> $self->{log} 2>&1";
        }
        die "Can't start $self->{box}: $!\n";
    }

    $self->{started} = 1;


    # wait for starting Tarantool
    for (my $i = 0; $i < 100; $i++) {
        last if IO::Socket::INET->new(
            PeerAddr => '127.0.0.1', PeerPort => $self->primary_port
        );

        sleep 0.01;
    }

    for (my $i = 0; $i < 100; $i++) {
        last if $self->log =~ /entering event loop/;
        sleep 0.01;
    }

    sleep 1 unless $self->log =~ /entering event loop/;
}

sub restart {
    my ($self) = @_;
    $self->kill('KILL');
    $self->_restart;
}

=head2 primary_port

Return Tarantool primary port

=cut

sub primary_port { return $_[0]->{primary_port} }


=head2 admin_port

Return Tarantool admin port

=cut

sub admin_port { return $_[0]->{admin_port} }


=head2 tarantool_pid

Return B<PID>

=cut

sub tarantool_pid { return $_[0]->{child} }


=head2 kill

Kills Tarantool

=cut

sub kill :method {
    my ($self, $signame) = @_;

    $signame ||= 'TERM';
    if ($self->{child}) {
        kill $signame => $self->{child};
        waitpid $self->{child}, 0;
        delete $self->{child};
    }
    $self->{started} = 0;
}


=head2 is_dead

Return true if child Tarantool process is dead.

=cut

sub is_dead {
    my ($self) = @_;
    return 1 unless $self->{child};
    return 0 if 0 < kill 0 => $self->{child};
    return 1;
}

=head2 DESTROY

Destructor. Kills tarantool, removes temporary files.

=cut

sub DESTROY {
    my ($self) = @_;
    local $?;
    chdir $self->{cwd};
    return unless $self->{master} == $$;

    if (-r $self->{core}) {
        warn "Tarantool was coredumped\n" if -r $self->{core};
        system "echo bt|gdb $self->{box} $self->{core}";
    }

    $self->kill;
    rmtree $self->{temp} if $self->{temp} and !$self->{dont_unlink_temp};
}


sub temp_dir {
    my ($self) = @_;
    return $self->{temp};
}


sub clean_xlogs {
    my ($self) = @_;
    return unless $self->{temp};
    my @xlogs = glob catfile $self->{temp}, '*.xlog';
    unlink for @xlogs;
}

{
    my %busy_ports;

    sub _find_free_port {

        while( 1 ) {
            my $port = 10000 + int rand 30000;
            next if exists $busy_ports{ $port };
            next unless IO::Socket::INET->new(
                Listen    => 5,
                LocalAddr => '127.0.0.1',
                LocalPort => $port,
                Proto     => 'tcp',
                (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
            );
            return $busy_ports{ $port } = $port;
        }
    }
}

=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=head1 VCS

The project is placed git repo on github:
L<https://github.com/dr-co/dr-tarantool/>.

=cut

1;
