package App::Install;

use warnings;
use strict;

use Cwd;
use File::Path qw(mkpath);
use File::ShareDir qw(module_dir);
use Text::Template;

=head1 NAME

App::Install - Install applications

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

our %files;
our %permissions;
our @delimiters = ('{{{', '}}}');

=head1 SYNOPSIS

    # In YourApp::Install:

    package YourApp::Install;
    use base qw(App::Install);

    __PACKAGE__->files(%files);
    __PACKAGE__->permissions(%permissions);
    __PACKAGE__->delimiters($start, $end);

    # In a yourapp-install script:

    use YourApp::Install;

    # you can optionally set files() and permissions() here too

    YourApp::Install->install(
        install_dir  => $install_dir,
        template_dir => $template_dir,
        data         => \%data,
    );

=head1 WARNING

This module is in its early days, and the interface is subject to
change.  If you're using it, please let me know and I'll try and tell
you if I'm going to break anything.

=head1 DESCRIPTION

This is easiest to do by analogy.  Have you ever used any of the
following?

    module-starter
    catalyst.pl
    kwiki-install
    minimvc-install

Each of these scripts comes packaged with its respective distro
(Module::Starter, Catalyst::Helper, Kwiki, and MasonX::MiniMVC
respectively) and is used to install an application or create a
framework, stub, or starting point for your own application.

If you're not familiar with any of those modules and their installers,
imagine a theoretical module Foo::Bar, providing some kind of CGI
application,  which comes with a foo-install script.  When you run
foo-install, it creates a directory structure like this:

    foo.cgi
    lib/
    lib/Foo/Local.pm
    t/
    t/foo_local.t

You can then adapt foo.cgi and the other provided files to suit your
specific needs.

Well, App::Install is a generic tool for creating installers like
those described above.

=head1 Using App::Install

=head2 Subclassing App::Install

App::Install is used by subclassing it.  In YourApp::Install, you'll
put:

    package YourApp::Install;
    use base qw(App::Install);

=head2 Specify files to install

Next, specify the files you want to install:

    YourApp::Install->files(
        'relative/file/location' => 'some_template.pl',
        'some/other/location'    => 'other_template.pl',
    );

You can do this either in YourApp/Install.pm or in your install script.

File locations are relative to the base directory the user's installing
into.  Using the Foo::Bar example given above, you might have:

    Foo::Bar::Install->files(
        'foo.cgi'          => 'foo_cgi.tmpl',
        'lib/Foo/Local.pm' => 'local_pm.tmpl',
        't/foo_local.t'    => 'local_test.tmpl',
    );

You need to include your input template files in the C<share> directory
of your module distribution.  If you're using Module::Build, this
typically means creating a directory called C<share/> at the top level
of your distro, and everything will be magically installed in the right
place.  App::Install uses File::ShareDir to determine the location of
your app's share directory after it's installed.

To put your files into a share directory in the first place:

=over 4

=item Using Module::Build

If your templates can be found under C<blib/lib/auto/YourApp/Install>,
they'll be installed into a directory which File::ShareDir can find.
You need to put them into that blib directory by putting something like
this in your Build.PL:

    # near the top of the Build.PL
    my $build_class = 'Module::Build';
    $build_class = $build_class->subclass(code => <<'HERE'
    sub process_install_files {
        system("mkdir -p blib/lib/auto/YourApp/Install");
        system("cp -r share/* blib/lib/auto/YourApp/Install");
    }
    HERE
    );

    # near the bottom of the Build.PL, just above create_build_script()
    $builder->add_build_element('install');

The MasonX::MiniMVC distribution provides an example of this.

=item Using Module::Install

Create a directory called C<share> in the same directory as C<Makefile.PL> and
put your templates in it.  Then add the following line to your
C<Makefile.PL>:

    install_share;

The File::ShareDir distribution provides an example of this.

=item Using ExtUtils::MakeMaker

Unknown; you'll want something similar to the technique outlined for
Module::Build, above.  Documentation patches welcome.

=back

=head2 Setting permissions

Permissions for the installed files are set as follows:

    Foo::Bar::Install->permissions(
        'foo.cgi' => 0755,
    );

You'll generally do this straight after listing the files to install.

Only non-default permissions need to be specified; the default will be
whatever your system generally creates files as, eg. 0644 for readable
by everyone, writable by owner.  See the docs for C<chmod()> for more
information.

=head2 Including variable data in your files

