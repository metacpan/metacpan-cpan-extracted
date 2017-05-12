package Alvis::NLPPlatform::Document;

use strict;
use warnings;

use Lingua::Identify;

use Data::Dumper;

our $VERSION=$Alvis::NLPPlatform::VERSION;

# use YAML qw( Dump );

sub getnamespace
{
    my $file = shift;

    my $line;
    my $xmlns = undef;

    open FILE, $file;
    binmode(FILE);

    while(($line=<FILE>)){
	if ($line =~ /xmlns=\"?([^\"]+)\"?/) {
            $xmlns = $1;
	    next;
        }
    };
    close FILE;

    return($xmlns);
}

sub get_documentRecords
{
    my $xmlalvisfile=shift;

    my $doc;
    my $Parser=XML::LibXML->new();


    my $doc_list = "";

    eval
    {
	$doc=$Parser->parse_string($xmlalvisfile);
    };
    if ($@)
    {
	warn "Parsing the doc failed: $@. Trying to get the IDs..\n";
	eval
	{
	    $xmlalvisfile=~s/<documentRecord\s(xmlns=[^\s]+)*\sid\s*=\s*\"([^\"]*?)\">/&unparseable_id($2)/esgo;
	};
    }
    else
    {
	if ($doc)
	{

	    my $root=$doc->documentElement();
	    for my $rec_node ($root->getChildrenByTagName('documentRecord'))
	    {
		my $id=$rec_node->getAttribute("id");
		if (defined($id))
		{
		    $doc_list .= $rec_node->toString();
		}
		else
		{
		    my $rec_str=$rec_node->toString();
		    $rec_str=~s/\n/ /sgo;
		    warn "No id for record $rec_str\n";
		}
	    }
	}
	else
	{
	    my $doc_str=$xmlalvisfile;
	    $doc_str=~s/\n/ /sgo;
	    warn "Parsing the doc failed. Doc: $doc_str\n";
	}
    }

    return $doc_list;
}

sub get_language_from_file
{
    my $xmlalvisfile=shift;
    my $outfile = shift;
    my $config = shift;

    print STDERR "Identifying the language from file ($xmlalvisfile)\n";

    my $doc;
    my $Parser=XML::LibXML->new();


    eval
    {
	$doc=$Parser->parse_file($xmlalvisfile);
    };
    if (!$@)
    {
	if ($doc)
	{
	    my $xmlalvisdata = &get_language($doc);


	    open OUTPUT_FILE, ">$outfile";
	    binmode(OUTPUT_FILE, ":utf8");
	    print OUTPUT_FILE "$xmlalvisdata\n";
	    close(OUTPUT_FILE);
	    return($outfile);
	}
	else
	{
	    warn "Parsing the doc failed.\n";
	}
    } else {
	warn "Parsing the doc failed.\n";
	print STDERR $@;
    }

    return $outfile;
}

sub get_language_from_data
{
    my $xmlalvis=shift;

#       print STDERR $xmlalvis;

    print STDERR "Identifying the language from data\n";

    my $doc;
    my $Parser=XML::LibXML->new();


    eval
    {
	$doc=$Parser->parse_string($xmlalvis);
    };
    if (!$@)
    {
	if ($doc)
	{
	    $xmlalvis = &get_language($doc);
	}
	else
	{
	    warn "Parsing the doc failed. \n";
	}
    } else {
	warn "Parsing the doc failed.\n";
	if ($@ =~ /UTF-8/) {
	    warn "Not a UTF-8, assume to be a latin-1 document\n";
	    print STDERR "Converting in UTF8...\n";
	    Encode::from_to($xmlalvis, "iso-8859-1", "UTF-8");
	    print STDERR "done\n";
	    $xmlalvis = &get_language_from_data($xmlalvis);
	}
    }
#         print STDERR $xmlalvis;
    return $xmlalvis;
}


sub get_language
{
    my ($doc) = @_;

#       print STDERR Dumper $doc;

#     print STDERR $doc->toString();

    print STDERR "In get_language\n";

    my $root=$doc->documentElement();
    my $analysis_node;
    my $property_node;
#     print STDERR Dumper $root;
    my $language_exists = 0;

#     print STDERR $root->nodeName() . "\n";


    my @rec_node;
    my $rec_node;

    if ($root->nodeName() eq "documentCollection") {
	@rec_node = $root->getChildrenByTagName('documentRecord');
    } else {
	@rec_node = $root;
    }

#     print STDERR Dumper $rec_node;
     foreach $rec_node (@rec_node) {

	my @acq_data = $rec_node->getChildrenByTagName("acquisition");
	$analysis_node = $acq_data[0]->getChildrenByTagName("analysis");
	if ((defined $analysis_node) && (scalar(@$analysis_node) > 0)) {
	    foreach $property_node ($analysis_node->[0]->getChildrenByTagName("property")) {
		if (($property_node->hasAttribute("name")) && ($property_node->getAttribute("name") eq "language")) {
		    print STDERR "Language found : " . $property_node->string_value() . "\n";
		    $language_exists = 1;
		}
	    }
	}
	if ($language_exists == 0) {
	    my $can_doc =  $acq_data[0]->getChildrenByTagName("canonicalDocument");
	    if (defined $can_doc) {
		my $language = Lingua::Identify::langof($can_doc->string_value());
		print STDERR "Language: $language\n";
		my $property_node = XML::LibXML::Element->new("property");
		$property_node->setAttribute( "name", "language" );
		$property_node->appendTextNode($language);
		my @attr = $property_node->attributes();
		
		$analysis_node = XML::LibXML::Element->new("analysis");
		$analysis_node->appendTextNode("\n\t\t\t");
		$analysis_node->appendChild($property_node);
		$analysis_node->appendTextNode("\n\t\t");
		
		$acq_data[0]->appendTextNode("\t\t");
		$acq_data[0]->appendChild($analysis_node);
		$acq_data[0]->appendTextNode("\n\t");
	    } else {
		print STDERR "no canonical document\n";
	    }
	}
     }
#     print STDERR $doc->toString();
#    print STDERR $root->toString();
    return($doc->toString());
#     return($rec_node->toString());
}

1;

__END__

=head1 NAME

Alvis::NLPPlatform::Document - Perl extension for handling (getting
and adding) information into a ALVIS XML file or data.

=head1 SYNOPSIS

use Alvis::NLPPlatform::Document;

Alvis::NLPPlatform::Document

=head1 DESCRIPTION

=head1 METHODS

=head2 getnamespace

    getnamespace($file);

This method returns the namespace of the file C<$file>.


=head2 get_documentRecords

    get_documentRecords($xmlalvisfile);

The method returns an array of the document record contained in the
document collection C<$xmlalvisfile>.

=head2 get_language_from_file

    get_language_from_file($xmlalvisfile, $outfile, $config);


=head2 get_language_from_data

    get_language_from_data($xmlalvis);

This method adds the language properties in the document records of
the document collection C<$xmlalvis>. C<$outfile> is the name of the
output file. The path of modified document collection is returned.

=head2 get_language

    get_language($doc);

This method identifies the language of each document in the document
collection C<$doc> and adds it in each ones. The modified document
collection is returned.


# =head1 ENVIRONMENT

=head1 SEE ALSO

Alvis web site: http://www.alvis.info

=head1 AUTHOR

Thierry Hamon <thierry.hamon@lipn.univ-paris13.fr>

=head1 LICENSE

Copyright (C) 2007 by Thierry Hamon

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.
