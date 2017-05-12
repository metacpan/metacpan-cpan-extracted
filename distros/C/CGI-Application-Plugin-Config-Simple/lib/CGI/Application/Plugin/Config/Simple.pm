package CGI::Application::Plugin::Config::Simple;
use strict;
use warnings;
use base 'Exporter';
use CGI::Application;
use Config::Simple;

$CGI::Application::Plugin::Config::Simple::VERSION = '1.01';
use vars '@EXPORT';
@EXPORT = qw(config_file config_param config);

=pod

=head1 NAME 

CGI::Application::Plugin::Config::Simple - Add Config::Simple support to CGI::Application

=head1 SYNOPSIS

in your CGI::Application based module

	use CGI::Application::Plugin::Config::Simple;

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

This module acts as a plugin for L<Config::Simple> to be easily used inside of a 
L<CGI::Application> module. It does not provide every method available from L<Config::Simple>
but rather easy access to your configuration variables. It does however provide direct 
access to the underlying L<Config::General> object created if you want to use it's full
power.

The module tries to make the getting and setting of configuration variables as easy as
possible. Only three methods are exported into your L<CGI::Application> module and they
are described below.

Before I wrote this module sometimes I would put my code that read in the configuration file
into the cgiapp_init() or cgiapp_prerun() methods but then if I had a run mode that didn't need
those config variables it was run anyway. This module helps to solve this is. The L<Config::Simple>
object is not created (and the config file is not read and parsed) until after your first call
to L<config()> or L<config_param()> to either retrieve/set values, or get the L<Config::Simple>
object. This lazy loading idea came from Cees Hek's L<CGI::Application::Plugin::Session> module.

=head1 METHODS

=head2 config_param()
                                                                                                                                             
This method acts as an accessor/mutator for configuration variables coming from the
configuration file.
                                                                                                                                             
This method will behave in three different ways depending on how many parameters it
is passed. If 0 parameters are passed then the entire config structure will be returned
as a hash ref. If 1 parameters is passed then the value of that parameter in the config
file will be returned. If more than 1 parameter is passed then it will treat them as name
value pairs and will set the parameters in the config file accordingly. In this case, if
we successfully set the parameters then a true value will be returned.
                                                                                                                                             
        #get the complete config hash
        my $config_hash = $self->config_param();
        #just get one config value
        my $value = $self->config_param($parameter);
        #set multiple config values
        my $success = $self->config_param(param1 => $value1, param2 => $value2);
                                                                                                                                             
This method uses Config::Simple so if you are using ini-files then you can set
the values of variables inside blocks as well using the '.' notation. See L<Config::Simple>;

You must set the name of the configuration file either using the L<config_file()> method
or the CGIAPP_CONFIG_FILE environment variable before calling this method or it will 'die'.

=cut
                                                                                                                                             
sub config_param {
    my $self = shift;
    my @params = @_;
    my $conf = $self->config();
                                                                                                                                             
    #if there aren't any params then we want the entire config structure as a hash ref
    if(scalar(@params) == 0) { 
        return scalar($conf->vars) 
    } elsif(scalar(@params) == 1) { 
    #if there is just one then we want just that value
        return $conf->param($params[0]) 
    }
    #else we might be setting some values
    else {
        my %params = (@params);
        $conf->param($_ => $params{$_}) foreach (keys %params);
        if($conf->write) { 
            return 1 
        } else { 
            die "Config-Plugin: Could not write to config file (" . $self->config_file . ")! " . $conf->error() 
        }
    }
}


=pod
                                                                                                                                             
=head2 config()
                                                                                                                                             
This method will return the underlying Config::Simple object for more direct use by your
application. You must set the name of the configuration file either using the L<config_file()> method
or the CGIAPP_CONFIG_FILE environment variable before calling this method or it will 'die'.
                                                                                                                                             
        my $conf = $self->config();
                                                                                                                                             
=cut
                                                                                                                                             
sub config {
    my $self = shift;
    #if we don't already have a config object or if the file name has changed on us then create it
    my $create = !$self->{__CONFIG_SIMPLE}->{__CONFIG_OBJ} 
        || $self->{__CONFIG_SIMPLE}->{__FILE_CHANGED};
    if($create) {
        #get the file name from config_file()
        my $file_name = $self->config_file or die "No config file specified!";
        my $conf = Config::Simple->new($file_name) or die "Could not create Config::Simple object for file $file_name! $!";
        $self->{__CONFIG_SIMPLE}->{__CONFIG_OBJ} = $conf;
        $self->{__CONFIG_SIMPLE}->{__FILE_CHANGED} = 0;
    }
    return $self->{__CONFIG_SIMPLE}->{__CONFIG_OBJ};
}
 
=pod
                                                                                                                                             
=head2 config_file([$file_name])
                                                                                                                                             
This method acts as an accessor/mutator to either get the name of the current config file
or to change/initialize it. This method must be called to initialize the name of the config
file before any call can be made to either L<config()> or L<config_param()> unless the
'CGIAPP_CONFIG_FILE' environment variable has been set. If this environment variable is set
it will be used as the initial value of the config file. This is useful if we are running in
a mod_perl environment when can use a statement like this in your httpd.conf file:
       
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
                                                                                                                                             
=cut
                                                                                                                                             
sub config_file {
    my ($self, $file_name) = @_;
    #if we have a file name to set
    if(defined $file_name) {
        $self->{__CONFIG_SIMPLE}->{__FILE_NAME} = $file_name;
        $self->{__CONFIG_SIMPLE}->{__FILE_CHANGED} = 1;
    } else { 
        #else we are getting the filename
        $file_name = $self->{__CONFIG_SIMPLE}->{__FILE_NAME} 
    }
    #if we don't have the file_name then get it from %ENV, but untaint it
    if(!$file_name) { 
        $ENV{CGIAPP_CONFIG_FILE} =~ /(.*)/;
        $file_name = $1;
    }
    return $file_name;
}

1;

__END__

=pod

=head1 CAVEATS

The CGI::Application object is implemented as a hash and we store the variables used by this
module's methods inside of it as a hash named __CONFIG_SIMPLE. If you use any other CGI::Application
plugins there would be problems if they also used $self->{__CONFIG_SIMPLE} but in practice this should
never actually happen.

=head1 AUTHOR 

Michael Peters <mpeters@plusthree.com>

Thanks to Plus Three, LP (http://www.plusthree.com) for sponsoring my work on this module

=head1 SEE ALSO

=over 8

=item * L<CGI::Application>

=item * L<Config::Simple>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