If you wish data to be interpolated into your inline files -- and you
probably do -- this is done using Text::Template.  In its simplest form,
simply put anything you wish to have interpolated in triple curly braces:

    package {{{$app_name}}};

The delimiters -- C<{{{> and C<}}}> have been chosen for their
unlikelihood of showing up in real Perl code.  If for some reason this
doesn't suit you, you can change the delimiters in YourApp::Install as
follows:

    YourApp::Install->delimiters($start, $end);

To actually create an installer script, simply write something like:

    use YourApp::Install;

    # Pick up options from the command line or elsewhere, if desired
    # eg. the application name, email, etc.

    # If for some reason you prefer to set up the files and permissions
    # here, that will also work.  You might want to do that if the
    # installation varies depending on command line options or
    # configuration options.

    YourApp::Install->install(
        template_dir => $template_dir,
        install_dir  => $install_dir,
        data => \%data,
    );

The template directory defaults to your distribution's C<share>
directory (see L<File::ShareDir>).

The installation directory defaults to the current working directory.

The data hashref will be passed to Text::Template for interpolation into
the files.

=head1 PUBLIC METHODS

=head2 files()

Set a list of files to install.

=cut

sub files {
    my ($class, %files) = @_;
    %App::Install::files = %files;
}

=head2 permissions

Set the permissions for files.

=cut

sub permissions {
    my ($class, %permissions) = @_;
    %App::Install::permissions = %permissions;
}

=head2 delimiters()

Change the delimiters used by the templating system.

=cut

sub delimiters {
    my ($class, $start, $end) = @_;
    @App::Install::delimiters = ($start, $end);
}

=head2 install()

Do it!

=cut

sub install {
    my ($class, %options) = @_;
    $class->_check_empty_dir($options{install_dir} || getcwd());
    $class->_write_files(%options);
}

sub _check_empty_dir {
    my ($class, $dir) = @_;

    opendir DIR, $dir or die "Can't open current directory to check if it's empty: $!\n";
    my @files = grep !/^\.+$/, readdir(DIR);
    closedir DIR;

    if (@files) {
        die "Directory isn't empty.  Remove files and try again.\n";
    }
}

sub _write_files {
    my ($class, %options) = @_;

    my $install_dir  = $options{install_dir}  || getcwd();
    my $template_dir = $options{template_dir} || module_dir($class);
    my $data         = $options{data};

    my %files = %App::Install::files;

    print "Running install from $class...\n";
    print "Creating file structure...\n";

    $DB::single = 1;
    foreach my $file ( sort keys %files) {
        my $template = _load_template($template_dir, $files{$file});
        my $content  = _fill_template($template, $data);

        if ($content) {
            my $outfile = ("$install_dir/$file");
            _check_subdir($outfile);
            _print_to_file($outfile, $content);
            _set_permissions($file) if $App::Install::permissions{$file};
        } else {
            warn "Couldn't get content for file $file}\n";
        }
    }
}

sub _load_template {
    my ($dir, $file) = @_;
    my $template_file = "$dir/$file";
    open my $ifh, '<', $template_file
        or warn "Can't open input file $template_file: $!\n";
    $/ = undef;
    my $template = <$ifh>;
    close $ifh;

    return $template;
}

sub _fill_template {
    my ($content, $data) = @_;
    my $template = Text::Template->new(
            TYPE       => 'STRING',
            SOURCE     => $content,
            DELIMITERS => \@App::Install::delimiters,
        );
    return $template->fill_in(HASH => $data);
}

sub _check_subdir {
    my ($outfile) = @_;
    my $subdir = $outfile;
    $subdir =~ s/[^\/]+$//; # strip trailing filename
    unless (-e $subdir) {
        unless (mkpath $subdir) {
            warn "Can't make subdirectory $subdir: $!\n";
        }
    }
}

sub _print_to_file {
    my ($outfile, $content) = @_;
    if (open my $ofh, '>', $outfile) {
        print $ofh $content;
        close $ofh;
        print "  $outfile\n";
    } else {
        warn "Couldn't open $outfile} to write: $!\n";
    }
}

sub _set_permissions {
    my ($file) = @_;
    return unless $file;
    printf "    Setting permissions for %s to %lo\n", $file, $App::Install::permissions{$file};
    chmod $App::Install::permissions{$file}, $file;
}

=head1 AUTHOR

Kirrily "Skud" Robert, C<< <skud at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-install at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Install>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Install

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Install>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Install>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Install>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Install>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Kirrily "Skud" Robert, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
