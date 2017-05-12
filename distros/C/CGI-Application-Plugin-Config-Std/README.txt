NAME
    CGI::Application::Plugin::Config::Std - Add Config::Std support to
    CGI::Application

SYNOPSIS
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

DESCRIPTION
    This module acts as a plugin for Config::Std to be used within a
    CGI::Application module.

    Three methods are exported into your CGI::Application module and they
    are described below.

    This module borrows the lazy loading idea from Cees Hek's
    CGI::Application::Plugin::Session module. Much of the code and tests are
    borrowed from CGI::Application::Plugin:::Config::Simple by Michael
    Peters. The three-signature behaviour of config() is also borrowed from
    Michael's implementation.

    This module is hosted on github:
    <https://github.com/stephenca/CGI-Application-Plugin-Config-Std>.

METHODS
  config_param()
    This method acts as an accessor/mutator for configuration variables
    coming from the configuration file.

    This method will behave in three different ways depending on how many
    parameters it is passed:

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

    Failing to set the name of the configuration file either using the
    config_file() method or the CGIAPP_CONFIG_FILE environment variable
    before calling this method it will generate a fatal exception.

  commit_config
    This method writes the current contents of the configuration object back
    to the config file (possibly a different one to that from which the
    config was read).

    Returns the current configuration object on success. A fatal exception
    is raised if the write fails.

    This method is potentially dangerous, so is not exported by default.

  config()
    This method will return the underlying Config::Std object for more
    direct use by your application.

    Failing to set the name of the configuration file either using the
    config_file() method or the CGIAPP_CONFIG_FILE environment variable
    before calling this method or it raise a fatal exception.

            my $conf = $self->config();

  config_file([$file_name])
    Get/set the name of the current config file or change/initialize it.

    This method must be called to initialize the name of the config file
    before any call can be made to either config() or config_param() unless
    the 'CGIAPP_CONFIG_FILE' environment variable has been set.

    If this environment variable is set it will be used as the initial value
    of the config file. This is useful if we are running in a mod_perl
    environment when can use a statement like this in your httpd.conf file:

            PerlSetEnv  CGIAPP_CONFIG_FILE  /path/to/my/conf

    It is typical to set the name of the config file in the cgiapp_init()
    phase of your application.

    If a value is passed as a parameter then the config file with that name
    is used. It will always return the name of the current config file.

            #get the value of the CGIAPP_CONFIG_FILE environment variable (if there is one)
            #since we haven't set the config file's name with config_file() yet.
            my $file_name = $self->config_file();
                                                                                                                                             
            #set the config file's name
            $self->config_file('myapp.conf');
                                                                                                                                             
            #get the name of the config file
            $file_name = $self->config_file();

CAVEATS
    The CGI::Application object is implemented as a hash and we store the
    variables used by this module's methods inside of it as a hash named
    __CONFIG_STD. If you use any other CGI::Application plugins there would
    be problems if they also used $self->{__CONFIG_STD} but in practice this
    should never actually happen.

ACKNOWLEDGEMENTS
    The implementation, tests and documentation are heavily based on Michael
    Peters' CGI::Application::Plugin::Config::Simple.

SEE ALSO
    *       CGI::Application

    *       CGI::Application::Plugin::Config::Simple

    *       Config::Std

BUGS
    Please use github for bug reports:
    <https://github.com/stephenca/CGI-Application-Plugin-Config-Std/issues>

