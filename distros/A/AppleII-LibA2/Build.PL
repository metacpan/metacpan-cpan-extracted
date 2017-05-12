#! perl
#---------------------------------------------------------------------
# Build.PL for AppleII-LibA2
# Copyright 2015 Christopher J. Madsen
#---------------------------------------------------------------------

use inc::A2_Build;          # Our customized version of Module::Build

my $build = inc::A2_Build->new(
  dist_name          => 'AppleII-LibA2',
  dist_version       => '0.201',
  dist_author        => 'Christopher J. Madsen <perl@cjmweb.net>',
  module_name        => 'AppleII::LibA2', # for packlist
  'build_requires' => {
    'FindBin' => '0',
    'Module::Build' => '0',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Cwd' => '0',
    'Module::Build' => '0.21',
    'perl' => '5.006'
  },
  'recommends' => {
    'Term::ReadLine::Perl' => '0'
  },
  'requires' => {
    'Carp' => '0',
    'Exporter' => '5.57',
    'File::Glob' => '0',
    'Getopt::Long' => '2.10',
    'IO::File' => '0',
    'POSIX' => '0',
    'Term::ReadLine' => '0',
    'perl' => '5.006'
  },
  get_options        => { 'no-scripts' => undef },
  add_to_cleanup     => [ 't/tmpdir' ],
);

my @scripts;

if ($build->args('no-scripts')) {
  $build->dispatch('clean');   # The scripts might already be in blib/
} else {
  @scripts = qw(bin/awp2txt bin/pro_fmt bin/pro_opt bin/prodos bin/var_display);
}

$build->script_files(\@scripts);

$build->create_build_script;

if (@scripts) {
  print "The following scripts will be installed along with the modules:\n";
  print join('   ', '', map { s!^.*/!!; $_ } @scripts) . "\n";
  printf("If you don't want these scripts installed, run:\n" .
         "%s Build.PL --no-scripts\n", $build->find_perl_interpreter);
} else {
  print "No scripts will be installed (installing modules only)\n";
}
