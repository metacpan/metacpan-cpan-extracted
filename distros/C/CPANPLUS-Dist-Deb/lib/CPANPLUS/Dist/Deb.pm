package CPANPLUS::Dist::Deb;

use strict;
use vars    qw[@ISA $VERSION];
@ISA =      qw[CPANPLUS::Dist];
$VERSION =  '0.12';

use CPANPLUS::Error;
use CPANPLUS::Internals::Constants;
use CPANPLUS::Dist::Deb::Constants;

use FileHandle;
use File::Basename;
use File::Find;
use File::Path;
use Cwd;

use IPC::Cmd                    qw[run can_run];
use Params::Check               qw[check];
use File::Basename              qw[dirname];
use Module::Load::Conditional   qw[can_load check_install];
use Locale::Maketext::Simple    Class => 'CPANPLUS', Style => 'gettext';

local $Params::Check::VERBOSE = 1;


=pod

=head1 NAME

CPANPLUS::Dist::Deb

=head1 SYNOPSIS

    my $cb      = CPANPLUS::Backend->new;
    my $modobj  = $cb->module_tree('Some::Module');


    ### as an option to ->install()
    $modobj->install( format => 'CPANPLUS::Dist::Deb' ); 


    ### just to create the debs, don't install
    $modobj->install( format => 'CPANPLUS::Dist::Deb',
                      target => 'create',
                      prereq_target => 'create' );


    ### the long way around
    $mobobj->fetch;
    $modobj->extract;

    my $deb = CPANPLUS::Dist->new(
                                format  => 'CPANPLUS::Dist::Deb',
                                module  => $modobj,
                                %extra_opts,
                          );
                          
    $bool   = $deb->create;     # create a .deb file
    $bool   = $deb->install;    # installs the .deb file

    $where  = $deb->status->dist;                   # from the dist obj
    $where  = $modobj->status->dist->status->dist;  # from the mod obj


    ### from the CPANPLUS Default shell
    CPAN Terminal> i --format=CPANPLUS::Dist::Deb Some::Module
    
    ### using the commandline tool
    cpan2dist --format CPANPLUS::Dist::Deb Some::Module
    
=head1 DESCRIPTION

C<CPANPLUS::Dist::Deb> is a distribution class to create C<debian>
packages from C<CPAN> modules, and all it's dependencies. This allows
you to have the most recent copies of C<CPAN> modules installed,
using your package manager of choice, but without having to wait for
central repositories to be updated.

You can either install them using the API provided in this package,
or manually via C<dpkg>.

Some of the bleading edge C<CPAN> modules have already been turned
into debian packages for you, and you can make use of them by adding
the following line to your C</etc/apt/sources.list> file:
    
    deb http://debian.pkgs.cpan.org/debian unstable main

Note that these packages are built automatically from CPAN and are 
assumed to have the same license as perl and come without support.
Please always refer to the original C<CPAN> package if you have 
questions.

=cut


=head1 ACCESSORS

=over 4

=item parent()

Returns the C<CPANPLUS::Module> object that parented this object.

=item status()

Returns the C<Object::Accessor> object that keeps the status for
this module.

Look at C<CPANPLUS::Dist> for a list of standard accessors every
C<Dist::*> object will have. Below is a list of those specific to
this package.

Note that these are mostly to ensure the inner workings of this
package.

=back

=head1 STATUS ACCESSORS

All accessors can be accessed as follows:
    $deb->status->ACCESSOR

=over 4

=item rules()

The location of the C<debian/rules> file. 

Will be removed after successful creation.

=item compat()

The location of the C<debian/compat> file

Will be removed after successful creation.

=item changelog()

The location of the C<debian/changelog> file

Will be removed after successful creation.

=item copyright()

The location of the C<debian/copyright> file

Will be removed after successful creation.

=item control()

The location of the C<debian/control> file

Will be removed after successful creation.

=item distdir()

The directory where the C<.deb> file is placed.

Will be removed after successful creation.

=item package()

The location of the C<.deb> file.

Note this is equivalent to the C<dist> accessor already
standardly provided.

=item files()

List of all the generated files for this distribution.

=back

=cut


=head1 METHODS

=head2 $bool = CPANPLUS::Dist::Deb->format_available();

Returns a boolean indicating whether or not you can use this package
to create and install modules in your environment.

It will verify if you have all the necessary components avialable to
build your own debian packages. You will need at least these 
dependencies installed:

=over 4

=item debhelper
    
=item dpkg

=item dpkg-dev
    
=item fakeroot

=item gcc

=item libc6-dev

=item findutils

=back

=cut

### XXX check if we're on debian? or perhaps we can do this cross-platform
sub format_available {
    my $flag;
    for my $prog (qw[gencat dpkg dh_perl gcc cp dpkg-buildpackage 
                     fakeroot xargs find]) {
        unless( can_run($prog) ) {
            error(loc("'%1' is a required program to build debian packages",
                      $prog));
            $flag++;
        }
    }
    return $flag ? 0 : 1;
}

=head2 $bool = $deb->init

Sets up the C<CPANPLUS::Dist::Deb> object for use.
Effectively creates all the needed status accessors.

Called automatically whenever you create a new C<CPANPLUS::Dist> 
object.

=cut

sub init {
    my $self    = shift;
    my $status  = $self->status;

    $status->mk_accessors(qw[rules compat changelog copyright control distdir
                             debiandir package package_name package_filename
                             readme prefix builddir _tmp_output_dir files
                             _prepare_args _create_args _install_args]);
                             ### XXX we might not be using _args properly!
    return 1;
}

=pod

=head2 $loc = $dist->prepare([perl => '/path/to/perl', distdir => '/path/to/build/debs', copyright => 'copyright_text', prereq_target => TARGET, force => BOOL, verbose => BOOL, skiptest => BOOL, prefix => 'prefix-', distribution => 'disttype', deb_version => INT])

