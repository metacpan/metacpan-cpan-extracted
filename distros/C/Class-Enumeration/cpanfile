use strict;
use warnings;

on configure => sub {
  requires 'ExtUtils::MakeMaker'           => '6.76';    # Offers the RECURSIVE_TEST_FILES feature
  requires 'ExtUtils::MakeMaker::CPANfile' => '0';       # Needs at least ExtUtils::MakeMaker 6.52
  requires 'File::Spec'                    => '0';
  requires 'strict'                        => '0';
  requires 'warnings'                      => '0'
};

on runtime => sub {
  requires 'Scalar::Util' => '0';
  requires 'Sub::Util'    => '1.40';
  requires 'feature'      => '0';
  requires 'overload'     => '0';
  requires 'strict'       => '0';
  requires 'warnings'     => '0'
};

on test => sub {
  requires 'Exporter'       => '0';
  requires 'Exporter::Tiny' => '0';
  requires 'Test::API'      => '0';
  requires 'Test::Fatal'    => '0';
  requires 'Test::More'     => '1.001005';    # Subtests accept args
  requires 'Test::Lib'      => '0';
  requires 'parent'         => '0'
}
