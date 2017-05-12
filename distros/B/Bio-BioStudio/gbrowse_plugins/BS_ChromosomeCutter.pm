#
# BioStudio Chromosome Cutter GBrowse interface
#

=head1 NAME

Bio::Graphics::Browser2::Plugin::BS_ChromosomeCutter

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>

=cut

package Bio::Graphics::Browser2::Plugin::BS_ChromosomeCutter;

use Bio::Graphics::Browser2::Plugin;
use Bio::BioStudio;
use Bio::BioStudio::GBrowse qw(:BS);
use Pod::Usage;
use CGI qw(:all delete_all);
use Digest::MD5;
use English qw(-no_match_vars);
use Carp;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '2.10';
@ISA = qw(Bio::Graphics::Browser2::Plugin);

##Global variables
my $BS;
my $plugin_name = 'BS_ChromosomeCutter';
my $bsversion = $plugin_name . q{_} . $VERSION;
local $OUTPUT_AUTOFLUSH = 1;

my $featdefault = " ( )";

=head2 name

Plugin name

=cut

sub name
{
  return 'BioStudio: Delete from the Chromosome';
}

=head2 type

Plugin type

=cut

sub type
{
  return 'dumper';
}

=head2 verb

Plugin verb

=cut

sub verb
{
  return q{ };
}

=head2 description

Plugin description

=cut

