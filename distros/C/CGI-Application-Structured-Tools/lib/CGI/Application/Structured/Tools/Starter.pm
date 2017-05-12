
=head1 NAME

CGI::Application::Structured::Tools::Starter - template based module starter for CGI::Application::Structured apps.

=head1 SYNOPSIS

    use Module::Starter qw(
        Module::Starter::Simple
        Module::Starter::Plugin::Template
        CGI::Application::Structured::Tools::Starter
    );

    Module::Starter->create_distro(%args);


    
=head1 ABSTRACT

The prefered method for using this module is via the L<scripts/cas-starter.pl> script.

=cut

package CGI::Application::Structured::Tools::Starter;
use base 'Module::Starter::Simple';
use warnings;
use strict;
use Carp qw( croak );
use English qw( -no_match_vars );
use ExtUtils::Command qw( mkpath );
use File::Basename;
use File::Spec ();

use HTML::Template;

=head1 VERSION

Version 0.015

=cut

our $VERSION = '0.015';

=head1 DESCRIPTION

This is a plugin for L<Module::Starter> that builds a skeleton 
L<CGI::Application::Structured> module with all the extra files needed to package it for 
CPAN. It also generates 
  - an CGI::Application::Structured controller base class for your modules
  - a customized CGI::Application::Dispatch subclass
  - a preconfigured development config file 
  - a server.pl that runs out of the box
  - helper scripts to generate Controller modules subclasses
  - a helper script to generate DBIx::Class schema and result classes.

This module is inspired L<Module::Starter::Plugin::CGIApp> by Jaldhar H. Vyas .


=head1 METHODS

=head2 new ( %args )

This method calls the C<new> supermethod from 
L<Module::Starter::Plugin::Template> and then initializes the template store 
and renderer. (See C<templates> and C<renderer> below.)

=cut

sub new {
     my ( $class, @opts ) = @_;
    
     my $self = $class->SUPER::new(@opts);

     $self->{templates} = { $self->templates };
     $self->{renderer}  = $self->renderer;
     return bless $self => $class;
 }

=head2 create_distro ( %args ) 

This method works as advertised in L<Module::Starter>.

=cut

sub create_distro {
    my ( $either, @opts ) = @_;

    ( ref $either ) or $either = $either->new( @_ );
    my $self = $either;



    # This plugin only works to create one module.  This is
    # hangover from borrowed code and should be fixed to remove
    # the impression that multiple modules can be created at once.
    my @modules = map { split /,/mx } @{ $self->{modules} };
    
    croak "No modules specified.\n" if ( !@modules );

    croak "No modules specified.\n" unless ( @modules );

    die "Only one module can be created.\n"
      unless( @modules == 1 );

    croak "Invalid module name: ". $modules[0]
	if ( $modules[0] !~ /\A[a-z_]\w*(?:::[\w]+)*\Z/imx );

    
    croak "Must specify an author\n"
	unless ( $self->{author} );

    croak "Must specify an email address\n"
	unless ( $self->{email} );

    ( $self->{email_obfuscated} = $self->{email} ) =~ s/@/ at /mx;

    $self->{license} ||= 'perl';

    $self->{main_module} = $self->{modules}->[0];

    unless ( $self->{distro} ) {
        $self->{distro} = $self->{main_module};
        $self->{distro} =~ s/::/-/gmx;
    }

    $self->{basedir} = $self->{dir} || $self->{distro};
    $self->create_basedir;

    # split out module package parts for ease of creating
    # directory structure.
    my @distroparts = split /-/mx, $self->{distro};
    $self->{distroparts} = \@distroparts;

    # templatedir is used in config_pl_guts
    $self->{templatedir} = File::Spec->catdir('templates');

    $self->{config_file} =
      File::Spec->catfile( $self->{basedir}, "config", "config.pl" );

    my @files;
    push @files, $self->create_modules(@modules);
    push @files, $self->create_t(@modules);
    push @files, $self->create_tmpl();

    my %build_results = $self->create_build();
    push @files, @{ $build_results{files} };
    push @files, $self->create_Changes;
    push @files, $self->create_README( $build_results{instructions} );
    push @files, $self->create_perlcriticrc;
    push @files, $self->create_mainmodule;
    push @files, $self->create_submodule;
    push @files, $self->create_dispatch;
    push @files, $self->create_config_pl;
    push @files, $self->create_create_dbic_pl;
    push @files, $self->create_create_pl;
    push @files, $self->create_server_pl;
    push @files, $self->create_debug_sh;
    push @files, 'MANIFEST';
    $self->create_MANIFEST( sub{
	my @files2 = 
	my $file = File::Spec->catfile( $self->{basedir}, 'MANIFEST' );
	open my $fh, '>', $file or die "Can't open file $file: $!\n";
	map{print $fh "$_\n"} grep { $_ ne 't/boilerplate.t' } @files;    
	close $fh or die "Can't close file $file: $!\n";	
			    }
	);

    return;
}