C<prepare> preps a distribution for creation. This means it will create
all meta data files required by C<dpkg-buildpackage> to build a C<.deb>
file of hte module you specified. 
This will also satisfy any prerequisites the module may have.

If you set C<skiptest> to true, it will skip the C<test> stage.
If you set C<force> to true, it will go over all the stages of the
creation process again, ignoring any previously cached results. It
will also ignore a bad return value from the C<test> stage and still
allow the operation to return true.

Returns true on success and false on failure.

You may then call C<< $deb->create >> on the object to create the 
C<.deb> from the metadata, and then C<< $deb->install >> on the object 
to actually install it.

Returns the location of the builddir on success, and false on failure.

Note any extra options you pass along, will be passed to the underlying
installers verbatim. This enables you to, for example, specify extra 
flags for the C<perl Makefile.PL> stage.

=cut

sub prepare { 
    ### just in case you already did a create call for this module object
    ### just via a different dist object
    my $dist        = shift;
    my $self        = $dist->parent;
    my $dist_cpan   = $self->status->dist_cpan;
    $dist           = $self->status->dist   if      $self->status->dist;
    $self->status->dist( $dist )            unless  $self->status->dist;

    my $cb   = $self->parent;
    my $conf = $cb->configure_object;
    my %hash = @_;

    my $args;
    my( $verbose,$force,$perl,$prereq_target,$distdir,$copyright,$prefix,
        $keep_source,$distribution, $deb_version,$prereq_build);
    {   local $Params::Check::ALLOW_UNKNOWN = 1;
        my $tmpl = {
            verbose     => { default => $conf->get_conf('verbose'),
                                store => \$verbose },
            force       => { default => $conf->get_conf('force'),
                                store => \$force },
            perl        => { default => $^X, store => \$perl },
            ### XXX is this the right thing to do???
            prereq_target   => { default => 'install',
                                 store   => \$prereq_target },
            copyright       => { default => DEB_STANDARD_COPYRIGHT_PERL,
                                 store   => \$copyright },
            distdir         => { default => '', store => \$distdir },
            prefix          => { default => 'cpan-', store => \$prefix },
            distribution    => { default => DEB_DEFAULT_RELEASE, 
                                  store => \$distribution },
            deb_version     => { default => DEB_DEFAULT_PACKAGE_VERSION,
                                  store => \$deb_version },                                  
            #keep_source     => { default => 0, store => \$keep_source },
            prereq_build    => { default => 0, store => \$prereq_build },
        };

        $args = check( $tmpl, \%hash ) or return;
    }

    ### store the prefix for later use
    $dist->status->prefix( $prefix );
    $dist->status->package_name( DEB_PACKAGE_NAME->($self, $prefix) );

    ### the directory we're going to put the files in, which has either
    ### a custom root, or our standard base directory
    my $basedir = File::Spec->catdir(       
                        ( $distdir || DEB_BASE_DIR->( $conf, $perl ) ),
                        DEB_DISTDIR->( $dist, $prefix )
                    );           
                    
    ### did we already create the package? if so, don't bother to rebuild
    ### unless we are forced to

    {   for my $has_xs (0,1) {
            my $pkg = DEB_DEB_FILE_NAME->( 
                            $self, $basedir, $prefix, $has_xs, $deb_version
                        );

            if( -e $pkg && -s _ and not $force) {
                msg(loc("Already created package of '%1' at '%2' -- not doing"
                        ." so again unless you force", $self->module, $pkg ));

                $dist->status->prepared( 1 );
                $dist->status->created( 1 );
                $dist->status->package( $pkg );
                return $dist->status->dist( $pkg );
            }
        }
    }

    {   ### we must install in site or vendor dirs..which means we *must*
        ### tell this to the underlying make/build process!
        MAKE: { 
            my $mmflags = $conf->get_conf('makemakerflags');
            my $mmadd   = DEB_MAKEMAKERFLAGS->( $dist->status->prefix );
            $conf->set_conf( makemakerflags => $mmflags . ' ' . $mmadd )
                unless $mmflags =~ /$mmadd/;
                                
            my $buildflags  = $conf->get_conf('buildflags');
            my $buildadd    = DEB_BUILDFLAGS->( $dist->status->prefix );
            $conf->set_conf(  buildflags => $buildflags . ' ' . $buildadd )
                unless $buildflags =~ /$buildadd/;                                        
        
            my $fail;
            $fail++ unless $dist_cpan->prepare( %hash );
                    
            ### restore the flags                     
            $conf->set_conf( makemakerflags => $mmflags );
            $conf->set_conf( buildflags     => $buildflags );
                    
            if( $fail ) {
                $dist->status->prepared(0);
                return;
            }                
        }
        
        
        unless ( $dist_cpan->create( %hash, prereq_format => __PACKAGE__ ) ) {
            $dist->status->prepared(0);
            return;
        }
        
        
        
        my $debdir = DEB_DEBIAN_DIR->( $self->status->extract );        
        ### store the dirs we build debs in, and where we put the current
        ### meta data files
        $dist->status->distdir( $basedir );                # final destination
        $dist->status->builddir( $self->status->extract ); # [EXTRACT]/
        $dist->status->debiandir( $debdir );               # [EXTRACT]/debian
        ### dir where the generated packages will end up after compiling them,
        ### before moving them to their final destination
        $dist->status->_tmp_output_dir( 
            File::Spec->catdir( $dist->status->builddir, '..' ) );
        
        
        ### create final destination dir && debian subdir ###
        for ( $debdir, $basedir ) {
            unless( -d $_ ) {
                unless( $cb->_mkdir( dir => $_ ) ) {
                    error( loc("Could not create directory '%1'", $_ ) );
                    $dist->status->prepared(0);
                    return;
                }
            }
        }
        
        ### chdir to builddir ###
        unless( $cb->_chdir( dir => $dist->status->builddir ) ) {
            $dist->status->prepared(0);
            return;
        }
    }      


    ### copy the original tarball over, in .orig format so it can
    ### be diffed against by the dh- tools
    {   my $file = $self->status->fetch;
        my $orig = File::Spec->catdir( 
                        $dist->status->builddir, 
                        '..',   # be sure to updir, so the diff is included
                        DEB_ORIG_PACKAGE_NAME->( $self, $prefix ) );
        
        unless( $cb->_copy( file => $file, to => $orig ) ) {
            error(loc("Couldn't copy original archive '%1' to '%2'",
                        $file, $orig ));
            $dist->status->prepared(0);
            return;
        }
    }

    ### let's figure out what this distribution will be called -- we'll need
    ### that later to see if it was actually created
    {   my $has_xs  = scalar GET_XS_FILES->( $self->status->extract ) ? 1 : 0;
        my $debfile = DEB_DEB_FILE_NAME->( 
                            $self, '.', $prefix, $has_xs, $deb_version 
                        );
        
        $dist->status->package_filename( $debfile );
    }


    ### find where prereqs landed, etc.. add them to our dependency list ###
    my @depends;
    {   my $prereqs = $self->status->prereqs;
    
        for my $prereq ( sort keys %$prereqs ) {
            my $obj = $cb->module_tree($prereq);

            unless( $obj ) {
                error( loc( "Couldn't find module object for prerequisite ".
                            "'%1' -- skipping", $prereq ) );
                next;
            }

            ### no point in listing prereqs that are IN the perl core
            ### themselves
            next if $obj->package_is_perl_core;

            ### if the prereq requires any specific version, we'll assume
            ### the one we can provide, otherwise, we'll set it to undef,
            ### marking 'any'
            ### make sure we pick the /lowest/ version available, in case
            ### of custom patches, core running ahead of cpan, etc
            
            ### XXX here's a problem: 
            ### some distributions contain several modules, like PathTools
            ### use to;
            ### Cwd 1.0, File::Spec 2.0, both in PathTools-3.0.tgz
            ### if you already have Cwd or File::Spec installed at a,
            ### for this install, sufficient version, we can no longer
            ### determine what /package/ they came from (as that information
            ### does not exist). So, if this situation occurs, we check
            ### if the installed version is the same as the cpan version.
            ### In that case, and then we will depend on the cpan package
            ### version. if *not* we will depend on the *installed_version*
            ### which may *differ* from the cpan version, but there's not
            ### much we can do :(
            {   my $version = undef;
                
                ### we need a certain version
                if( $prereqs->{$prereq} ) {

                    ### 2 scenarios -- either you have a previously
                    ### installed version, or you don't
                    if( $obj->installed_version ) {
                    
                        ### if the installed version is the same or higher
                        ### (wtf? custom patches?) than the cpan version,
                        ### use the cpan package version
                        if( $obj->installed_version >= $obj->version ) {
                            $version = $obj->package_version;

                        ### the version is *lower* than what's on cpan
                        ### now we need to find out what package that was
                        ### released. However, that is currenty impossible :(
                        ### so we assume that the installed version is magically
                        ### matching the package version.. pretty please, with
                        ### sugar on top...
                        ### this will only possibly hurt if it's wrong, if you
                        ### are making these modules available through an apt
                        ### repo, which will then point to the 'wrong' debian
                        ### dependency.. however, since the dependency has also
                        ### been built by us, the 'right' cpan-lib*perl will
                        ### be picked.
                        } else {
                            $version = $obj->installed_version    
                        }

                    ### no version installed? depend on the cpan package version
                    } else {
                        $version = $obj->package_version;
                    }
                }
                
                push @depends, [$obj, $version];
            }
        }
    }

    ### write a standard debian readme file
    {   my $debreadme = DEB_README->( $dist->status->builddir );
        
        ### open the makefile for writing ###
        my $fh;
        unless( $fh = FileHandle->new( ">$debreadme" ) ) {
            error( loc( "Could not open '%1' for writing: %2",
                         $debreadme, $! ) );
            $dist->status->prepared(0);
            return;
        }

        print $fh DEB_README_CONTENTS;
        close $fh;
    
        $dist->status->readme( $debreadme );
    }

    ### get all the metadata to make the control file ###
    {   my $control = DEB_CONTROL->( $dist->status->builddir );

        ### open the makefile for writing ###
        my $fh;
        unless( $fh = FileHandle->new( ">$control" ) ) {
            error( loc( "Could not open '%1' for writing: %2",
                         $control, $! ) );
            $dist->status->prepared(0);
            return;
        }

        ### check if there are xs files in this distribution ###
        my $has_xs = scalar GET_XS_FILES->( $self->status->extract ) ? 1 : 0;

        my $maintainer      = $conf->get_conf('email');
        my $desc            = $self->description || $self->module;
        my $arch            = DEB_RULES_ARCH->($has_xs);

        my $pkg             = DEB_PACKAGE_NAME->($self, $prefix);
        my $std_version     = DEB_STANDARDS_VERSION;
        my $debhelper       = DEB_DEBHELPER;
        my $perl_depends    = DEB_PERL_DEPENDS;

        ### prereqs will be 'libfoo-perl' if we don't have a prefix and 
        ### '${prefix}libfoo-perl' if we do have a prefix. We only add the
        ### >= VERSION if the prereqs were stated with requiring a certain
        ### version.. otherwise we leave it empty
        my %seen;
        my $prereqs         = join ', ', map {
                                ### do we need a specific version?
                                my $ver = $_->[1] 
                                            ? ' (>= ' . $_->[1] . ')' 
                                            : '';
                                
                                ### standard lib
                                my $str = DEB_PACKAGE_NAME->($_->[0]) . $ver;

                                ### our lib, if it has a prefix
                                if( $prefix ) {
                                    $str .= ' | ' . DEB_PACKAGE_NAME->(
                                            $_->[0], $prefix) . $ver;
                                }
                                
                                $str;
                            } grep {
                                ### shouldn't be a core module
                                ### and we shouldn't list the same
                                ### prereq twice. Note that 2 modules
                                ### may be in 1 package
                                !$_->[0]->package_is_perl_core and
                                !$seen{ DEB_PACKAGE_NAME->( $_->[0] ) }++
                            } @depends;

        ### always put debhelper in build-depends ###
        my $build_depends   =  $debhelper;

        ### always add prereqs to depends ###
        my $depends         = join ', ', $perl_depends, $prereqs;

        ### empty by default, only used if this module has xs parts ###
        my $build_indep; my $bdi_line = '';

        ### xs module, so all dependencies go in build-depend-indep
        if( $has_xs ) {
            $build_indep = $prereqs;

            ### the build-depends-indep line to add to the here-doc
            ### since it's not allowed to be empty in the rules file
            $bdi_line = "Build-Depends-Indep: $build_depends";

        ### no xs, so all dependencies get added to build-depend
        } else {
            $build_depends .= ', ' . $prereqs;
        }


        my $contents = << "EOF";
Source: $pkg
Section: perl
Priority: optional
Maintainer: $maintainer
Standards-Version: $std_version
Build-Depends: $build_depends
$bdi_line

Architecture: $arch
Package: $pkg
EOF

        ### we might have to print some 'Replaces:' lines
        ### - replace perl core if we were ever part of it
        ### - replaces 'standard' debian module (that may or may not exist)
        ###     if we are built without a prefix
        ### XXX OBSOLETE! since we install completely paralel to existing
        ### moduels, and dont replace any files, Replaces: is no longer
        ### required
#         if ( $self->module_is_supplied_with_perl_core or not $prefix ) {
#             my @printme;
#             
#             $fh->print('Replaces: ');
#             
#             ### so this module is also in perl core, add a rule telling the
#             ### .deb that it's ok to replace stuff from those packages.
#             push @printme, DEB_REPLACE_PERL_CORE
#                 if $self->module_is_supplied_with_perl_core;
# 
#             push @printme, DEB_PACKAGE_NAME->($self) if $prefix;
# 
#             $fh->print( join(', ', @printme), "\n" );
#         }
        
        ### so we have a prefix? best explain what package we are /actually/
        ### providing. Also note the Conflicts
        $contents .= "Provides: " . DEB_PACKAGE_NAME->($self) . "\n" if $prefix;
         
        ### XXX remove 'Conflicts:' -- versioned provides don't work
        ### with dpkg :( so if someone wants 'libfoo-perl > 2.0' it
        ### will be seen as not provided by our libfoo-perl, and 
        ### will propbably uninstall these things... bad bad :(
        #  "Conflicts: ". DEB_PACKAGE_NAME->($self) . "\n") 

        ### description should be mentioned twice: one long one, one
        ### short one... format is as follows:
        ### Description: short desc
        ### long description
    
        $contents .= << "EOF";
Depends: $depends
Description: $desc
 $desc

EOF

        ### run the contents through the callback for munging
        ### make this conditional, as this was introduced in the
        ### dev branch of 0.81_01, so not all may have it (automatically)
        ### installed
        if( $cb->_callbacks->munge_dist_metafile ) {
            $contents = $cb->_callbacks->munge_dist_metafile->( 
                            $cb, $contents 
                        );
        }                        

        $fh->print( $contents );

        $fh->close;
        $dist->status->control( $control );
    }


    ### get all the metadata for compat file and write it ###
    {   my $compat    = DEB_COMPAT->( $dist->status->builddir );

        my $fh;
        unless( $fh = FileHandle->new( ">$compat" ) ) {
            error( loc( "Could not open '%1' for writing: %2",
                        $compat, $! ) );
            $dist->status->prepared(0);
            return;
        }

        ### this is in the sample, but what the hell does it do?
        ### -- it's just the version of the spec files we used
        $fh->print( DEB_SPEC_FILE_VERSION . "\n");
        $fh->close;

        $dist->status->compat( $compat );
    }

    ### get all the metadata for changelog file and write it ###
    {   my $changelog   = DEB_CHANGELOG->( $dist->status->builddir );

        my $fh;
        unless( $fh = FileHandle->new( ">$changelog" ) ) {
            error( loc( "Could not open '%1' for writing: %2",
                        $changelog, $! ) );
            $dist->status->prepared(0);
            return;
        }

        ### XXX this will cause parse errors if the first line doesn't match
        ### if (m/^(\w[-+0-9a-z.]*) \(([^\(\) \t]+)\)((\s+[-0-9a-z]+)+)\;/i) {
        ### (taken from /usr/lib/dpkg/parsechangelog/debian ) which means that
        ### we can not have _ in package names, but dots are fine.

        my $pkg     = DEB_PACKAGE_NAME->($self, $prefix);
        my $version = DEB_VERSION->($self, $deb_version);
        my $urgency = DEB_URGENCY;
        my $email   = $conf->get_conf('email');
        my $who     = __PACKAGE__;

        ### geez timestamps are a b*tch with debian changelogs..
        ### this is the only correct format:
        ### Sun,  3 Jun 2001 20:36:41 +0200
        ### but scalar gmtime says:
        ### Sat Jul  3 14:23:31 2004
        my ($wday, $mon, $day, $time, $year) = split /\s+/, scalar gmtime;
        my $when = sprintf "%s, %2d %s %s %s +0100",
                    $wday, $day, $mon, $year, $time; # crackfueled :(

        $fh->print(<< "EOF");
$pkg ($version) $distribution; $urgency

  * Initial Release.

 -- $who <$email>  $when

EOF

        $fh->close;

        $dist->status->changelog( $changelog );
    }

    ### get all the metadata for changelog file and write it ###
    {   my $copyright_file = DEB_COPYRIGHT->( $dist->status->builddir );

        my $fh;
        unless( $fh = FileHandle->new( ">$copyright_file" ) ) {
            error( loc( "Could not open '%1' for writing: %2",
                        $copyright_file, $! ) );
            $dist->status->prepared(0);
            return;
        }

        ### XXX probe for possible license here rather than assume the
        ### default
        my $pkg     = $self->module;
        my $who     = $ENV{DEBFULLMAIL} 
                        ? $ENV{DEBFULLNAME} . ' <' . 
                          ($ENV{DEBEMAIL} || $conf->get_conf('email')) . '>'
                        : ($ENV{DEBEMAIL} || $conf->get_conf('email'));   
        my $when    = 1900 + (localtime)[5];
        my $license = DEB_STANDARD_COPYRIGHT_PERL;
        my $author  = $self->author->author;
        my $email   = $self->author->email;

        $fh->print(<< "EOF");
This is the debian package for the $pkg module.
It was created by $who.

The upstream author is $author <$email>.

Copyright (c) $when by $author

$license

EOF

        $fh->close;
        $dist->status->copyright($copyright_file);
    }

    {   ### add the debian rules file, which is mostly static ###
        my $rules_file  = DEB_RULES->( $dist->status->builddir );
        my $has_xs      = scalar GET_XS_FILES->($self->status->extract)
                                ? 1 : 0;
        my $content     = DEB_GET_RULES_CONTENT->( $self, $prefix, 
                                                    $has_xs, $verbose );

        my $fh;
        unless( $fh = FileHandle->new( ">$rules_file" ) ) {
            error( loc( "Could not open '%1' for writing: %2",
                        $rules_file, $! ) );
            $dist->status->prepared(0);
            return;
        }

        $fh->print( $content );
        $fh->close;

        ### make sure it's set as +x
        chmod 0755, $rules_file;

        $dist->status->rules( $rules_file );
    }

    $dist->status->prepared(1);
    return $dist->status->builddir;
}