sub description
{
  return p("This is a chromosome editor.  It requires a selection be made in
    the gbrowse view. Reference from the 5' end.");
}

=head2 init

Make a new BioStudio instance

=cut

sub init
{
  my $self = shift;
  $BS = Bio::BioStudio->new();
  return;
}

=head2 config_defaults

Set default configuration

=cut

sub config_defaults
{
  my $self = shift;
  return;
}

=head2 mime_type

Plugin return type

=cut

sub mime_type
{
  return 'text/html';
}

=head2 reconfigure

Recover configuration

=cut

sub reconfigure
{
  my $self  = shift;
  my $current = $self->configuration;
  foreach ( $self->config_param() )
  {
    $current->{$_} = $self->config_param($_) ? $self->config_param($_) : undef;
  }
}

=head2 configure_form

Render form, gather configuration from user

=cut

sub configure_form
{
  my $self = shift;
  my $gb_settings = $self->page_settings;
  my $sourcename  = $gb_settings->{source};
  my $chromosome  = $BS->set_chromosome(-chromosome => $sourcename);

  #Check if overwrite warning is needed
  my $gwarning = $BS->gv_increment_warning($chromosome);
  my $cwarning = $BS->cv_increment_warning($chromosome);

  my $scalewarns = "<br>";
  if ($gwarning)
  {
    my $gwarn  = "$gwarning already exists; if you increment the genome ";
       $gwarn .= "version it will be overwritten.";
    $scalewarns .= p("<strong style=\"color:#FF0000;\">$gwarn</strong><br> ");
  }
  if ($cwarning)
  {
    my $cwarn  = "$cwarning already exists; if you increment the chromosome ";
       $cwarn .= "version it will be overwritten.";
    $scalewarns .= p("<strong style=\"color:#FF0000;\">$cwarn.</strong><br> ");
  }

  my $db    = $self->db_search;
  my $start = $gb_settings->{view_start};
  my $stop  = $gb_settings->{view_stop};
  my @a = $db->features(-range=>"contains");
 
  my @flankers = grep {($_->start < $start && ($_->end <= $stop && $_->end >= $start))
                    || ($_->end > $stop && ($_->start >= $start && $_->start <= $stop))} @a;
  @flankers = map {$_->primary_tag . q{ } . $_->Tag_load_id . "<br>"} @flankers;
                 
  my %FEATTYPES = ();
  my @contained = grep {$_->start >= $start && $_->end <= $stop} @a;
  $FEATTYPES{$_->primary_tag}++ foreach (@contained);
  my @featcounts = map { $FEATTYPES{$_} . q{ } . $_  . "<br>"} sort keys %FEATTYPES;
  my @featkeys = sort {$a cmp $b} keys %FEATTYPES;
  unshift @featkeys, $featdefault;
 
  my $BS_FEATS = $BS->custom_features();
  my @BSKINDS = map {"<strong>" . $_->prototype . "</strong> " . $_->primary_tag  . "<br>"} values %{$BS_FEATS};
  @BSKINDS = sort {$a cmp $b} @BSKINDS;
  my @inskeys = sort {$a cmp $b} map {$_->prototype} values %{$BS_FEATS};
  unshift @inskeys, $featdefault;
 
  my %DELHASH;

  my $popupseqdelbsfeat = popup_menu(
    -name     => $self->config_name("seqdel.INSERT"),
    -values   => \@inskeys,
    -default  => $featdefault);
  $DELHASH{'seqdel'} = "delete this segment (and replace with a $popupseqdelbsfeat)<br>";
 
  $DELHASH{'seqdelprp'} = "propose this segment for deletion<br>";

  my $popupfeatdel = popup_menu(
    -name     => $self->config_name("featdel.TYPE"),
    -values   => \@featkeys,
    -default  => $featdefault);
  my $popupfeatdelbsfeat = popup_menu(
    -name     => $self->config_name("featdel.INSERT"),
    -values   => \@inskeys,
    -default  => $featdefault);
  $DELHASH{'featdel'} = "delete the $popupfeatdel features wholly contained within this segment (and replace with $popupfeatdelbsfeat)<br>";
 
  my $popupfeatdelprp = popup_menu(
    -name     => $self->config_name("featdelprp.TYPE"),
    -values   => \@featkeys,
    -default  => $featdefault);
  $DELHASH{'featdelprp'} = "propose the $popupfeatdelprp features wholly contained within this segment for deletion<br>";

  my $tfield = textfield(
    -name     => $self->config_name("listdel.FEATURES"),
    -value    => q{},
    -size     => 50);
  $DELHASH{'listdel'} = "delete the features with the following names: $tfield<br>";
  
  my @choices = ();
  
  push @choices, TR(
    {-class => 'searchtitle'},
    th('Editing Chromosome Features<br>')
  );
     
  push @choices, TR(
    {-class => 'searchtitle'},
    th('Editor Name'),
    td(
      textfield(
        -name       => $self->config_name('EDITOR'),
        -default    => $ENV{REMOTE_USER},
        -size       => 25,
        -maxlength  => 20
      )
    )
  );
           
  push @choices, TR(
    {-class => 'searchtitle'},
    th('Notes'),
    td(
      textfield(
        -name => $self->config_name('MEMO'),
        -size => 50
      )
    )
  );

  push @choices, TR(
    {-class => 'searchtitle'},
    th("Increment genome version or chromosome version?$scalewarns"),
    td(
      radio_group(
        -name     => $self->config_name('SCALE'),
        -values   => ['genome', 'chrom'],
        -default  => 'chrom',
        -labels   => {
          'chrom'   => 'chromosome version',
          'genome'  => 'genome version'
        },
      )
    )
  );
           
  autoEscape(0);
 
  push @choices, TR(
    {-class => 'searchbody'},
    th(
      {-align=>'RIGHT', -width=>'25%'},
      'DELETION OPTIONS:'
    ),
    td(
      "<br>",
      radio_group(
        -name   => $self->config_name('ACTION'),
        -values => \%DELHASH
      ),
      "<br><br>"
    )
  );

  if (scalar(@flankers))
  {
    push @choices, TR(
      {-class => 'searchtitle'},
      th(
        {-align => 'RIGHT', -width => '25%'},
        scalar(@flankers) . " features are not fully contained in this view "
      ),
      td("<br>@flankers<br>")
    );
  }
 
  push @choices, TR(
    {-class => 'searchtitle'},
    th(
      {-align => 'RIGHT',-width => '25%'},
      "Feature counts in this segment:",
      td(
        make_table(\@featcounts, 5)
      )
    )
  );
       
  push @choices, TR(
    {-class => 'searchtitle'},
    th(
      {-align => 'RIGHT', -width => '25%'},
      "Custom features available:"
    ),
    td(
      make_table(\@BSKINDS, 3)
    )
  );
       
  my $html = table(@choices, 2);
  autoEscape(1);
  return $html;
}

=head2 dump

Call BS_ChromosomeCutter and pass the parameters
Then monitor the scripts progress; print periodic output.

=cut

sub dump
{
  my $self      = shift;
  my $segment   = shift;

  #If we're monitoring the results, print out from the cache and refresh in 5
  if (my $sid = param('session'))
  {
    my $cache = get_cache_handle($plugin_name);
    my $data = $cache->get($sid);
    unless($data and ref $data eq 'ARRAY')
    {
      #some kind of error
      exit 0;
    }
    print $data->[0]
      ? start_html(-title => "Results for $plugin_name job $sid")
      : start_html(-title => "Running $plugin_name job $sid",
                   -head=>meta({-http_equiv =>'refresh', -content => '5'}));
    print p(i("This page will refresh in 5 seconds")) unless $data->[0];
    print pre($data->[1]);
    print p(i("...continuing...")) unless $data->[0];
    print end_html;
    return;
  }
 
  #Otherwise we're launching the script
  else
  {
   #Prepare persistent variables
    my $sid = Digest::MD5::md5_hex(Digest::MD5::md5_hex(time().{}.rand().$$));
    my $cache = get_cache_handle($plugin_name);
    $cache->set($sid, [0, q{}]);
  
   #Prepare arguments
    my $pa               = $self->configuration;
    my $gbrowse_settings = $self->page_settings;
    my $command;
    $pa->{CHROMOSOME} = $gbrowse_settings->{source};
    $pa->{STARTPOS} = $segment->start;
    $pa->{STOPPOS}  = $segment->end;
    $pa->{OUTPUT}   = 'html';
    my $action = $pa->{ACTION};
    foreach my $key (grep {$_ =~ /\./} keys %{$pa})
    {
      if ($pa->{$key} ne $featdefault)
      {
        $pa->{$1} = $pa->{$key} if ($key =~ /\.(\w+)/);
      }
      delete $pa->{$key};
    }
    $pa->{$_} = "\"$pa->{$_}\"" foreach (grep {$pa->{$_} =~ /\ /} keys %{$pa});
    $command .= "--" . $_ . q{ } . $pa->{$_} . q{ } foreach (keys %{$pa});

   #If we're the parent, prepare the url and offer a link.
    if (my $pid = fork)
    {
      delete_all();
      my $addy = self_url() . "?plugin=$plugin_name;plugin_action=Go;";
      $addy .= "session=$sid";
      print start_html(
        -title => "Launching BioStudio...",
        -head  => meta({
          -http_equiv  => 'refresh',
          -content     => "10; URL=\"$addy\""}));
      print p(i("BioStudio is running."));
      print p("Your job number is $sid.");
      print "If you are not redirected in ten seconds, ";
      print "<a href=\"$addy\">click here for your results</a><br>";
      print p("Command:");
      print pre("$command");
      print end_html;
      return;
    }
   #If we're a child, launch the script, feed results to the cache
    elsif(defined $pid)
    {
      close STDOUT;
      unless (open F, "-|")
      {
        my $path = $BS->{script_path} . $plugin_name . '.pl';
        open STDERR, ">&=1";
        exec "$path $command" || croak "Cannot execute $plugin_name: $OS_ERROR";
      }
      my $buf = q{};
      while (<F>)
      {
        $buf .= $_;
        $cache->set($sid, [0, $buf]);
      }
      $cache->set($sid, [1, $buf]);
      exit 0;
    }
   #Otherwise, uh oh
    else
    {
      croak "Cannot fork: $OS_ERROR";
    }
  }
}

=head2 make_table

Generate html tables

=cut

sub make_table
{
  my ($arlist, $colcount) = @_;
  my ($x, $y) = (0, $colcount-1);
  my @table;
  while ($x < scalar(@{$arlist}))
  {
    my @slice = @$arlist[$x..$y];
    push @table, TR(td(\@slice));
    $x += $colcount;
    $y += $colcount;
  }
  return table(@table);
}

1;

__END__