=head2 create_t( @modules )

This method creates a bunch of *.t files.  I<@modules> is a list of all modules
in the distribution.

=cut

sub create_t {
    my ( $self, @modules ) = shift;

    #
    # 
    #
    my %t_files = $self->t_guts(@modules);

    my @files = map { 
	$self->_create_t( $_, 
			  $t_files{$_} 
	    ) 
    } keys %t_files;

    # This next part is for the static files dir t/www
    my @dirparts = ( $self->{basedir}, 't', 'www' );
    my $twdir = File::Spec->catdir(@dirparts);
    if ( not -d $twdir ) {
        local @ARGV = $twdir;
        mkpath();
        $self->progress("Created $twdir");
    }
    my $placeholder =
      File::Spec->catfile( @dirparts, 'PUT.STATIC.CONTENT.HERE' );
    $self->create_file( $placeholder, q{ } );
    $self->progress("Created $placeholder");
    push @files, 't/www/PUT.STATIC.CONTENT.HERE';

    return @files;
}


=head2 render( $template, \%options )

This method is subclassed from L<Module::Starter::Plugin::Template>.

It is given an L<HTML::Template> and options and returns the resulting document.

Data in the C<Module::Starter> object which represents a reference to an array 
@foo is transformed into an array of hashes with one key called 
C<$foo_item> in order to make it usable in an L<HTML::Template> C<TMPL_LOOP>.
For example:

    $data = ['a'. 'b', 'c'];

would become:

    $data = [
        { data_item => 'a' },
        { data_item => 'b' },
        { data_item => 'c' },
    ];
    
so that in the template you could say:

    <tmpl_loop data>
        <tmpl_var data_item>
    </tmpl_loop>
    
=cut

sub render {
    my ( $self, $template, $options ) = @_;

    # we need a local copy of $options otherwise we get recursion in loops
    # because of [1]
    my %opts = %{$options};

    $opts{nummodules}    = scalar @{ $self->{modules} };
    $opts{year}          = $self->_thisyear();
    $opts{license_blurb} = $self->_license_blurb();
    $opts{datetime}      = scalar localtime;

    foreach my $key ( keys %{$self} ) {
        next if defined $opts{$key};
        $opts{$key} = $self->{$key};
    }

    # [1] HTML::Templates wants loops to be arrays of hashes not plain arrays
    foreach my $key ( keys %opts ) {
        if ( ref $opts{$key} eq 'ARRAY' ) {
            my @temp = ();
            for my $option ( @{ $opts{$key} } ) {
                push @temp, { "${key}_item" => $option };
            }
            $opts{$key} = [@temp];
        }
    }
    my $t = HTML::Template->new(
        die_on_bad_params => 0,
        scalarref         => \$template,
    ) or croak "Can't create template $template";
    $t->param( \%opts );
    return $t->output;
}

=head2 renderer ()

This method is subclassed from L<Module::Starter::Plugin::Template> but
doesn't do anything as the actual template is created by C<render> in this 
implementation.

=cut

sub renderer {
    my ($self) = @_;
    return;
}

=head2 templates ()

This method is subclassed from L<Module::Starter::Plugin::Template>.

It reads in the template files and populates the object's templates 
attribute. The module template directory is found by checking the 
C<MODULE_TEMPLATE_DIR> environment variable and then the config option 
C<template_dir>.

