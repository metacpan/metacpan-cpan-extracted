package Test::Crypt::NSS::SelfServ;

use strict;
use warnings;

use File::Spec;
use File::Slurp qw(slurp);
use Test::Builder;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(start_ssl_server stop_ssl_server);
our @EXPORT_OK = @EXPORT;

my $Tester = Test::Builder->new();
my $Pid;

# Stop any running server
my $Pid_file = File::Spec->catfile(File::Spec->tmpdir, "crypt-nss-selfserv.pid");
stop_ssl_server();

sub start_ssl_server {
    my %args = @_;
    
    my $bin = File::Spec->catfile($ENV{NSS_BASE}, "bin", "selfserv");
    unless (-e $bin) {
        $Tester->skip_all(q{Can't find ${NSS_BASE}/bin/server});
    }
    
    $Pid = fork();
    $Tester->skip_all(q{Fork failed}) unless defined $Pid;

    if ($Pid) {
        sleep 1;
        return;
    }

    my @args;
    
    # rsa nickname
    push @args, "-n", (exists $args{nickname} ? $args{nickname} : "127.0.0.1");
    
    # port
    push @args, "-p", ($args{port} || 4433);
    
    # db
    push @args, "-d", (exists $args{config_dir} ? $args{config_dir} : "db");
    
    # password
    push @args, "-w", (exists $args{password} ? $args{password} : "crypt-nss");
    
    # certs
    push @args, "-r" if $args{request_cert} || $args{require_cert};    
    push @args, "-r" if $args{require_cert};
    
#    close *STDERR;
#    close *STDOUT;
    
    exec($bin, @args, "-i", $Pid_file);
}

sub stop_ssl_server {
    if (-e $Pid_file) {
        my $pid = slurp($Pid_file);
        if ($pid) {
            kill 9, $pid;    
        }
    }
    unlink $Pid_file;
}

1;
__END__