=pod

=head2 $loc = $dist->create([force => BOOL, verbose => BOOL, keep_source => BOOL])

C<create> preps a distribution for installation. This means it will 
build a C<.deb> file of the module object you've specified from the 
meta data files that were generated during C<prepare>.

Returns true on success and false on failure.

You may then call C<< $deb->install >> on the object to actually
install it.
Returns the location of the C<.deb> file on success, and false on failure.

=cut

sub create {
    ### just in case you already did a create call for this module object
    ### just via a different dist object
    my $dist = shift;
    my $self = $dist->parent;
    $dist    = $self->status->dist   if      $self->status->dist;
    $self->status->dist( $dist )     unless  $self->status->dist;

    my $cb   = $self->parent;
    my $conf = $cb->configure_object;
    my %hash = @_;

    my $args;
    my( $verbose,$force,$keep_source);
    {   local $Params::Check::ALLOW_UNKNOWN = 1;
        my $tmpl = {
            verbose     => { default => $conf->get_conf('verbose'),
                                store => \$verbose },
            force       => { default => $conf->get_conf('force'),
                                store => \$force },
            keep_source => { default => undef, store => \$keep_source },                                
        };

        $args = check( $tmpl, \%hash ) or return;
    }
    
    ### did you prepare it yet?
    unless( $dist->status->prepared ) {
        error( loc( "You have not successfully prepared a '%2' distribution ".
                    "yet -- cannot create yet", __PACKAGE__ ) );
        return;
    }
    
    ### already created? 
    if( $dist->status->created and not $force ) {
        msg(loc("You have already created a '%1' distribution -- not doing ".
                "so again unless you force", __PACKAGE__ ));     
        return 1;
    }
    
    ### chdir to it ###
    unless( $cb->_chdir( dir => $dist->status->builddir ) ) {
        $dist->status->created(0);
        return;
    }

    {   ### all rules files done, time to build the .deb ###
        ### need to run: dpkg-buildpackage -rfakeroot -uc -us
        my $prog;
        unless( $prog = DEB_BIN_BUILDPACKAGE->() ) {
            error(loc( "Cannot create debian package" ));
            return $dist->status->created(0);
        }

        my $buffer;
        unless( scalar run(
                    command => [$prog, qw|-rfakeroot -uc -us -d|,
                                DEB_DPKG_SOURCE_IGNORE],
                    verbose => $verbose,
                    buffer  => \$buffer )
        ) {
            error( loc( "Failed to create debian package for '%1': '%2'",
                        $self->module, $buffer ) );

            return $dist->status->created(0);
        }

        ### ok, now we have a package created in:
        ### ../$NAME_$VERSION_$ARCH.deb
        ### and we can't tell dpkg-buildpackage to output it anywhere else :(
        #my $has_xs  = scalar GET_XS_FILES->($self->status->extract) ? 1 : 0;
        {   my $tmpfile = File::Spec->catfile(  $dist->status->_tmp_output_dir,
                                                $dist->status->package_filename 
                                            );

            unless( -e $tmpfile && -s _ ) {
                error( loc( "Debian package '%1' was supposed to be created ".
                            "but was not", $tmpfile ) );
                return $dist->status->created(0);
            }
        }
        
        ### XXX moves stuff here
        if( my @files = glob( File::Spec->catdir(
                                    $dist->status->_tmp_output_dir,
                                    $dist->status->package_name,
                                ) . '*' )
        ) {
            my @dest;
            for my $file (@files) {
                my $to = File::Spec->catdir(
                            $dist->status->distdir, basename( $file ) );
            
                unless( $cb->_move( file => $file, to => $to ) ) {
                    error(loc("Failed to move '%1' to its final ".
                                "destination '%2'", $file, $to ));
                    $dist->status->prepared(0);
                    return;
                }
                push @dest, $to;
            }
            
            ### save what files we ended up moving
            $dist->status->files( \@dest );
            
        } else {
            error(loc("No files found matching pattern '%1' in temporary ".
                        "directory '%2'", $dist->status->package_name,
                        $dist->status->_tmp_output_dir ));
            $dist->status->prepared(0);
            return;
        }                        

        ### final location
        my $debfile = File::Spec->catfile(  $dist->status->distdir,
                                            $dist->status->package_filename );


        ### store where we wrote the dist to
        $dist->status->package( $debfile );
        $dist->status->dist( $debfile );

        msg(loc("Wrote '%1' package for '%2' to '%3'",
                'debian', $self->module, $debfile), $verbose);
        
        unless( $cb->_chdir( dir => $conf->_get_build('startdir') ) ) {
            error(loc("Unable to '%1' back to startdir",'chdir'));
        }
    }

    ### if we're asked to clean up our sources, then they
    ### live in $dist->status->debiandir. Rmtree the lot 
    unless ( $keep_source ) {
        my $dir = $dist->status->debiandir;
        msg(loc("Cleaning up meta directory '%1'",$dir), $verbose);
        $cb->_rmdir( dir => $dir );
    }

    $dist->status->created(1);
    return $dist->status->dist;
}

