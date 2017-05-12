package AxKit::XSP::Swish;

@ISA = ('Apache::AxKit::Language::XSP::TaglibHelper');

# Swish-e Taglib
$VERSION = '0.2';

$NS = 'http://nexus-is.ca/NS/xsp/swish/v1';

@EXPORT_TAGLIB = (
'send($index,$query;$title,$props,$sort,$context,$limit):as_xml=1',
);

use vars qw/@ISA $VERSION $NS @EXPORT_TAGLIB/;

# libs and prototypes
use strict;
use SWISHE;
use Apache::AxKit::Language::XSP::TaglibHelper;
sub parse_char { Apache::AxKit::Language::XSP::TaglibHelper::parse_char(@_); }
sub parse_start { Apache::AxKit::Language::XSP::TaglibHelper::parse_start(@_); }
sub parse_end { Apache::AxKit::Language::XSP::TaglibHelper::parse_end(@_); }


## Taglib subs
sub send ($$;$$$$$) {

    my ($index,$query,$title,$props,$sort,$context,$limit) = @_;

    die "No index file provided" unless $index;

    my $handle = SwishOpen( $index ) or die "Failed to open index: $index check path or permissions";

    # Use an array for a hash slice when reading results.
    my @labels = qw/
        rank
        file_name
        title
        content_length
    /;

    my $num_results = SwishSearch(
                        $handle,
                        $query,
                        $context,
                        $props,
                        $sort,
                        );

    unless ( $num_results ) {
        my $error = SwishError( $handle );
        SwishClose ($handle);
        return "<results><message>No Results</message><error>$error</error></results>";
    }

    my %result;
    my %props;
    my @properties = split /\s+/, $props;
    my $return_list="";
    my $count=1;
    if ($limit == undef) { $limit = '1000000';} elsif ($limit < 0) { $limit = 0 } # max results hard coded to 1M 

    while ( ( ( @result{ @labels }, @props{@properties} ) = SwishNext( $handle ) ) && ($count <= $limit) ) {
       $return_list .= "<results>"; 
        for ( @labels ) {
          $return_list .= "<$_>" . $result{$_} . "</$_>";
	}
        for ( @properties ) {
          $return_list .= "<$_>" . $props{$_} . "</$_>";
        }
       $return_list .= "</results>"; 
       $count ++;
    }
 
    # Free the memory.
    SwishClose( $handle );

    return ($title) ? ('<rtitle name="'. $title . '">' . $return_list . '</rtitle>'):($return_list);

}

1;
 
__END__
 
=head1 NAME
 
AxKit::XSP::Swish - A namespace wrapper for accessing Swish-e.
 
=head1 SYNOPSIS
 
Add the param: namespace to your XSP C<<xsp:page>> tag:
 
    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:param="http://axkit.org/NS/xsp/param/v1"
    >
 
And add the taglib to AxKit (via httpd.conf or .htaccess):
 
    AxAddXSPTaglib AxKit::XSP::Swish
 
=head1 DESCRIPTION
 
The XSP Swish: tag library implements a simple way 

Swish-e.

1- Make sure that you have swish installed and have compiled
the Perl XS library for the swish-e indexer. See www.swish-e.org
for more information on using swish-e.

2- Add this to your httpd.conf

AddXSPTaglib AxKit::XSP::Swish

3- Create an xsp file such as this one :

<?xml version="1.0"?>

<?xml-stylesheet type="application/x-xsp" href="."?>

<xsp:page

 xmlns:xsp="http://apache.org/xsp/core/v1"

 xmlns:swish="http://nexus-is.ca/NS/xsp/swish/v1"

 language="Perl"

>

<page>

<swish:send 

index="./nexus.swish"

title="a search"

query="suexec"

context="1"

/>

</page>

</xsp:page>

4- Reload the server and try it out.
 
 
=head2 Tag Reference

The main tag is <swish:send> which takes the following attributes :

index: A path tp the index. Must be an httpd user readable file.

query: A string representing the search to be conducted. Ex. 'a string', 'title="a phrase"', or '(title="a phrase") or ("another")

The following optional tags which affect what and how things are
searched and returned :

title: A title that will be returned with the search results.

props: A list of properties to return with the results (see swish docs).

sort: A string containing a sort specification with property sort order pairs like "title asc description desc"

context: Where to search if the original documents are HTML. A bitwise OR

          like "1|2|3" where 

	  IN_FILE_BIT=1

	  IN_TITLE_BIT=2

	  IN_HEAD_BIT=3 

	  IN_BODY_BIT=4

  	  IN_COMMENTS_BIT=5

	  IN_HEADER_BIT=6

	  IN_EMPHASIZED_BIT=7

	  IN_META_BIT=7

limit: Limits the number of results returned. Max is set to 1,000,000.

=head1 AUTHOR
 
Francois Machabee, Nexus Information Systems & Marketing, 2002
=head1 COPYRIGHT
 
Copyright (c) 2002 Francois Machabee. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.
 
=head1 SEE ALSO
 
AxKit, Apache::AxKit::Language::XSP::TaglibHelper 
 
=cut

