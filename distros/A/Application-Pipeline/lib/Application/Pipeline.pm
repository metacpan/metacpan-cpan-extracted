package Application::Pipeline;
$VERSION = '0.1';

=head1 Application::Pipeline

Application::Pipeline is a module designed to map methods ( referred to in this
role as handlers ) to different phases of an application's life cycle.
By assigning methods to different phases of this pipeline, the author can
concentrate on the logic for each phase and let the framework manage the
application flow.  Adopting the same idea as CGI::Application, writing an
application with Application::Pipeline is a matter of creating a module that is
a subclass of Application::Pipeline.

=head2 The %plan

To build a pipeline application, it is necessary to register methods to run
during each phase.  This can be done one at a time, with the C<addHandler>
method.  But Application::Pipeline also looks in the subclass package for the
package variable C<%plan>.  This hash's keys are the names of the phases of the
pipeline. Each key points to an array reference which is a list of the methods
to run for that phase.  The methods are either the names of the methods to run,
or references to the actual methods.

This is not the be-all end-all definition of the pipeline.  It is still possible
to use C<addHandler> to modify the pipeline, and as explained later, it is
possible to take into account C<%plan>s defined in superclasses.

=cut

#-- pragmas ---------------------------- 
 use strict;
 use warnings;

#-- modules ---------------------------- 
 use Symbol qw( gensym );

#-- package variables ------------------ 

our @phase_stages = qw( FIRST EARLY MIDDLE LATE LAST );

#===============================================================================

=head2 Running an Application::Pipeline Application

Application::Pipeline is an object oriented module, but has no constructor.  It
is intended to be used as a base class only.  The primary responsibility of
a constructor under Application::Pipeline is to specify an ordered list of
names for the phases of the pipeline.  As it would be impractical to come up
with one unified set of phases that suited every kind of application that
Application::Pipeline could drive, that task, and the constructor along with it,
is left to subclasses.

It is expected that there may eventually become a set of first-level subclasses
that define common sets of phases for different problem spaces.  This way
plugins that are suited to those domains may expect to find a predictable set of
phases when included.  For an initial example of one such subclass, see
WWW::Pipeline.

=head3 run

 $pipeline->run()

A script calls this method when it is ready to run the application.  There are
no parameters

=cut

sub run {
  my $self = shift;

  $self->_buildPlan();

  foreach my $phase ( @{$self->{_phases}} ) {
      foreach my  $stage ( @phase_stages ) {

          next unless defined $self->{_plan}{$phase}{$stage}
            and scalar @{$self->{_plan}{$phase}{$stage}};

          foreach my $method ( @{$self->{_plan}{$phase}{$stage}} ) {
              if( $self->can($method) ) {
                  $self->$method()
              }
              else{
                  eval { $self->$method() }; 
                  die "Error executing $method for $stage of $phase: $@" if $@;
              }
          }                                              
      }
  }
}

#===============================================================================

=head2 Building an Application

Below are functions most useful when actually writing a Application::Pipeline
subclassed application.

=head3 setPhases

 $self->setPhases( qw( Initialization Main Teardown ) );

This method is typically invoked during a subclass's constructor to tell
Application::Pipeline what phases it will be running.  If it is not called
before the C<run> method is invoked, the application will simply terminate
without having done anything.

=cut

sub setPhases {

  my( $self, @phases ) = @_;
  $self->{_phases} = \@phases;
  return 1;
}

#-------------------------------------------------------------------------------

=head3 addHandler

 $self->addHandler( $phase, $handler, $stage )

Registers the given C<$handler> as a method to be run during C<$phase>.  The
optional C<$stage> parameter specifies where along the phase the method is to
be run.  Valid Phases are:

 Initialization ParseRequest GenerateResponse SendResponse Teardown

Valid stages are:

 FIRST EARLY MIDDLE LATE LAST

When no stage is specified, C<MIDDLE> is assumed.  $handler may either be the name
of a method, or a code reference.  Passing a name allows subclasses of the
application to override the method, while code references are slightly faster.
This is a trick taken directly from the CGI::Application folks.

