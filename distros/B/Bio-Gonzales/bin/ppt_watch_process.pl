#!/usr/bin/env perl

use warnings;
use strict;
use Time::HiRes;
use Proc::ProcessTable;
use Scalar::Util::Numeric qw/isnan isinf/;
use List::Util qw/sum/;
use Mail::Sendmail;
use Data::Dumper;
unshift @{ $Mail::Sendmail::mailcfg{'smtp'} }, 'net.wur.nl';

use Pod::Usage;
use Getopt::Long qw(:config auto_help);

my %opt = (
  interval     => 60,
  mail         => ['joachim.bargsten@wur.nl'],
  'threshold'  => 0.005,
  'num_steps'  => 3,
  waiting_time => 30,
  subject      => 'Proc::ProcessTable process tracking'
);

GetOptions(
  \%opt,         'help|?',      'waiting_time=i', 'subject=s', 'interval=i', 'mail=s@',
  'threshold=s', 'num_steps=i', "verbose"
) or pod2usage(2);

pod2usage( -exitval => 0, -verbose => 2 ) if ( $opt{help} );

pod2usage(2)
  unless ( @ARGV && @ARGV > 0 );

my @pids           = @ARGV;
my $poll_intervall = $opt{interval} * 1000 * 1000;

my @start_time;

$SIG{CHLD} = 'IGNORE';

my @cpu_time;

my $ppt = Proc::ProcessTable->new;

my $pid_running = 1;

BIG:
while ($pid_running) {
  my $pt = parse_ppt( $ppt->table );
  my %childs;
  for my $pid (@pids) {
    map { $childs{$_} => 1 } subproc_ids( $pid, $pt );
    $childs{$pid} = 1;
  }

  my $sum_cpu   = 0;
  my $sum_start = 0;

  $pid_running = 0;
  for my $p (@$pt) {
    if ( $childs{ $p->[0] } ) {
      $pid_running = 1;
      #say STDERR "timepoint" unless(defined($time_point));
      #say STDERR "time" unless(defined($t));
      #say STDERR "process" unless((grep { defined $_ } @$p ) != @$p);
      $sum_cpu   += $p->[4];
      $sum_start += time - $p->[5];
    }
  }
  shift @cpu_time if ( @cpu_time > $opt{num_steps} );
  push @cpu_time, $sum_cpu;

  shift @start_time if ( @start_time > $opt{num_steps} );
  push @start_time, $sum_start;

  if ( @start_time >= $opt{num_steps} ) {
    my $diff_cpu   = ( $cpu_time[-1] - $cpu_time[0] ) / ( 1000 * 1000 );
    my $diff_start = ( $start_time[-1] - $start_time[0] );
    my $ratio      = $diff_cpu / $diff_start;
    printf "%3.2f ", $ratio if ( $opt{verbose} );
    if ( $ratio < $opt{threshold} ) {
      print "| " if ( $opt{verbose} );
      for my $mail ( @{ $opt{mail} } ) {
        send_mail(
          {
            To      => $mail,
            Subject => $opt{subject},
            Message => "blast2go has low cpu usage, probably it is finished and you can do the next step"
          }
        );

      }
      sleep $opt{waiting_time} * 60;

    }
  } else {
    print ". " if ( $opt{verbose} );
  }
  Time::HiRes::usleep($poll_intervall);
}
print "\n" if ( $opt{verbose} );

for my $mail ( @{ $opt{mail} } ) {
  send_mail(
    { To => $mail, Subject => $opt{subject}, Message => "blast2go is not running anymore and/or finished" } );
}

sub send_mail {
  my $c    = shift;
  my %mail = (
    From => 'joachim.bargsten@wur.nl',
    %$c
  );

  sendmail(%mail) or die $Mail::Sendmail::error;
}

sub parse_ppt {
  my $ppt_table = shift;
  my @table = map { [ $_->pid, $_->ppid, $_->rss, $_->size, $_->time, $_->start, $_->exec ] } @$ppt_table;
  return \@table;
}

sub subproc_ids {
  my ( $pid, $procs ) = @_;
  #[ pid, parentid ]
  my @childs;
  for my $c ( grep { $_->[1] == $pid } @$procs ) {
    push @childs, $c->[0];
    push @childs, subproc_ids( $c->[0], $procs );
  }
  return @childs;
}

__END__

=head1 NAME



=head1 SYNOPSIS

  track_b2g.pl [OPTIONS] <pid1> [<pid2 ... <pidn>]

=head1 DESCRIPTION

Track the CPU usage of processes and send a mail if the usage falls below a certain threshold.

=head1 OPTIONS

=over 4

=item B<< --waiting_time <minutes> >>

If the mail got send, wait C<< <minutes> >> minutes before resume tracking. This
prevents sending you hundreds of mails if the processes are below the
threshold.

=item B<< --subject <subject> >>

Set the subject of the mail.

=item B<< --interval <seconds> >>

Record every C<< <seconds> >> seconds the CPU usage.

=item B<<  --mail <address> >>

Send notification mails to C<< <address >>.

=item B<< --threshold <fraction> >>

Set he notification threshold to C<< <fraction> >>. 100% CPU usage corresponds to a fraction of 1.

=item B<< --num_steps <steps>  >>

The CPU usage is averaged over a time span of C<< <steps> * <interval time> >>.

=item B<< --verbose >>

Enable reporting of CPU usage fraction to STDOUT. If the number of steps is
smaller than the averaging window, "." is printed. If a mail is sent, "|" is
printed.

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
