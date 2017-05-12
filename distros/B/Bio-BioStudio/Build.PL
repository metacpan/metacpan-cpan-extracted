use 5.006;

use FindBin '$Bin';
use lib "$Bin/install_util";
use BioStudioInstall;
use Carp;
use File::Basename;
use Digest::MD5;

use strict;
use warnings;

print "\n";

my $llt = 0;
my ($cpath, $tpath, $spath) = (q{}, q{}, q{});
my ($gb, $gba, $sge, $bl, $c) = (undef, q{}, undef, undef, undef);
my ($ms) = (undef, undef);
my ($mu, $mp, $mh, $mr) = (undef, undef, undef, undef);

#BUILDER
my $BSB = BioStudioInstall->new
(
  module_name         => 'Bio::BioStudio',
  license             => 'bsd',
  dist_author         => q{Sarah Richardson <smrichardson@lbl.gov>},
  dist_version        => '2.11',
  dist_abstract       => 'perl for the design of synthetic chromosomes',
  add_to_cleanup      => [ 'Bio::BioStudio-*' ],
  create_makefile_pl  => 'traditional',
  build_requires      =>
  {
    'Test::More' => 0,
  },
  requires            =>
  {
    'perl'                    => 5.006,
    'Readonly'                => 2.00,
    'Text::Diff'              => 1.3,
    'Time::Format'            => 1.11,
    'Exception::Class'        => 1.38,
    'URI::Escape'             => 1.59,
    'YAML::Tiny'              => 1.50,
    'Bio::Root::Root'         => 0,
    'Bio::GeneDesign'         => 5.00,
    'DBD::SQLite'             => 1.48,
  },
  configure_requires  =>
  {
    'Module::Build' => 0.38,
  },
  auto_features       =>
  {
    gbrowse =>
    {
      description => "Use GBrowse2 as a BioStudio GUI",
      requires    =>
      {
        'Bio::Graphics::Browser2' => 2.42,
        'Cache::FileCache'        => 0
      }
    },
    #mysql =>
    #{
    #  description => "Use MySQL as a database engine",
    #  requires    =>
    #  {
    #    'DBI' => 1.616,
    #    'DBD::mysql' => 4.020
    #  }
    #},
    cairo =>
    {
      description => "Use Cairo to generate chromosome maps",
      requires    =>
      {
        'Cairo'           => 1.081,
        'Font::FreeType'  => 0.03,
      }
    },
    blast =>
    {
      description => "Use BLAST+ to design primers and make alignments",
      requires    =>
      {
        'Bio::Tools::Run::StandAloneBlastPlus' => 0
      }
    }
  },
  script_files        =>
  [
    'bin/BS_AddFromGenbank.pl',
    'bin/BS_AddFromGFF.pl',
    'bin/BS_auto_codon_juggle.pl',
    'bin/BS_auto_filter_enzymes.pl',
    'bin/BS_auto_gather_enzymes.pl',
    'bin/BS_auto_tag_genes.pl',
    'bin/BS_Cartoonist.pl',
    'bin/BS_ChromosomeAnalyzer.pl',
    'bin/BS_ChromosomeCutter.pl',
    'bin/BS_ChromosomeDiff.pl',
    'bin/BS_ChromosomeSegmenter.pl',
    'bin/BS_ChromosomeSplicer.pl',
    'bin/BS_CodonJuggler.pl',
    'bin/BS_FirstGBrowse.pl',
    'bin/BS_PCRTagDumper.pl',
    'bin/BS_PCRTagger.pl',
    'bin/BS_RepeatSmasher.pl',
    'bin/BS_SeqChecker.pl',
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
    gbrowse_support =>
    {
      store => \$gb,
      type => '=i',
    },
    gbrowse_address =>
    {
      store => \$gba,
      type => '=s',
    },
    SGE_support =>
    {
      store => \$sge,
      type => '=i',
    },
    blast_support =>
    {
      store => \$bl,
      type => '=i',
    },
    cairo_support =>
    {
      store => \$c,
      type => '=i',
    },
    #mysql_support =>
    #{
    #  store => \$ms,
    #  type => '=i',
    #},
    #mysql_user =>
    #{
    #  store => \$mu,
    #  type => '=s',
    #},
    #mysql_pass =>
    #{
    #  store => \$mp,
    #  type => '=s',
    #},
    #mysql_host =>
    #{
    #  store => \$mh,
    #  type => '=s',
    #},
    #mysql_port =>
    #{
    #  store => \$mr,
    #  type => '=s',
    #},
  }
);

