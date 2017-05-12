#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 4;
use File::Path qw(mkpath rmtree);

use lib qw(t/lib);
use CPANPLUS::Dist::Arch::Test;

my $cda_obj = CPANPLUS::Dist::Arch::Test->new( name    => 'Wheres-Waldo',
                                               version => '0.502' );

sub touch_file
{
    my ($path) = @_;
    open my $touched, '>', $path or die "open: $!";
    close $touched;
}

sub with_tmpfile
{
    my ($path, $code_ref) = @_;

    touch_file( $path );
    $code_ref->();
    unlink $path or die "unlink: $!";
    return;
}

sub test_pkgfile
{
    my ($path, $pkg_type) = @_;
    my $suffix = $path;
    $suffix =~ s/\A.*[.]//;
    with_tmpfile( $path,
                  sub {
                      ok( $cda_obj->_find_built_pkg( $pkg_type, 't/tmp' ),
                          "finds $pkg_type $suffix package file" );
                    }
                 );
    return;
}

mkpath( 't/tmp' );

my $prefix = "t/tmp/perl-wheres-waldo-0.502";

test_pkgfile( "$prefix-1-any.pkg.tar.xz", 'bin' );
test_pkgfile( "$prefix-1-any.pkg.tar.gz", 'bin' );

# I don't think they have .tar.xz source package files, yet... owell.
test_pkgfile( "$prefix-1.src.tar.xz", 'src' );
test_pkgfile( "$prefix-1.src.tar.gz", 'src' );

rmtree( 't/tmp' );