=cut

sub templates {
    my ($self) = @_;
    my %template;

    my $template_dir = ( $ENV{MODULE_TEMPLATE_DIR} || $self->{templatedir} )
      or croak 'template dir not defined';
    if ( !-d $template_dir ) {
        croak "template dir does not exist: $template_dir";
    }

    foreach ( glob "$template_dir/*" ) {
        my $basename = basename $_;
        next if ( not -f $_ ) or ( $basename =~ /^\./mx );
        open my $template_file, '<', $_
          or croak "couldn't open template: $_";
        $template{$basename} = do {
            local $RS = undef;
            <$template_file>;
        };
        close $template_file or croak "couldn't close template: $_";
    }


    return %template;
}

=head2 create_MANIFEST_SKIP()

This method creates a C<MANIFEST.SKIP> file in the distribution's directory so 
that unneeded files can be skipped from inclusion in the distribution.
=cut

sub create_MANIFEST_SKIP {
    my $self = shift;

    my $fname = File::Spec->catfile( $self->{basedir}, 'MANIFEST.SKIP' );
    $self->create_file( $fname, $self->MANIFEST_SKIP_guts() );
    $self->progress("Created $fname");

    return 'MANIFEST.SKIP';
}

=head2 create_perlcriticrc ()

This method creates a C<perlcriticrc> in the distribution's test directory so 
that the behavior of C<perl-critic.t> can be modified.

=cut

sub create_perlcriticrc {
    my $self = shift;

    my @dirparts = ( $self->{basedir}, 't' );
    my $tdir = File::Spec->catdir(@dirparts);
    if ( not -d $tdir ) {
        local @ARGV = $tdir;
        mkpath();
        $self->progress("Created $tdir");
    }

    my $fname = File::Spec->catfile( @dirparts, 'perlcriticrc' );
    $self->create_file( $fname, $self->perlcriticrc_guts() );
    $self->progress("Created $fname");

    return 't/perlcriticrc';
}

=head2 create_server_pl ()

This method creates C<server.pl> in the distribution's root directory.

=cut

sub create_server_pl {
    my $self = shift;

    my $fname = File::Spec->catfile( $self->{basedir}, 'server.pl' );
    $self->create_file( $fname, $self->server_pl_guts() );
    chmod 0755, ($fname);
    $self->progress("Created $fname");

    return 'server.pl';
}


=head2 create_debug_sh ()

This method creates C<debug.sh> in the distribution's root directory. Starts werver with environment set to display ::Plugin::DebugScreen on error

=cut

sub create_debug_sh {
    my $self = shift;

    my $fname = File::Spec->catfile( $self->{basedir}, 'debug.sh' );
    $self->create_file( $fname, $self->debug_sh_guts() );
    chmod 0755, ($fname);
    $self->progress("Created $fname");

    return 'debug.sh';
}

=head2 create_config_pl ()

This method creates C<config-test.pl> in the distribution's root/config directory.

=cut

sub create_config_pl {
    my $self = shift;

    #my $reldir = join q{/}, File::Spec->splitdir( $self->{templatedir} );

    my @dirparts = ( $self->{basedir}, "config" );
    my $tdir = File::Spec->catdir(@dirparts);

    if ( not -d $tdir ) {
        local @ARGV = $tdir;
        mkpath();
        $self->progress("Created $tdir");
    }

    my $fname = File::Spec->catfile( $tdir, 'config.pl' );
    $self->create_file( $fname, $self->config_pl_guts() );
    $self->progress("Created $fname");

    return 'config.pl';
}

=head2 create_create_pl ()

This method creates C<create_controller.pl> in the distribution's app/script directory.

=cut

sub create_create_pl {
    my $self = shift;

    my @dirparts = ( $self->{basedir}, "script" );
    my $tdir = File::Spec->catdir(@dirparts);

    if ( not -d $tdir ) {
        local @ARGV = $tdir;
        mkpath();
        $self->progress("Created $tdir");
    }

    # template needs template_path not just template dir
    $self->{template_path} = File::Spec->rel2abs( $self->{templatedir} );

    # Store template directory
    my $fname = File::Spec->catfile( $tdir, 'create_controller.pl' );
    $self->create_file( $fname, $self->create_pl_guts() );
    chmod 0755, ($fname);
    $self->progress("Created $fname");

    return 'script/create_controller.pl';
}

