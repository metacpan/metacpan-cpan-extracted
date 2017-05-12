package Config::Simple::Extended;

use warnings;
use strict;
use base qw( Config::Simple );
use FindBin;
use Data::Dumper;

use lib "$FindBin::Bin/../../../local/lib/perl5";
use File::PathInfo;

our $VERSION = '0.16';

=head1 NAME

Config::Simple::Extended - Extend Config::Simple w/ Configuration Inheritance, chosen by URL

=head1 VERSION

Version 0.15

=cut

=head1 SYNOPSIS

my $url = $cgi->url();
my $cfg_file_path = parse_url_for_config_path($url);
my $cfg_base_path = '/etc/app_name/sites';
my $cfg_path = "$cfg_base_path/$cfg_file_path";

my $installation_cfg = Config::Simple->new( 
     file => '$cfg_path/app_name.ini' );

my $client_cfg = Config::Simple::Extended->inherit(
     base_config => $installation_cfg,
     filename => '$cfg_path/client_name/app_name.ini',
);

my $job_cfg = Config::Simple::Extended->inherit(
     base_config => $client_cfg,
     filename => '$cfg_path/client_name/app_job_id.ini',
);

my $arrayref_of_stanza_names = $cfg->get_stanzas();

  This is intended to provide, before this is complete
    ->inherit() to inherit configurations, done;
    ->parse_config_directory() choosing configuration by url;
    ->heredoc() to parse heredoc configurations (still pending);
    anything else?

=head1 EXAMPLES

For details on accessing configuration parameters, read perldoc
Config::Simple, which is well documented.  In short, even if
you wanted to bypass the published methods, everything seems
to be found at: $cfg->{'_DATA'}->{$stanza}->{$key}, which then
takes an anonymous list of whatever you feed it.  The notes
below focus on how to set up overloading configuration files
How to write a constructor which will use them, how to share
configuration hashes among modules in an application, etc.

These configuration hashes can be shared around with other
objects which need them, like this:

    my $object = My::New::Module->new({ 'cfg' => $self->{'cfg'} });

assuming that you are inside an object method whose constructor
stored the configuration hash at its own 'cfg' key, as I used  
to do, or in a ->cfg attribute as I tend to do these days now 
that Moose has come along.

or to needlessly duplicate the object in your memory overhead,
as I did it when I was first digging around in the innards of
Config::Simple, and learning how to use it:

    my $new_object = My::New::Module->new({ 
       'config_file' => $self->{'cfg'}->{'_FILE_NAME'} });

But don't do that.  It will make your dumpers needlessly confusing.  

Now I can write a constructor like this:

=over

    package My::New::Module;
    
    sub new {
      my $class = shift;
      my $defaults = shift;
      my $self = {};
    
      if(defined($defaults->{'config_file'})){
        $self->{'cfg'} = Config::Simple->new(
          $defaults->{'config_file'} );
      } elsif(defined($defaults->{'config_files'})){
        my $cfg;
        undef($cfg);
        foreach my $file (@{$defaults->{'config_files'}}){
          $cfg = Config::Simple::Extended->inherit({
                base_config => $cfg,
                   filename => $file });
        }
        $self->{'cfg'} = $cfg;
      } else {
        die "Constructor invoked with no Confirguration File."
      }
    
      my $db = $self->{'cfg'}->get_block('db');
      # print STDERR Dumper(\$db);
      $self->{'dbh'} = My::New::Module::DB->connect($db);
    
      bless $self, $class;
      return $self;
    }

=back

or, with Moose, perhaps adapt that as a ->_build_cfg() method 
to populate a ->cfg() attribute.  That is how I've used this 
module since I started using Moose.  

Making it possible to use it like so:

    my $new_object = My::New::Module->new({ 
           'config_files' => [ '/etc/my_app/base_configuration.ini',
                               '/etc/my_app/client/client_configuration.ini',
                               '/etc/my_app/client/job_id.ini' ]  });

