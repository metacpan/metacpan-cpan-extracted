package Bio::Grid::Run::SGE::Config;


use warnings;
use strict;
use Carp;

use 5.010;

use Mouse;
use Config::Auto;
use Bio::Gonzales::Util::Cerial;
use Bio::Grid::Run::SGE::Master;

our $VERSION = '0.042'; # VERSION

has 'job_config_file' => ( is => 'rw' );
has 'cluster_script_setup' => ( is => 'rw', default => sub { {} } );
has 'cluster_script_args' => ( is => 'rw', default => sub { [] } );
has 'config' => ( is => 'rw', lazy_build => 1 );
has 'opt' => (
  is      => 'rw',
  default => sub {
    {

    };
  }
);
has 'rc_file' => (
  is      => 'rw',
  default => sub {
    "$ENV{HOME}/.bio-grid-run-sge.conf.yml";
  }
);

has _old_rc_files => (
  is      => 'rw',
  default => sub {
    [ "$ENV{HOME}/.comp_bio_cluster.config", "$ENV{HOME}/.bio-grid-run-sge.conf", ];
  }
);


# hide notify settings, because they may contain passwords
sub hide_notify_settings {
  my $self = shift;

  my $c = $self->config;
  delete $c->{notify} if(exists($c->{notify}));
  return $self;
}

sub _read_old_rc_files {
  my $self = shift;

  my %c;
  for my $rcf ( @{ $self->_old_rc_files } ) {

    my $c_tmp = eval { Config::Auto::parse($rcf) } if ( $rcf && -f $rcf );
    if ( $c_tmp && !$@ ) {
      print STDERR "Found DEPRECATED config file: " . $rcf . "\n";
      print STDERR "Please switch to the new format (YAML) and name (~/.bio-grid-run-sge.conf.yml)\n";
      %c = ( %c, %$c_tmp );
    }

  }
  return \%c;
}

sub _read_rc_file {
  my $self = shift;

  my $rcf = $self->rc_file;
  return yslurp($rcf) if ( $rcf && -f $rcf );

  return {};
}

sub _build_config {
  my $self        = shift;
  my $config_file = $self->job_config_file;
  my $a           = $self->cluster_script_setup;
  my $opt         = $self->opt;
  my $script_args = $self->cluster_script_args;

  #merge config
  # global options always get overwritten by local config

  my %c = ( %{ $self->_read_old_rc_files }, %{ $self->_read_rc_file } );

  # from the config in the cluster script
  if ( $a->{config} ) {
    %c = ( %c, %{ $a->{config} } );
  }

  # from config file
  if ( $config_file && -f $config_file ) {
    %c = ( %c, %{ yslurp($config_file) } );
  }

  # from additional cluster script args
  if($script_args && @$script_args > 0) {
    $c{args} //= [];
    push @{$c{args}}, @$script_args;
  }

  $c{no_prompt} = $opt->{no_prompt} unless defined $c{no_prompt};
  confess "no configuration found, file: $config_file" unless (%c);

  _adjust_deprecated( \%c );
  _unknown_attrs_to_extra( \%c );
  return \%c;
}

sub _adjust_deprecated {
  my $c = shift;
  if ( exists( $c->{method} ) && !exists( $c->{mode} ) ) {
    warn "The configuration option 'method' is DEPRECATED, use 'mode' instead.";
    $c->{mode}   = $c->{method};
    $c->{method} = "DEPRECATED: The configuration option 'method' is DEPRECATED, use 'mode' instead.";
  }
  return;
}

# put unknown configuration options into extra
sub _unknown_attrs_to_extra {
  my $c = pop;
  my $m = Bio::Grid::Run::SGE::Master->meta;

  $c->{extra} //= {};
  my %attrs = map { $_->name => 1 } $m->get_all_attributes;
  for my $k ( keys %$c ) {
    unless ( exists( $attrs{$k} ) ) {
      $c->{extra}{$k} = delete $c->{$k};
    }
  }

  return;
}

__PACKAGE__->meta->make_immutable();


__END__

=pod

=encoding utf8

=head1 Configuration

Bio::Grid::Run::SGE uses various configuration settings to run a job. All
configuration is stored in the YAML format. The configuration can be stored at
B<two> places:

=over 4

=item 1. In a global configuration file located at F<~/.bio-grid-run-sge.conf>.

