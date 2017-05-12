package CGI::Application::Plugin::ConfigAuto;
use base 'Exporter';
use Carp;
use strict;

our @EXPORT_OK = qw(
    cfg_file
    cfg
);

# For compliance with CGI::App::Standard::Config
# we break the rule and export config and std_config by default. 
sub import {
  my $app = caller;
  no strict 'refs';
  my $full_name = $app . '::config';
  *$full_name = \&cfg;

  my $std_config_name = $app.'::std_config'; 
  *$std_config_name = \&std_config;
  CGI::Application::Plugin::ConfigAuto->export_to_level(1,@_);
}


our $VERSION = '1.33';

# required by C::A::Standard::Config;
sub std_config { return 1; }

=pod 

=head1 NAME

CGI::Application::Plugin::ConfigAuto - Easy config file management for CGI::Application

=head1 SYNOPSIS

 use CGI::Application::Plugin::ConfigAuto (qw/cfg/);

In your instance script:

 my $app = WebApp->new(PARAMS => { cfg_file => 'config.pl' });
 $app->run();

In your application module:

 sub my_run_mode {
    my $self = shift;

    # Access a config hash key directly 
    $self->cfg('field');
       
    # Return config as hash
    %CFG = $self->cfg; 

 } 


=head1 DESCRIPTION

CGI::Application::Plugin::ConfigAuto adds easy access to config file variables
to your L<CGI::Application|CGI::Application> modules.  Lazy loading is used to
prevent the config file from being parsed if no configuration variables are
accessed during the request.  In other words, the config file is not parsed
until it is actually needed. The L<Config::Auto|Config::Auto> package provides
the framework for this plugin.

=head1 RATIONALE

C<CGI::Application> promotes re-usable applications by moving a maximal amount
of code into modules. For an application to be fully re-usable without code changes,
it is also necessary to store configuration variables in a separate file.

This plugin supports multiple config files for a single application, allowing
config files to override each other in a particular order. This covers even
complex cases, where you have a global config file, and second local config
file which overrides a few variables.

It is recommended that you to declare your config file locations in the
instance scripts, where it will have minimum impact on your application. This
technique is ideal when you intend to reuse your module to support multiple
configuration files. If you have an application with multiple instance scripts
which share a single config file, you may prefer to call the plugin from the
setup() method.

=head1 DECLARING CONFIG FILE LOCATIONS

 # In your instance script
 # value can also be an arrayref of config files
 my $app = WebApp->new(PARAMS => { cfg_file => 'config.pl' })

 # OR ... 

 # Pass in an array of config files, and they will be processed in order.  
 $app->cfg_file('../../config/config.pl');

Your config files should be referenced using the syntax example above. Note
that the key C<config_files> can be used as alternative to cfg_file.




The format is detected automatically using L<Config::Auto|Config::Auto>. It it
known to support the following formats: colon separated, space separated,
equals separated, XML, Perl code, and Windows INI. See that modules
documentation for complete details. 

=head1 METHODS

=head2 cfg()

 # Access a config hash key directly 
 $self->cfg('field');
    
 # Return config as hash
 my %CFG = $self->cfg; 

 # return as hashref
 my $cfg_href = $self->cfg;
    
A method to access project configuration variables. The config
file is parsed on the first call with a perl hash representation stored in memory.    
Subsequent calls will use this version, rather than re-reading the file.

In list context, it returns the configuration data as a hash.
In scalar context, it returns the configuration data as a hashref.

=head2 config()

L<CGI::Application::Standard::Config/config()> is provided as an alias to cfg() for compliance with
L<CGI::Application::Standard::Config>. It always exported by default per the
standard.

=head2 std_config()

L<CGI::Application::Standard::Config/std_config()> is implemented to comply with L<CGI::Application::Standard::Config>. It's
for developers. Users can ignore it. 

=cut

sub cfg {
    my $self = shift;

    if (!$self->{__CFG}) {
        require Config::Auto;

         unless ($self->{__CFG_FILES}) {
             my @all_cfg_files;
             for my $key (qw/cfg_file config_files/) {
                 my $cfg_file = $self->param($key);
                 if (defined $cfg_file) {
                     push @all_cfg_files, @$cfg_file  if (ref $cfg_file eq 'ARRAY');
                     push @all_cfg_files,  $cfg_file  if (ref \$cfg_file eq 'SCALAR');
                 }
             }
 
             # Non-standard call syntax for mix-in happiness.
             cfg_file($self,@all_cfg_files);
         }

        # Read in config files in the order the appear in this array.
        my %combined_cfg;
        for (my $i = 0; $i < scalar @{ $self->{__CFG_FILES} }; $i++) {
            my $file = $self->{__CFG_FILES}[$i];
            my %parms;
            if (ref $self->{__CFG_FILES}[$i+1] eq 'HASH') {
                %parms = %{ $self->{__CFG_FILES}[$i+1] };
                # skip trying to process the hashref as a file name
                $i++;
            }
            my $cfg = Config::Auto::parse($file, %parms);
            %combined_cfg = (%combined_cfg, %$cfg);
        }
        die "No configuration found. Check your config file(s) (check the syntax if this is a perl format)." 
            unless keys %combined_cfg;

        $self->{__CFG} = \%combined_cfg;
    }

    my $cfg = $self->{__CFG};
    my $field = shift;
    return $cfg->{$field} if $field;
    if (ref $cfg) {
        return wantarray ? %$cfg : $cfg;
    }
}

=head2 cfg_file()

 # Usual
 $self->cfg_file('my_config_file.pl');
    
 # Supply the first format, guess the second
 $self->cfg_file('my_config_file.pl',{ format => 'perl' } );

Supply an array of config files, and they will be processed in order.  If a
hash reference if found it, will be used to supply the format for the previous
file in the array.

=cut

sub cfg_file {
    my $self = shift;
    my @cfg_files = @_;
    unless (scalar @cfg_files) { croak "cfg_file: must have at least one config file." }
    $self->{__CFG_FILES} = \@cfg_files;
}


1;
__END__

=pod

=head1 FILE FORMAT HINTS

=head2  Perl

Here's a simple example of my favorite config file format: Perl.
Having the "shebang" line at the top helps C<Config::Auto> to identify
it as a Perl file. Also, be sure that your last statement returns a 
hash reference.

    #!/usr/bin/perl

    my %CFG = ();

    # directory path name
    $CFG{DIR} = '/home/mark/www';

    # website URL
    $CFG{URL} = 'http://mark.stosberg.com/';

    \%CFG;

=head1 SEE ALSO

L<CGI::Application|CGI::Application> 
L<CGI::Application::Plugin::ValidateRM|CGI::Application::Plugin::ValidateRM>
L<CGI::Application::Plugin::DBH|CGI::Application::Plugin::DBH>
L<CGI::Application::Standard::Config|CGI::Application::Standard::Config>.
perl(1)

=head1 AUTHOR

Mark Stosberg C<< mark@summersault.com >>

=head1 LICENSE

Copyright (C) 2004 - 2011 Mark Stosberg C<< mark@summersault.com >>

This library is free software. You can modify and or distribute it under the same terms as Perl itself.

=cut

