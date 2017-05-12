package CHI::t::Driver::TokyoTyrant;

use strict;
use warnings;

use base qw(CHI::t::Driver);

use POSIX qw/SIGTERM WNOHANG :sys_wait_h/;
use File::Slurp;
use File::Temp qw/ :POSIX /;
use File::Spec;
use Config;

$File::Temp::KEEP_ALL = 1;


sub testing_driver_class    { 'CHI::Driver::TokyoTyrant' }
sub supports_get_namespaces { 1 }
sub supports_clear { 1 }

my $ttserver;
my $pid_file;
my $port = 21000;

sub required_modules {
  return { TokyoTyrant => undef, 'File::Temp' => undef, POSIX => 'SIGTERM WNOHANG :sys_wait_h',
            'File::Slurp' => undef, 'File::Spec' => undef, Config => undef,
         };
}


sub start_server : Test(startup) {


  my $self = shift;

  $pid_file = tmpnam();


  my $bin = _find_bin();

  die "Cannot find ttserver" unless $bin;

  my $started = 0;
  foreach my $i (0 .. 3) {

    my $use_port = $port + $i;
    system("$bin -dmn -pid $pid_file -port $use_port -log /tmp/ttlog");

    if ($? == -1 || ! $? & 127) {
      $started = 1;
      $port = $use_port;
      last;
    }
  }

  die "cannot execute ttserver" unless $started;

  my $ttserver_pid = read_file($pid_file) || die "Cannot read pid file $pid_file: $!";
  die "ttserver execution failed" unless $ttserver_pid;
  $self->{ttserver_pid} = $ttserver_pid;


}

sub stop_server : Test(shutdown) {

  my $self = shift;


    return unless defined $self->{ttserver_pid};
    my $sig ||= SIGTERM;

    kill $sig, $self->{ttserver_pid};

    delete $self->{ttserver_pid};

    unlink $pid_file;

};


sub SKIP_CLASS {
  my $class = shift;


  my $bin = _find_bin();
  return "cannot find ttserver" unless $bin;

  return 0;

}


sub new_cache_options {
  my $self = shift;

    return ( $self->SUPER::new_cache_options(), port => $port );
        
}

sub _find_bin {

    my @paths = File::Spec->path();

    my $searched_binary = 'ttserver';

    if ($Config{_exe}) {
      $searched_binary .= $Config{_exe};
    }

    for my $path (@paths) {
        my $bin = File::Spec->catfile($path, $searched_binary);
        return $bin if -x $bin;
    }

    return;
}

1;