with the job config over-writing the client config, over-writing
the base config.  If you let untrusted users write their
own job configuration files, you probably want to reverse
the order of the array, so that your base configuration file
ultimately overwrites the final object with your sanity checks
and security barriers in place.

=cut

=head1 METHODS 

=head2  $cfg_file_path = parse_url_for_config_path($url);

This converts a url into a configuration file path, in a manner
similar to the way that drupal lays out its configuration files,
permitting a single code installation to host multiple instances
of the same application.  Each url is aliased to the same code
installation, and this method sorts out which configuration
to provide it.

=cut

sub parse_url_for_config_path {
  my $self = shift;
  my($url)=@_;
  my $scriptpath = $0;
  my $scriptname = $0;
  my $default_domain = 'localhost.supporters';
  $scriptname =~ s/^(.*)\///;
  $scriptpath =~ s/$scriptname//;
  $url =~ s/https:\/\///;
  $url =~ s/http:\/\///;
  $url =~ s/\//./g;
  # print STDERR "The scriptname is: ",$scriptname,"\n";
  # print STDERR "The scriptpath is: ",$scriptpath,"\n";
  $url =~ s/$scriptname$//;
  $url =~ s/\.$//;
  # account for command line tests
  if($url eq 'localhost'){
    $url = $default_domain;
    $scriptpath =~ s/t\///;
  }
  $url = $scriptpath."conf.d/".$url;
  # print STDERR "The \$url is $url.\n";
  # $self->{'conf_path'} = $url;
  # print STDERR "The conf_path is $self->{'conf_path'}.\n";
  # print STDERR Dumper(\$self);
  return $url;
} # END parse_url_for_config_path

=head2 ->Config::Simple::Extended->inherit();

This is copied verbatim from ->Config::Simple::Inherit->inherit();
And this module's version number is taken from that module, as well.

=head2 ->inherit() 

This module only offers this one method, but I trust you'll
find it useful.  It returns a Config::Simple object, when given
a reference to a hash, of which it only recognizes two keys:
'base_config' and 'filename'.  The 'base_config' ought to be
left undefined or set to a 'Config::Simple' object created
with either this method or the ->new() method provided by
Config::Simple.  When 'base_config' is given a Config::Simple
object, it walks every configuration parameter defined in the
filename, and uses the new value to update the value for the
respective parameterin the 'base_config' object, inheriting
values from it, but overloading the configuration with the
new values.

I envision essentially two ways this module might be used:

(1) to provide a means for getting more specific with
a configuration by first creating an installation-wide
configuration, then a client specific configuration, then
job specific configuration, each overloading the more general
values provided by the configuration before it.

(2) to enforce client, and installation security controls and
sanity checks on a configuration prepared by an untrusted user.
Say you had an application which permitted a local user to
create a configuration file for a job.  By loading the user
created configuration first, then using the installation
default configuration to overwrite it, it would be possible
to prevent abuse and enforce system wide constraints.

=cut

