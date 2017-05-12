package BuzzSaw::Reporter;
use strict;
use warnings;

# $Id: Reporter.pm.in 21690 2012-08-23 07:47:01Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 21690 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Reporter.pm.in $
# $Date: 2012-08-23 08:47:01 +0100 (Thu, 23 Aug 2012) $

our $VERSION = '0.12.0';

use BuzzSaw::DateTime ();
use BuzzSaw::ReportLog ();
use BuzzSaw::Types qw(BuzzSawReportList);

use Readonly;

Readonly my $ONE_HOUR => 60 * 60;
Readonly my $ONE_DAY  => $ONE_HOUR * 24;
Readonly my $ONE_WEEK => $ONE_DAY * 7;

Readonly my @REPORT_TYPES => qw/hourly daily weekly monthly/;

use Moose;
use MooseX::Types::Moose qw(Bool);

with 'MooseX::Log::Log4perl', 'MooseX::SimpleConfig';

has '+configfile' => (
  default => '/etc/buzzsaw/reporter.yaml',
);

has 'all' => (
  is      => 'rw',
  isa     => Bool,
  default => 0,
);

has 'dryrun' => (
  is      => 'rw',
  isa     => Bool,
  default => 0,
);

has 'hourly' => (
  traits  => ['Array'],
  is      => 'ro',
  isa     => BuzzSawReportList,
  coerce  => 1,
  default => sub { [] },
  handles => {
    hourly_list => 'elements',
  },
);

has 'daily' => (
  traits  => ['Array'],
  is      => 'ro',
  isa     => BuzzSawReportList,
  coerce  => 1,
  default => sub { [] },
  handles => {
    daily_list => 'elements',
  },
);

has 'weekly' => (
  traits  => ['Array'],
  is      => 'ro',
  isa     => BuzzSawReportList,
  coerce  => 1,
  default => sub { [] },
  handles => {
    weekly_list => 'elements',
  },
);

has 'monthly' => (
  traits  => ['Array'],
  is      => 'ro',
  isa     => BuzzSawReportList,
  coerce  => 1,
  default => sub { [] },
  handles => {
    monthly_list => 'elements',
  },
);

has 'runlog' => (
  is      => 'ro',
  isa     => 'BuzzSaw::ReportLog',
  default =>  sub { BuzzSaw::ReportLog->new( store_after_change => 1 ) },
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub generate_reports {
  my ( $self, @reports ) = @_;

  if ( scalar @reports == 0 ) {
    @reports = @REPORT_TYPES;
  }

  for my $report (@reports) {
    if ( $report eq 'hourly' ) {
      $self->run_hourly_reports;
    } elsif ( $report eq 'daily' ) {
      $self->run_daily_reports;
    } elsif ( $report eq 'weekly' ) {
      $self->run_weekly_reports;
    } elsif ( $report eq 'monthly' ) {
      $self->run_monthly_reports;
    } else {
      warn "Ignoring unsupported report type '$report'\n";
    }
  }

  return;
}

sub run_hourly_reports {
  my ($self) = @_;

  if ( $self->log->is_debug ) {
    $self->log->debug('Running hourly reports');
  }

  return $self->_run_reports( $ONE_HOUR, 'hourly', $self->hourly_list );
}

sub run_daily_reports {
  my ($self) = @_;

  if ( $self->log->is_debug ) {
    $self->log->debug('Running daily reports');
  }

  return $self->_run_reports( $ONE_DAY, 'daily', $self->daily_list );
}

sub run_weekly_reports {
  my ($self) = @_;

  if ( $self->log->is_debug ) {
    $self->log->debug('Running weekly reports');
  }

  return $self->_run_reports( $ONE_WEEK, 'weekly', $self->weekly_list );
}

sub run_monthly_reports {
  my ($self) = @_;

  if ( $self->log->is_debug ) {
    $self->log->debug('Running monthly reports');
  }

  my $now = BuzzSaw::DateTime->now();
  $now->set_time_zone('local');

  my $dur = DateTime::Duration->new( months => 1 );
  my $then = $now - $dur;
  my $one_month = $now->epoch() - $then->epoch();

  return $self->_run_reports( $one_month, 'monthly', $self->monthly_list );
}

sub _run_reports {
  my ( $self, $duration, $report_type, @reports ) = @_;

  my $runlog = $self->runlog;

  # This is a little bit hacky...
  my $get_timestamp_method = 'get_' . $report_type . '_timestamp';
  my $set_timestamp_method = 'set_' . $report_type . '_timestamp';
  my $has_timestamp_method = 'has_' . $report_type . '_timestamp';

  for my $report (@reports) {
    my $name = $report->name;

    my $needs_run = 0;
    if ( $self->all ) {
      $needs_run = 1;
    } elsif ( $runlog->$has_timestamp_method($name) ) {
      my $now  = time;
      my $prev = $runlog->$get_timestamp_method($name);

      if ( $now - $prev >= $duration ) {
        $needs_run = 1;
      }

    } else {
      $needs_run = 1;
    }

    if ($needs_run) {
      if ( $self->dryrun ) {
        $self->log->info("Dry-run: Would have run $name $report_type report");
      } else {
        $self->log->info("Running $name $report_type report");
        $report->generate();
        $runlog->$set_timestamp_method( $name, time );
      }
    }

  }

  return;
}

1;
__END__