=head2 create_tmpl ()

This method takes all the template files ending in .tmpl (representing 
L<HTML::Template>'s and installs them into a directory under the distro tree.  
For instance if the distro was called C<Foo-Bar>, the templates would be 
installed in C<Foo-Bar/templates>.

Note the files will just be copied over not rendered.

=cut

sub create_tmpl {
    my $self = shift;

    return $self->tmpl_guts();
}

=head2 create_submodule ()

Implements a default "Home" subclass of the main module.  This module will be auto configured as the default module in the Dispatch subclass.

=cut
sub create_submodule {
    my $self = shift;

    my @distroparts = @{ $self->{distroparts} };

    my @dirparts = ( $self->{basedir}, 'lib', @distroparts, "C" );
    my $tdir = File::Spec->catdir(@dirparts);
    if ( not -d $tdir ) {
        local @ARGV = $tdir;
        mkpath();
        $self->progress("Created $tdir");
    }
    my $fname =
      File::Spec->catfile( $self->{basedir}, 'lib', @distroparts, "C",
        "Home.pm" );
    $self->create_file( $fname, $self->submodule_guts() );
    $self->progress("Created $fname");

    return $fname;
}


=head2 create_submodule ()

Implements a default controller baseclass (main module).  

=cut
sub create_mainmodule {
    my $self = shift;

    my @distroparts = @{ $self->{distroparts} };

    # 
    # For multi level main packages, separate out the path parts
    # from the main module file name part.
    #
    my $last_inx = $#distroparts - 1;
    my @distro_dirparts = @distroparts > 1? @distroparts[0..$last_inx]: ();
    my $distro_namepart = $distroparts[-1] . '.pm';

    my @dirparts = ( $self->{basedir}, 'lib', @distro_dirparts);
    my $tdir = File::Spec->catdir(@dirparts);
    if ( not -d $tdir ) {
        local @ARGV = $tdir;
        mkpath();
        $self->progress("Created $tdir");
    }
  
    
   
    my $fname =
      File::Spec->catfile( $self->{basedir}, 'lib',  @distro_dirparts, $distro_namepart );

    # need to delete the module starter default file for this customization
    if (-f $fname){unlink $fname;}

    $self->create_file( $fname, $self->mainmodule_guts() );
    $self->progress("Created $fname");

    return $fname;
}


=head2 create_dbic_pl ()

This method creates C<create_dbic_schema.pl> in the distribution's root/script/ directory.

=cut

sub create_create_dbic_pl {
    my $self = shift;

    # template needs path ucd nder lib to main module
    $self->{distrodir} = File::Spec->catdir( @{ $self->{distroparts} } );

    # Create the script directory if it is not there already

    my @dirparts = ( $self->{basedir}, "script" );
    my $tdir = File::Spec->catdir(@dirparts);

    if ( not -d $tdir ) {
        local @ARGV = $tdir;
        mkpath();
        $self->progress("Created $tdir");
    }

    # create the user script
    my $fname = File::Spec->catfile( $tdir, 'create_dbic_schema.pl' );
    $self->create_file( $fname, $self->create_create_dbic_guts() );
    chmod 0755, ($fname);
    $self->progress("Created $fname");

    return 'script/create_dbic_schema.pl';
}


=head2 create_dispatch ()

Implements a L<CGI::Application::Dispatch> subclass for this app in the lib directory under the main modules directory.

=cut

sub create_dispatch {
    my $self = shift;

    my @distroparts = split /::/, $self->{main_module};
    my @dirparts = ( $self->{basedir}, 'lib', @distroparts );
    my $tdir = File::Spec->catdir(@dirparts);

    if ( not -d $tdir ) {
        local @ARGV = $tdir;
        mkpath();
        $self->progress("Created $tdir");
    }
    my $fname =
      File::Spec->catfile( $self->{basedir}, 'lib', @distroparts,
        "Dispatch.pm" );
    $self->create_file( $fname, $self->dispatch_guts() );
    $self->progress("Created $fname");

    return $fname;

}



sub create_create_dbic_guts {
    my $self = shift;
    my %options;

    my $template = $self->{templates}{'create_dbic_schema.pl'};
    return $self->render( $template, \%options );
}


sub dispatch_guts {
    my $self = shift;
    my %options;
    $self->{config_file} =
      File::Spec->catfile( $self->{basedir}, "config", "config.pl" );

    my $template = $self->{templates}{'Dispatch.pm'};
    return $self->render( $template, \%options );
}

sub submodule_guts {
    my $self = shift;
    my %options;
    $self->{sub_module} = "C::Home";
    my $template = $self->{templates}{'submodule.pm'};
    return $self->render( $template, \%options );
}


sub mainmodule_guts {
    my $self = shift;
    return $self->render($self->{templates}{'Module.pm'}, {});
}

sub t_guts {
    my ( $self, @opts ) = @_;

    my %options;
    $options{modules}     = [@opts];
    $options{modulenames} = [];

    foreach ( @{ $options{modules} } ) {
        push @{ $options{module_pm_files} }, $self->_module_to_pm_file($_);
    }

    my %t_files;

    foreach ( grep { /\.t$/mx } keys %{ $self->{templates} } ) {
        my $template = $self->{templates}{$_};
        $t_files{$_} = $self->render( $template, \%options );
    }

    return %t_files;
}


sub tmpl_guts {
    my ($self) = @_;
    my %options;    # unused in this function.

    # we need the directory seperator to be / regardless of OS
    my $reldir = join q{/}, File::Spec->splitdir( $self->{templatedir} );

    # Create the default submodule template folder ("Home")
    # (could use reldir
    my @dirparts = (
        $self->{basedir}, $self->{templatedir}, @{ $self->{distroparts} },
        "C", "Home"
    );
    my $tdir = File::Spec->catdir(@dirparts);

    if ( not -d $tdir ) {
        local @ARGV = $tdir;
        mkpath();
        $self->progress("Created $tdir");
    }

    #TODO We only need one file so remove loop
    my @t_files;
    foreach my $filename ( grep { /\.tmpl$/mx } keys %{ $self->{templates} } ) {
        my $template = $self->{templates}{$filename};
        my $fname = File::Spec->catfile( @dirparts, $filename );
        $self->create_file( $fname, $template );
        $self->progress("Created $fname");
        push @t_files, "$reldir/$filename";
    }

    return @t_files;
}



sub Changes_guts {   
    my $self = shift;
    return $self->render( $self->{templates}{Changes}, {});
}


sub MANIFEST_SKIP_guts {
    my $self = shift;
    return $self->render($self->{templates}{'MANIFEST.SKIP'}, {});
}


sub perlcriticrc_guts {
    my $self = shift;
    return $self->render( $self->{templates}{perlcriticrc},{});
}


sub server_pl_guts {
    my $self = shift;
    return $self->render( $self->{templates}{'server.pl'},{});
}


sub debug_sh_guts {
    my $self = shift;
    return $self->render( $self->{templates}{'debug.sh'}, {});
}


sub config_pl_guts {
    my $self = shift;
    return $self->render( $self->{templates}{'config-dev.pl'},{});
}


sub create_pl_guts {
    my $self = shift;
    return $self->render($self->{templates}{'create_controller.pl'}, {} );
}


=head1 BUGS

Please report any bugs or feature requests to through the web 
interface at L<http://rt.cpan.org>. I will be notified, and then you'll 
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Gordon Van Amburg, E<lt>vanamburg at cpan.orgE<gt>

=cut

=head1 ACKNOWLEDGEMENT

This module borrows heavily, is verily grafted from, <Module::Starter::Plugin::CGIApp> by 
Jaldhar H. Vyas, E<lt>jaldhar at braincells.comE<gt>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Application::Structured-starter>, L<CGI::Application::Structured>, L<CGI::Application>, L<Module::Starter::Plugin::CGIApplication>

=cut

1;
