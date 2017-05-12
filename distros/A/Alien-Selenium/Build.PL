#!/usr/bin/perl -w

# This script automatically builds a "Build" file in the current
# directory (using a custom-made subclass to Module::Build), which in
# turn builds the Alien::Selenium package.

use strict;
use FindBin; use lib "$FindBin::Bin/inc";
use My::Module::Build;

require 5.006; # "our"

my $class = My::Module::Build->subclass( code => join('', <DATA>) );
my $build = $class->new
  ( module_name      => 'Alien::Selenium',
    license          => 'perl',
    script_files     => [ qw(bin/selenium_install) ],
    add_to_cleanup   => [ qw(t/sel) ],
    requires         => {
                         'File::Copy'        => 0,
                        },
    build_requires    => {
                         'Test::Builder'     => 0,
                         'Test::More'        => 0,
                         'Archive::Zip'      => 1.00,
                        },
    create_makefile_pl  => 'passthrough',
    );
$build->create_build_script;
warn sprintf("Will build Alien::Selenium with selenium version %s\n",
             $build->option_value("selenium_version"));

__END__

=head1 DESCRIPTION

This is a custom-made subclass to My::Module::Build that knows how to
build Alien::Selenium.  Its package name is a nonce chosen by
L<Module::Build>.

=cut

use strict;
use base qw(My::Module::Build);


=head1 COMMAND-LINE OPTIONS

=head2 --selenium-version <version>

The Selenium version that one wishes to package.  By default, will use
whatever is the current value of the variable $SELENIUM_VERSION in
L<Alien::Selenium>'s source code.

=cut

sub selenium_version : Config_Option(type="string") {
    # Warning, single quotes don't work in the Win32 shell, see RT #28048
    my $version = `$^X -Ilib -MAlien::Selenium -e "print Alien::Selenium->version"`;
    die "Problem invoking Alien::Selenium in a sub-Perl" if $?;
    chomp($version);
    return (default => $version);
}

=head1 INTERNAL METHODS

=cut

use File::Path qw(mkpath rmtree);
use File::Basename qw(basename);
use File::Spec::Functions qw(catdir catfile);
use Fatal qw(mkdir);

=head2 ACTION_code

Overloaded from L<Module::Build> so as to also L</fetch_selenium>,
L</extract_selenium> and/or L</install_selenium>.

=cut

sub ACTION_code {
    my $self = shift;

    $self->SUPER::ACTION_code;
    $self->fetch_selenium;
    $self->extract_selenium;
    $self->install_selenium;
}

=head2 process_pm_files

Overloaded from parent class so as to reserve a special treatment to
L<Alien::Selenium>; namely, the value of $SELENIUM_VERSION is changed
in place to reflect that of the L<--selenium-version> command-line
switch.

=cut

sub process_pm_files {
    my ($self) = @_;
    $self->SUPER::process_pm_files(@_);

    my $from = catfile(qw(lib Alien Selenium.pm));
    my $todir = catdir(qw(blib lib Alien));
    unless (-d $todir) {
        mkpath($todir) or die "Cannot create path $todir: $!";
    }
    my $tofile = catfile($todir, "Selenium.pm");
    unlink($tofile);
    my $infd = new IO::File($from, "<") or
        die "Cannot open $from for reading: $!";
    my $text = join('', <$infd>);
    $infd->close();

    my $version = $self->option_value("selenium_version");
    $text =~ s|^our.*\$SELENIUM_VERSION.*$|our \$SELENIUM_VERSION = '$version';|m;

    my $outfd = new IO::File($tofile, ">") or
        die "Cannot open $tofile for writing: $!";
    ($outfd->print($text) &&
     $outfd->close()) or
         die "Cannot write to $tofile: $!\n";

}


=head2 fetch_selenium

As the name implies, fetches Selenium over the interweb.  Does nothing
if the Selenium zipball is already here.

=cut

sub fetch_selenium {
    my $self = shift;

    return if -f $self->selenium_archive or -d $self->selenium_directory;
    require File::Fetch;

    printf "Fetching Selenium from %s...\n", $self->selenium_url;

    my $path = File::Fetch->new
      ( uri => $self->selenium_url )->fetch;
    die 'Unable to fetch archive' unless $path;
}

=head2 extract_selenium

Unpacks the Selenium zipball.

=cut

