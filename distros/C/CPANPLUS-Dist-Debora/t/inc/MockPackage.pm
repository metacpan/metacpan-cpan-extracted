package MockPackage;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = '1.000';

use parent qw(Test::MockObject::Extends);

use Carp qw(croak);
use Config;
use English qw(-no_match_vars);
use File::Path qw(make_path);
use File::Spec::Functions qw(catdir catfile splitpath);

sub new {
    my ($class, $package) = @_;

    _populate_stagingdir($package->stagingdir, $package->dist_name);

    my $self = $class->SUPER::new($package)
        ->set_false('rpm_cmd');

    return $self;
}

1;

sub _populate_directory {
    my ($dir, @files) = @_;

    for my $entry (@files) {
        my $path = $entry->{path};

        my ($volume, $dirs, $file) = splitpath($path);
        my $fulldir  = catdir($dir, $dirs);
        my $fullpath = catfile($dir, $dirs, $file);

        make_path($fulldir);

        if ($file) {
            open my $fh, '>:encoding(UTF-8)', $fullpath
                or croak "Cannot create '$fullpath': $OS_ERROR";
            if (exists $entry->{text}) {
                print {$fh} $entry->{text} or croak;
            }
            close $fh or croak;
        }
    }

    return;
}

sub _populate_stagingdir {
    my ($stagingdir, $dist_name) = @_;

    my @path = split qr{-}xms, $dist_name;

    my $datadir       = catdir($Config{vendorprefix}, 'share');
    my $archlibdir    = $Config{installarchlib};
    my $vendorarchdir = $Config{installvendorarch};
    my $vendorlibdir  = $Config{installvendorlib};
    my $vendorman3dir = $Config{installvendorman3dir}
        || catdir($datadir, 'man', 'man3');

    my @stagingfiles = (
        {path => catfile($archlibdir,    'perllocal.pod')},
        {path => catfile($vendorarchdir, 'auto', @path, '.packlist')},
        {path => catfile($vendorlibdir,  @path) . '.pm'},
        {path => catfile($vendorman3dir, $dist_name . '.3pm')},    # No colons!
    );

    _populate_directory($stagingdir, @stagingfiles);

    return;
}

1;
