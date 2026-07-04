package App::Ordo::Command::Ls;
use Moo;
use feature qw(say);
use utf8;
use open ':std', ':utf8';

extends 'App::Ordo::Command::Base';

use App::Ordo              qw($CURRENT_PATH epoch_to_tminus epoch_to_duration);
use Term::ANSIColor        qw(colored);
use Text::Table::Tiny 1.02 qw(generate_table);
use JSON::PP;

sub name    { "ls" }
sub summary { "List jobs and clusters in current path" }
sub usage   { "<path> [--wide|-l] [--deps] [--tree] [--json]" }

sub option_spec {
   return {
      'wide|l' => 'Show all columns including %CPU/%MEM/NEEDS',
      'json|j' => 'Output as JSON',
   };
}

has 'base_cluster_id' => (is => 'rw');
has 'cluster_by_id' => (is => 'rw');
has 'items' => (is => 'rw');
has 'json' => (is => 'rw', default => sub { JSON::PP->new->ascii->pretty->allow_nonref } );

sub execute {
   my ( $self, $opt, $name ) = @_;

   my $res = $self->api->call( 'find_cluster', { name => $name } );

   unless ( $res->{success} && $res->{clusters} && @{ $res->{clusters} } ) {
      say colored( ["bold yellow"], "No items found in current path" );
      return;
   }

   # Show local time
   my $now = scalar localtime;
   say colored( ["bright_black"], "Local time is $now" ) unless $opt->{json};

   $self->base_cluster_id($res->{clusters}[0]->{id});
   $self->items([]);

   $self->cluster_by_id( { map { $_->{id} => $_ } @{ $res->{clusters} } } );

   # Build hierarchy from current cluster
   my $base_path = $CURRENT_PATH;
   $self->_add_cluster_and_children( $self->base_cluster_id );

   if ( $opt->{json} ) {
      print $self->json->encode($res);
      return;
   }

   $self->_print_table( $self->items, $opt );
}

sub _add_cluster_and_children {
   my ( $self, $cluster_id, $base_path ) = @_;

   my $cluster = $self->cluster_by_id->{$cluster_id} or return;

   my $cluster_path = $cluster_id == $self->base_cluster_id ? '' 
                    : $base_path ? "$base_path/$cluster->{name}" 
                    : $cluster->{name};
   push @{ $self->items },
     {
      id          => $cluster->{id},
      full_path   => $cluster_path,
      jobstate    => $cluster->{jobstate} || '-',
      server_name => '',
      pid         => '',
      last_start  => epoch_to_tminus( $cluster->{started} ),
      duration    => epoch_to_duration( $cluster->{started}, $cluster->{ended} ),
      next_start  => epoch_to_tminus( $cluster->{next_start} ),
      cal_name    => $cluster->{cal_name},
      pctcpu      => '',
      pctmem      => '',
      needs       => $cluster->{needs} || {},
      is_cluster  => 1,
     } unless $cluster_id == $self->base_cluster_id;

   # Jobs
   my @jobs = sort { $a->{id} <=> $b->{id} } @{ $cluster->{jobs} || [] };
   for my $job (@jobs) {
      push @{ $self->items },
        {
         id          => $job->{id},
         full_path   => $cluster_path ? "$cluster_path/$job->{name}" : $job->{name},
         jobstate    => $job->{jobstate}    || '-',
         server_name => $job->{server_name} || '',
         pid         => $job->{pid} // '',
         last_start  => epoch_to_tminus( $job->{started} ),
         duration    => epoch_to_duration( $job->{started}, $job->{ended} ),
         next_start  => epoch_to_tminus( $job->{next_start} ),
         cal_name      => '',
         pctcpu      => $job->{pctcpu} // '',
         pctmem      => $job->{pctmem} // '',
         needs       => $job->{needs} || {},
         is_cluster  => 0,
        };
   }

   # Sub-clusters
   my @children = grep { $_->{parent_id} && $_->{parent_id} == $cluster_id } values %{ $self->cluster_by_id };
   @children = sort { $a->{id} <=> $b->{id} } @children;

   for my $child (@children) {
      $self->_add_cluster_and_children( $child->{id}, $cluster_path );
   }
}

sub _print_table {
   my ( $self, $items, $opt ) = @_;

   my @headers = ( "ID", "PATH", "STATE", "SERVER", "PID", "LAST_START", "DURATION", "NEXT_START", "CALENDAR" );
   push @headers, ( "%CPU", "%MEM", "NEEDS" ) if $opt->{wide};

   my @rows = ( \@headers );

   unshift @$items, {
      id => $self->base_cluster_id,
      full_path => $self->cluster_by_id->{$self->base_cluster_id}->{name},
      jobstate => $self->cluster_by_id->{$self->base_cluster_id}->{jobstate},
      is_cluster => 1.
   };

   for my $item (@$items) {
      my @deps = sort keys %{ $item->{needs} || {} };

      my $state_color =
          $item->{jobstate} =~ /^(complete|ice|prunded)/ ? 'green'
        : $item->{jobstate} eq 'immutable' ? 'cyan'
        : $item->{jobstate} eq 'running'  ? 'magenta'
        : $item->{jobstate} =~ /^(failed|hold|zombie)/ ? 'red'
        : $item->{jobstate} =~ /^(ready|waiting|looping|retrying)$/ ? 'yellow'
        :                                   'white';

      my $path_display =  
        $item->{is_cluster}
        ? colored( ["bold blue"], $item->{full_path} . '/')
        : $item->{full_path};

      unless ($self->base_cluster_id == $item->{id} && $item->{is_cluster}) {
         $path_display = '  ' . $path_display;
      }

      my @row = (
         $item->{id}, $path_display,
         colored( ["bold $state_color"], $item->{jobstate} ),
         $item->{server_name} || '',
         $item->{pid} // '',
         $item->{last_start} || '',
         $item->{duration}   || '',
         $item->{next_start} || '',
         $item->{cal_name} ? $item->{cal_name} : '',
      );

      push @row, ( $item->{pctcpu} // '', $item->{pctmem} // '', @deps ? join( ",", @deps ) : '', ) if $opt->{wide};

      if ( $opt->{deps} && @deps ) {
         push @rows, \@row;
         push @rows, [ ('') x 9, "← $_" ] for @deps;
      }
      else {
         push @rows, \@row;
      }
   }

   say generate_table(
      rows       => \@rows,
      header_row => 1,
      style      => 'boxrule',
   );
}

1;