=pod

=head2 $bool = $deb->install([verbose => BOOL, force => BOOL, dpkg => /path/to/dpkg, dpkg_flags => ["--extra", "--flags"]]);

Installs the C<.deb> using C<dpkg -i>.

Returns true on success and false on failure

=cut

sub install {
    ### just in case you already did a create call for this module object
    ### just via a different dist object
    my $dist = shift;
    my $self = $dist->parent;
    $dist    = $self->status->dist   if      $self->status->dist;
    $self->status->dist( $dist )     unless  $self->status->dist;

    my $cb   = $self->parent;
    my $conf = $cb->configure_object;
    my %hash = @_;

    my ($dpkg,$verbose,$force,$flags);
    
    {   local $Params::Check::ALLOW_UNKNOWN = 1;
        my $tmpl = {
            dpkg        => { default => can_run('dpkg'), store => \$dpkg },
            verbose     => { default => $conf->get_conf('verbose'),
                            store => \$verbose },
            force       => { default => $conf->get_conf('force'),
                                store => \$force },
            dpkg_flags  => { default => [], strict_type => 1, 
                                store => \$flags },                           
        };
    
        check( $tmpl, \%hash ) or return;
    }
    
    ### build the command ###
    my $sudo = $conf->get_program('sudo');
    my @cmd  = ($dpkg, '-i', @$flags, $dist->status->package);
    unshift @cmd, $sudo if $sudo;

    my $buffer;
    unless( scalar run( command => \@cmd,
                        verbose => $verbose,
                        buffer  => \$buffer )
    ) {
        error( loc( "Unable to install '%1': %2",
                    $dist->status->package, $buffer ) );
        return $dist->status->installed(0);
    }

    return $dist->status->installed(1);
};