B<Note:> Use the C<FIRST> and C<LAST> stages sparingly.  Note that each time a
handler is added to the stage of a phase, it is added to the end of that stage.
C<FIRST> and C<LAST> are best used for handlers that are depended on by others,
but that do not themselves have dependencies.

=cut

sub addHandler {
    my( $self, $phase, $handler, $stage ) = @_;

    warn "no phases established" and return undef
      unless defined $self->{_phases};

    warn "unrecognized phase '$phase' for handler" and return undef
      unless grep { $phase eq $_ } @{$self->{_phases}};

    warn "unrecognized phase stage '$stage'" and return undef
      if $stage and not grep { $stage eq $_ } @phase_stages;

    $stage ||= 'MIDDLE';
    $self->{_plan}{$phase}{$stage} ||= [];
    push @{$self->{_plan}{$phase}{$stage}},$handler;

}

#-------------------------------------------------------------------------------

=head3 setPluginLocations

 $self->setPluginLocations( qw(
   Application::Pipeline::Services
   WWW::Pipeline::Services
 ));

It is possible to load plugins from certain predetermined namespaces in such
a way that you don't have to specify the fully qualified namespace.  After this
method is called, any time a plugin is loaded it first will see if that plugin
exists by concatenating its name with the namespaces you provided, in the order
in which you provided them.  Failing that, it will see if the plugin has a fully
qualified package name before giving up on loading.

=cut

sub setPluginLocations {
    my( $self, @locations ) = @_;

    $self->{_plugin_locations} = [
        grep /^[A-Za-z_]\w*(::[A-Za-z_]\w*)*$/,  @locations
    ];
}

#-------------------------------------------------------------------------------

=head3 loadPlugin

 $self->loadPlugin( $package, @arguments )

Takes and tries to load the provided C<$package>. unless the
C<$nonstandard_namespace> flag is set it will assume the package needs the
'Application::Pipeline::Services' namespace appended to it.  Upon requiring the module
it passes \@arguments to the package's C<load> method.  For more information
refer to the section below on writing plugins.

=cut

sub loadPlugin {

    my( $self, $plugin, @args ) = @_;
    return 1 if defined $self->{_plugins}{$plugin};

    if( $self->{_plugin_locations} ) {
        foreach my $namespace ( @{$self->{_plugin_locations}}, '' ) {
            my $package = $namespace
                        ? $namespace .'::'.$plugin
                        : $plugin;

            eval "require $package";
            
            die $@ if $@ and $@ !~ /^Can't locate/;
            next if $@;

            warn "Nothing to load from $plugin" and return undef
              unless UNIVERSAL::can( $package, 'load' );

            $package->load( $self, @args )
              or warn "Failed to load plugin '$plugin'" and return undef;
            $self->{_plugins}{$plugin} = $package;

            return 1;
	}
    }

    warn "Failed to load plugin '$plugin': could not locate file";
    return undef;
}

#-------------------------------------------------------------------------------

=head3 loadPlugins

 $self->loadPlugins( 'Foo','Bar',....)
 
A shortcut method for loading plugins that take no arguments.

=cut

sub loadPlugins {
    my( $self, @packages ) = @_;

    my $success_count = 0;
    $success_count += $self->loadPlugin($_) foreach @packages;
    return $success_count;
}

#-------------------------------------------------------------------------------

=head3 unloadPlugins

 $self->unloadPlugins( 'Foo','Bar',...)

While it will likely be rare that an application would want to manually remove
a plugin before it is finished running, this method will do just that to the
named plugins.  It does so by calling the plugin's package's C<unload()> method
if one exists, and deleting the plugin from the application's registry.

=cut

sub unloadPlugins {
    my( $self, @packages ) = @_;

    foreach my $plugin ( @packages ) {
        if( my $package = $self->{_plugins}{$plugin} ) {
            $package->unload( $self ) if UNIVERSAL::can($package, 'unload');
            delete $self->{_plugins}{$plugin};
        }
    }
}

#===============================================================================

=head2 Writing Plugins

Plugins in their simplest form are packages which have two methods: C<load()>
and, optionally, C<unload()>. The former is called when the application calls
C<loadPlugin>, and the latter on C<unloadPlugin()>

