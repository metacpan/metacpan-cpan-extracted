package App::derived;

use strict;
use warnings;
use 5.008005;
use File::Temp qw/tempfile/;
use File::Copy;
use Proclet;
use JSON ();
use Log::Minimal;

our $VERSION = '0.10';

my $_JSON = JSON->new()
    ->utf8(1)
    ->shrink(1)
    ->space_before(0)
    ->space_after(0)
    ->indent(0);

sub new {
    my $class = shift;
    my %opt = ref $_[0] ? %{$_[0]} : @_;
    my %args = (
        proclet  => Proclet->new(enable_log_worker => ($ENV{LM_DEBUG} ? 1 : 0)),
        interval => 10,
        host     => 0,
        port     => 12306,
        timeout  => 10,
        services => {},
        %opt
    );
    bless \%args, $class;
}

sub add_service {
    my $self = shift;
    my ($key, $cmd) = @_;
    my ($tmpfh,$tmpfile) = tempfile(UNLINK=>0, EXLOCK=>0);
    print $tmpfh $_JSON->encode({
        status=>"INIT",
        persec => '0E0',
        latest => '0E0',
    });
    close $tmpfh;
    $self->{services}->{$key} = {
        cmd => ['bash', '-c', $cmd],
        file => $tmpfile,
        prev => undef,
    };
    infof("register service: %s", $key);
    $self->{proclet}->service(
        code => sub {
            $0 = "$0 worker $key";
            $self->worker($key);
            exit;
        },
        tag => $key.'_worker',
    );
}

sub add_plugin {
    my $self = shift;
    my ( $plugin, $args) = @_;

    my %args = (
        %$args,
        _services => $self->{services},
        _proclet => $self->{proclet},
    );    
    infof("register plugin: %s", $plugin);
    my $instance = $plugin->new(\%args);
    $instance->init();
}

sub run {
    my $self = shift;
    $self->{proclet}->run;
}

sub DESTROY {
    my $self = shift;
    for my $key ( keys %{$self->{services}} ) {
        unlink $self->{services}->{$key}->{file};
    }
}

sub worker {
    my ($self, $service_key) = @_;
    srand();
    my $service = $self->{services}->{$service_key};
    my $n = time;
    $n = $n - ( $n % $self->{interval}) + $self->{interval} + int(rand($self->{interval}));; #next + random
    my $stop = 1;
    local $SIG{TERM} = sub { $stop = 0 };

    while ( $stop ) {
        my $current = time();
        while ( $n < $current ) {
            $n = $n + $self->{interval};
        }
        while ( $stop ) {
            last if time() >= $n;
            select undef, undef, undef, 0.1 ## no critic;
        }
        $n = $n + $self->{interval};
        local $Log::Minimal::AUTODUMP = 1;
        debugf("exec command for %s => %s", $service_key, $service);
        my ($result, $exit_code) = cap_cmd($service->{cmd});
        debugf("command [%s]: exit_code:%s result:%s", $service_key, $exit_code, $result);
        if ( ! defined $result ) {
            atomic_write($service->{file}, {
                status => "ERROR",
                persec => undef,
                latest => undef,
                raw => undef,
                exit_code => $exit_code,
                last_update => time,
            });
            next;
        }
    
        my $orig = $result;
        $result =~ s!^[^0-9]+!!;
        {
            no warnings;
            $result = int($result);
        }
        if ( ! defined $service->{prev} ) {
            $service->{prev} = $result;
            atomic_write( $service->{file}, {
                status => "CALCURATE",
                persec => "E0E",
                latest => $result,
                raw => $orig,
                exit_code => $exit_code,
                last_update => time,
            });
            next;
        }
        my $derive = ($result - $service->{prev}) / $self->{interval};
        atomic_write( $service->{file}, {
            status => "OK",
            persec => $derive,
            latest => $result,
            raw => $orig,
            exit_code => $exit_code,
            last_update => time,
        });
        $service->{prev} = $result;
    }
}

sub cap_cmd {
    my ($cmdref) = @_;
    pipe my $logrh, my $logwh
        or die "Died: failed to create pipe:$!";
    my $pid = fork;
    if ( ! defined $pid ) {
        die "Died: fork failed: $!";
    } 

    elsif ( $pid == 0 ) {
        #child
        close $logrh;
        open STDOUT, '>&', $logwh
            or die "Died: failed to redirect STDOUT";
        close $logwh;
        exec @$cmdref;
        die "Died: exec failed: $!";
    }
    close $logwh;
    my $result;
    while(<$logrh>){
        chomp;chomp;
        $result .= $_;
    }
    close $logrh;
    while (wait == -1) {}
    my $exit_code = $?;
    $exit_code = $exit_code >> 8;
    if ( $exit_code != 0 ) {
        warnf("Error: command exited with code: $exit_code");
    }
    return ($result, $exit_code);
}

sub atomic_write {
    my ($writefile, $body) = @_;
    my ($tmpfh,$tmpfile) = tempfile(UNLINK=>0);
    print $tmpfh $_JSON->encode($body);
    close($tmpfh);
    move( $tmpfile, $writefile);
}


1;
__END__

=encoding utf8

=head1 NAME

App::derived - run command periodically and calculate rate and check from network

=head1 SYNOPSIS

  $ cat CmdsFile
  slowqueries: mysql -NB -e 'show global status like "Slow_queries%"'
  $ derived -MMemcahced,port=11211,host=127.0.0.1 CmdsFile

  $ telnet localhost port
  get slowqueris
  VALUE slowqueris 0 3
  0.2  # slow queries/sec

=head1 DESCRIPTION

derived runs commands periodically and capture integer value. And calculate per-second rate. 
You can retrieve these values from integrated memcached-protocol server or pluggable workers.

You can monitoring the variation of metrics through this daemon.

See detail for perldoc "derived"

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=head1 SEE ALSO

<derived>

=head1 LICENSE

Copyright (C) Masahiro Nagano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