=pod

=head2 $bool = $deb->uninstall([verbose => BOOL, force => BOOL, dpkg => /path/to/dpkg, dpkg_flags => ["--extra", "--flags"]]);

Uninstalls the C<.deb> using C<dpkg -r>.

Returns true on success and false on failure

=cut

sub uninstall {
    ### just in case you already did a create call for this module object
    ### just via a different dist object
    my $dist = shift;
    my $self = $dist->parent;
    $dist    = $self->status->dist   if      $self->status->dist;
    $self->status->dist( $dist )     unless  $self->status->dist;

    my $cb   = $self->parent;
    my $conf = $cb->configure_object;
    my %hash = @_;

    my ($dpkg,$verbose,$force,$flags);
    
    {   local $Params::Check::ALLOW_UNKNOWN = 1;
        my $tmpl = {
            dpkg        => { default => can_run('dpkg'), store => \$dpkg },
            verbose     => { default => $conf->get_conf('verbose'),
                            store => \$verbose },
            force       => { default => $conf->get_conf('force'),
                                store => \$force },
            dpkg_flags  => { default => [], strict_type => 1, 
                                store => \$flags },                           
        };
    
        check( $tmpl, \%hash ) or return;
    }
    
    ### build the command ###
    my $sudo = $conf->get_program('sudo');
    my @cmd  = ($dpkg, '-r', @$flags, $dist->status->package_name);
    unshift @cmd, $sudo if $sudo;

    my $buffer;
    unless( scalar run( command => \@cmd,
                        verbose => $verbose,
                        buffer  => \$buffer )
    ) {
        error( loc( "Unable to uninstall '%1': %2",
                    $dist->status->package, $buffer ) );
        return $dist->status->uninstalled(0);
    }

    return $dist->status->uninstalled(1);
};    

