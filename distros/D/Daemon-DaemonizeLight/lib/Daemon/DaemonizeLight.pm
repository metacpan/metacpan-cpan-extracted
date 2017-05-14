package Daemon::DaemonizeLight;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(daemonize);
use strict;
use FindBin;
use Proc::ProcessTableLight 'process_table';

=head1 NAME

Daemon::DaemonizeLight - New variant of Daemon::Daemonize based on nohup unix command

=head1 SYNOPSIS

use strict;
use Daemon::DaemonizeLight 'daemonize';

daemonize();

... something useful code

=head1 DESCRIPTION

This module provides create simple daemon from your perl script.

Only add the daemonize procedure at the beginning of your script.

It provide 'start' 'stop' 'restart' arguments for you script in command string.

=cut

sub check_process{
  my ($pid)=@_;
  
  my $t=process_table();
  
  my $exists=0;
  my $script=$FindBin::RealScript;
  my $i=0;
  foreach my $p ( @{$t} ){
    $exists=1 if (!$pid || $p->{PID}==$pid) && $p->{PID}!=$$ && $p->{COMMAND}=~/$script/;
  }
  
  return $exists;
}

sub stop{
  my ($tmp)=@_;
  
  my $pid=read_pid($tmp);
  
  if ($pid){
    if (check_process($pid)){
      print "Try to killing process $FindBin::RealScript : $pid\n";
      kill 'KILL', $pid;
      my $i=0;
      while(check_process($pid) && $i<3){
        $i++;
        sleep(1);
        print ".";
      }
      if (check_process($pid)){
        print "Kill process $FindBin::RealScript : $pid FAIL\n";
      } else {
        print "Kill process $FindBin::RealScript : $pid SUCCESS\n";
      }
    } else {
      
    }
  } else {
    print "Nothing to kill\n";
  }
}

sub start{
  my ($tmp)=@_;
  if (check_process()){
    print "Process $FindBin::RealScript already exists\n";
  } else {
    my $script = $FindBin::Bin.'/'.$FindBin::RealScript;
    my $clear_script = $tmp.'/'.clear_ext($FindBin::RealScript);
    
    print "Starting the process $FindBin::RealScript\n";
    
    my $cmd="nohup perl $script pid 1>$clear_script.log 2>$clear_script.err &";
    `$cmd`;
    
    sleep(1);
    if (check_process()){
      print "Starting process $FindBin::RealScript SUCCESS\n";
    } else {
      print "Starting process $FindBin::RealScript FAILED\n";
    }
  }
}

sub restart{
  my ($tmp)=@_;
  stop($tmp);
  start($tmp);
}

sub pid{
  my ($tmp)=@_;
  
  my $script=clear_ext($FindBin::RealScript);
  open(F, ">$tmp/$script.pid");
  print F $$;
  close(F);
}

sub read_pid{
  my ($tmp)=@_;
  
  my $script=clear_ext($FindBin::RealScript);
  open(F, "$tmp/$script.pid");
  my $pid=<F>;
  $pid=~s/[\n\r]//gs;
  close(F);
  
  return $pid;
}

sub clear_ext{
  my ($script)=@_;
  
  $script=~s/\..{1,3}$//gs;
  
  return $script;
}

sub daemonize{
  my (%params)=@_;
  
  my $tmp=$params{tmp};
  $tmp=$FindBin::Bin if (!$tmp || !(-d $tmp));
  
  my $in=$ARGV[0];
  
  my $funcs_in={
    'start'=>\&start,
    'stop'=>\&stop,
    'restart'=>\&restart,
    'pid'=>\&pid
  };

  if (!$funcs_in->{$in}){
    delete $funcs_in->{pid};
    die 'Dont`t know input parameter '."'$in'\nTry to ".join(",", sort(keys(%{$funcs_in})))."\n";
  } else {
    &{$funcs_in->{$in}}($tmp);
    
    if ($in ne 'pid'){
      die "EXIT\n";
    }
  }
}

=head2 daemonize(%params)

%options - only one parameter yet tmp=>'/some/tmp/dir', if not exists then tmp dir takes from directory where your script placed.
=cut

=head1 SEE ALSO

L<Daemon::Daemonize>

=head1 AUTHOR

Bulichev Evgeniy, <F<bes@cpan.org>>.

=head1 COPYRIGHT

  Copyright (c) 2017 Bulichev Evgeniy.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut


1;