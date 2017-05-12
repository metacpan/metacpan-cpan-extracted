
use strict;

package                   # thwart the PAUSE indexer
    CAF_MB_Installer;

use base 'Module::Build';
use File::Spec ();
use HTML::Template;
use Cwd;
use File::Path;
use File::Find;
use Carp;


=for comment

This is an attempt to make an installer that handles files not normally
handled by Module::Build:

   caf_cgi_files     # get installed in user's cgi-bin or cgi-sec directory
                     # get shbang line properly set to #!/usr/bin/perl (or local equiv)
                     # are set to be executable
                     # are run through template to localize paths

   caf_htdoc_files   # are installed in subdirectory of user's webroot (e.g. /caf-examples)
                     # are run through template to localize paths

   caf_config_files  # are installed in the project directory
                     # are run through template to localize paths

   caf_img_files     # are installed in images subdirectory of user's webroot (e.g. /caf-examples/images)

   caf_project_files # are installed in project subdirectory of user's webroot (e.g. /caf-examples/images)

   caf_server_files  # installed in caf framework directory.  Also, an an attempt is made
                     # to make these owned by the webserver

=cut


sub caf_add_examples_build_elements {
    my $self = shift;

    $self->add_build_element('caf_cgi');
    $self->add_build_element('caf_htdoc');
    $self->add_build_element('caf_image');
    $self->add_build_element('caf_config');
    $self->add_build_element('caf_project');
    $self->add_build_element('caf_server');
    $self->add_build_element('caf_sql');
}


# Override the install action to also install certain directories
# required by CAF at runtime.  These directories need to be writeable by
# the webserver, so an effort is made to change their ownership

sub ACTION_install {
    my $self = shift;
    $self->SUPER::ACTION_install(@_);

    my $user  = $self->notes('examples_user_num');
    my $group = $self->notes('examples_group_num');

    $self->caf_install_example_files($self->caf_install_map, 1, $user, $group);

    $self->caf_fix_server_directories;
}

sub caf_fix_server_directories {
    my $self = shift;

    # after the regular install has completed,
    # install server directories (relative to destdir)

    return unless $self->notes('install-examples');

    my $verbose = $self->{properties}->{verbose};
    print "Installing Server Paths... \n" if $verbose;

    my @server_paths = (
        $self->notes('path_sqlite'),
        $self->notes('path_weblog'),
        $self->notes('path_session_dir'),
        $self->notes('path_session_locks'),
    );
    my @server_files = (
        $self->notes('file_sqlite_db'),
    );

    my $uid = $self->notes('web_server_user_num');
    my $gid = $self->notes('web_server_group_num');

    my $destdir = $self->{properties}{destdir} || '';

    foreach my $server_path (@server_paths) {

        if ($destdir) {
            # Need to remove volume from $map{$_} using splitpath, or else
            # we'll create something crazy like C:\Foo\Bar\E:\Baz\Quux
            my ($volume, $path) = File::Spec->splitpath( $server_path, 1 );
            $server_path = File::Spec->catdir($destdir, $path);
        }
    }
    foreach my $server_file (@server_files) {

        if ($destdir) {
            # Need to remove volume from $map{$_} using splitpath, or else
            # we'll create something crazy like C:\Foo\Bar\E:\Baz\Quux
            my ($volume, $path, $file) = File::Spec->splitpath( $server_file );
            $server_file = File::Spec->catdir($destdir, $path, $file);
        }
    }

    foreach my $server_path (@server_paths) {
        File::Path::mkpath($server_path, 0, 0777);
    }

    foreach my $server_path (@server_paths, @server_files) {

        # skip chown on Win32 - instead notify the user
        if ($^O =~ /Win32/) {
            print "Make sure this path is writeable by your webserver:\n\t$server_path\n";
            next;
        }

        print "making path writeable by webserver: $server_path\n" if $verbose;
        chown $uid, $gid, $server_path
            or warn "Could not make the following path writeable by the webserver - you'll have to do it manually:\n\t$server_path\n";

        # Make writeable
        my $current_mode = (stat $server_path)[2];
        chmod $current_mode | 0600, $server_path;
    }
}

sub find_caf_cgi_files      {  shift->_find_file_by_type('.*',                'caf_cgi'     ) }
sub find_caf_config_files   {  shift->_find_file_by_type('conf',              'caf_config'  ) }
sub find_caf_htdoc_files    {  shift->_find_file_by_type('(html?)|(css)',     'caf_htdoc'   ) }
sub find_caf_image_files    {  shift->_find_file_by_type('(png)|(jpg)|(gif)', 'caf_image'   ) }
sub find_caf_project_files  {  shift->_find_file_by_type('.*',                'caf_project' ) }
sub find_caf_server_files   {  shift->_find_file_by_type('.*',                'caf_server'  ) }
sub find_caf_sql_files      {  shift->_find_file_by_type('.*',                'caf_sql'     ) }

