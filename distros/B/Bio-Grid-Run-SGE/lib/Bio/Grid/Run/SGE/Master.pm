package Bio::Grid::Run::SGE::Master;

use Mouse;

use warnings;
use strict;
use Carp;
use Storable qw/nstore retrieve/;
use File::Temp qw/tempdir/;
use File::Which;
use File::Spec;
use Bio::Grid::Run::SGE::Index;
use Bio::Grid::Run::SGE::Iterator;
use Bio::Grid::Run::SGE::Util qw/my_glob expand_path my_mkdir expand_path_rel/;
use Cwd qw/fastcwd/;
use File::Spec::Functions qw/catfile rel2abs/;
use Clone qw/clone/;
use Data::Dump;
use Bio::Gonzales::Util::Cerial;
use List::MoreUtils qw/uniq/;
use List::Util qw/min/;
use Capture::Tiny 'capture';
use Config;
use Bio::Gonzales::Util qw/sys_fmt/;
use FindBinNew qw($Bin $Script);
FindBinNew::again();

our $VERSION = '0.065'; # VERSION

has 'env'    => ( is => 'rw', required => 1 );
has 'config' => ( is => 'rw', required => 1 );
has 'log'    => ( is => 'rw', required => 1 );

has 'iterator' => ( is => 'rw', lazy_build => 1 );

sub populate {
  my $self = shift;

  my $env    = $self->env;
  my $config = $self->config;

	# sge doc: job names are ascii alphanumeric and 
	# cannot contain "\n", "\t", "\r", "/", ":", "@", "\", "*", or "?".
  ( my $jn = $config->{job_name} ) =~ y/-0-9A-Za-z_./_/cs;
  $env->{job_name_save} = $jn;
  $env->{job_id} //= -1;

  $env->{script_bin}            //= "$Bin/$Script";    # vorher cmd
  $env->{script_dir}            //= $Bin;
  $config->{prefix_output_dirs} //= 1;
  # FIXME wo config setzten, nur für master nötig?
  $config->{submit_bin}    //= 'qsub';
  $config->{input}         //= [];
  $config->{submit_params} //= [];
  $config->{mode}          //= "None";

  $env->{perl_bin} //= rel2abs($^X);

  # tmp_dir
  {
    my $name = 'tmp';
    $name = join ".", $jn, $name if ( $config->{prefix_output_dirs} );
    $config->{tmp_dir} //= catfile( $config->{working_dir}, $name );
  }

  $config->{log_dir}    //= catfile( $config->{tmp_dir},     'log' );
  $config->{stderr_dir} //= catfile( $config->{tmp_dir},     'err' );
  $config->{stdout_dir} //= catfile( $config->{tmp_dir},     'out' );
  $config->{idx_dir}    //= catfile( $config->{working_dir}, 'idx' );

  # result_dir
  {
    my $name = 'result';
    $name = join ".", $jn, $name if ( $config->{prefix_output_dirs} );
    $config->{result_dir} //= catfile( $config->{working_dir}, $name );
  }

  $env->{worker_config_file} = catfile( $config->{tmp_dir}, $jn . '.job.conf.json' );
  $env->{worker_env_script} = catfile( $config->{tmp_dir}, join( '.', 'env', $jn, 'pl' ) );
}

sub BUILD {
  my ( $self, $args ) = @_;

  $self->populate;
  # FIXME check required options
}

sub to_string {
  my ($self) = @_;

  my %conf = %{ $self->config };
  my %env  = %{ $self->env };
  $conf{input} = clone( $conf{input} );

  for my $in ( @{ $conf{input} } ) {
    if ( @{ $in->{elements} } > 10 ) {
      my @elements;
      push @elements, @{ $in->{elements} }[ 0 .. 4 ];
      push @elements, '...';
      push @elements, @{ $in->{elements} }[ -5 .. -1 ];
      $in->{elements} = \@elements;
    }
  }
  my $string = Data::Dump::dump( \%conf );

  return $string;
}