=item 2. In a per-job configuration file supplied as argument to the cluster script.

=back

=head2 Creating a global config file

The global config file can contain e.g. settings that are used for job
notifications and paths to executables.

=head3 Job notification

Bio::Grid::Run::SGE can notify you if a job finishes by email or jabber
message. You can also use a custom script with the C<script> option. An
example configuration would be:

    ---
    notify:
      mail:
        dest: person.in.charge@example.com
        smtp_server: smtp.example.com
      jabber:
        jid: grid-report@jabber.example.com/grid_report
        password: ...
        dest: person-in-charge@jabber.example.com
      script: /path/to/log/script.pl

Custom scripts will get a json encoded structure passed via stdin. The structure has the form:


    {
      "subject": "the subject",
      "message": "the main log message",
      "from":    "user@the.cluster.org"
    }

=head3 Other global configuration

You can add other configuration settings. If you start a lot of L<R|http://www.r-project.org> scripts you might want to add the Rscript bin as global configuration:

  ---
  notify:
    ....
  r_script_bin: /usr/bin/Rscript

This configuration setting is accessible in the cluster script via the
supplied configuration of the task function as
C<$c->{extra}{r_script_bin}>.


=head2 Creating a job-specific config file


  job_name: NAME
  mode: Consecutive/AvsB/AllvsAll/AllvsAllNoRep

  args: [ '-a', 10, '-b','no' ]
  test: 2
  no_prompt: 1

  parts: 3000
  # or
  combinations_per_job: 300

  result_dir: result_gff
  working_dir:
  stderr_dir:
  stdout_dir:

  log_dir: dir
  tmp_dir: dir
  idx_dir: dir

  prefix_output_dirs: 

=head3 path specifictation in the config file

If the config file contains relative paths, the following policy is used:

=over 4

=item 1. The C<working_dir> config entry is used as "root".

=item 2. If no C<working_dir> config entry is specified, the directory of the config file is set to the working/root dir.

=item 3. If no config file is specified (yes, this is possible, but not recommended), the current dir is used as working/root dir.

=back

The working directory needs to exist.

=head3 The input section

With the input section it is possible to specify the type of input data and
how the index should be created.

The basic layout is:

  ---
  input:
  - ... # details of index 1
  - ... # details of index 2

Each index element shows up as argument in the C<task> function, 

  run_job(...
    task => sub {
      my ( $c, $result_prefix, $element_index_1, $element_index_2, ... ) = @_;
    }
    ...
  )

The number of indices you can use is determined by the L<mode|/Running mode>.
The most basic mode is C<Consecutive> and it takes one index and iterates
through every element.

=head4 Index types

=over 4

=item L<General|Bio::Grid::Run::SGE::Index::General>

=item L<List|Bio::Grid::Run::SGE::Index::List>

=item L<FileList|Bio::Grid::Run::SGE::Index::FileList>

=item L<Range|Bio::Grid::Run::SGE::Index::Range>

=item L<ListFromFile|Bio::Grid::Run::SGE::Index::ListFromFile>

=item L<Dummy|Bio::Grid::Run::SGE::Index::Dummy>

=back

=head3 Running mode

Bio::Grid::Run::SGE can run in different iteration modes

=over 4

=item L<Consecutive|Bio::Grid::Run::SGE::Iterator::Consecutive>

=item L<AvsB|Bio::Grid::Run::SGE::Iterator::AvsB>

=item L<AllvsAll|Bio::Grid::Run::SGE::Iterator::AllvsAll>
  
=item L<AllvsAllNoRep|Bio::Grid::Run::SGE::Iterator::AllvsAllNoRep>

=back


=

  ---
  input:
  - format: General
    #files, list and elements are synonyms
    files:
    - ../03_clean_evidence/result/merged.fa.clean
    chunk_size: 30
    sep: ^>
    sep_remove: 1
    sep_pos: '^'/'$'
    ignore_first_sep: 1

  - format: List
    list: [ 'a', 'b', 'c' ]
    
  - format: FileList
    files: [ 'filea', 'fileb', 'filec' ]

  - format: Range
    list: [ 'from', 'to' ]

=head3 RESEVED CONFIGURATION OPTIONS

Example configuration:

  'stdout_dir' => '/WORKING_DIR/xml_munge1.tmp/out',
  'test'       => '1',
  'no_prompt'  => undef,
  'input'      => [
    {
      'elements' => [
        '../../2013-10-13_string_b2g_blast/cafa_b2g_blastSTRING_9606_protein.sequences.result/cafa_b2g_blastSTRING_*_protein.sequences.*.blast.gz'
      ],
      'format'   => 'FileList',
      'idx_file' => '/WORKING_DIR/idx/xml_munge1.0.idx'
    }
  ],
  'mode'          => 'Consecutive',
  'range'         => [ '1', '1' ],
  'submit_bin'    => 'qsub',
  'submit_params' => [],
  'args'          => [],
  'working_dir'   => '/WORKING_DIR/test',
  'num_comb'      => 564,
  'log_dir'       => '/WORKING_DIR/xml_munge1.tmp/log',
  'stderr_dir'    => '/WORKING_DIR/xml_munge1.tmp/err',
  'tmp_dir'       => '/WORKING_DIR/xml_munge1.tmp',
  'smtp_server'   => 'net.wur.nl',
  'job_name'      => 'xml_munge1',
  'extra'         => { 'map' => '../split_test.map.json.gz' },
  'mail'          => 'joachim.bargsten@wur.nl',
  'script_dir'    => '/WORKING_DIR/bin',
  'idx_dir'       => '/WORKING_DIR/idx',
  'job_cmd' =>
    'qsub -t 1-1 -S perl -N xml_munge1 -e /WORKING_DIR/xml_munge1.tmp/err -o /WORKING_DIR/xml_munge1.tmp/out /WORKING_DIR/xml_munge1.tmp/env.xml_munge1.pl WORKING_DIR/bin/cl_xml_munge.pl --worker /WORKING_DIR/xml_munge1.tmp/xml_munge1.config.dat',
  'job_id' => '325541.1',
  'cmd'    => [ '/WORKING_DIR/bin/cl_xml_munge.pl' ],
  '_worker_config_file' =>
    '/WORKING_DIR/xml_munge1.tmp/xml_munge1.config.dat',
  'prefix_output_dirs' => '1',
  'perl_bin'           => '/home/cafa/perl5/perlbrew/perls/perl-5.16.3/bin/perl',
  'result_dir'         => '/WORKING_DIR/xml_munge1.result',
  'part_size'          => 1,
  'parts'              => 564



Here is a list of reserved configuration options:


  $c = {
    cmd => ...,
    script_dir => ...
    no_post_task => ...,
    tmp_dir => ...,
    stderr_dir => ...,
    stdout_dir => ...,
    result_dir => ...,
    log_dir => ...,
    idx_dir => ...,
    test => ...,
    mail => ...,
    smtp_server => ...,
    no_prompt => ...,
    lib => ...,
    input => ...,
    extra => ...,
    parts => ...,
    combinations_per_job => ...,
    job_name => ...,
    job_id => ...,
    mode => ...,
    _worker_config_file => ...,
    _worker_env_script => ...,
    submit_bin => ...,
    submit_params => ...,
    perl_bin => ...,
    working_dir => ...,
    iterator => ...,

    args => ...,
  };

=head3 input section

  ---
  input:
  - format: General
    #files, list and elements are synonyms
    files:
    - ../03_clean_evidence/result/merged.fa.clean
    chunk_size: 30
    sep: ^>
    sep_remove: 1
    sep_pos: '^'/'$'
    ignore_first_sep: 1

  - format: List
    list: [ 'a', 'b', 'c' ]
    
  - format: FileList
    files: [ 'filea', 'fileb', 'filec' ]

  - format: Range
    list: [ 'from', 'to' ]

  job_name: NAME
  mode: Consecutive/AvsB/AllvsAll/AllvsAllNoRep

  args: [ '-a', 10, '-b','no' ]
  test: 2
  no_prompt: 1

  parts: 3000
  # or
  combinations_per_job: 300

  result_dir: result_gff
  working_dir:
  stderr_dir:
  stdout_dir:

  log_dir: dir
  tmp_dir: dir
  idx_dir: dir

  prefix_output_dirs: 

The attribute C<args> is special, normally the main executable is hard-coded in the cl_* script,
but the arguments are changing per configuration. Therefore
L<Bio::Grid::Run::SGE::Master> provides the convenience attribute C<< $c->{args} >>

