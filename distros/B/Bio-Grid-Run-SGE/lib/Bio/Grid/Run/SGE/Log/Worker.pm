package Bio::Grid::Run::SGE::Log::Worker;

use Mouse;

use warnings;
use strict;
use Carp;

our $VERSION = '0.066'; # VERSION
use Bio::Gonzales::Util::File qw/slurpc open_on_demand/;
has log_file => ( is => 'rw', required => 1 );
has log_data => ( is => 'rw' );

sub BUILD {
  my ($self) = @_;
  $self->_parse unless $self->log_data;
}

sub _parse {
  my ($self) = @_;
  my $log_file = $self->log_file;

  return unless ( -f $log_file );
  my @raw_log = slurpc $log_file;
  return unless ( @raw_log > 0 );

  my %log;
  for my $line (@raw_log) {
    if ( $line =~ /^([\w.]+)(::? )?(.*)$/ ) {
      if ( $2 && length($2) == 3 ) {
        $log{$1} = []
          unless ( exists( $log{$1} ) );

        push @{ $log{$1} }, $3;
      } elsif ($2) {
        $log{$1} = $3;
      } else {
        $log{$1} = 1;
      }
    }
  }

  $self->log_data( \%log );
  return \%log;
}

sub to_script {
  my $self = shift;
  my $src  = shift;

  my $data = $self->log_data;

  # get perl executable
  $data->{job_cmd} =~ /-S\s+(\S+)/;
  my $perl = $1;

  my @job_cmd = ( split /\s+/, $data->{job_cmd} )[ -4 .. -1 ];

  my ( $fh, $was_open ) = open_on_demand( $src, '>' );

  print $fh "#!/usr/bin/env bash\n";
  print $fh "export SGE_TASK_ID=" . $data->{id}, "\n";
  print $fh "export JOB_ID=" . $data->{job_id},  "\n";
  print $fh "export SGE_STDERR_PATH=" . $data->{'err'}, "\n";
  print $fh "export SGE_STDOUT_PATH=" . $data->{'out'}, "\n";

  print $fh join( ' ', $perl, @job_cmd ), "\n";

  $fh->close unless $was_open;
}

__PACKAGE__->meta->make_immutable();
