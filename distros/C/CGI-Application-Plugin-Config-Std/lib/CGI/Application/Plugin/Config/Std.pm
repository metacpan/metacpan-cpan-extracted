package CGI::Application::Plugin::Config::Std;
use common::sense   3.4;

use CGI::Application;
use Config::Std;

use Hash::Merge     0.12  qw(merge);

use Sub::Exporter   0.982
  -setup => { exports => [qw(config_file config_param config)] };

Hash::Merge::set_behavior('RIGHT_PRECEDENT');

# Version set by dist.ini.  Do not change here.
our $VERSION = '1.003'; # VERSION


# Recursively search the config hash for 'foo.bar' style params.
sub _find_keys {
  my ($c,@keys) = @_;

  my $k = shift(@keys);
  
  if(exists($c->{$k})) {
    if(@keys) {
      _find_keys( $c->{$k}, @keys);
    }
    else {
      return $c->{$k};
    }
  }
  else {
    return;
  }
}

sub config_param {
    my $self = shift;
    my @params = @_;

    my $conf = $self->config();
    #if there aren't any params then we want the entire config structure as a hash ref
    if(scalar(@params) == 0) {
        return $conf;
    }
    elsif(scalar(@params) == 1) { 
    #if there is just one then we want just that value
       my @keys = split(/\./,$params[0]);
       return _find_keys($conf,@keys);
    }
    #else we might be setting some values
    else {
      my %params = (@params);
      my %addconf;
      for my $k (keys %params) {
        my(@keys) = split(/\./,$k);
        my $last = pop(@keys);
        if(@keys) {
          $addconf{$keys[0]} = {$last => $params{$k} } ;
        }
        else {
          $addconf{$last} = $params{$k};
        }
      }
      my $c = merge( $conf, \%addconf );
      $self->{__CONFIG_STD}->{__CONFIG_OBJ} = $c; #Ugh
    }
}


sub commit_config {
  my $self = shift;

  my $conf = $self->config;
  write_config( $conf, $self->config_file );
  return $conf;
}

                                                                                                                                             
sub config {
  my $self = shift;
  #if we don't already have a config object or if the file name has changed on us then create it
  my $create = !$self->{__CONFIG_STD}->{__CONFIG_OBJ} 
             || $self->{__CONFIG_STD}->{__FILE_CHANGED};
  if($create) {
        #get the file name from config_file()
        my $file_name = $self->config_file or die "No config file specified!";
        read_config( $file_name, my %conf );
        $self->{__CONFIG_STD}->{__CONFIG_OBJ}   = \%conf;
        $self->{__CONFIG_STD}->{__FILE_CHANGED} = 0;
  }
  return $self->{__CONFIG_STD}->{__CONFIG_OBJ};
}
 
                                                                                                                                             
sub config_file {
    my ($self, $file_name) = @_;
    #if we have a file name to set
    if(defined $file_name) {
        $self->{__CONFIG_STD}->{__FILE_NAME}    = $file_name;
        $self->{__CONFIG_STD}->{__FILE_CHANGED} = 1;
    } else { 
        #else we are getting the filename
        $file_name = $self->{__CONFIG_STD}->{__FILE_NAME} 
    }
    #if we don't have the file_name then get it from %ENV, but untaint it
    if(!$file_name) { 
        $ENV{CGIAPP_CONFIG_FILE} =~ /(.*)/;
        $file_name = $1;
    }
    return $file_name;
}

1;

# ABSTRACT: Add Config::Std support to CGI::Application



=pod

=head1 NAME

CGI::Application::Plugin::Config::Std - Add Config::Std support to CGI::Application

=head1 VERSION

version 1.003

=head1 SYNOPSIS

in your CGI::Application-based module

	use CGI::Application::Plugin::Config::Std;

    sub cgiapp_init {
	  my $self = shift;
	  #set my config file
	  $self->config_file('myapp.conf');

	  #
	  #do other stuff
	  #
	}

	#later on in a run mode
	sub run_mode1 {
	  my $self = shift;

	  #just get a single parameter from my config file
 	  my $value = $self->config_param('my_param');

	  #get a parameter in a block (if using ini style files)
	  $value = $self->config_param('my_block.my_param');

	  #the entire config hash reference
	  my $config_vars = $self->config_param();

	  #get my Config::Simple object for direct access
	  my $config = $self->config;
	}

