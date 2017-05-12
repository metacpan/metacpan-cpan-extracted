#
# BioStudio Cartoonist GBrowse interface
#

=head1 NAME

Bio::Graphics::Browser2::Plugin::BS_Cartoonist

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>

=cut

package Bio::Graphics::Browser2::Plugin::BS_Cartoonist;

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
my $plugin_name = 'BS_Cartoonist';
my $bsversion = $plugin_name . q{_} . $VERSION;
local $OUTPUT_AUTOFLUSH = 1;

=head2 name

Plugin name

=cut

sub name
{
  return 'BioStudio: Create Chromosome Diagram';
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

=head2 mime_type

Plugin return type

=cut

sub mime_type
{
  return 'text/html'
}

=head2 description

Plugin description

=cut

sub description
{
  return p('Create an editable vector illustration of a chromosome');
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

=head2 config_defaults

Set default configuration

=cut

sub config_defaults
{
  my $self = shift;
  return;
}

=head2 configure_form

Render form, gather configuration from user

=cut

sub configure_form
{
  my $self = shift;
 
  return "This plugin will not run; BioStudio is not configured for Cairo<br>\n"
    unless($BS->{cairo_support});
  my $curr_config       = $self->configuration;
  my $gbrowse_settings  = $self->page_settings;
  my $sourcename        = $gbrowse_settings->{source};
  my $chromosome        = $BS->set_chromosome(-chromosome => $sourcename);
  my @features          = $chromosome->db->features;
  my @chrs              = grep {$_->primary_tag eq "chromosome"} @features;
  my $chr               = $chrs[0];
 
  my @choices;
  
  push @choices, TR(
    {-class => 'searchtitle'},
    th('Scaling factor'),
    td(
      textfield(
        -name       => $self->config_name('FACTOR'),
        -default    => 10,
        -size       => 5,
        -maxlength  => 4
      )
    )
  );
           
  push @choices, TR(
    {-class => 'searchtitle'},
    th('Start at base'),
    td(
      textfield(
        -name       => $self->config_name('START'),
        -default    => 1,
        -size       => 8,
        -maxlength  => 7
      )
    )
  );

  push @choices, TR(
    {-class => 'searchtitle'},
    th('Stop at base'),
    td(
      textfield(
        -name       => $self->config_name('STOP'),
        -default    => $chr->end,
        -size       => 8,
        -maxlength  => 7
      )
    )
  );
                   
  push @choices, TR(
    {-class => 'searchtitle'},
    th('Amount of data per level, in bases'),
    td(
      textfield(
        -name       => $self->config_name('LEVELWIDTH'),
        -default    => 50000,
        -size       => 8,
        -maxlength  => 7
      )
    )
  );

  push @choices, TR(
    {-class => 'searchtitle'},
    th('Data repeated on each line at left, in bases'),
    td(
      textfield(
        -name       => $self->config_name('REPEATLEFT'),
        -default    => 1000,
        -size       => 5,
        -maxlength  => 4
      )
    )
  );
         
  push @choices, TR(
    {-class => 'searchtitle'},
    th('Data repeated on each line at right, in bases'),
    td(
      textfield(
        -name       => $self->config_name('REPEATRIGHT'),
        -default    => 1000,
        -size       => 5,
        -maxlength  => 4
      )
    )
  );
                           
  my $html = table(@choices);
  return $html;
}

=head2 dump

Call BS_Cartoonist and pass the parameters
Then monitor the scripts progress; print periodic output.

=cut

sub dump
{
  my ($self, $segment) = @_;

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
                   -head=>meta({-http_equiv =>'refresh', -content => '60'}));
    print p(i('This page will refresh in 1 minute')) unless $data->[0];
    print pre($data->[1]);
    print p(i('...continuing...')) unless $data->[0];
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
    $pa->{$_} = "\"$pa->{$_}\"" foreach (grep {$pa->{$_} =~ /\ /} keys %{$pa});
    $command .= "--" . $_ . q{ } . $pa->{$_} . q{ } foreach (keys %{$pa});

   #If we're the parent, prepare the url and offer a link.
    if (my $pid = fork)
    {
      delete_all();
      my $addy = self_url() . "?plugin=$plugin_name;plugin_action=Go;";
      $addy .= "session=$sid";
      print start_html(
        -title  => 'Launching BioStudio...',
        -head   => meta({
          -http_equiv => 'refresh',
          -content    => "10; URL=\"$addy\""}));
      print p(i('BioStudio is running.'));
      print p("Your job number is $sid.");
      print 'If you are not redirected in ten seconds, ';
      print "<a href=\"$addy\">click here for your results</a><br>";
      print p('Command:');
      print pre("$command");
      print end_html;
      return;
    }
   #If we're a child, launch the script, feed results to the cache
    elsif(defined $pid)
    {
      close STDOUT;
      unless (open F, q{-|})
      {
        my $path = $BS->{script_path} . $plugin_name . '.pl';
        open STDERR, '>', "&=1";
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