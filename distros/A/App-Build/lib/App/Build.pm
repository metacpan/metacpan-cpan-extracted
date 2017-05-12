package App::Build;

use strict;

# undo @ARGV manipulation done by App::Options, to allow Module::Build to work
my @orig_ARGV; BEGIN { @orig_ARGV = @ARGV; }
use App::Options;
@ARGV = @orig_ARGV;

use Module::Build;
use Cwd ();
use File::Spec;
use File::Basename qw();
use File::Path qw();

our $VERSION = "0.74";
our @ISA = ("Module::Build");

=head1 NAME

App::Build - extends Module::Build to build/install/configure entire applications (i.e. web applications), not just modules and programs

=head1 SYNOPSIS

  This module is used within a Build.PL script directly or
  it can be subclassed to provide extra capabilities.

  use App::Build;

  my $build = App::Build->new (
      dist_name         => "App-Build-Foo",
      dist_version      => "1.0",
      dist_author       => "stephen.adkins\@officevision.com",
      extra_dirs        => [ "htdocs", "cgi-bin", "etc", "var" ],
      license           => "perl",
      build_requires => {
          "App::Build"  => 0,  # needed for installing the software
      },
  );
  
  $build->create_build_script;

=head1 DESCRIPTION

App::Build is a subclass of Module::Build, so you can use
it in place of Module::Build when creating your "Build.PL"
installation scripts.

Module::Build is good at
installing perl modules and programs/scripts.  Full applications
(i.e. web applications) need to install other files such as
web pages, images, CSS style sheets, javascript files,
CGI programs, data files, and configuration data.
App::Build addresses these issues.

The vision of App::Build is to make installing entirely
functional perl applications (particularly web applications)
as easy as installing individual modules from CPAN.

An ISP customer (or other unprivileged user)
who has shell access should be able to install any number
of available applications from CPAN simply by typing the
usual

  perl -MCPAN -e "install App::Build::Foo"

and the "Foo" application is installed on his account.

App::Build does this by implementing the following features.

1. Distributions that use App::Build instead of Module::Build
can easily install files to other places, besides just
"lib" and "bin".  e.g. "htdocs", "cgi-bin", "etc".
(see the "extra_dirs" argument in the example in the Synopsis
above)

2. App::Build also adds a hook into the "install" action to
call the "configure()" method.  If you are subclassing
App::Build, you can override this method and perform
customized configuration tasks.

=head1 INCLUDED APPLICATIONS AND EXTERNAL APPLICATIONS

Although the distribution primarily supports the deployment
of an application whose files are included in the distribution,
it also supports deployment of applications which are not
included or are not on CPAN at all.

Anyone who finds a useful perl application somewhere 
(i.e. "Foo") can write a small perl distribution called
App-Build-Foo and upload it to CPAN.
When someone uses the CPAN shell, they can install the
application simply by typing

 install App::Build::Foo

Within the App-Build-Foo distribution would be a module,
App::Build::Foo, which would be a subclass of App::Build.
It would contain any specific logic necessary to download
and install the Foo application.

All applications installed with App::Build (and its
derivatives) should conform to a set of standards (see
below) so that when multiple applications are installed,
they are integrated seamlessly and work side by side.

=head1 APPLICATION INSTALLATION REQUIREMENTS

The following are the requirements of all App::Build
installations.

 * The installation MUST be useful to ISP's (internet
   service providers) and ASP's (application service
   providers) such that the software is installed
   in such a way that each customer of theirs may use
   it without any interactions with other customers.

 * The installation SHOULD allow for multiple versions
   even for an unprivileged user (an ISP/ASP customer).
   This allows a user to install a new version of an
   application and evaluate it and run it in parallel
   with an existing version of the application.

=head1 APPLICATION INSTALLATION STANDARDS

The following are additional standards of all App::Build
installations.

 * TBD

=head1 App::Build CONFIGURABILITY

Since App::Build uses App::Options, App::Options makes all the
of the --var=value options available via the global %App::options hash.
App::Build however does not remove the --var=value options from @ARGV.

This will be put to good use sometime in the future.

=head1 FIX-UPS

Module::Build complains if the PREFIX environment variable is
set.  App::Build doesn't.  It just ignores it.

