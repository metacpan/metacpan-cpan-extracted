package Bio::Grid::Run::SGE::Master;

use Mouse;

use warnings;
use strict;
use Carp;
use Storable qw/nstore retrieve/;
use File::Temp qw/tempdir/;
use File::Which;
use File::Spec;
use Data::Dumper;
use Bio::Grid::Run::SGE::Index;
use Bio::Grid::Run::SGE::Iterator;
use Bio::Grid::Run::SGE::Util qw/my_glob my_sys expand_path my_mkdir expand_path_rel/;
use Cwd qw/fastcwd/;
use Clone qw/clone/;
use Data::Printer colored => 1, use_prototypes => 0, rc_file => '';
use Bio::Gonzales::Util::Cerial;
use Capture::Tiny 'capture';
use Config;
use FindBinNew qw($Bin $Script);
FindBinNew::again();

our $VERSION = '0.042'; # VERSION

has 'cmd' => (
  is       => 'rw',
  required => 1,
  isa      => 'ArrayRef[Str]',
  default  => sub {
    ["$Bin/$Script"];
  }
);
has 'no_post_task' => ( is => 'rw' );

has 'tmp_dir'    => ( is => 'rw', lazy_build => 1 );
has 'stderr_dir' => ( is => 'rw', lazy_build => 1 );
has 'stdout_dir' => ( is => 'rw', lazy_build => 1 );
has 'result_dir' => ( is => 'rw', lazy_build => 1 );
has 'log_dir'    => ( is => 'rw', lazy_build => 1 );
has 'idx_dir'    => ( is => 'rw', lazy_build => 1 );
has 'test'       => ( is => 'rw' );
has 'notify'     => ( is => 'rw' );
has 'no_prompt'  => ( is => 'rw' );
has 'lib'        => ( is => 'rw' );
has 'script_dir' => ( is => 'ro', default    => $Bin );

has 'input' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

has 'extra' => ( is => 'rw', default => sub { {} } );

# one can supply parts or combinations per job
has 'parts' => ( is => 'rw', default => 0 );
has 'combinations_per_job' => ( is => 'rw' );

has 'job_name' => ( is => 'rw', default => 'cluster_job' );
has 'job_id' => ( is => 'rw' );

has 'mode' => ( is => 'rw', default => 'None' );

has '_worker_config_file' => ( is => 'rw', lazy_build => 1 );
has '_worker_env_script'  => ( is => 'rw', lazy_build => 1 );
has 'submit_bin'          => ( is => 'rw', default    => 'qsub' );
has 'submit_params'       => ( is => 'rw', default    => sub { [] }, isa => 'ArrayRef[Str]' );
has 'perl_bin'            => ( is => 'rw', default    => $Config{perlpath} );
has 'working_dir'         => ( is => 'rw', default    => '.' );
has 'prefix_output_dirs'  => ( is => 'rw', default    => 1 );

# arguments for the cluster script
has 'args' => ( is => 'rw', isa => 'ArrayRef[Str]', default => sub { [] } );

has 'iterator' => ( is => 'rw', lazy_build => 1 );

sub num_slots { return shift->parts(@_) }

sub _build_log_dir {
  my ($self) = @_;

  return File::Spec->catfile( $self->tmp_dir(), 'log' );
}

sub _build_stderr_dir {
  my ($self) = @_;

  return File::Spec->catfile( $self->tmp_dir, 'err' );
}

sub _build_stdout_dir {
  my ($self) = @_;

  return File::Spec->catfile( $self->tmp_dir, 'out' );
}

sub _build_idx_dir {
  my ($self) = @_;

  return File::Spec->catfile( $self->working_dir, 'idx' );
}

sub _build_tmp_dir {
  my ($self) = @_;

  my $name = 'tmp';

  $name = join ".", $self->_job_name_stripped, $name
    if ( $self->prefix_output_dirs );

  return File::Spec->catfile( $self->working_dir, $name );
}

sub _job_name_stripped {
  my $self = shift;
  ( my $jn = $self->job_name ) =~ y/-0-9A-Za-z_./_/csd;
  return $jn;
}

sub _build_result_dir {
  my ($self) = @_;

  my $name = 'result';

  $name = join ".", $self->_job_name_stripped, $name
    if ( $self->prefix_output_dirs );

  return File::Spec->catfile( $self->working_dir, $name );
}