C<load> receives the plugin's package name, a reference to the application, and
whatever arguments may have been sent through C<loadPlugin>.

C<unload> receives the plugin's package name and a reference to the application.

=head3 addServices

 $pipeline->addServices( name => $object, name2 => sub{ },... );

This method is most commonly used within the C<load> method of a plugin.
Services are either a subroutine that the application will adopt as one of its
own by the name specified, or a data structure (often objects) that the
application will make available under the specified name

=cut

sub addServices {
    my( $self, %services )  = @_;

    while( my( $name, $service ) = each %services ) {
        next unless $name =~ /^[A-Za-z_]\w*$/;
        {	
            no strict 'refs';
            *{ ref($self)."::$name" } = ( ref $service eq 'CODE' )
                     ? $service
                     : sub { return $service };
        }
        $self->{_services}{$name} = 1;
    }
    return 1;
}

#-------------------------------------------------------------------------------

=head3 dropServices

 $pipeline->dropServices( name, name2,... )

Probably a good idea to unregister the services you added as a plugin when your
C<unload()> method gets called.  Also, rather than forcing the application to
manually call your unload method you may choose to register one of your methods
as a handler to be run during the Teardown phase of the application, so that you
can perform any cleanup you might require.

=cut

sub dropServices {
    my( $self, @services ) = @_;

    foreach my $service ( @services ) {
        next unless defined $self->{_services}{$service};
	
	my $old;
	{
            no strict 'refs';
	    $old = \*{ ref($self)."::$service" };
	}
	
	my $new = gensym;
	*$new = *$old{$_} foreach ( grep { defined *$old{$_} } qw( SCALAR ARRAY HASH IO FORMAT ) );
	{
            no strict 'refs';
	    *{ ref($self)."::$service" } = *$new;
	}

        delete $self->{_services}{$service};
    }
    return 1;
}

#===============================================================================

=head2 Building the Pipeline Plan

When the run method gets called, the first thing the method does is build the
list of methods to be run.  First, it checks for a C<%plan> varaible in the
current package.

Any method entry in a phase of the plan with the value of 'SUPER' causes the
application to go looking up the inheritence tree for packages (that are
themselves descendents of Application::Pipeline) that have a %plan, and substitutes the
superclass' plan for that phase in the place of the 'SUPER' placeholder. This
allows the designer of the current application to choose where and whether to
include the plan of a superclass for a given phase.

The appliation will put all of the plan methods found into the C<MIDDLE> stage
of the phase.

=cut

sub _buildPlan {
    my $self = shift;

    $self->{_phases} ||= [];
    foreach my $phase ( @{$self->{_phases}} ) {
        $self->{_plan}{$phase}{MIDDLE} ||= [];
        $self->_buildPhase( $phase, ref $self );
    }
}

#-------------------------------------------------------------------------------
sub _buildPhase{
    my( $self, $phase, @packages ) = @_;

    foreach my $package( @packages ) {
        my %plan =  eval '%'.$package .'::plan';
        my @isa = grep { UNIVERSAL::isa($_,'Application::Pipeline') }
                       eval '@'.$package.'::ISA';

        unless( %plan && $plan{$phase} ) {
            $self->_buildPhase( $phase, @isa ) if @isa;
            next;
        }

        foreach my $method ( @{$plan{$phase}} ) {

            if( not ref $method and $method eq 'SUPER' ) {
                $self->_buildPhase( $phase, @isa ) if @isa;
                next;
            }

            push @{$self->{_plan}{$phase}{MIDDLE}}, $method;
        }
    }
}

#========
1;

=head2 Acknowledgements

I would like to thank the members of the CGI::Application mailing list that have
participated in the discussions that resulted in this module, particularly
Rob Kinyon, Cees Hek, Mark Stosberg, Michael Peters and David Naughton.  And of
course to Jesse Erlbaum for introducing me to sane methods of web development
with CGI::Application.

=head2 Authors

Stephen Howard <stephen@thunkit.com>

=head2 License

This module may be distributed under the same terms as Perl itself.

=cut

