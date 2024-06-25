use strict;
use warnings;

on configure => sub {
  requires 'Config'                        => '0';
  requires 'ExtUtils::MakeMaker::CPANfile' => '0';
  requires 'File::Basename'                => '0';
  requires 'File::Spec'                    => '0';
  requires 'lib'                           => '0';
  requires 'strict'                        => '0';
  requires 'subs'                          => '0';
  requires 'version'                       => '0.9915';
  requires 'warnings'                      => '0';
};

on runtime => sub {
  requires 'Carp'           => '1.32';    # * bugfix: don't vivify @CARP_NOT and @ISA in caller's namespace
  requires 'Config'         => '0';
  requires 'Cwd'            => '0';
  requires 'File::Basename' => '0';
  requires 'File::Spec'     => '0';
  requires 'File::Which'    => '0';
  requires 'Getopt::Std'    => '0';
  requires 'POSIX'          => '0';
  requires 'strict'         => '0';
  requires 'warnings'       => '0';
};

on test => sub {
  requires 'App::Prove'    => '3.17';
  requires 'Sub::Override' => '0.12';
  requires 'Test::Fatal'   => '0';
  requires 'Test::Needs'   => '0';
  requires 'Test::More'    => '0.92';
};

on develop => sub {
  requires 'Devel::Cover'       => '0';
  requires 'Perl::Tidy'         => '0';
  requires 'Template'           => '0';
  requires 'Test::Perl::Critic' => '0';
  requires 'Test::Pod'          => '1.26';
};
