#
# BioStudio functions for GBrowse interaction
#

=head1 NAME

Bio::BioStudio::GBrowse - GBrowse interaction

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

BioStudio functions for interacting with GBrowse

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::GBrowse;

require Exporter;
use Carp;
use English qw(-no_match_vars);
use YAML::Tiny;
use File::Find;
use File::Path qw(make_path);
use Bio::BioStudio::ConfigData;
use Bio::BioStudio::DB qw(:BS);
use GBrowse::ConfigData;
use autodie qw(open close);
use Cache::FileCache;
use Time::Format qw(%time);

use base qw(Exporter);

use strict;
use warnings;

our $VERSION = '2.10';
our $colorhash = _parse_gbrowse_colors();

our @EXPORT_OK = qw(
  add_to_GBrowse
  remove_from_GBrowse
  determine_feature_color
  link_to_feature
  link_to_chromosome
  get_cache_handle
  $colorhash
);
our %EXPORT_TAGS = (BS => \@EXPORT_OK);

my $VERNAME = qr{([\w]+)_[chr]*([\w\d]+)_(\d+)_(\d+)([\_\w+]*)}msix;

=head1 FUNCTIONS

=head2 add_to_GBrowse

=cut

sub add_to_GBrowse
{
  my ($chromosome) = @_;
  
  ## update the chromosome configuration file
  _create_chromosome_conf($chromosome);
  
  ## add to the GBrowse configuration file if it isn't there
  _add_to_GBrowse_conf($chromosome);
 
  return 1;
}

=head2 remove_from_GBrowse

=cut

sub remove_from_GBrowse
{
  my ($chromosome) = @_;
	
  my $name = $chromosome->name();
  my $repo_p = _path_in_repository($chromosome);
  if (-e $repo_p)
  {
    system "rm $repo_p";
  }
  my $GBconf = _path_to_conf();
  my $GBconftmp = $GBconf . ".tmp";
  my @args = ("sed -e \"/$name/d\" $GBconf >$GBconftmp");
  local $SIG{CHLD} = 'DEFAULT';
  system (@args) == 0 || croak ("BSERROR: oh no, can't edit $GBconf? $OS_ERROR");
  system "mv $GBconftmp $GBconf";
  return 1;
}

=head2 link_to_chromosome()

=cut

sub link_to_chromosome
{
  my ($chromosome) = @_;
  return q{} if (! $chromosome);
  my $href  = "http://" . _server_address() . q{/};
  $href .= "/cgi-bin/gb2/gbrowse/" . $chromosome->name();
  return $href;
}

=head2 link_to_feature()

=cut

sub link_to_feature
{
  my ($chromosome, $feat) = @_;
  return q{} if (! ($feat && $chromosome));
  my $href  = link_to_chromosome($chromosome) . q{/?};
  $href .= "start=" . $feat->start . q{;};
  $href .= "stop=" . $feat->end . q{;};
  $href .= "ref=" . $chromosome->seq_id() . q{;};
  return $href;
}

=head2 get_gbrowse_src_list()

Given the BioStudio config hashref, return a list of all of the chromosomes that
are available through GBrowse

=cut

sub get_gbrowse_src_list
{
	my ($BS) = @_;
	my @srcs;
	find sub { push @srcs, $File::Find::name}, $BS->{conf_repository};
	@srcs = grep {$_ =~ m{\.conf\Z}msix} @srcs;
  my @sources;
  foreach (@srcs)
  {
    push @sources, $1 if ($_ =~ /($VERNAME)/);
  }
	return @sources;
}

=head2 determine_feature_color()

=cut

sub determine_feature_color
{
  my ($feat) = @_;
  return "yellow" if (! scalar keys %{$colorhash});
  my $orfstat = $feat->has_tag('orf_classification') ? $feat->Tag_orf_classification : q{};
  return $colorhash->{gene}->{orf_classification}->{$orfstat} || "yellow";
}


=head1 INTERNALS

=head2 _path_to_GBrowse_dir

=cut