sub inherit {
  my $class = shift;
  my $args = shift;
  my $f = new File::PathInfo;

  # print STDERR Dumper(\$args);
  { no strict 'refs';
    unless(defined($args->{'base_config'}) &&
        UNIVERSAL::isa($args->{'base_config'},'Config::Simple')) {
      print "the base_config undef, return Config::Simple object \n" 
          if( $args->{'debug'} );
      return Config::Simple->new( filename => $args->{'filename'} );
    }
  }
  my @cfg_filenames;
  my $cfg = $args->{'base_config'};
  print "The base_config exists and includes this data: "
      . Dumper( $cfg->{'_DATA'} ) if( $args->{'debug'} && 0 );
  if(defined($cfg->{'_FILE_NAMES'})){
    push @cfg_filenames, @{$cfg->{'_FILE_NAMES'}};
    push @cfg_filenames, $args->{'filename'};
  } elsif(defined($cfg->{'_FILE_NAME'})) { 
    push @cfg_filenames, $cfg->{'_FILE_NAME'};
    push @cfg_filenames, $args->{'filename'};
  } else {
    die "We have a Config::Simple object, without an initial '_FILE_NAME' value.\n";
  }
  $cfg->{'_FILE_NAMES'} = \@cfg_filenames;
  $f->set( $args->{'filename'} ) or die('file does not exist');
  my $cfg_file = $f->abs_path;
  my $cfg_overload = Config::Simple::Extended->new( $cfg_file );
  print 'Our $cfg_overload applies this file: ' 
      . $args->{'filename'} 
      . ' and looks like this: ' 
      . Dumper( $cfg_overload )
          if( $args->{'debug'} );

  my $stanzas = $cfg_overload->get_stanzas();
  foreach my $stanza ( @{$stanzas} ){
    my %stanza = %{$cfg_overload->get_block( $stanza )};
    foreach my $param_key (keys %stanza){
      print "\t$stanza.$param_key being overloaded with " 
          . $cfg_overload->param("$stanza.$param_key") 
          . "\n" if( $args->{'debug'} );
      $cfg->param( "$stanza.$param_key", $cfg_overload->param("$stanza.$param_key") );
    }
  }

  return $cfg; 
}

=head2 my $array_ref = $cfg->get_stanzas();

If you use a hierarchical configuration file structure, with values 
assigned to keys inside of stanzas, you can use this method to 
pull a reference to a list of the stanzas currently defined 
in your configuration file.  In an ini files this would be 
denoted as [stanza_name], as if it were a one element arrayref.  

=cut

sub get_stanzas {
  my $self = shift;
  my @stanzas;
  my %stanza_keys;
  my %config = $self->vars();
  foreach ( keys %config ){
    $_ =~ s/\..*//;
    $stanza_keys{$_} = 1;
  }
  @stanzas = keys %stanza_keys;
  return \@stanzas;
}

=head1 AUTHOR

Hugh Esco, C<< <hesco at campaignfoundations.com> >>

=head1 BUGS

On January 2nd, 2012 I resolved a long standing documentation bug which
I believe (but have in no way confirmed) was introduced by an interface 
change to Config::Simple.  

On January 11th, 2013, I hardened this module by using the 
interface, rather than the internals of Config::Simple.  

It seems that ->inherit will not overwrite a configuration 
value for a key which does not already exist in the inherited 
from ->cfg object.  That is something which should be easy to 
rectify but which seems barely outside the scope of this evening's 
work when I'm supposed to be working on something else which 
depends on these changes.  I had not noticed this prior to these 
revisions and this may represent regression.  Hope this does not 
break production installations for others.  I will try to watch 
the smoke tests and RT and respond if I see these recent enhancements 
make problems for folks.  

Please report any bugs or feature requests to
C<bug-config-simple-inherit at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Simple-Extended>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Simple::Extended

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-Simple-Extended>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-Simple-Extended>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Simple-Extended>

I also watch for bug reports at:

L<http://www.campaignfoundations.com/project/Config-Simple-Extended>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-Simple-Extended>

=back

=head1 ACKNOWLEDGEMENTS

Sherzod B. Ruzmetov, author of Config::Simple, which I've come
to rely on as the primary tool I use to manage configuration
for the applications I write.

=head1 COPYRIGHT & LICENSE

Copyright 2008-2016 Hugh Esco, all rights reserved.

This program is released under the following license: Gnu
Public License.

=head1 SEE ALSO

Config::Simple which handles ini, html and simple formats.
Config::Simple::Extended returns a Config::Simple object, and
the accessors (and other methods) for its configuration are
documented by Mr. Ruzmetov in the perldoc for his module.

If you need some combination of json, yaml, xml, perl, ini or
Config::General formats, take a look at: Config::Merge, which I
learned of after releasing version 0.03 of this module to cpan.

=cut

1; # End of Config::Simple::Extended

