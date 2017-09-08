package Bio::Grid::Run::SGE::Util;

use warnings;
use strict;
use Carp qw/cluck confess carp/;

use File::Glob ':glob';
use File::Spec;
use File::Path qw/mkpath/;
use File::Spec::Functions qw/catfile/;
use Data::Dumper;
use List::Util qw/min/;
use Path::Tiny;
use JSON::XS qw/encode_json/;
use Bio::Gonzales::Util::Log;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.060'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(
  my_glob
  glob_list
  delete_by_regex
  expand_path
  my_mkdir
  concat_files
  my_glob_non_fatal
  timer
  expand_path_rel
  poll_interval
);

our $LOG =  Bio::Gonzales::Util::Log->new();

sub my_glob_non_fatal {
  my (@dirs) = @_;

  return unless defined wantarray;    # don't bother doing more
  my @expanded_dirs;
  for my $dir (@dirs) {
    push @expanded_dirs, bsd_glob( $dir, GLOB_TILDE | GLOB_ERR );
    confess 'glob error' if (GLOB_ERROR);
  }

  return unless (@expanded_dirs);

  @expanded_dirs = map { File::Spec->rel2abs($_) } @expanded_dirs;

  return wantarray ? @expanded_dirs : ( shift @expanded_dirs );
}

sub glob_list {
  my $input_files = shift;

  my @abs_input_files;
  for my $glob_pattern (@$input_files) {
    my @files = my_glob($glob_pattern);
    next unless ( @files > 0 );
    for my $f (@files) {
      confess "Couldn't find/access $f" unless ( -f $f || -d $f );
    }
    push @abs_input_files, @files;
  }
  confess "INDEX: no input files found" unless ( @abs_input_files > 0 );

  return \@abs_input_files;
}

sub my_glob {
  my (@dirs) = @_;

  return unless defined wantarray;    # don't bother doing more
  my @expanded_dirs;
  for my $dir (@dirs) {
    push @expanded_dirs, bsd_glob( $dir, GLOB_TILDE | GLOB_ERR );
    confess 'glob error' if (GLOB_ERROR);
  }

  cluck "no results in glob: " . join( ", ", @dirs ) unless (@expanded_dirs);

  @expanded_dirs = map { File::Spec->rel2abs($_) } @expanded_dirs;

  return wantarray ? @expanded_dirs : ( shift @expanded_dirs );
}

sub expand_path {
  my @expanded = expand_path_rel(@_);
  @expanded = map { File::Spec->rel2abs($_) } @expanded;
  return wantarray ? @expanded : ( shift @expanded );
}

sub expand_path_rel {
  my @files = @_;
  my @expanded;
  for my $file (@files) {
    confess "trying to expand empty path" unless($file);
    $file =~ s{ ^ ~ ( [^/]* ) }
            { $1
                ? (getpwnam($1))[7]
                : ( $ENV{HOME} || $ENV{LOGDIR} || (getpwuid($>))[7] )
            }ex;
    push @expanded, $file;
  }

  return wantarray ? @expanded : ( shift @expanded );
}


sub my_mkdir {
  my ($path) = @_;

  eval { mkpath($path) };
  if ($@) {
    confess "Couldn't create $path: $@";
  }
}

sub delete_by_regex {
  my ( $dir, $file_regex, $simulate ) = @_;

  $dir = my_glob($dir);

  opendir( my $dh, $dir ) || die "can't opendir >$dir< $!";
  for ( readdir($dh) ) {
    if (/$file_regex/) {
      my $file = File::Spec->catfile( $dir, $_ );
      if ($simulate) {
        print STDERR $file;
      } else {
        unlink $file;
      }
    }
  }
  closedir $dh;
  return;
}

