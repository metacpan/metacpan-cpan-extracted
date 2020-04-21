#!/usr/bin/perl -w
#
# Adds a constant to PhysicalConstants.xml
# Boyd Duffee, July 2017
#
# TODO
# - check that constant name does not already exist
# - write out a file of local changes so that the main file can be patched
# - use relative paths to run script from anywhere

use strict;
use autodie;
use 5.010;
use XML::LibXML;

my $file = $ARGV[0] || '../data/PhysicalConstants.xml';
die "Can't file $file (run from the script directory)" unless -f $file;
my $schema_file = $file;
$schema_file =~ s/\.xml$/.xsd/; 

my $bak = $file . '.bak';
die "Script won't overwrite backup file $bak  Stopping." if -f $bak;

my $xml = XML::LibXML->load_xml(location => $file, no_blanks => 1);
my ($short, $long, $description, $cgs, $value, $precision, $category_list, @categories,
	$dimensions, $minValue, $maxValue, $url,  );

my %category = ( fundamental => 1 , cosmology => 1, electromagnetic => 1,
	planetary => 1, conversion => 1, nuclear => 1, mathematical => 1,
); 


my $add_constant = 1;
while ($add_constant) {
	get_constant_definition();

	print 'Add another constant? [y/N] ';
	my $ans = <STDIN>;
	$add_constant = 0 unless $ans =~ /^y/i; 
}

write_entries();

exit;

sub populate_fields {
	get_long_name();
	get_short_name();
	get_description();
	get_value();
	get_precision();
	get_dimensions();
	get_url();
	get_categories();
}

sub get_constant_definition {
	do {
		populate_fields();
	} while ( edit_fields() );

	append_to_list();
}

sub edit_fields {
	print <<"EDIT";

I have the following values for your new PhysicalConstant
long name [required]\t $long
short name\t $short
description\t $description
value (mks)\t $value
precision\t $precision
categories\t $category_list

Do you want to make any changes? [Y/n]
EDIT

	my $ans = <STDIN>;
	return $ans !~ /^n/i ? 1 : 0;
}

sub write_entries {
	print <<"EDIT";
These are the values that will be written to $file
long name\t $long
short name\t $short
description\t $description
value \t $value
precision\t $precision
categories\t $category_list

I should ask if you really want to overwrite the file,
but I do it automatically for now.  The original file 
was written to $bak

I should really, REALLY, validate the new xml file
against PhysicalConstant.xsd before overwriting the main file.
EDIT

	if (-f $schema_file) {
		my $schema =  XML::LibXML::Schema->new( location => $schema_file );
		eval { $schema->validate( $xml ); };
		warn "Couldn't validate PhysicalConstants.xml against $schema_file: \n\t$@" 
			if $@;
	}
	else {
		warn "No XML Schema file to validate against at $schema_file";
	}
	rename $file, $bak;

	open my $fh, '>', $file;
	print {$fh} $xml->toString(2);
	close $fh;
}

sub append_to_list {
	my $node_name = 'PhysicalConstant';
    my $new_constant = $xml->createElement( 'PhysicalConstant' );
    $xml->getElementsByTagName('items')->[0]->addChild($new_constant);

    if ($long) {
        my $name = XML::LibXML::Element->new('name');
        $name->setAttribute( 'type', 'long' );
        $name->appendText( $long );
        $new_constant->addChild($name);
    }
    if ($short) {
        my $name = XML::LibXML::Element->new('name');
        $name->setAttribute( 'type', 'short' );
        $name->appendText( $short );
        $new_constant->addChild($name);
    }
    if ($description) {
        my $e = XML::LibXML::Element->new('description');
        $e->appendText( $description );
        $new_constant->addChild($e);
    }
    if (defined $value) {
        my $e = XML::LibXML::Element->new('value');
        $e->setAttribute( 'system', 'MKS' );
        $e->appendText( $value );
        $new_constant->addChild($e);
    }
    if (defined $precision) {
        my $e = XML::LibXML::Element->new('uncertainty');
        $e->setAttribute( 'type', 'relative' );
        $e->appendText( $precision );
        $new_constant->addChild($e);
    }
    if ($dimensions) {
        my $e = XML::LibXML::Element->new('dimensions');
        $e->appendText( $dimensions );
        $new_constant->addChild($e);
    }
	else {
		$new_constant->addChild( XML::LibXML::Element->new('dimensions') );
	}
    if (defined $maxValue) {
        my $e = XML::LibXML::Element->new('maxValue');
        $e->appendText( $maxValue );
        $new_constant->addChild($e);
    }
	else {
		$new_constant->addChild( XML::LibXML::Element->new('maxValue') );
	}
    if (defined $minValue) {
        my $e = XML::LibXML::Element->new('minValue');
        $e->appendText( $minValue );
        $new_constant->addChild($e);
    }
	else {
		$new_constant->addChild( XML::LibXML::Element->new('minValue') );
	}
    if ($url) {
        my $e = XML::LibXML::Element->new('url');
        $e->setAttribute( 'href', $url );
        $new_constant->addChild($e);
    }
    if (scalar @categories) {
        my $list = XML::LibXML::Element->new('categoryList');
        $new_constant->addChild($list);

		for my $cat (@categories) {
			my $e = XML::LibXML::Element->new('category');
			$e->appendText( $cat );
			$list->addChild($e);
		}
    }

}

#### could use these subs to validate ####
#
sub get_short_name {
	print "Short name for constant (A_c)\t";
	$short = <STDIN>;
	$short =~ s/\s//g;
}

sub get_long_name {
	GET_NAME: {
		print "Long name for constant (SPEED_LIGHT)\t";
		$long = <STDIN>;
		chomp $long;
		unless ($long) {
			print "This field is mandatory\n";
			redo GET_NAME;
		}
		$long =~ s/\s//g;
	}
}

sub get_description {
	print "Description \t";
	$description = <STDIN>;
	chomp $description;
}

sub get_value {
	print "Value for constant (2.99e8)\t";
	$value = <STDIN>;
	$value =~ s/\s*$//g;
	$value =~ s/^\s*//g;
}

sub get_precision {
	print "Precision (relative) for constant\t";
	$precision = <STDIN>;
	chomp $precision;
}

sub get_dimensions {
	print "Dimensions of the constant [mass^1, length^-3, time|luminosity]\t";
	$dimensions = <STDIN>;
	chomp $dimensions;
}

sub get_url {
	print "An official url publishing the value of the constant\t";
	$url = <STDIN>;
	chomp $url;
}

sub get_categories {
	print "Currently available categories: ", join ', ', keys %category;
	print "\nGive a list of categories the constant belongs to, separated by commas ";
	my $cat = <STDIN>;
	chomp $cat;
	@categories = grep { exists $category{$_} } split /\s*,\s*/, $cat;
	$category_list = join ", ", @categories;

	# a default
	@categories = qw/unclassified/ unless scalar @categories;
}
