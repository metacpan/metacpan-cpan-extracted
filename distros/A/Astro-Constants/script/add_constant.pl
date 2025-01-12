#!/usr/bin/perl -w
#
# Adds a constant to PhysicalConstants.xml
# Boyd Duffee, July 2017 & April 2024
#
# validation is not fatal, it only warns of errors

use v5.10;
use autodie;
use FindBin qw($Bin);
use XML::LibXML;

my $file = $ARGV[0] || "$Bin/../data/PhysicalConstants.xml";
die "Can't file $file\n" unless -f $file;
my $schema_file = $file;
$schema_file =~ s/\.xml$/.xsd/; 

my $bak = $file . '.bak';
die "Script won't overwrite backup file $bak  Stopping.\n" if -f $bak;

my $xml = XML::LibXML->load_xml(location => $file, no_blanks => 1);
my ($name, $description, $value, $precision, $category_list, @categories,
	$dimensions, $minValue, $maxValue, $source,  );

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
    get_name();
    check_not_a_duplicate() or return;
    get_description();
    get_value();
    get_precision();
    get_dimensions();
    get_source();
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
name [required]\t $name
description\t $description
value (in SI)\t $value
precision\t $precision
categories\t $category_list

Do you want to make any changes to this definition? [Y/n]
EDIT

	my $ans = <STDIN>;
	return $ans !~ /^n/i ? 1 : 0;
}

sub write_entries {
	print <<"EDIT";
These are the values that will be written to $file
name\t $name
description\t $description
value \t $value
precision\t $precision
categories\t $category_list

I should ask if you really want to overwrite the file,
but I do it automatically for now.  The original file 
was written to $bak

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

    # write a patch file for the change
    open my $pfh, '>', $file . '.patch';
    print {$pfh} `diff -u $bak $file`;
    close $pfh;
    print "Patch file writen to $file.patch\n";
}

sub append_to_list {
	my $node_name = 'PhysicalConstant';
    my $new_constant = $xml->createElement( 'PhysicalConstant' );
    $xml->getElementsByTagName('items')->[0]->addChild($new_constant);

    if ($name) {
        my $e = XML::LibXML::Element->new('name');
        $e->appendText( $name );
        $new_constant->addChild($e);
    }
    if ($description) {
        my $e = XML::LibXML::Element->new('description');
        $e->appendText( $description );
        $new_constant->addChild($e);
    }
    if (defined $value) {
        my $e = XML::LibXML::Element->new('value');
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
    if ($source) {
        my $e = XML::LibXML::Element->new('source');
        $e->setAttribute( 'url', $source );
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

sub get_name {
	GET_NAME: {
		print "Name for constant (SPEED_LIGHT)\t";
		$name = <STDIN>;
		chomp $name;
		unless ($name) {
			print "This field is mandatory\n";
			redo GET_NAME;
		}
		$name =~ s/\s//g;
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

sub get_source {
	print "An official URL publishing the value of the constant\t";
	$source = <STDIN>;
	chomp $source;
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

sub check_not_a_duplicate {
    my @constants = $xml->getElementsByTagName('PhysicalConstant');
    for my $node (@constants) {
        if ($node->getChildrenByTagName('name') eq $name) {
            warn "$name already exists.  Skipping\n";
            return;
        }
    }
    return 1; # no duplicates
}