sub prepare {
  my ($self) = @_;

  my $conf = $self->config;
  my $env  = $self->env;

  #confess "No input given" unless ( @{ $conf->{input} } > 0 );
  $conf->{input} //= [];

  # FIXME vllt in job.pm init?
  my $submit_bin = -f $conf->{submit_bin} ? $conf->{submit_bin} : which( $conf->{submit_bin} );
  confess "[SUBMIT_ERROR] $submit_bin not found or not executable" unless ( -x $submit_bin );
  $conf->{submit_bin} = rel2abs($submit_bin);

  for my $i ( @{ $conf->{input} } ) {
    #merge different namings to one std. naming: elements
    for my $key (qw/list files/) {
      $i->{elements} = delete $i->{$key} if ( exists( $i->{$key} ) && @{ $i->{$key} } > 0 );
    }
    confess "No input given" unless ( exists( $i->{elements} ) && @{ $i->{elements} } );
  }

  $conf->{working_dir} = rel2abs( $conf->{working_dir} );
  confess "working dir does not exist: " . $conf->{working_dir} unless ( -d $conf->{working_dir} );

  for my $d (qw/log_dir stderr_dir stdout_dir result_dir tmp_dir idx_dir/) {
    $conf->{$d} = expand_path( $conf->{$d} );
    my_mkdir( $conf->{$d} ) unless ( -d $conf->{$d} );
  }

  # make sure the iterator gets built
  my $iter = $self->iterator;

  # one can supply parts or combinations per job
  $self->config->{num_parts} = $self->calc_num_parts;
  $self->env->{num_comb} = $iter->num_comb;
  return $self;
}

sub generate_idx_file_name {
  my ( $self, $suffix ) = @_;
  return catfile( $self->config->{idx_dir}, join( '.', ( $self->env->{job_name_save}, $suffix, 'idx' ) ) );
}

sub _build_iterator {
  my ($self) = @_;

  my @indices;

  my $i = 0;
  for my $in ( @{ $self->config->{'input'} } ) {
    $in->{idx_file} = $self->generate_idx_file_name( $i++ );
    push @indices, Bio::Grid::Run::SGE::Index->new( %{$in}, writeable => 1, log => $self->log );
    $indices[-1]->create( $in->{elements} );
  }

  # create iterator
  return Bio::Grid::Run::SGE::Iterator->new( mode => $self->config->{mode}, indices => \@indices, );
}

sub run {
  my ($self) = @_;

  my $conf               = $self->config;
  my $env                = $self->env;
  my $tmp_dir            = $conf->{tmp_dir};
  my $worker_config_file = $env->{worker_config_file};

  my $submit_cmd = $self->build_exec_env;

  $self->log->info( "Running: " . $submit_cmd );

  # capture from external command
  my ( $stdout, $stderr, $exit ) = capture {
    system($submit_cmd);
  };

  if ( $exit != 0 ) {
    die "[SUBMIT_ERROR] Could not submit job:\n$stdout$stderr";
  }

  $stdout =~ /^Your\s*job(-array)?\s*(\d+)/;

  if ( defined $2 ) {
    $env->{job_id} = $2;
  } else {
    warn "[SUBMIT_WARNING] could not parse job id, using -1 as job id.\nSTDOUT:\n$stdout\nSTDERR:\n$stderr";
    $env->{job_id} = -1;
  }

  open my $main_fh, '>',
    catfile( $conf->{log_dir}, sprintf( "main.%s.j%s.cmd", $env->{job_name_save}, $env->{job_id} ) )
    or confess "Can't open filehandle: $!";
  say $main_fh "cd '" . fastcwd . "' && " . $submit_cmd;
  $main_fh->close;
  $self->log->info( ">>job_id:" . $env->{job_id} ) if ( $env->{job_id} >= 0 );
  $self->queue_post_task() if ( $env->{job_id} >= 0 );
  return;
}

sub calc_num_parts {
  my ($self) = @_;

  my $c    = $self->config;
  my $iter = $self->iterator;
  if ( !$c->{num_parts} || $c->{num_parts} > $iter->num_comb ) {
    if ( $c->{combinations_per_task} && $c->{combinations_per_task} > 1 ) {
      my $num_parts = int( $iter->num_comb / $c->{combinations_per_task} );

      #we have a rest, so one part more
      $num_parts++
        if ( $num_parts * $c->{combinations_per_task} < $iter->num_comb );

      return $num_parts;
    } else {
      return $iter->num_comb;
    }
  }
  return $c->{num_parts};
}