#  STUPID y_n TAKES y/n only as inputs BUT OUTPUTS 1/0!!!!!! AAAGHHGHGHGHGHGG  #
my @on = ('Y', 1);
my @off = ('N', 0);

my ($dcpath, $dspath, $dtpath) = ('/etc/BioStudio', '/usr/local/bin/', '/tmp');

#gbrowse is on by default
my ($dgb, $lgb) = @on;
my $dgba = 'localhost';

#blast is on by default
my ($dbl, $lbl) = @on;

#cairo is on by default
my ($dc, $lc) = @on;

#qsub is off by default
my ($dsge, $lsge) = @off;

#mysql is off by default
#my ($dms, $lms) = @off;
#my ($dmu, $dmp, $dmh, $dmr) = ('bss', 'bsspass', 'localhost', '3306');

#If BioStudio has been installed before, use its configuration settings as the
# defaults
my $check = eval
{
  require Bio::BioStudio::ConfigData;
};
if ($check)
{
  ($dgb,  $lgb)  = Bio::BioStudio::ConfigData->config('gbrowse_support') ? @on : @off;
  ($dbl,  $lbl)  = Bio::BioStudio::ConfigData->config('blast_support')   ? @on : @off;
  ($dsge, $lsge) = Bio::BioStudio::ConfigData->config('SGE_support')     ? @on : @off;
  ($dc,   $lc)   = Bio::BioStudio::ConfigData->config('cairo_support')   ? @on : @off;
  #($dms,  $lms)  = Bio::BioStudio::ConfigData->config('mysql_support')   ? @on : @off;
  $dcpath = Bio::BioStudio::ConfigData->config('conf_path')        || $dcpath;
  $dtpath = Bio::BioStudio::ConfigData->config('tmp_path')         || $dtpath;
  $dspath = Bio::BioStudio::ConfigData->config('script_path')      || $dspath;
  $dgba   = Bio::BioStudio::ConfigData->config('gbrowse_address')  || $dgba;
  #$dmp    = Bio::BioStudio::ConfigData->config('mysql_pass')       || $dmp;
  #$dmu    = Bio::BioStudio::ConfigData->config('mysql_user')       || $dmu;
  #$dmh    = Bio::BioStudio::ConfigData->config('mysql_host')       || $dmh;
  #$dmr    = Bio::BioStudio::ConfigData->config('mysql_port')       || $dmr;
}