sub extract_selenium {
    my $self = shift;

    my $targetdir = $self->selenium_directory;
    return if -d $targetdir;
    my $selenium_archive = $self->selenium_archive;
    die "$selenium_archive is not present, cannot extract"
        if (! -f $selenium_archive);

    print "Extracting Selenium...\n";

    eval { require Archive::Zip }; die <<"EOT" if $@;
$@

Please either install Archive::Zip or manually extract
the Selenium distribution into $targetdir.

EOT

    my $zip = Archive::Zip->new( $selenium_archive );

    # Some versions of Selenium Core (eg 0.8.3) spill their beans into the
    # current directory, as opposed to using a main directory named after
    # the version number :-(.

    use Cwd qw(getcwd);
    my $origdir = getcwd();
    if (grep { m|^core/?$| } $zip->memberNames()) {
      my $target_dir = $self->selenium_directory;
      mkdir($target_dir) unless -d $target_dir;
      chdir($target_dir);
      # Also, Archive::Zip is stupid.
      $zip = Archive::Zip->new( catfile($origdir, $selenium_archive) );
    }

    $zip->extractTree() == Archive::Zip::AZ_OK() or
        die "Error extracting file $selenium_archive\n";
    chdir($origdir);
    return;
}

=head2 install_selenium

Copies select bits of the unpacked copy of Selenium into blib/lib/, so
that they get embedded into the Alien::Selenium Perl package.

=cut

sub install_selenium {
    my $self = shift;

    print "Installing Selenium...\n";

    my $srcdir = $self->selenium_directory;
    {
        my $selenium_installdir =
            catdir(qw(blib lib Alien Selenium javascript));
        rmtree($selenium_installdir); mkpath($selenium_installdir);

        my @seleniumfiles = grep { -f $_ }
            ( glob(catfile($srcdir, "selenium", "*")),   # Before 0.7.0
              glob(catfile($srcdir, "core",     "*")) ); # After

        foreach my $file ( @seleniumfiles ) {
            my $dest = catfile( $selenium_installdir, basename( $file ) );
            $self->copy_if_modified( from    => $file,
                                     to      => $dest,
                                     verbose => 1,
                                   );
        }
    }

    {
        mkpath ( my $xpi_installdir =
                 catdir(qw(blib lib Alien Selenium xpi)) );
        my @xpifiles = 'readyState.xpi';
        foreach my $file ( @xpifiles ) {
            my $src = catfile ($srcdir, $file);
            warn "Cannot find $file in $srcdir, skipping", next
                if (! -f $src);
            my $dest = catfile ( $xpi_installdir, $file );
            $self->copy_if_modified( from => $src,
                                     to   => $dest,
                                     verbose => 1,
                                   );
        }
    }
}

=head1 UTILITY METHODS

=cut

=head2 selenium_archive_basename()

Returns the basename of the Selenium zipball with version number,
e.g. C<selenium-0.x> or C<selenium-core-0.x>

=cut

sub selenium_archive_basename {
    my ($self) = @_;
    if ($self->option_value("selenium_version") lt '0.7') {
        return 'selenium-' . $self->option_value("selenium_version");
    } else {
        return 'selenium-core-' . $self->option_value("selenium_version");
    }
}

=head2 selenium_archive()

Returns the full name of the Selenium zipball,
e.g. C<selenium-0.x.zip>

=cut

sub selenium_archive {
    my ($self) = @_;
    return $self->selenium_archive_basename . ".zip";
}

=head2 selenium_url()

Returns the URL that we should attempt to fetch the Selenium tarball
from.

=cut

sub selenium_url {
    my ($self) = @_;
    if ($self->option_value("selenium_version") lt '0.7') {
        return 'http://gforge.public.thoughtworks.org/download.php/51/'
            . $self->selenium_archive;
    } else {
        return sprintf('http://release.openqa.org/selenium-core/%s/%s',
                       $self->option_value("selenium_version"),
                       $self->selenium_archive);
    }
}

=head2 selenium_directory()

Returns the directory in which Selenium is (to be) unpacked.  Grovels
around a bit looking for already existing directories, and returns
L</selenium_archive_basename> if none is found.

=cut

sub selenium_directory {
    my ($self) = @_;
    my $version = $self->option_value("selenium_version");
    foreach my $dir ("selenium-core-$version", "selenium-$version",
                     "selenium-$version-stripped") {
        return $dir if -d $dir;
    }

    return $self->selenium_archive_basename;
}

