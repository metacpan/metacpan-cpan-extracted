# -*- mode: perl; -*-
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw(in_set);
use Test2::Tools::Exception qw(dies);
use Alien::MUSCLE;
use Env qw( @PATH );
use Path::Tiny qw(path tempfile);

plan skip_all => "Bio::Tools::Run required"
  unless eval { require Bio::Tools::Run::Alignment::Muscle; 1; };

my @params  = (-quiet => 1);
my $factory = Bio::Tools::Run::Alignment::Muscle->new(@params);
my $input   = path('t')->child('data', 'cysprot.fa');

like(
  dies { $factory->align("$input") },
  qr{MSG: Cannot find executable for muscle},
  'muscle not found'
);

# fix that
unshift @PATH, Alien::MUSCLE->bin_dir;

(my $version = Alien::MUSCLE->version) =~ s{^([0-9]+\.[0-9]+).*$}{$1};
is($factory->version, $version, 'correct version');
my $align = $factory->align("$input");
ok($align, 'aligned');
is($align->num_sequences, 7, 'correct');

my $s1_perid = int( $align->average_percentage_identity );
in_set($s1_perid, 42 .. 44);

done_testing;
