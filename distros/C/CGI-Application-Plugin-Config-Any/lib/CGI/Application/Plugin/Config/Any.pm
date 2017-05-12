## --------------------------------------------------------------------
## C::A::Plugin to use Config::Any
## --------------------------------------------------------------------

package CGI::Application::Plugin::Config::Any;
use strict;
use warnings;

use base 'Exporter';
use vars qw/ @EXPORT @EXPORT_OK %EXPORT_TAGS /;

@EXPORT      = qw( config );
@EXPORT_OK   = qw( config_init config_name config_section config_read );
%EXPORT_TAGS = ( 
    'all' =>  [ 
        qw( config config_init config_name config_section config_read ) 
    ] 
); 

use Config::Any;

my $prefix = '__CONFIG_ANY_';

$CGI::Application::Plugin::Config::Any::DEBUG = 0;


=head1 NAME

CGI::Application::Plugin::Config::Any - Add Config::Any Support to CGI::Application

=head1 VERSION

Version 0.13

=cut

$CGI::Application::Plugin::Config::Any::VERSION = '0.14';


=head1 SYNOPSIS

There are two ways to initialize this module.

B<In your instance script:>

    my $app = WebApp->new(
        PARAMS => {
            config_dir    => '/path/to/configfiles',
            config_files  => [ 'app.conf' ],
            config_name   => 'main',
            config_params => {
                ## passed to Config::Any->load_files;
                ## see Config::Any for valid params
            }
        }
    );
    $app->run();
    
B<In your L<CGI::Application|CGI::Application>-based module:>

    use base 'CGI::Application';
    use CGI::Application::Plugin::Config::Any;

    sub cgiapp_init {
        my $self = shift;

        # Set config file and other options
        $self->config_init(
            config_dir    => '/path/to/configfiles',
            config_files  => [ 'app.conf' ],
            config_name   => 'main',
            config_params => {
                ## passed to Config::Any->load_files;
                ## see Config::Any for valid params
            }
        );
    }

Later...

    ## get a complete config section as a hashref
    my $section = $self->config_section( 'sectionname' );
    
    ## get a single config param
    my $param = $self->config( 'paramname' );
    

=head1 DESCRIPTION

This module allows to use L<Config::Any|Config::Any> for config files inside a
CGI::Application based application.

B<This module is "work in progress" and subject to change without warning!>

(L<Config::Any|Config::Any> provides a facility for Perl applications and libraries
to load configuration data from multiple different file formats. It 
supports XML, YAML, JSON, Apache-style configuration, Windows INI 
files, and even Perl code.)


=head1 EXPORTS

By default, only the L<config|config>() method is exported.

B<The following methods are only exported on demand:>

=over 4

=item config_init

=item config_name

=item config_section

=item config_read

=back

You can import them explicitly, or use ':all':

    use CGI::Application::Plugin::Config::Any qw( :all );


=head1 METHODS

=head2 config

This method is exported to your C::A based application as an accessor
to the configuration params.

There are several ways to retrieve a config param:

    $self->config_section('mysection');
    $self->config('mysetting');
    # set section to 'mysection' before retrieving 'mysetting'

    $self->config('mysetting', section => 'mysection' );
    # more convenient way to do the same as above

    $self->config('mysection.mysetting');
    # another way to do the same as above

    $self->config('mysetting');
    # let the module find a param named 'mysetting' without
    # knowing or bothering the section name

See also L<BUGS|bugs>!

=cut

#-------------------------------------------------------------------
# METHOD:     config
# + author:   Bianka Martinovic
# + reviewed: Bianka Martinovic
# + purpose:
#-------------------------------------------------------------------
sub config {
    my $self    = shift;
    my $param   = shift;

    my %attrs = (
        section => $self->{$prefix.'CURRENT_SECTION'},
        name    => $self->{$prefix.'CONFIG_NAME'} || 'default',
        @_
    );

    my $section = $attrs{'section'};

    if ( $param && $param =~ /^(.*)\.(.*)$/ ) {
        $section = $1;
        $param   = $2;
    }

    $CGI::Application::Plugin::Config::Any::DEBUG
        and __PACKAGE__->_debug(
              "    config name [$attrs{'name'}]\n"
            . "          param [$param]\n"
            . "        section [$section]\n"
        );

    return _load(
        $self,
        section => $section,
        param   => $param,
        name    => $attrs{'name'}
    );
}   # --- end sub config ---


