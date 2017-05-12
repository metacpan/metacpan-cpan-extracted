#!perl

use strict;
use warnings;

use Test::More;

use Cwd qw(realpath);
use Config;

require Alien::Packages;

my $extensive_tests = $ENV{AUTHOR_TESTING} || $ENV{KWALITEE_TESTING};

my $ap = Alien::Packages->new();
ok( $ap, "Instantiating" );

my @packages = $ap->list_packages();
# can't check result: Slackware, Gentoo, OpenBSD, MirBSD, IRIX, HP-UX, ...
ok( 1, "still alive after list_packages" );

if( @packages )
{
    # for the author, to see if there is something
    my %pkgtypes = map { $_->{PkgType} => $_ } @packages;

    foreach my $pkg (values %pkgtypes)
    {
	diag( "{ " . join( ", ", map { $_ . " => " . $pkg->{$_} } keys %{$pkg} ) . " }" );
    }
}

my @perls;
eval {
    require File::Which;
    @perls = File::Which::where( 'perl' );
};
my $perlbin = realpath( $Config{perlpath} );
my %perls = map { $_ => 1 } ( @perls, $perlbin );
@perls = keys %perls;
my @files = @perls;
$extensive_tests and push( @files, values %INC );
my %assoc_pkgs = $ap->list_fileowners( @files );
ok( 1, "still alive after list_fileowners" );
# can't check result, could be unsupported pkg type or wild installation (e.g. blead)
if( keys %assoc_pkgs )
{
    # for the author, to see if there is something
    foreach my $perl (@perls)
    {
	my $perl_pkg = $assoc_pkgs{$perl} or next;
	diag( "$perl is registered in { " . join( ", ", map { $_ . " => " . $perl_pkg->[0]{$_} } keys %{$perl_pkg->[0]} ) . " }" );
    }

    if( $extensive_tests )
    {
	my %pkgtypes;
	foreach my $mod (values %INC)
	{
	    next unless $assoc_pkgs{$mod};
	    my $key = join( ",", map { $_->{Filename} = $mod; $_->{PkgType} } @{$assoc_pkgs{$mod}} );
	    next if $pkgtypes{$key};
	    $pkgtypes{$key} = $assoc_pkgs{$mod};
	}

	while( my ($pkgtype, $pkgs) = each %pkgtypes )
	{
	    my $file;
	    my @pkgdetails;
	    foreach my $pkg (@$pkgs)
	    {
		$file = delete $pkg->{Filename};
		push( @pkgdetails, "{ " . join( ", ", map { $_ . " => " . $pkg->{$_} } keys %{$pkg} ) . " }" );
	    }
	    diag( "$file is registered in " . join( " and ", @pkgdetails ) );
	}
    }
}

done_testing();