sub _path_to_GBrowse_dir
{
  my $GBrowse_conf_path = GBrowse::ConfigData->config('conf');
  $GBrowse_conf_path .= q{/} unless substr($GBrowse_conf_path, -1, 0) eq q{/};
  return $GBrowse_conf_path;
}

=head2 _path_to_conf

=cut

sub _path_to_conf
{
  return _path_to_GBrowse_dir() . 'GBrowse.conf';
}

=head2 _path_to_repo

=cut

sub _path_to_repo
{
  my $bs_dir = Bio::BioStudio::ConfigData->config('conf_path') . 'gbrowse/';
  my $repo_p = $bs_dir . 'conf_repository/';
  if (! -e $repo_p)
  {
    make_path($repo_p) || croak ("BSERROR: Can't mkdir $repo_p");
  }
  return $repo_p;
}

=head2 _server_address

=cut

sub _server_address
{
  return Bio::BioStudio::ConfigData->config('gbrowse_address');
}

=head2 _gbrowse_template

=cut

sub _gbrowse_template
{
  my $bs_dir = Bio::BioStudio::ConfigData->config('conf_path') . 'gbrowse/';
  return $bs_dir . 'BS_GBrowse_chromosome.conf';
}

=head2 _path_to_colors

=cut

sub _path_to_colors
{
  my $bs_dir = Bio::BioStudio::ConfigData->config('conf_path') . 'gbrowse/';
  return $bs_dir . 'GBrowse_colors.yaml';
}

=head2 _dir_in_repository

=cut

sub _dir_in_repository
{
  my ($chromosome) = @_;
  my $path = _path_to_repo() . $chromosome->species . q{/};
  $path .= $chromosome->seq_id . q{/};
  make_path($path) unless (-e $path);
  return $path;
}

=head2 _path_in_repository();

=cut

sub _path_in_repository
{
  my ($chromosome) = @_;
  my $path = _dir_in_repository($chromosome);
  $path .= $chromosome->name . ".conf";
  return $path;
}

=head2 _create_chromosome_conf()

=cut

sub _create_chromosome_conf
{
  my ($chromosome) = @_;
	
  my $name = $chromosome->name();
  #Grab chromosome configuration template
  my $template_p = _gbrowse_template();
  open (my $BSCONF, '<', $template_p)
    || croak "BSERROR: Can't open configuration template $template_p : $OS_ERROR";
  my $BSref = do {local $/ = <$BSCONF>};
  close $BSCONF;

  #make edits
  #my $dbengine = $chromosome->db_engine();
  #if ($dbengine ne 'memory')
  #{
  #  my $adaptor = 'DBI::' . $dbengine;
  #  my $handlestring = '-dsn ' . _connectstring($name, $dbengine);
  #  my $userstring = '-user ' . _user($dbengine);
  #  my $passstring = '-pass ' . _pass($dbengine);
  #  $BSref =~ s{\*ENGINE\*}{$adaptor}msixg;
  #  $BSref =~ s{\*DBARG2\*}{$handlestring}msixg;
  #  $BSref =~ s{\*DBARG3\*}{$userstring}msixg;
  #  $BSref =~ s{\*DBARG4\*}{$passstring}msixg;
  #}
  #else
  #{
    my $adaptor = 'DBI::SQLite';
    my $dsn = '-dsn dbi:SQLite:database=' . $chromosome->path_to_DB();
    $BSref =~ s{\*ENGINE\*}{$adaptor}msixg;
    $BSref =~ s{\*DBARG2\*}{$dsn}msixg;
    $BSref =~ s{\*DBARG3\*}{}msixg;
    $BSref =~ s{\*DBARG4\*}{}msixg;
  #}
  
  my $seqid = $chromosome->seq_id();
  my $landmark = $seqid . q{:1..} . $chromosome->len();
	$BSref =~ s{\*LANDMARK\*}{$landmark}msixg;
  
	$BSref =~ s{\*VERSION\*}{$name}msixg;
  
	#$BSref =~ s{\*VERSIONNOTE\*}{}msixg;

  #Compute chromosome confpath, create directories if path is new
  my $conf_p = _path_in_repository($chromosome);

  #Write out chromosome configuration file
	open (my $CONF, '>', $conf_p);
  system "chmod 777 $conf_p";
	print $CONF $BSref;
	close $CONF;
  return $conf_p;
}