sub BUILD {
  my ( $self, $args ) = @_;

  #confess "No input given" unless ( @{ $self->input } > 0 );

  my $submit_bin = -f $self->submit_bin ? $self->submit_bin : which( $self->submit_bin );
  confess "[SUBMIT_ERROR] $submit_bin not found or not executable" unless ( -x $submit_bin );

  for my $i ( @{ $self->input } ) {
    #merge different namings to one std. naming: elements
    for my $key (qw/list files/) {
      $i->{elements} = delete $i->{$key} if ( exists( $i->{$key} ) && @{ $i->{$key} } > 0 );

    }

    confess "No input given" unless ( exists( $i->{elements} ) && @{ $i->{elements} } );
  }

  $self->perl_bin( expand_path_rel( $self->perl_bin ) );

  $self->working_dir( File::Spec->rel2abs( $self->working_dir ) );
  confess "working dir does not exist: " . $self->working_dir unless ( -d $self->working_dir );

  for my $d (qw/log_dir stderr_dir stdout_dir result_dir tmp_dir idx_dir/) {
    $self->$d( expand_path( $self->$d ) );
    unless ( -d $self->$d ) {
      my_mkdir( $self->$d );
    }
  }

  my $m = __PACKAGE__->meta;

  my %extra = %{$args};
  my %attrs = map { $_->name => 1 } $m->get_all_attributes;
  for my $k ( keys %extra ) {
    delete $extra{$k} if ( $attrs{$k} );
  }

  $self->extra( { %extra, %{ $self->extra } } );
}

sub to_string {
  my ($self) = @_;

  $self->_prepare;
  my %c = %{$self};
  delete $c{iterator};
  $c{input} = clone( $self->input );

  for my $in ( @{ $c{input} } ) {
    if ( @{ $in->{elements} } > 10 ) {
      my @elements;
      push @elements, @{ $in->{elements} }[ 0 .. 4 ];
      push @elements, '...';
      push @elements, @{ $in->{elements} }[ -5 .. -1 ];
      $in->{elements} = \@elements;
    }
  }
  $c{parts} = $self->_calculate_number_of_parts;
  my $string = p \%c;

  return "CONFIGURATION:\n" . $string;
}

sub _prepare {
  my ($self) = @_;
  $self->_worker_config_file;
  $self->iterator;
}

sub _build__worker_config_file {
  my $self = shift;
  return File::Spec->catfile( $self->tmp_dir, join( '', $self->job_name, '.config.dat' ) );
}

sub _build__worker_env_script {
  my $self = shift;
  return File::Spec->catfile( $self->tmp_dir, join( '.', 'env', $self->job_name, 'pl' ) );
}

sub generate_idx_file_name {
  my ( $self, $suffix ) = @_;
  return File::Spec->catfile( $self->idx_dir, join( '.', ( $self->job_name, $suffix, 'idx' ) ) );
}

sub _build_iterator {
  my ($self) = @_;

  my @indices;

  my $i = 0;
  for my $in ( @{ $self->input } ) {
    $in->{idx_file} = $self->generate_idx_file_name( $i++ );
    push @indices, Bio::Grid::Run::SGE::Index->new( %{$in}, writeable => 1 );
    $indices[-1]->create( $in->{elements} );
  }

  # create iterator
  my $iter = Bio::Grid::Run::SGE::Iterator->new( mode => $self->mode, indices => \@indices, );
  return $iter;
}

sub run {
  my ($self) = @_;

  $self->_prepare;

  my $tmp_dir     = $self->tmp_dir;
  my $config_file = $self->_worker_config_file;

  my ( $cmd_args, $c ) = $self->cache_config($config_file);
  my $cmd = join ' ', @$cmd_args;

  say STDERR "Running: " . $cmd;

  # capture from external command

  my ( $stdout, $stderr, $exit ) = capture {
    system(@$cmd_args);
  };

  if ( $exit != 0 ) {
    die "[SUBMIT_ERROR] Could not submit job:\n$stdout$stderr";
  }

  $stdout =~ /^Your\s*job(-array)?\s*(\d+)/;

  unless ( defined $self->job_id ) {
    if ( defined $2 ) {
      $self->job_id($2);
    } else {
      warn "[SUBMIT_WARNING] could not parse job id, using -1 as job id.\nSTDOUT:\n$stdout\nSTDERR:\n$stderr";
      $self->job_id(-1);
    }
  }

  open my $main_fh, '>',
    File::Spec->catfile( $self->log_dir, sprintf( "main.%s.j%s.cmd", $self->job_name, $self->job_id ) )
    or confess "Can't open filehandle: $!";
  print $main_fh "cd '" . fastcwd . "' && " . $cmd, "\n";
  $main_fh->close;
  $self->queue_post_task($config_file) if ( $self->job_id >= 0 );

  return { config => $c, command => $cmd_args };
}