The CPAN shell (for some reason I don't understand) runs Build.PL
as "perl Build.PL Build" and this fails.
App::Build just throws away the "Build" so that the default "build"
action is invoked.

Module::Build deprecated the PREFIX option to Makefile.PL
(i.e. "perl Makefile.PL PREFIX=/usr/foo").  App::Build just makes
the PREFIX option a synonym for "install_base", which does
essentially the same thing.

=cut

delete $ENV{PREFIX};   # Module::Build protests if this var is set

# Enable the continued use of the PREFIX=$PREFIX option
# (from Makefile.PL and ExtUtils::MakeMaker) by making it
# an alias for the "install_base" option of Module::Build.

######################################################################
# BUILD: enhancements to "perl Build.PL"
######################################################################

=head1 METHODS

The documentation of the methods below is not for users of the
App::Build module (who are writing Build.PL scripts), but for people
interested in the internals of how App::Build extends Module::Build.

It is also so that I can remember what I was doing so that if the
internals of Module::Build change, I can maintain this code.

=head2 new()

We override the new() method in order to enhance the install paths.

In the future, we may also download and unpack external perl 
distributions.

=cut

sub new {
    my ($class, %args) = @_;
    my $obj = $class->SUPER::new(%args);

    $obj->_enhance_install_paths() if $obj->_prefix;
    $obj->_get_supporting_software();

    return($obj);
}

=head2 read_config()

Overridden to transparently call C<_enhance_install_paths()>.

=cut

sub read_config {
    my ($self) = @_;

    $self->SUPER::read_config();
    $self->_enhance_install_paths() if $self->_prefix;
}

=head2 install_base()

Overridden to transparently call C<_enhance_install_paths()>.

=cut

sub install_base {
    my ($self, @args) = @_;

    my $ret = $self->SUPER::install_base(@args);
    $self->_enhance_install_paths() if $self->_prefix;

    return $ret;
}

=head2 _get_supporting_software()

Downloads supporting software (if necessary), unpacks it, compiles it,
and installs it.

=cut

sub _get_supporting_software {
    my ($self) = @_;

    my $tag = $self->_app_tag();

    my $url  = $App::options{"$tag.url"};   # check to see if there was software to download
    if ($url) {
        my $file = $App::options{"$tag.file"};
        if (!$file) {
            $file = $url;
            $file =~ s!.*/!!;
        }
        ($file) || die "File [$tag.file] does not exist";

        my $subdir = $App::options{"$tag.subdir"};
        if (!$subdir) {
            $subdir = $file;
            $subdir =~ s!\.tar.gz$!!;
            $subdir =~ s!\.tgz$!!;
        }
        ($subdir) || die "Subdir [$tag.subdir] does not exist";

        my $archive_dir = $App::options{archive_dir} || "archive";
        mkdir($archive_dir) if (! -d $archive_dir);

        my $archive = "$archive_dir/$file";

        (-d $archive_dir) || die "Archive Directory [$archive_dir] does not exist";
        (-w $archive_dir) || die "Archive Directory [$archive_dir] not writeable";

        $self->mirror($url, $archive);
        $self->unpack($archive, "unpack", $subdir);
    }
}

=head2 _app_tag()

This lowercase-ifies the dist_name, removes "app-build-" from the front,
and returns it as the "application tag".
Therefore, a distribution called "App-Build-Kwiki" would have an
"app_tag" of "kwiki".  An "app_tag" is used for looking up configuration
settings in the %App::options hash produced by App::Options.

=cut

sub _app_tag {
    my ($self) = @_;
    my $dist_name = $self->dist_name();
    my $tag = lc($dist_name);
    $tag =~ s/^app-build-//;
    return($tag);
}

=head2 _prefix()

This returns the "install_base" property if it was supplied on the command
line. i.e.

   perl Build.PL install_base=/usr/mycompany/prod

or (synonymously) ...

   perl Build.PL PREFIX=/usr/mycompany/prod

If the install_base was not supplied, the "prefix" out of perl's own
Config.pm is returned.  So if perl is installed in "/usr/local/bin", then
"/usr/local" is returned.
If perl is installed in "/usr/bin", then "/usr" is returned.

=cut

sub _prefix {
    my ($self) = @_;
    my $prefix = $self->{properties}{install_base} || $self->{config}{prefix};
    return($prefix);
}

=head2 _enhance_install_paths()

The install_sets (core, site, vendor) as set from values in perl's own
Config.pm are enhanced to include the absolute directories in which
the extra_dirs will be installed.

=cut

sub _enhance_install_paths {
    my ($self) = @_;
    my $properties = $self->{properties};
    my $install_sets = $properties->{install_sets};
    my @extra_dirs = $self->_get_extra_dirs();
    my $prefix = $self->_prefix();
    my $tag = $self->_app_tag();
    my ($path);
    foreach my $dir (@extra_dirs) {
        $path = $App::options{"$tag.$dir.dir"} || File::Spec->catdir($prefix, $dir);
        $install_sets->{core}{$dir}   = $path;
        $install_sets->{site}{$dir}   = $path;
        $install_sets->{vendor}{$dir} = $path;
    }
}

######################################################################
# BUILD: enhancements to "./Build"
######################################################################

=head2 ACTION_code()

We override ACTION_code() to copy additional directories of files
needed to install the application.

When you invoke "./Build", the method $self->ACTION_build() gets
called on this object.  This, in turn, calls $self->ACTION_code()
and $self->ACTION_docs().  Each of these methods copies files into
the "blib" subdirectory in preparation for installation.

=cut

sub ACTION_code {
    my ($self) = @_;
    $self->SUPER::ACTION_code(); # call this first (creates "blib" dir if necessary)
    $self->process_app_files();  # NEW. call this to copy "extra_dirs" to "blib"
}

=head2 _added_to_INC()

We override this method to ensure that "lib" (libraries to be installed)
is added to the front of @INC.
This is because we often want to use the (latest) enclosed module as
the installing module, even if it has already been installed.

=cut

sub _added_to_INC {
  my $self = shift;
  my %seen;
  $seen{$_}++ foreach $self->_default_INC;
  unshift(@INC,"lib");
  return grep !$seen{$_}++, @INC;
}

=head2 _get_extra_dirs()

Gets the list of extra_dirs to be installed.

The extra_dirs may be specified in the Build.PL in
a variety of ways.
It can be a scalar (comma-separated list of directories),
an array ref of directories, or a hash ref where the
keys are the directories.

If extra_dirs is specified with a hash ref, the hash values
are hashrefs of attributes. i.e.

   extra_dirs => {
       var => {
           dest_dir => "var",
       },
       htdocs => {
           dest_dir => "htdocs",
       },
       "cgi-bin" => {  # any dir ending in "bin" contains executable scripts
           dest_dir => "cgi-bin",
       },
       support => {
           dest_dir => "support",
           executable => 1,  # treat contents as executable scripts
       },
   },

So far, only the "dest_dir" attribute is defined.  The "dest_dir" attribute
can be overridden using the "--install_path" parameter.

=cut

sub _get_extra_dirs {
    my ($self) = @_;
    my $properties = $self->{properties};
    my @extra_dirs = ();
    if ($properties->{extra_dirs}) {
        if (ref($properties->{extra_dirs}) eq "ARRAY") {
             @extra_dirs = @{$properties->{extra_dirs}};
        }
        elsif (ref($properties->{extra_dirs}) eq "HASH") {
             @extra_dirs = (sort keys %{$properties->{extra_dirs}});
        }
        elsif (ref($properties->{extra_dirs})) {
             die "extra_dirs can be a scalar, array ref, or hash ref, but not " . ref($properties->{extra_dirs});
        }
        else {
             @extra_dirs = split(/,/,$properties->{extra_dirs});
        }
    }
    return(@extra_dirs);
}

=head2 _get_extra_dirs_attributes()

Gets the hash of all extra_dirs attributes.

=cut

sub _get_extra_dirs_attributes {
    my ($self) = @_;
    my $properties = $self->{properties};
    my @extra_dirs = ();
    my ($extra_dirs);
    if ($properties->{extra_dirs}) {
        if (ref($properties->{extra_dirs}) eq "ARRAY") {
             @extra_dirs = @{$properties->{extra_dirs}};
             $extra_dirs = { map { $_ => { dest_dir => $_ } } @extra_dirs };
        }
        elsif (ref($properties->{extra_dirs}) eq "HASH") {
             @extra_dirs = (sort keys %{$properties->{extra_dirs}});
             $extra_dirs = $properties->{extra_dirs};
        }
        elsif (ref($properties->{extra_dirs})) {
             die "extra_dirs can be a scalar, array ref, or hash ref, but not " . ref($properties->{extra_dirs});
        }
        else {
             @extra_dirs = split(/,/,$properties->{extra_dirs});
             $extra_dirs = { map { $_ => { dest_dir => $_ } } @extra_dirs };
        }
        foreach my $dir (@extra_dirs) {
            $extra_dirs->{$dir}{dest_dir} = $self->install_path($dir)
              if $self->install_path($dir);
            $extra_dirs->{$dir}{dest_dir} = $dir if (!$extra_dirs->{$dir}{dest_dir});
        }
    }
    return($extra_dirs);
}

=head2 process_app_files()

During "./Build" (which calls ACTION_code()), the process_app_files()
method copies files from the extra_dirs to their appropriate
locations under "blib".

=cut

sub process_app_files {
    my ($self) = @_;
    my ($path, $files);

    my @extra_dirs = $self->_get_extra_dirs();
    my $extra_dirs = $self->_get_extra_dirs_attributes();

    my $blib = $self->blib;
    my ($contains_executables, $result, $target_file);
    foreach my $dir (@extra_dirs) {
        if (-d $dir) {
            $contains_executables = $extra_dirs->{$dir}{executable};
            $contains_executables = ($dir =~ /bin$/) ? 1 : 0 if (!defined $contains_executables);
            $path = File::Spec->catfile($blib, $dir), 
            File::Path::mkpath($path);
            $files = $self->_find_all_files($dir);
            my ($should_be_executable);
            while (my ($file, $dest) = each %$files) {
                $target_file = File::Spec->catfile($blib, $dest);
                $result = $self->copy_if_modified(from => $file, to => $target_file) || "";
                if ($result && $contains_executables) {
                    $self->fix_shebang_line($result);
                    $self->make_executable($result)
                      if $self->_should_be_executable($result);
                }
            }
        }
    }
}

sub _should_be_executable {
    my ($self, $file) = @_;

    # copied from Module::Build::Base::fix_shebang_line
    my $FIXIN = IO::File->new($file) or die "Can't process '$file': $!";
    local $/ = "\n";
    chomp(my $line = <$FIXIN>);
    if ($line =~ /^\s*\#!\s*/) {
        return 1;
    } else {
        return 0;
    }
}

=head2 _find_all_files()

This is used by process_app_files() to get the list of files under "extra_dirs"
to copy to "blib".

=cut

sub _find_all_files {
    my ($self, $dir) = @_;
    return {} unless -d $dir;
    return { map { $_, $_ } @{ $self->rscan_dir($dir, sub { -f $_ }) } };
}

=head2 rscan_dir()

Don't include CVS, RCS, and SVN (*/.svn/*) files.

=cut

sub rscan_dir {
    my ($self, $dir, $pattern) = @_;
    my $files = $self->SUPER::rscan_dir($dir, $pattern);
    my @files = grep(!/[\/\\](CVS|RCS|\.svn)[\/\\]/, @$files);
    return \@files;
}

######################################################################
# INSTALL: enhancements to "./Build install"
######################################################################

=head2 packlist()

This creates the name of the "packlist" file that needs to be
written with the list of all of the files that get installed.

=cut

sub packlist {
    my ($self) = @_;
    # Write the packlist into the same place as ExtUtils::MakeMaker.
    my $archdir = $self->install_destination('arch');
    my @ext = $self->module_name ? split /::/, $self->module_name :
                                   $self->dist_name;
    my $packlist = File::Spec->catfile($archdir, 'auto', @ext, '.packlist');
    return($packlist);
}

=head2 install_map()

This method is only overridden in order to put in the fix so
that it creates a .packlist based on dist_name if the module_name
is not specified.

=cut

sub install_map {
  my ($self, $blib) = @_;
  $blib ||= $self->blib;

  my %map;
  foreach my $type ($self->install_types) {
    my $localdir = File::Spec->catdir( $blib, $type );
    next unless -e $localdir;

    if (my $dest = $self->install_destination($type)) {
      # thins alters the behavious of Module::Build, and
      # looks into the implementation
      if (   $self->install_path($type)
          && !File::Spec->file_name_is_absolute($dest)) {
        $dest = File::Spec->catdir( $self->_prefix, $dest );
      }
      $map{$localdir} = $dest;
    } else {
      # Platforms like Win32, MacOS, etc. may not build man pages
      die "Can't figure out where to install things of type '$type'"
        unless $type =~ /^(lib|bin)doc$/;
    }
  }

  my $extra_dirs_attrs = $self->_get_extra_dirs_attributes();
  foreach my $dir ( $self->_get_extra_dirs() ) {
    my $dest = $extra_dirs_attrs->{$dir}{dest_dir};
    if (!File::Spec->file_name_is_absolute($dest)) {
      $dest = File::Spec->catdir( $self->_prefix, $dest );
    }
    $map{File::Spec->catdir( $blib, $dir )} = $dest;
  }

  if ($self->create_packlist) {
    $map{write} = $self->packlist();
  }

  if (length(my $destdir = $self->{properties}{destdir} || '')) {
    foreach (keys %map) {
      # Need to remove volume from $map{$_} using splitpath, or else
      # we'll create something crazy like C:\Foo\Bar\E:\Baz\Quux
      my ($volume, $path) = File::Spec->splitpath( $map{$_}, 1 );
      $map{$_} = File::Spec->catdir($destdir, $path);
    }
  }

  $map{read} = '';  # To keep ExtUtils::Install quiet

  return \%map;
}

=head2 has_config_data()

No. We're not using config data.
Always return FALSE.

=cut

sub has_config_data {
    my ($self) = @_;
    return(0);
}

=head2 ACTION_install()

This method is overridden to put in the configure() hook so that
a module which extends App::Build can implement the configure()
method.  Then the configure() method will run when 
"./Build install" is invoked.

=cut

sub ACTION_install {
    my ($self) = @_;
    require ExtUtils::Install;
    $self->depends_on('build');
    my $map = $self->install_map;
    ExtUtils::Install::install($map, 1, 0, $self->{args}{uninst}||0);
    $self->perllocal_install();
    $self->configure();
}

=head2 perllocal_install()

This method should be modelled after ExtUtils::Command::MM::perllocal_install
so that it writes the same information at MakeMaker does.

It currently is a stub, waiting to be implemented

=cut

sub perllocal_install {
    my ($self) = @_;
    # Not yet implemented.
}

=head2 configure()

Do nothing.  This method is a hook that can be overridden by a 
subclass of App::Build.
The idea is that after installing files, you might need to run additional
code to configure the application.

=cut

sub configure {
    my ($self) = @_;
    # Do nothing.  This is a hook for overriding in a subclass.
}

=head2 mirror()

    * Signature: $build->mirror($url, $file);
    * Param:  $url          string
    * Param:  $file         string

TODO: Should be rewritten to use cross-platform, pure-perl.

=cut

sub mirror {
    my ($self, $url, $file) = @_;
    if (! -f $file) {
        $self->log_info("Mirroring $url to $file\n");
        require File::Fetch;
        my $ff = File::Fetch->new(uri => $url);
        my $where = $ff->fetch(to => File::Basename::dirname($file));
        if($where) {
            rename($where, $file);
        }
    }
    else {
        $self->log_info("Mirrored file $file up to date\n");
    }
}

=head2 unpack()

    * Signature: $build->unpack($archive_file, $directory, $subdir);
    * Param:  $archive_file string
    * Param:  $directory    string
    * Param:  $subdir       string

TODO: Should be rewritten to use cross-platform, pure-perl.

=cut

sub unpack {
    my ($self, $archive_file, $directory, $subdir) = @_;
    require Archive::Extract;
    $directory ||= "$App::options{install_prefix}/src";
    mkdir($directory) if (! -d $directory);
    die "Directory $directory does not exist and can't be created" if (! -d $directory);

    if (! File::Spec->file_name_is_absolute($archive_file)) {
        $archive_file = File::Spec->catfile(Cwd::getcwd(), $archive_file);
    }
    $subdir = File::Spec->catdir($directory, $subdir);

    if ($subdir && -d $subdir) {
        $self->log_info("Removing preexisting directory $subdir ...\n");
        File::Path::rmtree($subdir);
    }
    $self->log_info("Unpacking $archive_file ...\n");

    my $ae = Archive::Extract->new(archive => $archive_file);
    my $ok = $ae->extract(to => $directory) or die $ae->error;

    die "Subdirectory $subdir not created" if (! -d $subdir);
}

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <stephen.adkins@officevision.com>
 * Maintainer: Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SOURCES

The latest sources can be found on GitHub at
L<http://github.com/mbarbon/app-build/tree>

=head1 SEE ALSO

=cut

1;

__END__