sub caf_type_is_static {
    my ($self, $ext) = @_;
    return 1 if $ext eq 'caf_project';
    return 1 if $ext eq 'caf_image';
    return 1 if $ext eq 'caf_server';
    return;
}

sub process_files_by_extension {
    my $self  = shift;
    my ($ext) = @_;

    # skip special processing for non-caf
    unless ($ext =~ /^caf_/) {
        return $self->SUPER::process_files_by_extension(@_);
    }

    my $method = "find_${ext}_files";
    my $files = $self->can($method) ? $self->$method() : $self->_find_file_by_type($ext,  'lib');

    while (my ($file, $dest) = each %$files) {

        my $source = $file;
        my $target = File::Spec->catfile($self->blib, $dest);

        return if $self->up_to_date($source, $target);

        # caf_images and caf_project are a simple copy
        if ($self->caf_type_is_static($ext)) {
            $self->copy_if_modified(from => $source, to => $target);
        }
        else {
            # Make parent directory
            File::Path::mkpath(File::Basename::dirname($target), 0, 0777);

            my $template = HTML::Template->new(
                filename          => $source,
                die_on_bad_params => 0,
                filter            => sub {
                    my $text_ref = shift;
                    # Convert !!- var -!! to <TMPL_VAR var>
                    $$text_ref =~ s/!!-\s*(.*?)\s*-!!/<TMPL_VAR "$1">/g;
                },
            );

            my $notes = $self->notes;

            $template->param(%$notes);

            my $output = $template->output;

            open my $fh, '>', $target or die "Can't overwrite target: $!";
            print $fh $output;
            close $fh;

            if ($ext eq 'caf_cgi') {
                $self->fix_shebang_line($target);
                $self->make_executable($target);
            }
        }
    }
}

# caf_install_example_files is adapted from ExtUtils::Install::install,
# with the following changes:
#  - removed all the arcane bits about packlists and archlibs and whatnot
#  - allows you to specify a user and group for ownership of the resulting files and directories
#  - doesn't try to make the files read only - instead it respsects the current user's umask
#    (note that umask might not be correct if the user is installing on behalf of a different user,
#     e.g. a web virtual host user with a restrictive group)
#

sub forceunlink {
    chmod 0666, $_[0];
    unlink $_[0] or Carp::croak("Cannot forceunlink $_[0]: $!")
}

sub caf_install_example_files {
    my ($self,$from_to,$verbose,$user,$group) = @_;

    $verbose ||= 0;

    my $is_vms   = $^O eq 'VMS';

    my $cwd = Cwd::cwd();

    foreach my $source_path (sort keys %$from_to) {

        my $targetroot = $from_to->{$source_path};

        chdir $source_path or next;

        File::Find::find(sub {
            my ($mode,$size,$atime,$mtime) = (stat)[2,7,8,9];
            return unless -f _;

            my $origfile = $_;
            return if $origfile eq ".exists";

            my $targetdir  = File::Spec->catdir(  $targetroot,  $File::Find::dir);
            my $targetfile = File::Spec->catfile( $targetdir,   $origfile);
            my $sourcedir  = File::Spec->catdir(  $source_path, $File::Find::dir);
            my $sourcefile = File::Spec->catfile( $sourcedir,   $origfile);

            my $save_cwd = Cwd::cwd;
            chdir $cwd;  # in case the target is relative
                         # 5.5.3's File::Find missing no_chdir option.

            my $diff = 0;
            if ( -f $targetfile && -s _ == $size) {
                # We have a good chance, we can skip this one
                $diff = File::Compare::compare($sourcefile, $targetfile);
            } else {
                print "$sourcefile differs\n" if $verbose>1;
                $diff++;
            }

            # TODO:
            # currently if the target file is the same as the source file,
            # the file is not installed.
            #
            # However, no check is made to see if the file metadata is wrong.
            # So you can't just run ./Build install to fix broken permissions -
            # you actually have to delete the target files.
            #
            # I'm not sure I understand the reason for the diff check anyway.
            # If the local file is different it is clobbered, so it can't be
            # about preserving local changes.
            #
            # So is it for performance or to conserve resources?  If so,
            # why bother?  This is just an install script that gets run very
            # rarely.  And it's exceptionally rare that the copying is skipped
            # because the files haven't changed.
            #
            # Anyway, for now, we go with the same behaviour that is in
            # ExtUtils::Install, but in the future, we may change.

            if ($diff){
                if (-f $targetfile){
                    forceunlink($targetfile);
                }
                else {
                    File::Path::mkpath($targetdir,0,0755);
                    print "mkpath($targetdir,0,0755)\n" if $verbose>1;

                    if ($user && $group) {
                        chown $user, $group, $targetdir;
                        print "chown($user, $group, $targetdir)\n" if $verbose>1;
                    }
                }
                File::Copy::copy($sourcefile, $targetfile);

                print "Installing $targetfile\n";

                utime($atime,$mtime + $is_vms, $targetfile);

                print "utime($atime,$mtime,$targetfile)\n" if $verbose>1;

                # We don't change the mode of the files, since these are
                # example files and should be installed with permissions
                # that respect the users umask

                # However, if the original file was executable, make
                # the new file executable too

                my $executable = (stat $sourcefile)[2] & 0111;

                if ($executable) {
                    my $mode = (stat $targetfile)[2];
                    $mode = $mode | $executable;
		            chmod $mode, $targetfile;
		            print "chmod($mode, $targetfile)\n" if $verbose>1;
                }

                # MAG - allow changing ownership of installed files
                if ($user && $group) {
                    chown $user, $group, $targetfile;
                    print "chown($user, $group, $targetfile)\n" if $verbose>1;
                }

            }
            else {
                print "Skipping $targetfile (unchanged)\n" if $verbose;
            }

            # File::Find can get confused if you leave the directory it
            # placed you in so we chdir back to the directory it put us in.
            chdir $save_cwd;

        }, File::Spec->curdir);

        # After each copying run, return to the main directory
        chdir($cwd) or Carp::croak("Couldn't chdir to $cwd: $!");
    }

}