#If we're not using the like_last_time shortcut, prompt for anything that wasn't
# provided on the command line
if ($llt == 0)
{
  if (! $cpath)
  {
    $cpath = $BSB->prompt('Where should configuration files be installed?', $dcpath);
  }
  if (! $spath)
  {
    $spath = $BSB->prompt('Where should scripts be installed?', $dspath);
  }
  if (! $tpath)
  {
    $tpath = $BSB->prompt('Where should BioStudio write tmp files?', $dtpath);
  }
  if (! defined $gb && $BSB->feature('gbrowse'))
  {
    $gb = $BSB->y_n('Enable GBrowse interaction?', $dgb);
    $gba = $gb  ? $BSB->prompt('Address of GBrowse server?', $dgba) : $dgba;
  }
  if (! defined $sge)
  {
    $sge = $BSB->y_n('Enable SGE job farming?', $dsge);
  }
  if (! defined $bl && $BSB->feature('blast'))
  {
    $bl = $BSB->y_n('Enable BLAST+ support?', $dbl);
  }
  if (! defined $c && $BSB->feature('cairo'))
  {
    $c = $BSB->y_n('Enable Cairo graphics support?', $dc);
  }
  #if (! defined $ms && $BSB->feature('mysql'))
  #{
  #  $ms = $BSB->y_n('Use MySQL instead of SQLite?', $dms);
  #  if ($ms)
  #  {
  #    $mh = defined $mh ? $mh : $BSB->prompt('Host for MySQL?', $dmh);
  #    $mr = defined $mr ? $mr : $BSB->prompt('Port for MySQL?', $dmr);
  #    $mu = defined $mu ? $mu : $BSB->prompt('Username for MySQL?', $dmu);
  #    $mp = defined $mp ? $mp : $BSB->prompt('Password for MySQL?', $dmp);
  #  }
  #}
  print "\n";
}
#If we are using the like_last_time shortcut, use the defaults if something
# happens to not be defined.
else
{
  $cpath = $cpath || $dcpath;
  $tpath = $tpath || $dtpath;
  $spath = $spath || $dspath;
  $gb    = defined $gb  ? $gb : $lgb;
  $gba   = $gba   || $dgba;
  $sge   = defined $sge ? $sge : $lsge;
  $bl    = defined $bl  ? $bl  : $lbl;
  $c     = defined $c   ? $c   : $lc;
  #$ms    = defined $ms  ? $ms  : $lms;
  #$mu    = $mu    || $dmu;
  #$mp    = $mp    || $dmp;
  #$mh    = $mh    || $dmh;
  #$mr    = $mr    || $dmr;
}

my $ttp = $tpath;
$ttp .= q{/} unless substr($ttp, -1, 1) eq q{/};
$BSB->config_data(tmp_path => $ttp);

#Prepare scripts directory
my $tsp = $spath;
$tsp .= q{/} unless substr($tsp, -1, 1) eq q{/};
$BSB->config_data(script_path => $tsp);
$BSB->install_path(script => $BSB->config_data('script_path'));
print "\tWill install script files in ", $BSB->config_data('script_path'), "\n";


#Prepare configuration directory
my $tcp = $cpath;
$tcp .= q{/} unless substr($tcp, -1, 1) eq q{/};
$BSB->config_data(conf_path => $tcp);
my $confs =
[
  'cairo/Armata-Regular.otf',
  'cairo/Armata_license.txt',
  'cairo/Aurulent_license.txt',
  'cairo/AurulentSansMono-Regular.otf',
  'cairo/Bree_license.txt',
  'cairo/BreeSerif-Regular.otf',
  'cairo/Cairo_colors.yaml',
  'cairo/Inconsolata.otf',
  'cairo/Inconsolata_license.txt',
  'cairo/Pecita.otf',
  'cairo/Pecita_license.txt',
  'cairo/Verily_license.txt',
  'cairo/VerilySerifMono.otf',
  'features/loxPsym.fasta',
  'features/rox.fasta',
  'features/universal_telomere_cap_left.fasta',
  'features/universal_telomere_cap_right.fasta',
  'foswiki/WebAtom.txt',
  'foswiki/WebChanges.txt',
  'foswiki/WebCreateNewTopic.txt',
  'foswiki/WebHome.txt',
  'foswiki/WebIndex.txt',
  'foswiki/WebLeftBar.txt',
  'foswiki/WebNotify.txt',
  'foswiki/WebPreferences.txt',
  'foswiki/WebRss.txt',
  'foswiki/WebSearch.txt',
  'foswiki/WebSearchAdvanced.txt',
  'foswiki/WebStatistics.txt',
  'foswiki/WebTopicList.txt',
  'gbrowse/BS_GBrowse_chromosome.conf',
  'gbrowse/GBrowse_colors.yaml',
  'gbrowse/conf_repository/repository_README.txt',
  'genome_repository/repository_README.txt',
  'genome_repository/Escherichia_coli_MG1655/chr01/Escherichia_coli_MG1655_chr01_0_00.gff',
  'markers/LEU2.gff',
  'markers/URA3.gff',
];
$BSB->add_build_element('BioStudio');
$BSB->process_conf_files($confs);
$BSB->install_path(BioStudio => $BSB->config_data('conf_path'));
print "\tWill install configuration files in ";
print $BSB->config_data('conf_path') . "\n";

