#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw( tempdir );
use FindBin;

# The acceptance test for maint/spec-to-type.pl: it must reproduce every
# class under lib/API/Docker/Type/ byte for byte out of spec/v1.51.yaml.
#
# That is the whole argument for letting a generator write the remaining
# hundred and twenty-seven. The classes in lib/ were written by hand from the
# swagger and then read, corrected and documented; if the generator renders
# something else, the generator is what is wrong. Left unchecked this rots
# the moment anyone edits a class or a rule, which is why it is a test and
# not a paragraph in a report.
#
# Nothing here opens a socket or reaches a daemon, in either mode. It does
# need YAML::XS, which is a develop-only dependency (Docker's published YAML
# is not YAML that YAML::PP 0.41 will parse -- see spec/README.md), and the
# maint/ tooling and spec/ that only a checkout carries.

my $ROOT   = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $SCRIPT = File::Spec->catfile($ROOT, 'maint', 'spec-to-type.pl');
my $SPEC   = File::Spec->catfile($ROOT, 'spec', 'v1.51.yaml');

# Only in a checkout. [PodWeaver] rewrites the POD of every lib/*.pm on its
# way into a built distribution -- =attr becomes =head2, NAME and VERSION and
# AUTHOR sections appear -- so inside `dzil test` the files this compares
# against are no longer the files the generator writes, and the comparison
# would be against the weaver rather than against the model.
plan skip_all => 'not a checkout; the POD in a built distribution is woven'
  unless -e File::Spec->catdir($ROOT, '.git');
plan skip_all => 'maint/spec-to-type.pl is not in this distribution' unless -f $SCRIPT;
plan skip_all => 'spec/v1.51.yaml is not in this distribution'       unless -f $SPEC;
plan skip_all => 'YAML::XS is not installed (develop-only dependency)'
  unless eval { require YAML::XS; 1 };

my $stage = tempdir(CLEANUP => 1);

subtest 'the generator reproduces the shipped classes byte for byte' => sub {
  my $out = qx{$^X \Q$SCRIPT\E --verify \Q$stage\E/out 2>&1};
  my ($compared, $identical, $different)
    = $out =~ /(\d+) class\(es\) compared, (\d+) identical, (\d+) different/;
  ok defined $compared, 'the run reported a comparison'
    or diag $out;
  cmp_ok $compared, '>', 0, 'it had classes to compare against';
  is $different, '0', 'no class differs from what lib/ ships'
    or diag $out;
  is $identical, $compared, 'every compared class is identical';
};

subtest 'the generator refuses to write into the model' => sub {
  # The rule the whole script is built around: it may create a file that does
  # not exist and it may never touch one that does. A --stage pointed at lib/
  # is the shape that would break it, and it is refused before anything is
  # rendered -- not left to the accident that most classes already exist.
  for my $target ('lib', 'lib/API/Docker/Type', 'maint/../lib') {
    my $out = qx{$^X \Q$SCRIPT\E --stage \Q$ROOT\E/$target --only NOTHING 2>&1};
    like $out, qr/refusing to write into the model itself/,
      "--stage $target is refused";
  }
};

subtest 'the generator refuses to overwrite a file it already wrote' => sub {
  my $dir = File::Spec->catdir($stage, 'twice');
  my $only = '^API::Docker::Type::HealthConfig$';
  my $first = qx{$^X \Q$SCRIPT\E --verify \Q$dir\E --only \Q$only\E 2>&1};
  like $first, qr/rendered\s+1 class/, 'the first run writes the class';
  my $second = qx{$^X \Q$SCRIPT\E --verify \Q$dir\E --only \Q$only\E 2>&1};
  like $second, qr/never overwrites a\nfile/,
    'the second run refuses rather than regenerating it';
};

subtest 'stage has nothing left to write' => sub {
  # The end state of karr k79 step 5: every class the spec calls for is in
  # lib/, so the generator's creating half has no work. A number other than
  # zero here means the spec grew a definition and nobody noticed -- which is
  # the drift checker's report, arrived at from the other side.
  my $out = qx{$^X \Q$SCRIPT\E --stage \Q$stage\E/nothing 2>&1};
  like $out, qr/rendered\s+0 class\(es\)/,
    'no class in the spec is missing from lib/';
  unlike $out, qr/NEEDS A/,
    'and nothing is blocked waiting for a name or an abstract';
};

subtest 'a name with a run of capitals must be in the map' => sub {
  # Silently guessing is how `device_i_ds` would reach a hundred classes at
  # once: the derivation produces it, and it survives the round-trip check
  # that catches every other bad name.
  my $names = File::Spec->catfile($stage, 'names.yaml');
  open my $in, '<', File::Spec->catfile($ROOT, 'maint', 'spec-to-type-names.yaml')
    or die $!;
  open my $out, '>', $names or die $!;
  while (my $line = <$in>) { print $out $line unless $line =~ /\AEndpointID:/ }
  close $out;
  close $in;
  my $report = qx{$^X \Q$SCRIPT\E --verify \Q$stage\E/names --names \Q$names\E --only '^API::Docker::Type::EndpointSettings\$' 2>&1};
  like $report, qr/'EndpointID'.*carries a run of capitals/s,
    'the run stops and names the field';
  like $report, qr/spec-to-type-names\.yaml/, 'and says where to put the answer';
};

done_testing;