=head2 $loc = CPANPLUS::Dist::Deb->write_meta_files( type => sources|packages, [basedir => /path/to/base, perl => /path/to/perl, release => $releasename]);

This writes the metafiles needed to use this archive as a debian mirror.

It returns the location of the metafile on success, and false on failure.

=cut

{   my $prog;

    sub write_meta_files {
        my $dist = shift;
        my %hash  = @_;
    
        my($type, $basedir, $perl, $release);
        my $tmpl = {
            type    => { required => 1, store => \$type,
                            allow => [  DEB_METAFILE_SOURCES, 
                                        DEB_METAFILE_PACKAGES] },
            basedir => { store => \$basedir },
            perl    => { default => $^X, store => \$perl },
            release => { default => DEB_DEFAULT_RELEASE, store => \$release },
        };
        
        check( $tmpl, \%hash ) or return;
    
        ### check only once for it per running session if possible
        $prog ||= DEB_METAFILE_PROGRAM->();
        
        ### optional program, just can't run it.
        unless( $prog ) {
            error(loc("Could not find '%1' in your path -- please install it",
                      $prog));
            return;
        }

        ### class or object method?
        my $conf = ref $dist 
                        ? $dist->parent->parent->configure_object
                        : do {  require CPANPLUS::Configure; 
                                CPANPLUS::Configure->new };
    
        ### store the old value if needed
        my $oldbase;
        if( $basedir ) {
            $oldbase = $conf->get_conf('base');
            $conf->set_conf( base => $basedir );
        };
    
        ### this is the base path under which we'll put the debian structure
        ### for source files
        my $path = DEB_BASE_DIR->( $conf, $perl );
    
        ### set back the old path
        $conf->set_conf( base => $oldbase ) if $oldbase;
    
        my $outputfile = DEB_OUTPUT_METAFILE->( $type, $path );

        ### check if we need to make the dir for this output file
        {   my $dir = dirname( $outputfile );
            unless( -d $dir ) {
                CPANPLUS::Internals::Utils->_mkdir( dir => $dir ) or return;
            }
        }

        my $oldcwd = cwd();
        chdir $path or return error(loc( "Could not chdir to '%1': %2",
                                            $basedir, $! ));

        my $buffer;      
        my $fail;
        my $command = "$prog $type . | gzip -9 > $outputfile";
        
        ### using IPC::Cmd here gives errors, probably due to pipes and >
        if( system($command) ) {   
            error(loc("Could not run command '%1': %2", $command, $buffer ));
            $fail++;
        }            
    
        chdir $oldcwd or error(loc("Could not chdir back to '%1': %2",
                                    $oldcwd, $! ));
    
        return if $fail;
    
        return $outputfile;
    }
}


