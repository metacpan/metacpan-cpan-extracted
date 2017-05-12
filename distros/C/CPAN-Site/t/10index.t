#!/usr/bin/env perl
# CPAN-Site-Index.t - unit tests for CPAN::Site::Index
#-------------------------------------------------------------------------------
$^W = 0;
use strict;
use warnings;
use FindBin qw($Bin);
use Test::More tests => 60;

use_ok('CPAN::Site::Index');

test_inspect_archive_for_distro_with_strange_data();
test_inspect_archive_for_distro_with_packages_that_should_not_be_registered();
test_inspect_archive_for_distro_with_module_with_multiple_packages();

exit;

#-------------------------------------------------------------------------------

sub test_inspect_archive_for_distro_with_strange_data {
    my $distro_to_test = 'Text-PDF-0.29a.tar.gz';
    my %want_packages  = (
        'Text::PDF::Array'           => undef,
        'Text::PDF::Bool'            => undef,
        'Text::PDF::Dict'            => undef,
        'Text::PDF::File'            => '0.27',
        'Text::PDF::Filter'          => undef,
        'Text::PDF::ASCII85Decode'   => undef,
        'Text::PDF::RunLengthDecode' => undef,
        'Text::PDF::ASCIIHexDecode'  => undef,
        'Text::PDF::FlateDecode'     => undef,
        'Text::PDF::LZWDecode'       => undef,
        'Text::PDF::Name'            => undef,
        'Text::PDF::Null'            => undef,
        'Text::PDF::Number'          => undef,
        'Text::PDF::Objind'          => undef,
        'Text::PDF::Page'            => undef,
        'Text::PDF::Pages'           => undef,
        'Text::PDF::SFont'           => undef,
        'Text::PDF::String'          => undef,
        'Text::PDF::TTFont'          => undef,
        'Text::PDF::TTIOString'      => undef,
        'Text::PDF::TTFont0'         => undef,
        'Text::PDF::Utils'           => undef,
        'Text::PDF'                  => '0.29',
    );
    _test_inspect_archive_for_distro( $distro_to_test, \%want_packages );
}

sub test_inspect_archive_for_distro_with_packages_that_should_not_be_registered {
    my $distro_to_test = 'Distro-With-Packages-Outside-lib.tar.gz';
    my %want_packages  = (
        'TopOfDistro' => '0.01',
        'InsideLib'   => '0.01',
    );
    _test_inspect_archive_for_distro( $distro_to_test, \%want_packages );
}

sub _test_inspect_archive_for_distro {
    my $distro        = shift;
    my $want_packages = shift;

    # inspect_archive() relies upon a global variable $topdir which
    # we is declared with 'our' in Index.pm so we can set it here for testing.
    $CPAN::Site::Index::topdir = "$Bin/test_data";

    # inspect_archive is called in Index.pm using File::Find
    #   find { wanted => \&inspect_archive, no_chdir => 1 }, $topdir;
    # so we set two variables that File::Find normally sets:
    {  no warnings;
       $File::Find::name = "$CPAN::Site::Index::topdir/$distro";
       $File::Find::dir  = $CPAN::Site::Index::topdir;
    }

    $CPAN::Site::Index::findpkgs = {};
    CPAN::Site::Index::inspect_archive();

    my @missing_pkgs = ();
    foreach my $want_pkg ( sort keys %{$want_packages} ) {
        my $have_package = exists $CPAN::Site::Index::findpkgs->{$want_pkg};
        ok( $have_package, "Found package '$want_pkg' in tarball." )
            || push @missing_pkgs, $want_pkg;

    SKIP: {
            skip( "Didn't find '$want_pkg', no point in testing VERSION", 1 )
                unless $have_package;
            my $have_version = $CPAN::Site::Index::findpkgs->{$want_pkg}->[0];
            my $want_version = $want_packages->{$want_pkg};
            is( $have_version, $want_version,
                "Got expected version of $want_pkg" );
        }
    }

    if (@missing_pkgs) {
        diag(
            "Missing packages: @missing_pkgs\n\n",
            'Packages found: ',
            explain($CPAN::Site::Index::findpkgs)
        );
    }

    my @unexpected_packages = ();
    foreach my $got_package ( sort keys %{$CPAN::Site::Index::findpkgs} ) {
        if ( not exists $want_packages->{$got_package} ) {
            push @unexpected_packages, $got_package;
        }
    }
    is( scalar @unexpected_packages,
        0, "No unexpected packages found in $distro" )
        || diag(
        "Got unexpected packages in distro '$distro':\n\t",
        join( "\n\t", @unexpected_packages ),
        );

    #diag Test::More::explain($CPAN::Site::Index::findpkgs);
}

sub test_inspect_archive_for_distro_with_module_with_multiple_packages {      
    my $distro_to_test = 'Distro-With-Multi-Package-Module.tar.gz';           
    my %want_packages  = (                                                    
        'Module::MultiPackage' => '0.01',                                     
        'Module::MultiPackage::SubPackageOne' => '0.011',                     
        'Module::MultiPackage::SubPackageTwo' => '0.012',                     
    );                                                                        
    _test_inspect_archive_for_distro( $distro_to_test, \%want_packages );     
}
