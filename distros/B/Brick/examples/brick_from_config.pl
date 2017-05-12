#!/usr/bin/perl
use strict;
use warnings;

use Config::IniFiles;

die "File does not !" unless -e "brick_from_config.ini";

open my( $fh ), "<", "brick_from_config.ini" || die "$!";

my $config = Config::IniFiles->new(
	'-file' => $fh,
	) || die "Could not make object!";
	
my @sections = $config->Sections;

my $bucket = Brick::Bucket->new();

foreach my $section ( @sections )
	{
	print "Processing section $section...\n";
	
	$bucket->create_brick( {
		code     => $config->val( $section, 'code' ),
		message  => $config->val( $section, 'message' ),
		field    => $config->val( $section, 'field' ), 
		name     => $config->val( $section, 'name' ), 
		name     => $config->val( $section, 'description' ), 
		} );
		
	}	


BEGIN {
use Brick::Bucket;
use Scalar::Util;

sub main::length_is_three { return 1 if length $_[0] == 3 }
	
sub Brick::Bucket::create_brick
	{
	my( $bucket, $setup ) = @_;
	
	my( $package, $sub_name ) = do {
		if( $setup->{code} =~ /(.*)::(.*)/ )
			{
			( $1, $2 )
			}
		else
			{
			( 'Brick', $setup->{code} )
			}
		};
	
	print STDERR "Package is $package; sub is $sub_name\n";
	
	my $coderef = $package->can( $sub_name );

	print STDERR "Coderef is $coderef\n";
	
	return unless defined $coderef;

	print STDERR "Got a coderef!\n";
	
	my $sub = sub {
		my $input = shift;
	
		return 1 if eval { $coderef->( $input->{ $setup->{field} } ) };
		
		die {
			message => $setup->{message},
			field   => $setup->{field},
			handler => $setup->{code},
			}
		
		};
		
	$bucket->add_to_bucket( {
		name        => $setup->{name},
		description => $setup->{description},
		code        => $sub,
		} );
	}
	
};