sub build_exec_env {
  my ($self) = @_;

  my $conf = $self->config;
  my $env  = $self->env;

  my ( $from, $to ) = ( 1, $conf->{num_parts} );
  $to = min( $conf->{test}, $conf->{num_parts} ) if ( $conf->{test} && $conf->{test} > 0 );

  my @cmd = ( $conf->{submit_bin} );
  push @cmd, '-t', "$from-$to";
  push @cmd, '-S', $env->{perl_bin};
  push @cmd, '-N', $conf->{job_name};
  push @cmd, '-e', $conf->{stderr_dir};
  push @cmd, '-o', $conf->{stdout_dir};
  push @cmd, @{ $conf->{submit_params} };

  $self->write_worker_env_script;
  push @cmd, $env->{worker_env_script}, $env->{script_bin}, '--stage', 'worker', $env->{worker_config_file};

  $env->{job_cmd} = sys_fmt( \@cmd );
  $env->{job_range} = [ $from, $to ];

  jspew( $env->{worker_config_file}, { config => $conf, env => $env } );
  return $env->{job_cmd};
}

sub write_worker_env_script {
  my ($self) = @_;

  my $conf = $self->config;
  my $env  = $self->env;
  open my $fh, '>', $env->{worker_env_script} or confess "Can't open filehandle: $!";
  print $fh <<EOS;
#!/usr/bin/env perl
use warnings;
use strict;

EOS

  if ( exists $ENV{PERL5LIB} ) {
    my @inc_dirs = split( /\Q$Config{path_sep}\E/, $ENV{PERL5LIB} );
    @inc_dirs = grep {$_} @inc_dirs;
    if ( @inc_dirs && @inc_dirs > 0 ) {
      say $fh '$ENV{PERL5LIB} //= "";';
      say $fh '$ENV{PERL5LIB} = "$ENV{PERL5LIB}:' . join( ':', @inc_dirs ) . '";';
      say $fh "use lib ('" . join( "','", @inc_dirs ) . "');";
    }
  }

  if ( exists $ENV{PATH} ) {

    my @dirs = uniq( grep {$_} split( /\Q$Config{path_sep}\E/, $ENV{PATH} ) );
    my $path = "'" . join( "','", @dirs ) . "'";
    print $fh <<EOS;
my \@path = do { my \%seen; grep { !\$seen{\$_}++ } ( split(/:/, \$ENV{PATH}), $path) };
\$ENV{PATH} = join(":", \@path);
EOS
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
}

sub queue_post_task {
  my ($self) = @_;

  my $conf = $self->config;
  my $env  = $self->env;

  my @cmd = ( $conf->{submit_bin} );
  push @cmd, '-S', $env->{perl_bin};
  push @cmd, '-N', join( '_', 'p' . $env->{job_id}, $env->{job_name_save} );
  push @cmd, '-e', $conf->{stderr_dir};
  push @cmd, '-o', $conf->{stdout_dir};

  my @hold_arg = ( '-hold_jid', $env->{job_id} );

  #push @cmd, @{ $self->submit_params };

  my @post_cmd = (
    $env->{worker_env_script},
    $env->{script_bin}, '--stage', 'post_task', '--job_id', $env->{job_id}, $env->{worker_config_file}
  );

  $self->log->info( "post processing: " . join( " ", @cmd, @hold_arg, @post_cmd ) );

  my $post_cmd_file
    = catfile( $conf->{tmp_dir}, sprintf( "post.%s.j%s.cmd", $env->{job_name_save}, $env->{job_id} ) );

  open my $post_fh, '>', $post_cmd_file or confess "Can't open filehandle: $!";
  say $post_fh join( " ", "cd", "'" . fastcwd . "'", '&&', @cmd, @post_cmd );
  $post_fh->close;

  chmod 0755, $post_cmd_file;

  system( @cmd, @hold_arg, @post_cmd ) == 0 or confess "post task system failed: $?";

  return;
}

1;

__END__

=head1 NAME



=head1 SYNOPSIS

  #wenn export, dann hier im qw()

=head1 DESCRIPTION

=over 4

=item B<< combinations_per_task >>

=item B<< num_parts >>

=back


=head1 OPTIONS

=head1 SUBROUTINES
=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
