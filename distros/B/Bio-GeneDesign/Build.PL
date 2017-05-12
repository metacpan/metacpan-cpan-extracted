use 5.006;

use strict;
use warnings;

use Module::Build;
use File::Basename;
use Carp;

print "\n";

my $llt = 0;
my ($cpath,  $spath,  $tpath, $g) =  (undef, undef, undef, undef);

my $GDB = Module::Build->new
(
  module_name         => 'Bio::GeneDesign',
  license             => 'bsd',
  dist_author         => q{Sarah Richardson <SMRichardson@lbl.gov>},
  dist_version        => '5.54',
  dist_abstract       => 'Functions for the design of synthetic genes',
  add_to_cleanup      => [ 'Bio::GeneDesign-*' ],
  create_makefile_pl  => 'traditional',
  build_requires      =>
  {
    'Test::More'      => 0.8,
    'Test::Deep'      => 0.1,
  },
  requires            =>
  {
    'perl'                => 5.006,
    'List::Util'          => 1.22,
    'Math::Combinatorics' => 0.09,
    'Text::Wrap'          => 2009.0305,
    'Bio::Root::Root'     => 1.006924,
  },
  configure_requires  =>
  {
    'Module::Build'     => 0.38
  },
  auto_features       =>
  {
    graphing =>
    {
      description => 'Use GD::Graphics to draw graphs',
      requires    =>
      {
        'GD::Graph::lines'  => 1.15,
        'GD::Graph::colour' => 1.10,
        'GD::Image'         => 2.38,
      }
    },
  },
  script_files =>
  [
    'bin/GD_Filter_Enzymes.pl',
    'bin/GD_Generate_RSCU_Table.pl',
    'bin/GD_Graph_Dotplot.pl',
    'bin/GD_Graph_RSCU_Values.pl',
    'bin/GD_Juggle_Codons.pl',
    'bin/GD_List_Codon_Tables.pl',
    'bin/GD_Repeat_Smash.pl',
    'bin/GD_Reverse_Translate.pl',
    'bin/GD_Sequence_Subtraction.pl',
  ],
  get_options =>
  {
    like_last_time =>
    {
      store => \$llt,
      default => 0,
    },
    conf_path =>
    {
      store => \$cpath,
      type => '=s',
    },
    script_path =>
    {
      store => \$spath,
      type => '=s',
    },
    tmp_path =>
    {
      store => \$tpath,
      type => '=s',
    },
    graphing_support =>
    {
      store => \$g,
      type => '=i',
    },
  }
);

#  STUPID y_n TAKES y/n only as inputs BUT OUTPUTS 1/0!!!!!! AAAGHHGHGHGHGHGG  #
my @on = ('Y', 1);
my @off = ('N', 0);

my ($dcpath, $dspath, $dtpath) = ('/etc/GeneDesign/', '/usr/local/bin/', '/tmp/');
my ($dg, $lg) =  @on;

my $check = eval
{
  require Bio::GeneDesign::ConfigData;
};
if ($check)
{
  $dcpath = Bio::GeneDesign::ConfigData->config('conf_path')        || $dcpath;
  $dtpath = Bio::GeneDesign::ConfigData->config('tmp_path')         || $dtpath;
  $dspath = Bio::GeneDesign::ConfigData->config('script_path')      || $dspath;
  ($dg, $lg) = Bio::GeneDesign::ConfigData->config('graphing_support') ? @on : @off;
}

#If we're not using the like_last_time shortcut, prompt for anything that wasn't
# provided on the command line
if ($llt == 0)
{
  if (! defined $cpath)
  {
    $cpath = $GDB->prompt('Where should configuration files be installed?', $dcpath);
  }
  if (! defined $spath)
  {
    $spath = $GDB->prompt('Where should scripts be installed?', $dspath);
  }
  if (! defined $tpath)
  {
    $tpath = $GDB->prompt('Where should GeneDesign write tmp files?', $dtpath);
  }
  if (! defined $g && $GDB->feature('graphing'))
  {
    $g = $GDB->y_n('Enable GD::Graphics support?', $dg);
  }
  elsif (! $GDB->feature('graphing'))
  {
    $g = 0;
  }
}
#If we are using the like_last_time shortcut, use the defaults if something
# happens to not be defined.
else
{
  $cpath = defined $cpath ? $cpath : $dcpath;
  $tpath = defined $tpath ? $tpath : $dtpath;
  $spath = defined $spath ? $spath : $dspath;
  $g = defined $g ? $g : $lg;
}


#Prepare configuration directory
my $tcp = $cpath;
$tcp .= q{/} if substr($tcp, -1, 1) ne q{/};
$GDB->config_data(conf_path => $tcp);
print 'Configuration files will be in ', $GDB->config_data('conf_path'), "\n";
my $confs =
[
  'codon_tables/Arabidopsis_thaliana.rscu',
  'codon_tables/Bacillus_subtilis.rscu',
  'codon_tables/Caenorhabditis_elegans.rscu',
  'codon_tables/Corynebacterium_glutamicum.rscu',
  'codon_tables/Deinococcus_radiodurans.rscu',
  'codon_tables/Drosophila_melanogaster.rscu',
  'codon_tables/Escherichia_coli.rscu',
  'codon_tables/Unbiased.rscu',
  'codon_tables/Homo_sapiens.rscu',
  'codon_tables/Mycoplasma_genitalium.ct',
  'codon_tables/Mycoplasma_genitalium.rscu',
  'codon_tables/Oryza_sativa.rscu',
  'codon_tables/Saccharomyces_cerevisiae.rscu',
  'codon_tables/Standard.ct',
  'codon_tables/Yarrowia_lipolytica.rscu',
  'enzymes/all_enzymes',
  'enzymes/blunts',
  'enzymes/IIB',
  'enzymes/nonpal',
  'enzymes/nonpal_short',
  'enzymes/nonpal_and_IIB',
  'enzymes/outside',
  'enzymes/standard',
  'enzymes/standard_and_IIB',
  'enzymes/test',
];
$GDB->add_build_element('GeneDesign');
process_conf_files($GDB, $confs);
$GDB->install_path(GeneDesign => $GDB->config_data('conf_path'));


my $tsp = $spath;
$tsp .= q{/} if substr($tsp, -1, 1) ne q{/};
$GDB->config_data(script_path => $tsp);
$GDB->install_path(script => $GDB->config_data('script_path'));
print 'Scripts will be in ', $GDB->config_data('script_path'), "\n";

my $ttp = $tpath;
$ttp .= q{/} if substr($ttp, -1, 1) ne q{/};
$GDB->config_data(tmp_path => $ttp);
print 'Temporary files will be written to ', $GDB->config_data('tmp_path'), "\n";

if ($GDB->feature('graphing'))
{
  $GDB->config_data(graphing_support => $g);
  print 'Installing graphics support', "\n";
}
else
{
  $GDB->config_data(graphing_support => -1);
  print "$g; Graphing will not be installed\n"; 
}
print "\n";

$GDB->create_build_script();

print "\n";

sub process_conf_files
{
  my $build = shift;
  my $files = shift;
  return unless $files;

  my $conf_dir = File::Spec->catdir($build->blib, 'GeneDesign');
  File::Path::mkpath( $conf_dir );

  foreach my $file (@{$files})
  {
    my $result = $build->copy_if_modified($file, $conf_dir) or next;
    $build->fix_shebang_line($result) unless $build->is_vmsish;
  }
  return;
}