=head2 config_init

Initializes the plugin.

    $self->config_init(
        config_dir   => '/path/to/configfiles',
        config_files => [ 'app.conf' ],
    );

Valid params:

=over 4

=item config_dir SCALAR

Path where the config files reside in.

=item config_files ARRAY

A list of files to load.

=item config_name SCALAR

You can use more than one configuration at the same time by using config
names. For example:

    $self->config_init(
        config_name   => 'database',
        config_files  => [ 'db.conf' ],
    );
    $self->config_init(
        config_name   => 'template',
        config_files  => [ 'tpl.conf' ],
    );

    ...

    my $connection_options  = $self->config_section('connection', name => 'database' );
    my $template_file       = $self->config( 'file', name => 'template' );

=item config_names HASHREF



=item config_params HASHREF

Options to pass to Config::Any->load_files().

B<Example:>

    $self->config_init(
        config_files  => [ 'default.yml' ],
        config_params => {
            'use_ext' => 1,
        }
    );

See L<Config::Any> for details.

=back

=cut

#-------------------------------------------------------------------
# METHOD:     config_init
# + author:   Bianka Martinovic
# + reviewed: Bianka Martinovic
# + purpose:  
#-------------------------------------------------------------------
sub config_init {
    my $self = shift;

    my %args = (
        'config_names'  => $self->param('config_names')  || {},
        'config_dir'    => $self->param('config_dir')    || undef,
        'config_files'  => $self->param('config_files')  || [],
        'config_params' => $self->param('config_params') || {},
        'config_name'   => $self->param('config_name')   || 'default',
        @_
    );
    
    foreach ( keys %args ) {
        $self->{ $prefix . uc($_) } = delete $args{$_};
    }

    $CGI::Application::Plugin::Config::Any::DEBUG
        and __PACKAGE__->_debug(
              "initialized with:\n"
            . "\tconfig_names: $self->{$prefix.'CONFIG_NAMES'}\n"
            . "\tconfig_dir  : $self->{$prefix.'CONFIG_DIR'}\n"
            . "\tconfig_files: "
            . join( ', ', @{ $self->{$prefix.'CONFIG_FILES'} } )
        );

    return 1;
    
}   # --- end sub config_init ---

=head2 config_name

Set the name of the config to use.

=cut

#-------------------------------------------------------------------
# METHOD:     config_name
# + author:   Bianka Martinovic
# + reviewed: Bianka Martinovic
# + purpose:  set the name of the current config
#-------------------------------------------------------------------
sub config_name {
    my $self = shift;
    my $name = shift;
    
    return unless $name;
    
    $CGI::Application::Plugin::Config::Any::DEBUG
        and __PACKAGE__->_debug( "setting config name: $name" );
    
    $self->{$prefix.'CONFIG_NAME'} = $name;
    
    return $name;

}   # --- end sub config_name ---


=head2 config_section

Retrieve a complete section from your configuration, or set the name
of the current "default section" for later use with C<config()>.

    my $hash = $self->config_section('mysection');

=cut

#-------------------------------------------------------------------
# METHOD:     config_section
# + author:   Bianka Martinovic
# + reviewed: Bianka Martinovic
# + purpose:  
#-------------------------------------------------------------------
sub config_section {
    my $self    = shift;
    my $section = shift;
    
    $self->{$prefix.'CURRENT_SECTION'} = $section;
    
    $CGI::Application::Plugin::Config::Any::DEBUG
        and __PACKAGE__->_debug(
            "loading section [$section]"
        );
    
    return _load( $self, section => $section, @_ ) if defined wantarray;
    
    return;
    
}   # --- end sub config_section ---


=head2 config_read

Get complete configuration as a hashref.

    my $config = $self->config_read();

=cut

#-------------------------------------------------------------------
# METHOD:     config_read
# + author:   Bianka Martinovic
# + reviewed: Bianka Martinovic
# + purpose:  
#-------------------------------------------------------------------
sub config_read {
    my $self = shift;
    
    return _load( $self, @_ );
    
}   # --- end sub config_read ---


=head2 std_config

For CGI::Application::Standard::Config compatibility. Just returns 
'TRUE'.

=cut

