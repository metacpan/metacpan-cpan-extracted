package Config::Simple::Inherit;
# package Simple::Inherit;

use warnings;
use strict;
use base qw( Config::Simple );
use UNIVERSAL qw( isa can );
# use UNIVERSAL qw( isa can VERSION );
use Data::Dumper;

our $VERSION = '0.04';

sub inherit {
  my $class = shift;
  my $args = shift;
  # print STDERR Dumper(\$args);
  { no strict 'refs';
    unless(defined($args->{'base_config'}) &&
        UNIVERSAL::isa($args->{'base_config'},'Config::Simple')) {
      # print STDERR "Now we create the first Config::Simple object using $args->{'filename'}; none already exists.\n";
      # return "->inherit() has returned with debugging message.";
      return Config::Simple->new( filename => $args->{'filename'} );
    }
  }
  my @cfg_filenames;
  my $cfg = $args->{'base_config'};
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
  my $cfg_overload = Config::Simple->new( filename => $args->{'filename'} );

  foreach my $stanza_key (keys %{$cfg_overload->{'_DATA'}}){
    foreach my $param_key (keys %{$cfg_overload->{'_DATA'}->{$stanza_key}}){
      $cfg->{'_DATA'}->{$stanza_key}->{$param_key} = $cfg_overload->{'_DATA'}->{$stanza_key}->{$param_key};
    }
  }

  return $cfg; 
}

=head1 NAME

Config::Simple::Inherit - Inherit values from, overwrite a base configuration

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

my $installation_cfg = Config::Simple->new( 
     file => '/etc/app_name/app_name.ini' );

my $client_cfg = Config::Simple::Inherit->inherit(
     base_config => $installation_cfg,
     filename => '/etc/app_name/client_name/app_name.ini',
);

my $job_cfg = Config::Simple::Inherit->inherit(
     base_config => $client_cfg,
     filename => '/etc/app_name/client_name/app_job_id.ini',
);

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
stored the configuration hash at its own 'cfg' key, as I tend
to do.

or to needlessly duplicate the object in your memory overhead,
as I did it when I was first digging around in the innards of
Config::Simple, and learning how to use it:

    my $new_object = My::New::Module->new({ 
       'config_file' => $self->{'cfg'}->{'_FILE_NAME'} });

Now I can write a constructor like this:

=over

    package My::New::Module;
    
    sub new {
      my $class = shift;
      my $defaults = shift;
      my $self = {};
    
      if(defined($defaults->{'config_file'})){
        $self->{'cfg'} = Config::Simple::Inherit->new(
          { filename => $defaults->{'config_file'} } );
      } elsif(defined($defaults->{'config_files'})){
        my $cfg;
        undef($cfg);
        foreach my $file (@{$defaults->{'config_files'}}){
          $cfg = Config::Simple::Inherit->inherit({
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

=head1 AUTHOR

Hugh Esco, C<< <hesco at campaignfoundations.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-config-simple-inherit at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Simple-Inherit>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I also do business as CampaignFoundations.com,
where we host an issues que, available at:
L<http://www.campaignfoundations.com/project/Config-Simple-Inherit>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Simple::Inherit

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-Simple-Inherit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-Simple-Inherit>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Simple-Inherit>

I also watch for bug reports at:

L<http://www.campaignfoundations.com/project/Config-Simple-Inherit>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-Simple-Inherit>

=back

=head1 ACKNOWLEDGEMENTS

Sherzod B. Ruzmetov, author of Config::Simple, which I've come
to rely on as the primary tool I use to manage configuration
for the applications I write.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Hugh Esco, all rights reserved.

This program is released under the following license: Gnu
Public License.

=head1 SEE ALSO

Config::Simple which handles ini, html and simple formats.
Config::Simple::Inherit returns a Config::Simple object, and
the accessors (and other methods) for its configuration are
documented by Mr. Ruzmetov in the perldoc for his module.

If you need some combination of json, yaml, xml, perl, ini or
Config::General formats, take a look at: Config::Merge, which I
learned of after releasing version 0.03 of this module to cpan.

=cut

1; # End of Config::Simple::Inherit
