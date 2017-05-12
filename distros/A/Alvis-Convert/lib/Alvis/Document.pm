package Alvis::Document;

########################################################################
#
# Assembles an ALVIS XML documentRecord from given pieces
#
#   -- Kimmo Valtonen
#
########################################################################

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Digest::MD5;
use Compress::Zlib;
use MIME::Base64;
use Encode;

use Alvis::Document::Meta;
use Alvis::Document::Links;

use strict;

my ($ERR_OK,
    $ERR_CAN_DOC,
    $ERR_META,
    $ERR_DATE,
    $ERR_URL,
    $ERR_NO_LINK_TYPE,
    $ERR_LINKS_TXT
    )=(0..6);

my %ErrMsgs=($ERR_OK=>"",
	     $ERR_CAN_DOC=>"No canonicalDocument.",
	     $ERR_META=>"No meta information.",
	     $ERR_DATE=>"No document date.",
	     $ERR_URL=>"No URL.",
	     $ERR_NO_LINK_TYPE=>"No type for a link.",
	     $ERR_LINKS_TXT=>"Assembling links text failed."
	     );

sub new
{
    my $proto=shift;
 
    my $class=ref($proto)||$proto;
    my $parent=ref($proto)&&$proto;
    my $self={};
    bless($self,$class);

    $self->_set_err_state($ERR_OK);

    $self->_init(@_);

    return $self;
}

sub _init
{
    my $self=shift;

    $self->{includeOriginalDocument}=1;

    if (defined(@_))
    {
        my %args=@_;
        @$self{ keys %args }=values(%args);
    }
}

sub _set_err_state
{
    my $self=shift;
    my $errcode=shift;
    my $errmsg=shift;

    if (!defined($errcode))
    {
	confess("set_err_state() called with an undefined argument.");
    }

    if (exists($ErrMsgs{$errcode}))
    {
	if ($errcode==$ERR_OK)
	{
	    $self->{'errstr'}="";
	}
	else
	{
	    $self->{'errstr'}.=" " . $ErrMsgs{$errcode};
	    if (defined($errmsg))
	    {
		$self->{'errstr'}.=" " . $errmsg;
	    }
	}
    }
    else
    {
	confess("Internal error: set_err_state() called with an " .
		"unrecognized argument ($errcode).")
    }
}

sub errmsg
{
    my $self=shift;
    
    return $self->{errstr};
}

############################################################################
#
#          Public methods
#
############################################################################

sub assemble
{
    my $self=shift;
    my $ingredients=shift;

    if (!defined($ingredients->{canDoc}))
    {
	$self->_set_err_state($ERR_CAN_DOC);
	return undef;
    }
    if (!defined($ingredients->{meta}))
    {
	$self->_set_err_state($ERR_META);
	return undef;
    }
    if (!defined($ingredients->{meta}->get('date')))
    {
	$self->_set_err_state($ERR_DATE);
	return undef;
    }
    if (!defined($ingredients->{meta}->get('url')))
    {
	$self->_set_err_state($ERR_URL);
	return undef;
    }

    my $XML;

    my $md5;
    if (defined($ingredients->{origText}) && $self->{includeOriginalDocument})
    {
	$md5=uc(Digest::MD5->new->add($ingredients->{origText})->hexdigest());
    }
    else
    {
	$md5=uc(Digest::MD5->new->add(encode_utf8($ingredients->{canDoc}))->hexdigest());
    }

    $XML.="  <documentRecord id=\"$md5\" xmlns=\"http://alvis.info/enriched/\">\n";
    $XML.="    <acquisition>\n";

    my $last_modified;
    if (defined($ingredients->{meta}->get('date')))
    {
	$last_modified=$ingredients->{meta}->get('date');
    }
    else
    {
	$last_modified=$ingredients->{meta}->get('dc:date');
    }
    $last_modified=$self->_txt2XMLsafe($last_modified);
    my $http_server;
    if (defined($ingredients->{meta}->get('server')))
    {
	$http_server=$self->_txt2XMLsafe($ingredients->{meta}->get('server'));
    }
    $XML.=$self->_acquisition_data($last_modified,
				   $http_server,
				   $self->_txt2XMLsafe(
					$ingredients->{meta}->get('url')));
    if (defined($ingredients->{origText}) && $self->{includeOriginalDocument})
    {
	$XML.="      " . 
	    $self->_original_document($ingredients->{origText}) . "\n";
    }
    $XML.=$self->_canonical_document($ingredients->{canDoc});
    $XML.=$self->_meta_data($ingredients->{meta});
    if (defined($ingredients->{links}))
    {
	my $links_txt=$self->_links($ingredients->{links});
	if (!defined($links_txt))
	{
	    $self->_set_err_state($ERR_LINKS_TXT);
	    return undef;
	}
	$XML.=$links_txt;
    }
    $XML.="    </acquisition>\n";
    $XML.="  </documentRecord>\n";

    return $XML;
}

sub set
{
    my $self=shift;
    my $option=shift;
    my $value=shift;

    $self->{$option}=$value;
}