=head1 DESCRIPTION

This module acts as a plugin for L<Config::Std> to be used within a
L<CGI::Application> module.

Three methods are exported into your L<CGI::Application> module and they
are described below.

This module borrows the lazy loading idea from Cees Hek's
L<CGI::Application::Plugin::Session> module.  Much of the code and tests are
borrowed from L<CGI::Application::Plugin:::Config::Simple> by Michael Peters.
The three-signature behaviour of config() is also borrowed from Michael's
implementation.

This module is hosted on github:
L<https://github.com/stephenca/CGI-Application-Plugin-Config-Std>.

=head1 NAME 

CGI::Application::Plugin::Config::Std - Add Config::Std support to CGI::Application

=head1 METHODS

=head2 config_param()

This method acts as an accessor/mutator for configuration variables coming from the
configuration file.

This method will behave in three different ways depending on how many parameters it
is passed:

 - zero parameters: Config::Std::Hash object returned.
 - one parameters: assumed to be config lookup.  Will return value associated
with parameter, or undef if none exists.  Note that 'dot' notation parameters
are supported, e.g. $self->config_param('foo.bar') will be translated to
something like $conf->{foo}{bar}.
 - more than 1 parameter: treated as name/value pairs. Returns true if successful.  The same 'dot notation'
is supported as per a single paremeter.  Existing config params will be
over-written by this form of the method call.
                                                                                                                              
        #get the complete config  object.  This is the same as calling
        #$self->config().
        my $config_hash = $self->config_param();
        #just get one config value
        my $value = $self->config_param($parameter);
        #set multiple config values
        my $success = $self->config_param(param1 => $value1, param2 => $value2);

Failing to set the name of the configuration file either using the L<config_file()> method
or the CGIAPP_CONFIG_FILE environment variable before calling this method it
will generate a fatal exception.

=head2 commit_config 

This method writes the current contents of the configuration object back to
the config file (possibly a different one to that from which the config was
read).

Returns the current configuration object on success.  A fatal exception is
raised if the write fails.

This method is potentially dangerous, so is not exported by default.

=head2 config()

This method will return the underlying Config::Std object for more direct use by your
application.

Failing to set the name of the configuration file either using the L<config_file()> method
or the CGIAPP_CONFIG_FILE environment variable before calling this method or
it raise a fatal exception.

        my $conf = $self->config();

=head2 config_file([$file_name])

Get/set the name of the current config file or change/initialize it.

This method must be called to initialize the name of the config file before
any call can be made to either L<config()> or L<config_param()> unless the
'CGIAPP_CONFIG_FILE' environment variable has been set.

If this environment variable is set it will be used as the initial value of
the config file. This is useful if we are running in a mod_perl environment
when can use a statement like this in your httpd.conf file:

	PerlSetEnv  CGIAPP_CONFIG_FILE  /path/to/my/conf

It is typical to set the name of the config file in the cgiapp_init() phase of your application.

If a value is passed as a parameter then the config file with that name is used. It will always
return the name of the current config file.

        #get the value of the CGIAPP_CONFIG_FILE environment variable (if there is one)
        #since we haven't set the config file's name with config_file() yet.
        my $file_name = $self->config_file();
                                                                                                                                             
        #set the config file's name
        $self->config_file('myapp.conf');
                                                                                                                                             
        #get the name of the config file
        $file_name = $self->config_file();

=head1 CAVEATS

The CGI::Application object is implemented as a hash and we store the variables used by this
module's methods inside of it as a hash named __CONFIG_STD. If you use any other CGI::Application
plugins there would be problems if they also used $self->{__CONFIG_STD} but in practice this should
never actually happen.

=head1 ACKNOWLEDGEMENTS

The implementation, tests and documentation are heavily based on Michael
Peters' L<CGI::Application::Plugin::Config::Simple>.

=head1 SEE ALSO

=over 8

=item * L<CGI::Application>

=item * L<CGI::Application::Plugin::Config::Simple>

=item * L<Config::Std>

=back

=head1 BUGS

Please use github for bug reports:
L<https://github.com/stephenca/CGI-Application-Plugin-Config-Std/issues>

=head1 AUTHOR

Stephen Cardie <stephenca@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Stephen Cardie.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