sub _calculate_number_of_parts {
  my ($self) = @_;

  my $iter = $self->iterator;
  if ( !$self->parts || $self->parts > $iter->num_comb ) {
    if ( $self->combinations_per_job && $self->combinations_per_job > 1 ) {
      my $parts = int( $iter->num_comb / $self->combinations_per_job );

      #we have a rest, so one part more
      $parts++
        if ( $parts * $self->combinations_per_job < $iter->num_comb );

      return $parts;
    } else {
      return $iter->num_comb;
    }
  }
  return $self->parts;
}

sub cache_config {
  my ( $self, $config_file ) = @_;

  $self->_prepare;

  my $iter = $self->iterator;

  $self->parts( $self->_calculate_number_of_parts );

  my %c = ( %{$self}, num_comb => $iter->num_comb, extra => $self->extra );
  delete $c{iterator};

  my ( $from, $to ) = ( 1, $self->parts );
  $to = $self->test if ( $self->test && $self->test > 0 && $to > 7 );

  my @cmd = ( $self->submit_bin );
  push @cmd, '-t', "$from-$to";
  push @cmd, '-S', $self->perl_bin;
  push @cmd, '-N', $self->job_name;
  push @cmd, '-e', $self->stderr_dir;
  push @cmd, '-o', $self->stdout_dir;
  push @cmd, @{ $self->submit_params };

  my $worker_env_script_cmd = $self->prepare_worker_env_script($config_file);
  push @cmd, $worker_env_script_cmd, @{ $self->cmd }, '--worker', $config_file;

  my $cmd = join ' ', @cmd;
  $c{job_cmd} = $cmd;
  $c{range} = [ $from, $to ];

  nstore \%c, $config_file;

  return ( \@cmd, \%c );
}

sub prepare_worker_env_script {
  my ( $self, $config_file ) = @_;

  open my $fh, '>', $self->_worker_env_script or confess "Can't open filehandle: $!";
  print $fh <<EOS;
#!/usr/bin/env perl
use warnings;
use strict;

EOS

  if ( exists $ENV{PERL5LIB} ) {
    my @inc_dirs = split( /\Q$Config{path_sep}\E/, $ENV{PERL5LIB} );
    print $fh "use lib ('" . join( "','", @inc_dirs ) . "');\n"
      if ( @inc_dirs && @inc_dirs > 0 );
  }

  print $fh <<'EOF';
  my $cmd = shift;
  unless ( my $return = do $cmd ) {
    warn "could not parse $cmd\n$@\n\n$!" if $@;
    warn "couldn't execute $cmd\n$!" unless defined $return;
    warn "couldn't run $cmd" unless $return;
  }
  exit;
EOF
  $fh->close;

  return $self->_worker_env_script;
}

sub queue_post_task {
  my ( $self, $config_file ) = @_;

  my @cmd = ( $self->submit_bin );
  push @cmd, '-S', $self->perl_bin;
  push @cmd, '-N', join( '_', 'p' . $self->job_id, $self->job_name );
  push @cmd, '-e', $self->stderr_dir;
  push @cmd, '-o', $self->stdout_dir;

  my @hold_arg = ( '-hold_jid', $self->job_id );

  #push @cmd, @{ $self->submit_params };

  my @post_cmd = ( $self->_worker_env_script, @{ $self->cmd }, '--post_task', $self->job_id, $config_file );

  $self->save_config;
  say STDERR "post processing: " . join( " ", @cmd, @hold_arg, @post_cmd );

  my $job_id = $self->job_id;
  my $post_cmd_file
    = File::Spec->catfile( $self->tmp_dir, sprintf( "post.%s.j%s.cmd", $self->job_name, $self->job_id ) );

  open my $post_fh, '>', $post_cmd_file or confess "Can't open filehandle: $!";
  print $post_fh join( " ", "cd", "'" . fastcwd . "'", '&&', @cmd, @post_cmd ), "\n";
  $post_fh->close;

  chmod 0755, $post_cmd_file;

  my_sys( @cmd, @hold_arg, @post_cmd );

  return;
}

sub save_config {
  my ($self) = @_;

  my $cfg_save
    = File::Spec->catfile( $self->result_dir, sprintf( "%s.j%s.config", $self->job_name, $self->job_id ) );

  say STDERR "Saving config to " . $cfg_save;
  open my $cfg_fh, '>', $cfg_save
    or confess "Can't open filehandle: $!";
  print $cfg_fh Dumper($self);
  $cfg_fh->close;

  return;
}

1;

__END__

=head1 NAME



=head1 SYNOPSIS

  #wenn export, dann hier im qw()

=head1 DESCRIPTION

=over 4

=item B<< combinations_per_job >>

=item B<< parts >>

=back


=head1 OPTIONS

=head1 SUBROUTINES
=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