#Check for bioperl scripts
my $bp = `which bp_seqfeature_load.pl` || `which bp_seqfeature_load`;
if (! $bp)
{
  warn ("Either BioPerl scripts are not installed or they are not in my PATH");
}
else
{
  my ($x, $bppath) = fileparse($bp);
  $BSB->config_data('bioperl_path' => $bppath);
  print "\tWill use BioPerl scripts found in $bppath\n";  
}

#configure GBrowse if GBrowse is installed
$BSB->config_data(gbrowse_support => $gb);
$BSB->config_data(gbrowse_address => $gba);
if ( $BSB->config_data('gbrowse_support') )
{
  my $plugins =
  [
    'gbrowse_plugins/BS_Cartoonist.pm',
    'gbrowse_plugins/BS_ChromosomeAnalyzer.pm',
    'gbrowse_plugins/BS_ChromosomeCutter.pm',
    'gbrowse_plugins/BS_ChromosomeDiff.pm',
    'gbrowse_plugins/BS_ChromosomeSegmenter.pm',
    'gbrowse_plugins/BS_ChromosomeSplicer.pm',
    'gbrowse_plugins/BS_CodonJuggler.pm',
    'gbrowse_plugins/BS_PCRTagDumper.pm',
    'gbrowse_plugins/BS_PCRTagger.pm',
    'gbrowse_plugins/BS_RepeatSmasher.pm',
  ];
  require GBrowse::ConfigData;
  my $plugin_path = GBrowse::ConfigData->config('conf') . q{/} . 'plugins/';
  $BSB->config_data(gbrowse_plugin_path => $plugin_path);
  $BSB->add_build_element('gbrowse_plugins');
  $BSB->install_path(gbrowse_plugins => $plugin_path);
  print "\tWill install gbrowse plugins in $plugin_path\n";
  print "\tWill run with gbrowse installation in $gba\n";
  $BSB->process_gbrowse_files($plugins);
  chmod 0777, GBrowse::ConfigData->config('conf') . q{/} . 'GBrowse.conf';
}

$BSB->config_data(SGE_support => $sge);
if ( $BSB->config_data('SGE_support') )
{
  print "\tWill enable qsub\n";
}

#Optionally configure BLAST+ if Standalonetools is installed
$BSB->config_data(blast_support => $bl);
if ( $BSB->config_data('blast_support') )
{
  my $blp = `which blastn`;
  die ("Either BLAST+ is not installed or it is not on my PATH") unless ($blp);
  my ($y, $blpath) = fileparse($blp);
  print "\tWill use BLAST+ executables found in $blpath\n";
}

#Optionally configure Cairo if Cairo is installed
$BSB->config_data(cairo_support => $c);
if ( $BSB->config_data('cairo_support ') )
{
  print "\tWill use Cairo libraries\n";
}

#if ($ms && $BSB->feature('mysql'))
#{
#  $BSB->config_data(db_engine => 'MySQL');
#  $BSB->config_data(mysql_support => $ms);
#  $BSB->config_data(mysql_host => $mh);
#  $BSB->config_data(mysql_port => $mr);
#  $BSB->config_data(mysql_user => $mu);
#  $BSB->config_data(mysql_pass => $mp);
#  print "\tYou must ensure that BioStudio can interact with mysql:\n";
#  print "\t\t\$ mysql -u root\n";
#  print "\t\t" . '> CREATE USER "' . $mu . '"@"' . $mh . '" IDENTIFIED BY "' ;
#  print $mp . q{";} . "\n";
#  print "\t\t" . '> GRANT ALL PRIVILEGES ON `bsdb\_%`.* TO "' . $mu . '"@"';
#  print $mh . q{";} . "\n";
#}
#else
#{
  $BSB->config_data(db_engine => 'SQLite');
#}
$BSB->create_build_script();