=head2 _add_to_GBrowse_conf()

=cut

sub _add_to_GBrowse_conf
{
  my ($chromosome) = @_;

  my $chrname = $chromosome->name();
  my $conf_p = _path_in_repository($chromosome);
  my $gbconf_p = _path_to_conf();
  
  #Read GBrowse conf file;
  open (my $CONFIN, '<', $gbconf_p)
    || croak "BSERROR: Can't open GBrowse conf $gbconf_p : $OS_ERROR";
  my $GBref = do {local $/ = <$CONFIN>};
  close $CONFIN;

  #if it doesn't have the chromosome, add a section
  if ($GBref !~ m{\[$chrname\]}msix)
  {
    open (my $CONFOUT, '>>', $gbconf_p)
      || croak "BSERROR: can't write GBrowse conf $gbconf_p : $OS_ERROR";
    print $CONFOUT "\n[$chrname]\n";
    print $CONFOUT "description     = $chrname\n";
    print $CONFOUT "path            = $conf_p\n";
    close $CONFOUT;
  }
	return 1;
}

=head2 _parse_gbrowse_colors()

=cut

sub _parse_gbrowse_colors
{
  my $bs_dir = Bio::BioStudio::ConfigData->config('conf_path') . 'gbrowse/';
  my $path = $bs_dir . 'GBrowse_colors.yaml';
  my $colorhref = {};
  return $colorhref unless (-e $path);

  my $yaml = YAML::Tiny->read($path);
  foreach my $tag (keys %{$yaml->[0]})
  {
    $colorhref->{$tag} = $yaml->[0]->{$tag};
  }
  return $colorhref;
}

=head2 get_cache_handle

=cut

sub get_cache_handle
{
  my ($namespace, $username, $expire, $pinterval) = @_;
  croak 'No namespace provided for get_cache_handle' unless ($namespace);
  $username = $username || 'nobody';
  $expire = $expire || '30 minutes';
  $pinterval = $pinterval || '4 hours';
  
  my $cache = Cache::FileCache->new
  (
    {
      namespace           => $namespace,
      username            => $username,
      default_expires_in  => $expire,
      auto_purge_interval => $pinterval,
    }
  );
  
  return $cache;
}

=head1 STUBS

=cut

=head2 gbrowse_color_link()

Creates links to the gbrowse installation for genes

=cut

sub gbrowse_color_link
{
  my ($BS, $feat) = @_;
  my $DISPLAY = {};
  my ($pre, $prep, $post) = ("<code style=\"color:", ";\">", "</code>");
  my $chref = $BS->gb_colors();
  my $color = exists $chref->{$feat->primary_tag}
              ? exists $chref->{$feat->primary_tag}->{default}
                ? $chref->{$feat->primary_tag}->{default}
                : "black"
              : "black";
  foreach my $tag (keys %{$chref->{$feat->primary_tag}})
  {
    if ($feat->has_tag($tag))
    {
      my $val = join(q{}, $feat->get_tag_values($tag));
      $color = $chref->{$feat->primary_tag}->{$tag}->{$val};
      last;
    }
  }
  my $displayname = $feat->has_tag("gene")
                  ?  $feat->Tag_load_id . " (" . $feat->Tag_gene . ")"
                  :  $feat->Tag_load_id;
  my $fulldisplay = $pre . $color . $prep . $displayname . $post;
  return make_link($BS, $feat, $fulldisplay)
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, BioStudio developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Joint BioEnergy 
Institute, the Lawrence Berkeley National Laboratory, the Department of Energy, 
and the BioStudio developers may not be used to endorse or promote products 
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE DEVELOPERS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut