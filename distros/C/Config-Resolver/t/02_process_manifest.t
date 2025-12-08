#!/usr/bin/env perl

use strict;
use warnings;

# --- Lesson 1: Load Modulino at Compile Time ---
BEGIN {
  use FindBin;
  my $ScriptPath = "$FindBin::Bin/../bin/config-resolver.pl";
  require $ScriptPath;
}

use Test::More;
use Data::Dumper;
use File::Temp qw(tempfile tempdir);
use YAML::Tiny qw(Dump);

# --- Setup a Mock Class ---
{

  package MockCLI;

  # --- Lesson 2: Set up Inheritance ---
  our @ISA = qw(CLI::Config::Resolver);

  # --- Lesson 3: Override init ---
  # This stops the real, complex init() from running.
  sub init { }

  # --- Mock Methods (Stubs and Spies) ---

  # Stub: Return the *injected* manifest file path
  sub get_manifest {
    my ($self) = @_;
    # This will now use the real temp file path we give it
    return $self->{_mock_get_manifest};
  }

  # Stub: Call the *real* fetch_file from the parent class
  # This will correctly read our temp files from disk
  sub fetch_file {
    my ( $self, $file ) = @_;
    return $self->SUPER::fetch_file($file);
  }

  # Stubs: These are called by process_manifest, so we
  # override them to do nothing.
  sub fetch_parameters { }
  sub resolve          { }

  # Spies: We "spy" on the setters to record what they were
  # called with. This is how we'll verify the test.
  sub set_parameter_file { $_[0]->{_called_params}   = $_[1]; }
  sub set_template       { $_[0]->{_called_template} = $_[1]; }
  sub set_outfile        { $_[0]->{_called_outfile}  = $_[1]; }
  sub set_umask          { $_[0]->{_called_umask}    = $_[1]; }
}

# This list comes from your config-resolver.pl
my @option_specs = qw(
  debug|g dump|d help key|k=s manifest|m=s outfile|o=s
  parameter-file|p=s pretty|P parameters|V=s plugins=s
  plugin=s@ resolve|r template=s umask=s warning-level|w=s
);

# --- Test 1: Basic Job (No Globals) ---
subtest 'Test Case: Basic job, no globals' => sub {

  # --- 1. Create ALL the real temp files ---
  my ( $p_fh, $p_name ) = tempfile( SUFFIX => '.json', UNLINK => 1 );
  print $p_fh '{}';
  close $p_fh;

  my ( $t_fh, $t_name ) = tempfile( SUFFIX => '.tpl', UNLINK => 1 );
  print $t_fh 'Hello';
  close $t_fh;

  my ( $mf_fh, $mf_name ) = tempfile( SUFFIX => '.yml', UNLINK => 1 );
  print $mf_fh Dump(
    { jobs => [
        { parameters => $p_name,       # <-- Use real temp file path
          template   => $t_name,       # <-- Use real temp file path
          outfile    => 'output.conf',
        }
      ]
    }
  );
  close $mf_fh;

  # --- 2. Create the MockCLI object ---
  my $mock = MockCLI->new(
    commands     => { resolve => sub { }, dump => sub { } },
    option_specs => \@option_specs,
  );

  # --- 3. Inject the path to our REAL manifest file ---
  $mock->{_mock_get_manifest} = $mf_name;

  # --- 4. Run the test ---
  $mock->process_manifest();

  is( $mock->{_called_params},   $p_name,       'Correctly sets parameters' );
  is( $mock->{_called_template}, $t_name,       'Correctly sets template' );
  is( $mock->{_called_outfile},  'output.conf', 'Correctly sets outfile' );
};

# --- Test 2: Convention Over Configuration ---
subtest 'Test Case: Convention over configuration' => sub {

  # --- 1. Create a temp directory and ALL files ---
  my $temp_dir      = tempdir( CLEANUP => 1 );
  my $template_path = "$temp_dir/templates";
  mkdir $template_path or die "Could not create $template_path: $!";

  # Create the global params file
  my $global_params_file = "$temp_dir/global-params.json";
  open my $gp_fh, '>', $global_params_file or die;
  print $gp_fh '{}';
  close $gp_fh;

  # Create the *derived* template file
  my $derived_template_file = "$template_path/output.conf.tpl";
  open my $dt_fh, '>', $derived_template_file or die;
  print $dt_fh 'Derived Template';
  close $dt_fh;

  # Create the manifest file
  my ( $mf_fh, $mf_name ) = tempfile( SUFFIX => '.yml', UNLINK => 1 );
  print $mf_fh Dump(
    { globals => {
        parameters    => $global_params_file,
        template_path => $template_path,
      },
      jobs => [
        { outfile => '/etc/output.conf',  # Basename is 'output.conf'
        }
      ]
    }
  );
  close $mf_fh;

  # --- 2. Create the MockCLI object ---
  my $mock = MockCLI->new(
    commands     => { resolve => sub { }, dump => sub { } },
    option_specs => \@option_specs,
  );

  # --- 3. Inject the path to our REAL manifest file ---
  $mock->{_mock_get_manifest} = $mf_name;

  # --- 4. Run the test ---
  $mock->process_manifest();

  is( $mock->{_called_params},   $global_params_file,    'Correctly inherits global parameters' );
  is( $mock->{_called_outfile},  '/etc/output.conf',     'Correctly sets outfile' );
  is( $mock->{_called_template}, $derived_template_file, 'Correctly *derives* template path' );
};

# --- Test 3: Job Overrides Globals ---
subtest 'Test Case: Job overrides globals' => sub {

  # --- 1. Create ALL files ---
  my ( $gp_fh, $gp_name ) = tempfile( SUFFIX => '.json', UNLINK => 1, DEBUG => 0 );
  print $gp_fh '{"global":1}';
  close $gp_fh;

  my ( $jp_fh, $jp_name ) = tempfile( SUFFIX => '.json', UNLINK => 1, DEBUG => 0 );
  print $jp_fh '{"job":1}';
  close $jp_fh;

  my ( $gt_fh, $gt_name ) = tempfile( SUFFIX => '.tpl', UNLINK => 1, DEBUG => 0 );
  print $gt_fh 'global';
  close $gt_fh;

  my ( $jt_fh, $jt_name ) = tempfile( SUFFIX => '.tpl', UNLINK => 1, DEBUG => 0 );
  print $jt_fh 'job';
  close $jt_fh;

  my ( $mf_fh, $mf_name ) = tempfile( SUFFIX => '.yml', UNLINK => 1, DEBUG => 0 );
  print $mf_fh Dump(
    { globals => {
        parameters => $gp_name,  # This will be overridden
        template   => $gt_name,
        umask      => '0027',    # This will be inherited
      },
      jobs => [
        { parameters => $jp_name,      # The override
          outfile    => 'output.conf',
          template   => $jt_name,      # The override
        }
      ]
    }
  );
  close $mf_fh;

  # --- 2. Create the MockCLI object ---
  my $mock = MockCLI->new(
    commands     => { resolve => sub { }, dump => sub { } },
    option_specs => \@option_specs,
  );

  # --- 3. Inject the path to our REAL manifest file ---
  $mock->{_mock_get_manifest} = $mf_name;

  # --- 4. Run the test ---
  $mock->process_manifest();

  is( $mock->{_called_params},   $jp_name, 'Job parameters override global' );
  is( $mock->{_called_template}, $jt_name, 'Job template overrides global' );
  is( $mock->{_called_umask},    '0027',   'Correctly inherits global umask' );
};

done_testing();

1;
