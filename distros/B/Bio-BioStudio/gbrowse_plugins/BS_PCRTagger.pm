#
# BioStudio PCRTagger GBrowse interface
#

=head1 NAME

Bio::Graphics::Browser2::Plugin::BS_PCRTagger

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>

=cut

package Bio::Graphics::Browser2::Plugin::BS_PCRTagger;

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
my $plugin_name = 'BS_PCRTagger';
my $bsversion = $plugin_name . q{_} . $VERSION;
local $OUTPUT_AUTOFLUSH = 1;

=head2 name

Plugin name

=cut

sub name
{
  return 'BioStudio: Add PCR Tags';
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
  return p('This plugin adds PCR Tags to exons.');
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
  return;
}

=head2 mime_type

Plugin return type

=cut

sub mime_type
{
  return 'text/html'
}

=head2 configure_form

Render form, gather configuration from user

=cut

sub configure_form
{
  my $self = shift;
  my $gbrowse_settings = $self->page_settings;
  my $sourcename        = $gbrowse_settings->{source};
  my $chromosome        = $BS->set_chromosome(-chromosome => $sourcename);
 
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
 
  my @choices;

  push @choices, TR(
    {-class => 'searchtitle'},
    th("Adding PCR Tags<br>")
  );
     
  push @choices, TR(
    {-class => 'searchtitle'},
    th("Editor Name"),
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
        -labels   => {'chrom' => 'chromosome', 'genome' => 'genome'},
        -default  => 'genome'
      )
    )
  );
         
  push @choices, TR(
    {-class => 'searchtitle'},
    th('Options')
  );
     
  push @choices, TR(
    {-class => 'searchbody'},
    th("Tm range for pcr tags (&deg;C)"),
    td(
      'min',
      textfield(
        -name       => $self->config_name('MINTAGMELT'),
        -size       => 4,
        -maxlength  => 2,
        -default    => 58
      ),
      'max',
      textfield(
        -name      => $self->config_name('MAXTAGMELT'),
        -size      => 4,
        -maxlength => 2,
        -default   => 60
      )
    )
  );
           
  push @choices, TR(
    {-class => 'searchbody'},
    th('range for tag size (bp)'),
    td(
      'min',
      textfield(
        -name       => $self->config_name('MINTAGLEN'),
        -size       => 4,
        -maxlength  => 3,
        -default    => 19
      ),
      'max',
      textfield(
        -name      => $self->config_name('MAXTAGLEN'),
        -size      => 4,
        -maxlength => 3,
        -default   => 28
      )
    )
  );
           
  push @choices, TR(
    {-class => 'searchbody'},
    th('range for amplicon size (bp)'),
    td(
      'min',
      textfield(
        -name       => $self->config_name('MINAMPLEN'),
        -size       => 4,
        -maxlength  => 3,
        -default    => 200
      ),
      'max',
      textfield(
         -name      => $self->config_name('MAXAMPLEN'),
         -size      => 4,
         -maxlength => 3,
         -default   => 500
      )
    )
  );
        
  push @choices, TR(
    {-class => 'searchbody'},
    th("maximum amplicon overlap (%)"),
    td(
      textfield(
        -name       => $self->config_name('MAXAMPOLAP'),
        -size       => 4,
        -maxlength  => 2,
        -default    => 25
      )
    )
  );
         
  push @choices, TR(
    {-class => 'searchbody'},
    th("minimum bp diff between tags (%)"),
    td(
      textfield(
        -name       => $self->config_name('MINPERDIFF'),
        -size       => 4,
        -maxlength  => 3,
        -default    => 33
      )
    )
  );
           
  push @choices, TR(
    {-class => 'searchbody'},
    th('minimum gene length'),
    td(
      textfield(
        -name       => $self->config_name('MINORFLEN'),
        -size       => 4,
        -maxlength  => 3,
        -default    => 501
      )
    )
  );
           
  push @choices, TR(
    {-class => 'searchbody'},
    th('most five prime base eligble'),
    td(
      textfield(
        -name       => $self->config_name('FIVEPRIMESTART'),
        -size       => 4,
        -maxlength  => 3,
        -default    => 101
      )
    )
  );
           
  push @choices, TR(
    {-class => 'searchbody'},
    th(
      "minimum RSCU value for codon replacement",
      td(
        textfield(
          -name       => $self->config_name('MINRSCUVAL'),
          -size       => 5,
          -maxlength  => 4,
          -default    => 0.06
        )
      )
    )
  );
           
  push @choices, TR(
    {-class => 'searchbody'},
    th('Tagging Scope'),
    td(
      radio_group(
        -name     => $self->config_name('SCOPE'),
        -values   => ['chrom', 'seg'],
        -default  =>'chrom',
        -labels   => {
          'chrom' => 'whole chromosome',
          'seg'   => 'the following genes entirely within view now'
        }
      )
    )
  );
           
  my $html = table(@choices);
  return $html;
}

=head2 dump

Call BS_PCRTagger and pass the parameters
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
    $pa->{CHROMOSOME}   = $gbrowse_settings->{source};
    $pa->{STARTPOS} = $segment->start if ($pa->{SCOPE} eq "seg");
    $pa->{STOPPOS}  = $segment->end if ($pa->{SCOPE} eq "seg");
    $pa->{OUTPUT} = "html";
   
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
          -http_equiv => 'refresh',
          -content    => "10; URL=\"$addy\""}));
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

1;

__END__