1;

=pod

=head1 TODO

There are no TODOs of a technical nature currently, merely of an
administrative one;

=over 4

=item Scan for proper license

Right now we assume that the license of every module is C<the same
as perl itself>. Although correct in almost all cases, it should 
really be probed rather than assumed.
This forms a barrier before C<.debs> generated by this package can
be used by C<debian> itself in it's own repositories.

=item Long description

Right now we provided the description as given by the module in it's
meta data. However, not all modules provide this meta data and rather
than scanning the files in the package for it, we simply default to the
name of the module.

=back

=head1 AUTHOR

This module by
Jos Boumans E<lt>kane@cpan.orgE<gt>.

=head1 COPYRIGHT

The CPAN++ interface (of which this module is a part of) is
copyright (c) 2005, Jos Boumans E<lt>kane@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<CPANPLUS::Backend>, L<CPANPLUS::Module>, L<CPANPLUS::Dist>, 
C<cpan2dist>, C<dpkg>, C<apt-get>

=cut



# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:


__END__

### XXX what is the use of:
### Build-Depends vs Build-Depends-Indep?
### According to HE:
### Put debhelper *always* in Build-Depends (not -Indep!). The rest goes to
### Build-Depends-Indep for non-xs packages, in the case something has to be
### compiled, put all dependencies into Build-Depends.

### Standards-Version
### <HE> About Standards-Version: The standards version defines which policy
#### revision was used to create this packages. In fact it's not important,
#### just put the newest one in there (3.6.1 at the moment)

### Source vs Package
### Package vs. Source: You can build more than one deb from a source package
### (which is a tarball with the upstream sources and a diff with the debian
### changes, don't worry about that, it'll be created automatically if you do
### the right stuff (which i'll ensure)). One of my packages' source package
### is called libgtk2-perl and created 2 debs: libgtk2-perl and
### libgtk2-perl-doc.

### Why is Version not mentioned in the example?
### <HE> You don't have to worry about these things, these fields are
### generated by dh_builddeb
### <HE> The version of a package is not controlled in debian/control, but in
### debian/changelog. The version of the first entry is used to say which
### version this is.
### <HE> As you create the changelog properly, everything should be OK.

# 11:22 <HE> I told ypu total crap
# 11:23 <HE> First rule:
# 11:23 <HE> Always add debhelper to Build-Depends.
# 11:23 <HE> Second rule:
# 11:24 <HE> If a package has no XS stuff (what i mean: No arch-dependent stuff)
#            put all dependencies (for building as well as for running) into
#            Build-Depends-Indep.
# 11:24 <HE> Third rule:
# 11:24 <HE> If a package *has* XS stuff (what i mean: No arch-dependent stuff)
#            put all dependencies (for building as well as for running) into
#            Build-Depends.
# 11:25 <HE> Fourth rule:
# 11:25 <HE> Put all Dependencies into Depends (+ the ${$FOO} stuff)
# 11:25 <HE> That should be everything you need.
# 11:26 <HE> You can do better, but you can't script that.
# 11:28 <kane> ehm, ok... stil lone point of confuseion.. when you say 'package
#              has xs stuff' do you mean a a dependency (like Has::XS) or the
#              module it self (A)?
# 11:30 <HE> The module itself.

# 11:32 <kane> ok, can you write just 2 rule sets out for me, completely? case 1:
# 11:33 <kane> module A::With::XS, has prereqs Pure::Perl and Has::XS and needs
#              Needed::To::Build to build
# 11:33 <kane> case 2, module B::No::XS, same prereqs and all
# 11:35 <HE> OK, for A::With::XS
# 11:35 <HE> Build-Depends: debhelper, libhas-xs-perl, libneeded-to-build-perl
# 11:35 <HE> Depends: ${perl:Depends}, ${misc:Depends}, libhas-xs-perl
# 11:36 <HE> For B::No::XS:
# 11:36 <HE> Build-Depends: debhelper
# 11:36 <HE> Build-Depends-Indep: libhas-xs-perl, libneeded-to-build-perl
# 11:36 <HE> Depends: ${perl:Depends}, ${misc:Depends}, libhas-xs-perl
# 11:37 <HE> Oh. I've forgotten Pure::Perl, but it always has to be next to
#            libhas-xs-perl. There's no difference between the two.
# 11:37 <kane> okidoki... what's the ${} stuff in the Depends line?
# 11:39 <HE> They are substvars. They are filled by debhelper. (${perl:Depends}
#            creates the dependency on the right perl package (i mean the
#            interpreter perl, not some modules) and ${misc:Depends} stays empty
#            atm, but it's there because it could be of use in the future)
# 12:22 <HE> No, you don't need to know if a prereq has xs in it.
# 12:23 <HE> Once again: If you have XS in the Module you want to build,
#            everything belongs to Build-Depends. If it doesn't have XS,
#            everything has to go to Build-Depends-Indep, only debhelper stays in
#            Build-Depends.