sub concat_files {
  my $c = shift;

  my $dir = expand_path( $c->{result_dir} );

  my $file_regex = qr/\Q$c->{job_name}\E #job name
                        \.j$c->{job_id} #the job id
                        \.[0-9]+ #the sge task id
                        \.c[\-0-9]+(?:\.[\w\-.#]+)? # combination idx
                        (?:\..*)? #suffix
                        $/x;

  my @to_be_unlinked;
  open my $concat_fh, '>', catfile( $dir, "$c->{job_name}.j$c->{job_id}.result.concat" )
    or confess "Can't open filehandle: $!";

  my @paths = path($dir)->children($file_regex);
  for my $abs_f (@paths) {
    open my $fh, '<', $abs_f or confess "Can't open filehandle for $abs_f: $!";
    while ( my $line = <$fh> ) { print $concat_fh $line; }
    $fh->close;
    push @to_be_unlinked, $abs_f;
  }
  $concat_fh->close;

  for my $f (@to_be_unlinked) {
    $LOG->info("Deleting $f");
    unlink $f;
  }

  return;
}

sub timer {

  my ( $time_start, $time_end );

  return sub {
    unless ( defined $time_start ) {
      $time_start = time;
      return ( localtime($time_start) );
    } else {
      $time_end = time;

      return unless defined wantarray;    # don't bother doing more
      return wantarray
        ? localtime($time_end)
        : sprintf( "%dd %dh %dm %ds", ( gmtime( $time_end - $time_start ) )[ 7, 2, 1, 0 ] );

    }
  };
}

sub poll_interval {
  my ( $prev_waiting_time, $max_time ) = @_;

  return int( min( $max_time, $prev_waiting_time * ( 1.6 + rand() ) ) );
}


1;

__END__

=head1 NAME

Bio::Grid::Run::SGE::Util - Utility functions for Bio::Grid::Run::SGE

=head1 SYNOPSIS

    use Bio::Grid::Run::SGE::Util qw(
      my_glob
      delete_by_regex
      expand_path
      my_mkdir
      concat_files
      my_glob_non_fatal
      timer
      expand_path_rel
    );

=head1 DESCRIPTION

Provides utility functions for the Bio::Grid::Run::SGE module.

=head1 SUBROUTINES

=over 4

=item B<< $first_file = my_glob($pattern) >>

=item B<< @all_files = my_glob($pattern) >>

See L<File::Glob::bsd_glob> for an explanation of the C<$pattern>. This
function is for convenience only and takes care of some quirks of bsd_glob.

=item B<< $first_file = my_glob_non_fatal($pattern) >>

=item B<< @all_files = my_glob_non_fatal($pattern) >>

Same as C<my_glob>, but does not die if glob result is empty.

=item B<< $first_file = expand_path(\@files) >>

=item B<< @files = expand_path(\@files) >>

Expands a path to its absoulte equivalent. Taks also care of paths beginning
with '~'.

=item B<< $first_file = expand_path_rel(\@files) >>

=item B<< @files = expand_path_rel(\@files) >>

Expands the '~' at the beginning of a path to the home directory.

=item B<< my_mkdir($path) >>

Creates C<$path> and dies if something goes wrong. See also
L<File::Path/mkpath>.

=item B<< delete_by_regex($dir, $file_regex, $simulate) >>

Opens C<$dir> and deletes all files that match C<$file_regex>. If simulate is
true, then just print the files that would be deleted.

=item B<< concat_files($config) >>

Concatenates all result files in one file F< $c->{result_dir}/$c->{job_name}.j${job_id}.result.concat
and deletes the single result files. Result files are determined by following regex:

  qr/\Q$c->{job_name}\E #job name
    \.j$c->{job_id} #the job id
    \.[0-9]+ #the sge task id
    \.c[\-0-9]+(?:\.[\w\-.#]+)? #combination idx
    (?:\..*)? #suffix
    $/x;

If your toolwrapper makes use of it, you can also invoke it by hand. In the
working dir of your job run:

    ~/script/<toolwrapper>.pl -p <job_id> <tmp>/<job_name>.config

B<TAKE CARE, IT DELETES THE RESULT FILES AND OVERWRITES THE LAST RESULT.CONCAT FILE>

=item B<< $timer = timer() >>

Time something. Usage:

  # get a timer
  my $timer = timer();

  # start
  my $start_time = $timer->();

  # stop
  my $stop_time = $timer->();
  my ($stop_time, $elapsed_time_as_string) = $timer->();

=back

=head1 SEE ALSO

L<Bio::Grid::Run::SGE>

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