#-------------------------------------------------------------------
# METHOD:     std_config
# + author:   Bianka Martinovic
# + reviewed: Bianka Martinovic
# + purpose:  CGI::Application::Standard::Config compatibility
#-------------------------------------------------------------------
sub std_config { return 1; }


#-------------------------------------------------------------------
#               + + + + + INTERNAL METHODS + + + + +
#-------------------------------------------------------------------

#-------------------------------------------------------------------
# METHOD:     _load
# + author:   Bianka Martinovic
# + reviewed: 07-11-14 Bianka Martinovic
# + purpose:  load config file(s)
#-------------------------------------------------------------------
sub _load {
    my $self = shift;

    my %args = (
        section   => undef,
        param     => undef,
        name      => $self->{$prefix.'CONFIG_NAME'} || 'default',
        @_
    );
    
    my $name = $args{'name'};

    unless ( $self->{$prefix.'CONFIG_CONFIG'} ) {
        $self->config_init( %args );
    }

    my %config = ();
    
    ## config already loaded?
    unless ( $self->{$prefix.'CONFIG_CONFIG'}->{ $name } ) {
    
        $CGI::Application::Plugin::Config::Any::DEBUG
            and __PACKAGE__->_debug(
                "loading config named [$name]"
            );

        if ( exists $self->{$prefix.'CONFIG_NAMES'}->{ $name } ) {
        
            my $this = $self->{$prefix.'CONFIG_NAMES'}->{ $name };

            foreach ( qw/ config_dir config_files config_params / ) {
                my $key = $prefix.uc($_);
                if ( exists $this->{ $_ } ) {
                    $self->{$key} = $this->{$_};
                }
                $self->{$prefix.'CONFIG_FILES'}
                    = $self->{$prefix.'CONFIG_NAMES'}->{ $name }->{'config_files'};
            }
        }

        if ( $self->{$prefix.'CONFIG_FILES'}
          && ref $self->{$prefix.'CONFIG_FILES'} ne 'ARRAY'
        ) {
            $self->{$prefix.'CONFIG_FILES'} = [ $self->{$prefix.'CONFIG_FILES'} ];
        }
        
        $self->{$prefix.'CONFIG_FILES'}
            = [ 
                map { $self->{$prefix.'CONFIG_DIR'}.'/'.$self->{$prefix.'CONFIG_FILES'}[$_] }
                    0 .. $#{ $self->{$prefix.'CONFIG_FILES'} }
              ];

        $CGI::Application::Plugin::Config::Any::DEBUG
            and __PACKAGE__->_debug(
                "searching files: "
              . join( ', ', @{$self->{$prefix.'CONFIG_FILES'}} )
            );

        ## load the files using Config::Any
        my $cfg = Config::Any->load_files( 
                      { 
                          files   => $self->{$prefix.'CONFIG_FILES'},
                          %{ $self->{$prefix.'CONFIG_PARAMS'} }
                      }
                  );

        $CGI::Application::Plugin::Config::Any::DEBUG
            and __PACKAGE__->_debug(
                "found [" . scalar @$cfg . "] config files"
            );
    
        ## import settings
        for ( @$cfg ) {
        
            my ( $filename, $thisconfig ) = each %$_;
            
            foreach ( keys %$thisconfig ) {
                $config{$_} = $thisconfig->{$_};
            }
        
        }
    
        $self->{$prefix.'CONFIG_CONFIG'}->{ $args{'name'} } = \%config;
        
    }
    else {
        %config = %{ $self->{$prefix.'CONFIG_CONFIG'}->{ $args{'name'} } };
    }

    ## return a section
    if ( $args{'section'} && ! $args{'param'} ) {
    
        $CGI::Application::Plugin::Config::Any::DEBUG
            and __PACKAGE__->_debug(
                "returning complete section [$args{'section'}]"
            );
    
        return $config{ $args{'section'} };
    
    }

    if ( $args{'param'} ) {

        no strict 'vars';
        
        my $value;
        
        if ( exists $config{ $args{'param'} } ) {
            $value = $config{ $args{'param'} };
        }
        elsif ( $args{'section'} 
             && $config{ $args{'section'} }
             && $config{ $args{'section'} }->{ $args{'param'} }
        ) {
            $value = $config{ $args{'section'} }->{ $args{'param'} };
        }
                 
        unless ( defined $value ) {
            $CGI::Application::Plugin::Config::Any::DEBUG
                and __PACKAGE__->_debug(
                    "trying to find key [$args{'param'}]"
                );
            $value = _find_key( $self, $args{'param'}, \%config );
        }

        return $value;

    }

    return \%config;# unless wantarray;

}   # --- end sub _load ---