############################################################################
#
#          Private methods
#
############################################################################

sub _acquisition_data
{
    my $self=shift;
    my $last_modified=shift;
    my $http_server=shift;
    my $url=shift;

    my $res="";
    $res.="      <acquisitionData>\n";
    $last_modified=$self->_txt2XMLsafe($last_modified);
    $res.="        <modifiedDate>$last_modified</modifiedDate>\n";
    $res.="        <httpServer>" . $self->_txt2XMLsafe($http_server) . "</httpServer>\n" if
	defined $http_server;
    $url=$self->_txt2XMLsafe($url);
    $res.="        <urls>\n" .
	  "          <url>$url</url>\n" .
	  "        </urls>\n";
    $res.="      </acquisitionData>\n";

    return $res;
}

sub _original_document
{
    my $self=shift;
    my $orig_text=shift;

    my $gzip=Compress::Zlib::memGzip($orig_text);
    my $base64=MIME::Base64::encode($gzip);

    return "<originalDocument charSet=\"UTF-8\" " .
	"mimeType=\"text/html\" compression=\"gzip\" " .
	"encoding=\"base64\">$base64" .
	"</originalDocument>";
}

sub _canonical_document
{
    my $self=shift;
    my $text=shift;

    $text=~s/^/" " x 8/mgoe;
    my $res="";
    $res.="      <canonicalDocument>$text" .
	"      </canonicalDocument>\n";

    return $res;
}



sub _meta_data
{
    my $self=shift;
    my $meta=shift;

    my $res="";
    $res.="      <metaData>\n";

#    warn Dumper($meta);
    my $title=$meta->get('title');
    if (defined($title))
    {
	$res.="        <meta name=\"title\">" . 
	    $self->_txt2XMLsafe($title) . "</meta>\n"; 
    }
    for my $m ($meta->get_dcs())
    {
	my ($name,$value)=@$m;
	$res.="        <meta name=\"$name\">" . 
	    $self->_txt2XMLsafe($value) . "</meta>\n";
    }

    $res.="      </metaData>\n";

    return $res;
}

sub _links
{
    my $self=shift;
    my $links=shift;

    my $res="";
    $res.="      <links>\n";
    $res.="        <outlinks>\n";
    for my $l ($links->get())
    {
	my ($url,$text,$type)=@$l;

	if (!defined($type))
	{
	    $self->_set_err_state($ERR_NO_LINK_TYPE,
				  "URL:$url, TEXT:$text.");
	    return undef;
	}

 	$type=$self->_txt2XMLsafe($type);
	$res.="          <link type=\"$type\">\n";
	if (defined($text))
	{
	    $text=$self->_txt2XMLsafe($text);
	    $res.="            <anchorText>$text</anchorText>\n";
	}
	$url=$self->_txt2XMLsafe($url);
	$res.="            <location>$url</location>\n";
	$res.="          </link>\n";
    }
    $res.="        </outlinks>\n";
    $res.="      </links>\n";

    return $res;
}

sub _rm_non_XML_chars
{
    my $self=shift;
    my $text=shift;

    $text=~tr/\000-\010\013-\014\016-\037//d;

    return $text;
}

sub _txt2XMLsafe
{
    my $self=shift;
    my $text=shift;

    if (!defined($text))
    {
	return "";
    }

    $text=~s/\&/\&amp;/go;
    $text=~s/</\&lt;/go;
    $text=~s/>/\&gt;/go;

    return $self->_rm_non_XML_chars($text);
}



1;

__END__

=head1 NAME

Alvis::Document - Perl extension for assembling an Alvis documentRecord
from given pieces.

=head1 SYNOPSIS

 use Alvis::Document;

 # Create a new instance
 my $D=Alvis::Document->new(includeOriginalDocument=>1});
 if (!defined($D))
 {
    die("Instantiating Alvis::Document failed.");
 }

 #
 # Assemble a new document from a canonicalDocument, link information,
 # meta information and the original document text.
 #
 my $alvisXML=$D->assemble({canDoc=>$can_doc,
                            links=>$links,
                            meta=>$meta,
                            origText=>$html});
 if (!defined($alvisXML))
 {
    die $D->errmsg();
 }

=head1 DESCRIPTION

A module for assembling an Alvis XML from constituent pieces
(canonicalDocument, meta information, links, original text of the
 document).

=head1 METHODS

=head2 new()

Options:

    includeOriginalDocument    Include originalDocument in the output?
                               Default: yes.

=head2 assemble($ingredients)

Returns the assembled Alvis XML documentRecord. Pieces can be given in
the following fields of $ingredients hash:

    canDoc       canonicalDocument
    meta         meta information
    origText     original document text
    links        an instance of Alvis::Document::Links. Link information.

=head2 errmsg()

Returns a stack of error messages, if any. Empty string otherwise.

=head1 SEE ALSO

Alvis::Document::Type, Alvis::Document::Encoding,   Alvis::Document::Meta,
Alvis::Document::Links

=head1 AUTHOR

Kimmo Valtonen, E<lt>kimmo.valtonen@hiit.fiE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kimmo Valtonen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