# Tell MB where to install our special files
sub caf_install_map {
    my ($self, $blib) = @_;
    $blib ||= $self->blib;

    my %install_map;

    if ($self->notes('install-examples')) {

        my %caf_map = (
            'caf_cgi'     => $self->notes('path_examples_cgi_bin'),
            'caf_htdoc'   => $self->notes('path_examples_htdocs'),
            'caf_image'   => $self->notes('path_examples_images'),
            'caf_config'  => $self->notes('path_projects_dir'),
            'caf_project' => $self->notes('path_projects_dir'),
            'caf_server'  => $self->notes('path_framework_root'),
            'caf_sql'     => $self->notes('path_sql_dir'),
        );

        # Taken directly from Module::Build::Base
        if (length(my $destdir = $self->{properties}{destdir} || '')) {
            foreach (keys %caf_map) {
                # Need to remove volume from $map{$_} using splitpath, or else
                # we'll create something crazy like C:\Foo\Bar\E:\Baz\Quux
                my ($volume, $path) = File::Spec->splitpath( $caf_map{$_}, 1 );
                $caf_map{$_} = File::Spec->catdir($destdir, $path);
            }
        }

        foreach my $dir (keys %caf_map) {
            my $blib_dir = File::Spec->catdir($blib, $dir);
            $install_map{$blib_dir} = $caf_map{$dir};
        }
    }

    return \%install_map;
}

###################################################################
# User input methods
###################################################################
sub prompt {
    my $self   = shift;

    my $value;
    while (1) {
        $value = $self->SUPER::prompt(@_);
        last unless $value =~ /\010/;  # backspace pressed, leaving
                                       # us with some ^H characters, so redo
    };
    return $value;
}

sub multiple_choice {
    my $self = shift;
    my %args = @_;

    # if there is a predefined value, skip the question and return it
    return $args{'pre_defined'} if $args{'pre_defined'};

    my $name     = $args{'question_name'};
    my $preamble = $args{'preamble'};
    my $prompt   = $args{'prompt'};
    my $default  = $args{'default'}  || '';

    my $choices  = $args{'choices'};
    $choices     = [$choices] unless ref $choices eq 'ARRAY';

    # Remove leading whitespace from the preamble text
    if ($preamble) {
        my @lines = split /\r?\n/, $preamble;
        my $whitespace = '';
        foreach my $line (@lines) {
            if (!$whitespace && $line =~ /^(\s*)/) {
                $whitespace = $1;
            }
            $line =~ s/^$whitespace//;
            print $line, "\n";
        }
    }

    my $choice;
    if (@$choices > 1) {
        $prompt ||= "$name (pick a number or type a path)";
        for (my $i = 0; $i < @$choices; $i++) {
            my $item    = $choices->[$i];
            my $num     = $i + 1;
            print " [$num]: $item\n";
        }
        print "\n";


        while (1) {
            $choice = $self->prompt($prompt, $default);
            if ($choice =~ /^\d+$/) {
                $choice -= 1; # make zero based
                redo if $choice < 0 or $choice > (@$choices-1);
                $choice = $choices->[$choice];
            }
            last;
        }
    }
    else {
        $prompt ||= "$name";
        $choice = $self->prompt($prompt, $default);
    }
    $choice ||= $default;
    return $choice;

}

1;