#-------------------------------------------------------------------
# METHOD:     _find_key
# + author:   Bianka Martinovic
# + reviewed: Bianka Martinovic
# + purpose:  find a key in the config data structure
#-------------------------------------------------------------------
sub _find_key {
    my $self   = shift;
    my $key    = shift;
    my $config = shift;

    unless ( ref $config eq 'HASH' ) {
        return;
    }
    
    if ( exists $config->{ $key } ) {
        $CGI::Application::Plugin::Config::Any::DEBUG
                and __PACKAGE__->_debug(
                    "key [$key] found"
                );
        return $config->{ $key };
    }
    
    foreach my $subkey ( keys %{ $config } ) {
        my $value = _find_key( $self, $key, $config->{$subkey} );
        return $value if $value;
    }
    
    return;

}   # --- end sub _find_key ---


=pod

=head1 DEBUGGING

This module provides some internal debugging. Any debug messages go to
STDOUT, so beware of enabling debugging when running in a web
environment. (This will end up with "Internal Server Error"s in most
cases.)

There are two ways to enable the debug mode:

=over 4

=item In the module

Find line

    $CGI::Application::Plugin::Config::Any::DEBUG = 0;

and set it to any "true" value. ("1", "TRUE", ... )

=item From outside the module

Add this line B<before> calling C<new>:

    $CGI::Application::Plugin::Config::Any::DEBUG = 1;

=back

=cut

#-------------------------------------------------------------------
# METHOD:     _debug
# + author:   Bianka Martinovic
# + reviewed: 07-11-14 Bianka Martinovic
# + purpose:  print out formatted _debug messages
#-------------------------------------------------------------------
sub _debug {
    my $self = shift;
    my $msg  = shift;
    
    my $dump;
    if ( @_ ) {
        if ( scalar ( @_ ) % 2 == 2 ) {
            %{ $dump } = ( @_ );
        }
        else {
            $dump = \@_;
        }
    }
    
    my ( $package, $line, $sub ) = (caller())[0,2,3];
    my ( $callerpackage, $callerline, $callersub ) 
        = (caller(1))[0,2,3]; 
    
    $sub ||= '-';
    
    print "\n",
          join( ' | ', $package, $line, $sub ),
          "\n\tcaller: ",
          join( ' | ', $callerpackage, $callerline, $callersub ),
          "\n\t$msg",
          "\n\n";
    
    #if ( $dump ) {
    #    print $self->_dump( $dump );
    #}
    
    return;
}   # --- end sub _debug ---

1;

__END__


=head1 AUTHOR

Bianka Martinovic, C<< <mab at cpan.org> >>

=head1 BUGS

B<This module is "work in progress" and subject to change without warning!>

=head2 Complex data structures

At the moment, there is no way to require a key buried deep in the config
data structure. Example for a more complex data structure (YAML syntax):

    database_settings:
        dsn: dbi:mysql:cm4web2:localhost
        driver: mysql
        host: localhost
        port: 3306
        additional_args:
            ShowErrorStatement: 1

You can not require the key 'ShowErrorStatement' directly, 'cause it's a
subkey of 'additional_args', but the C<param()> method does not support
nested section names.

Anyway, if CAP::Config::Any isn't able to find a required key in the current
section, it walks through the complete config data structure to find it. So,
the following works with this example:

    my $param = $self->config('ShowErrorStatement');
    ## this will return '1'

There is no way to suppress this at the moment, so beware of having similar
named keys in different sections of your configuration! You may not get what
you expected.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Application::Plugin::Config::Any

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Application-Plugin-Config::Any>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Application-Plugin-Config::Any>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Application-Plugin-Config::Any>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Application-Plugin-Config::Any>

=back
    
=head1 DEPENDENCIES

=over 8

=item Config::Any

=back

=head1 ACKNOWLEDGEMENTS

This module was slightly inspired by C<CGI::Application::Plugin::Context>.
See L<http://search.cpan.org/perldoc?CGI::Application::Plugin::Config::Context>
for details.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Bianka Martinovic, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
