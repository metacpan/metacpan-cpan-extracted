#!/usr/local/bin/perl

use CPAN::PackageDetails;

my $package_details = CPAN::PackageDetails->new( 
	file         => "02packages.details.txt",
	url          => "http://example.com/MyCPAN/modules/02packages.details.txt",
	description  => "Package names for my private CPAN",
	columns      => "package name, version, path",
	intended_for => "My private CPAN",
	last_updated => CPAN::PackageDetails->format_date,
	);

my @entries = (
	[ qw( Foo::Bar 1.23 A/AB/ABC/Foo-Bar.tgz ) ],
	[ qw( Baz      2.34 A/AB/ABC/Foo-Baz.tgz ) ],
	[ qw( Quux     3.45 A/AB/ABC/Quux.tgz    ) ],
	);

foreach my $entry ( @entries )
	{
	my( $package, $version, $path ) = @$entry;
	
	$package_details->add_entry(
		'package name' => $package,
		version        => $version,
		path           => $path,
		);
	}
	
$package_details->write_fh( \*STDOUT )