[16:45] 	<HE>	Pong.
[16:47] 	<kane-xs>	hey, did you manage to take a look at the tarball?
[16:47] 	<kane-xs>	(also, afk for a min or 2)
[16:49] 	<HE>	Hm? Which tarball?
[16:49] 	<HE>	Ah, that tarball. Sorry, somehow i missed those lines.
[16:49] 	<kane-xs>	p4.elixus.org/snap
[16:49] 	<kane-xs>	there's a -devel tarball of cpanplus
[16:49] 	<kane-xs>	which has cpanplus::dist::deb in it
[17:07] 	<kane-xs>	ehm, found it?
[17:07] 	---	[HE] is away (Gone)
[17:14] 	<HE>	Yes, sorry. My mother asked for my help :)
[17:14] 	<kane-xs>	on perl coding? ;)
[17:15] 	<HE>	No, she hasn't done that in the last few weeks.
[17:15] 	<HE>	[But it happened, my mother is sysadmin at the local university]
[17:15] 	<kane-xs>	heh... and here i think i was being clever ;)
[17:15] 	<HE>	:-)
[17:16] 	<kane-xs>	the deb code is getting slighly out of hand, so i'd like the sanity check :)
[17:17] 	<HE>	Looking at it now.
[17:20] 	<HE>	Well, the code for the description is a bit short atm...
[17:20] 	<HE>	Errr.
[17:20] 	<HE>	OK, reworded: The code for the description creates a very short one atm.
[17:20] 	<HE>	There should be at least one paragraph after that (it's the one and only multi-line-field)
[17:21] 	<kane-xs>	ok.. where do you suggest i get it from? :)
[17:21] 	<HE>	dh-make-perl searches the module source for README files and/or =head1 DESCRIPTION parts in the modules.
[17:22] 	<HE>	Oh, and a "This module was autogenerated by CPANPLUS" would be nice too.
[17:22] 	<HE>	The whole license stuff has to be changed. Debian is pretty anal about licenses :-)
[17:23] 	<kane-xs>	yeah, but i don't care all that much about it ;) what's a good way of probing this?
[17:24] 	<HE>	Once again, grepping README files for common phrases.
[17:24] 	<kane-xs>	hmm... there's often a =head1 LICENSE too...
[17:25] 	<kane-xs>	but still.. heuristics :(
[17:25] 	<HE>	Yes, but a script can't do more than that.
[17:25] 	<kane-xs>	true
[17:25] 	<HE>	Oh. Big problem: Where do you create the debian/rules file?
[17:25] 	*	kane-xs checks
[17:26] 	<kane-xs>	eh, i don't :)
[17:27] 	<HE>	Yeah, looked like that.
[17:27] 	*	kane-xs mixed up 'control' and 'rules' apparently
[17:28] 	<kane-xs>	let me see if i can figure out what rules should do? i'm so annoyed i lost most of our previous conversations ;(
[17:29] 	<HE>	rules is the Makefile used to create the deb.
[17:31] 	<kane-xs>	is the rules file also packed with the .deb?
[17:33] 	<HE>	No, it's only used to create them.
[17:33] 	<kane-xs>	hmm, then show me the one you used for the cpanplus one?
[17:34] 	<HE>	http://marcbrockschmidt.de/tmp/rules
[17:35] 	<kane-xs>	oh right.. /that one/
[17:36] 	<kane-xs>	that one looks trickier than the stuff we're generating so far
[17:38] 	<kane-xs>	and i know you told me there were parts that were always there, and ones that were dynamic
[17:39] 	<kane-xs>	but maybe it's more efficient for me to make -devel work on debian properly, and ask you to look at cpanplus::dist::deb and help me finish it
[17:43] 	<HE>	The rules is pretty static.
[17:43] 	<HE>	The only dynamic parts should be the dh_installdocs and dh_installchangelog lines.
[17:44] 	<kane-xs>	hmm.. those are tricky
[17:44] 	<kane-xs>	-f README and install it
[17:44] 	<kane-xs>	and -f CHANGES || ChangeLog and install it?
[17:44] 	<kane-xs>	that seems like a good enough approximation
[17:45] 	<HE>	Yes, something like that should work.
[17:45] 	<kane-xs>	    install --mode=777 -d $(TMP)/var/cache/cpanplus
[17:45] 	<kane-xs>	is that important?
[17:45] 	<kane-xs>	ie, the 'cpanplus' part -- can that just be any name?
[17:46] 	<HE>	It's only needed for the CPANPLUS module, just remove it.
[17:46] 	<kane-xs>	ok... other moduels don't need something like that?
[17:48] 	<HE>	No, other modules don't.
[17:48] 	<kane-xs>	that seems like good news
[17:50] 	<kane-xs>	so i create the rules just before i run dpkg-buildpackage -rfakeroot -uc -us
[17:50] 	<kane-xs>	and then all should be well?
[17:50] 	<HE>	Yes.
[17:50] 	<kane-xs>	see any logic missing in the deb.pm bit?
[17:50] 	<HE>	Not at the moment, but i haven't run it.
[17:51] 	<kane-xs>	yeah, i need to fix the makefile.pl to work nicely, then you can install the devel version and try it
[17:51] 	<kane-xs>	and then dpkg -i the .deb, and that's it?
[17:51] 	<HE>	Yes.
[17:52] 	<kane-xs>	ok, then i'll try and add that... i have a virtualpc installed with debian, so i should be able to try this out
[17:53] 	<HE>	OK :)
