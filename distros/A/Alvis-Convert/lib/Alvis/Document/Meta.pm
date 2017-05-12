package Alvis::Document::Meta;

########################################################################
#
# Parses a Meta specification for a document and maps fields to 
# Dublin Core. 
#
#   -- Kimmo Valtonen
#
########################################################################

use strict;

$Alvis::Document::Meta::VERSION = '0.1';

#########################################################################
#
#        Mappings 
#
#########################################################################

#
# Metadata mappings. Ripped off Anders's e-mail.
#
my %MetaMap=(
	     "rights" => "dc:rights",
	     "coverage" => "dc:coverage",
	     "creator" => "dc:creator",
	     "content" => "dc:description",
	     "geo.country" => "dc:coverage",
	     "email" => "dc:publisher",
	     "language " => "dc:language",
	     "identifier-url" => "dc:identifier",
	     "timemodified" => "dc:date",
	     "last-modified" => "dc:date",
	     "copyright " => "dc:copyright",
	     "classification " => "dc:subject",
	     "url" => "dc:identifier",
	     "timecreated " => "dc:date",
	     "category" => "dc:subject",
	     "description " => "dc:description",
	     "location" => "dc:coverage",
	     "originator" => "dc:creator",
	     "subject" => "dc:subject",
	     "author " => "dc:creator",
	     "publisher " => "dc:publisher",
	     "pd" => "dc:date",
	     "publisher-email" => "dc:publisher",
	     "abstract" => "dc:description",
	     "documenttype" => "dc:type",
	     "content-type"=>"dc:type",
	     "doc-rights" => "dc:rights",
	     "page-topic" => "dc:subject",
	     "keyword" => "dc:subject",
	     "document-rights" => "dc:rights",
	     "keywords " => "dc:subject",
	     "resource-type " => "dc:type",
	     "summary" => "dc:description",
	     "creation-date" => "dc:date",
	     "type " => "dc:type",
	     "document-classification" => "dc:subject",
	     "country" => "dc:coverage",
	     "progid" => "dc:format",
	     "content-language " => "dc:language",
	     "title " => "dc:title",
	     "created" => "dc:date",
	     "doc-type" => "dc:type",
	     "mimetype" => "dc:type",
	     "server"=>"server"
	     );

my %DCMap=(
	   "dc:coverage" => "dc:coverage",
	   "dc:date.x-metadatalastmodified" => "dc:date",
	   "dc:language" => "dc:language",
	   "dc:title" => "dc:title",
	   "dc:date.created" => "dc:date",
	   "dc:format" => "dc:format",
	   "dc:description" => "dc:description",
	   "dc:source" => "dc:source",
	   "dc:date.modified" => "dc:date",
	   "dc:creator" => "dc:creator",
	   "dc:coverage.placename" => "dc:coverage",
	   "dc:rights" => "dc:rights",
	   "dc:subject" => "dc:subject",
	   "dc:contributor" => "dc:contributor",
	   "dc:type" => "dc:type",
	   "dc:identifier" => "dc:identifier",
	   "dc:publisher" => "dc:publisher",
	   "dc:date" => "dc:date"
	   );

#########################################################################

my ($ERR_OK,
    $ERR_UNK_FIELD_NAME,
    $ERR_PARSE
    )=(0..2);

my %ErrMsgs=($ERR_OK=>"",
	     $ERR_UNK_FIELD_NAME=>"Unrecognized field name.",
	     $ERR_PARSE=>"Parsing the meta text failed."
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

    if (defined($self->{text}))
    {
	if (!$self->parse($self->{text}))
	{
	    $self->_set_err_state($ERR_PARSE,
				  "Text:\"$self->{text}\".");
	    return undef;
	}
    }

    return $self;
}

sub _init
{
    my $self=shift;

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
	    $self->{errstr}="";
	}
	else
	{
	    $self->{errstr}.=" " . $ErrMsgs{$errcode};
	    if (defined($errmsg))
	    {
		$self->{errstr}.=" " . $errmsg;
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

#
# in UTF-8
#
sub parse
{
    my $self=shift;
    my $meta=shift;

    $self->_set_err_state($ERR_OK);

    my @l=split(/\n/,$meta);
    for my $l (@l)
    {
	chomp $l;
	my ($name,$value)=split(/\t/,$l,-1);
	if (!(defined($name) && defined($value)))
	{
	    next;
	}
	
	if ($name=~/^\s*url\s*$/isgo)
	{
	    $self->{attr}{url}=$value;
	}
	elsif ($name=~/^\s*date\s*$/isgo)
	{
	    $self->{attr}{date}=$value;
	}
	elsif ($name=~/^\s*title\s*$/isgo)
	{
	    $self->{attr}{title}=$value;
	}
	elsif ($name=~/^\s*detected\s*\-\s*charset\s*$/isgo)
	{
	    $self->{attr}{detectedCharSet}=$value;
	}
	elsif ($name=~/^\s*Meta\-\s*(.*)$/isgo)
	{
	    my $metafield=$1;

	    $metafield=lc($metafield);
	    if (exists($MetaMap{$metafield}))
	    {
		$metafield=$MetaMap{$metafield};
		if (exists($DCMap{$metafield}))
		{
		    $metafield=$DCMap{$metafield};
		}

		$self->{attr}{$metafield}=$value;
	    }
	}
	else
	{
	    $self->_set_err_state($ERR_UNK_FIELD_NAME,
				  "Field name:\"$name\".");
	    return 0;
	}
    }

    return 1;
}

sub set
{
    my $self=shift;
    my $param=shift; 
    my $value=shift;

    $self->{attr}{$param}=$value;
}

sub get
{
    my $self=shift;
    my $param=shift; 

    if (exists($self->{attr}{$param}))
    {
	return $self->{attr}{$param};
    }
    else
    {
	return undef;
    }
}

sub get_dcs
{
    my $self=shift;
    
    my @dcs=();

    for my $p (keys %{$self->{attr}})
    {
	if ($p=~/^\s*dc\:.*\s*$/)
	{
	    push(@dcs,[$p,$self->{attr}{$p}]);
	}
    }

    return @dcs;
}

############################################################################
#
#          Private methods
#
############################################################################



1;

__END__

=head1 NAME

Alvis::Document::Meta - Perl extension for representing meta information 
about a document, such as its URL, title, modification date, HTML header
information, detected character set,...

Maps HTML header attributes to the Dublin Core set (dc:title etc.). 

=head1 SYNOPSIS

 use Alvis::Document::Meta;

 # Two ways of creating an instance 

 # Create a new instance from e.g. a file containing the meta information
 my $m=Alvis::Document::Meta->new();
 if (!defined($m))
 {
    die('Ugh!');
 }
 my $meta_txt=&read_meta_file($file);
 if (!$m->parse($meta_txt))
 {
    die('Parsing the meta file failed.' . $m->errmsg());
 }

 # or by directly supplying the text at instantiation time
 my $m=Alvis::Document::Meta->new(text=>$meta_txt);
 if (!defined($m))
 {
    die('Ugh!');
 }

 # If you wish to get the list of DC fields
 for my $dc_attr ($m->get_dcs())
 { 
     my ($attr,$value)=@$dc_attr;
     # do something
 }
 
 # There are additional special attributes you can set and get like this
 $m->set('url','foo.html');
 my $date=$$m->get('date');

=head1 DESCRIPTION

See the source for the exact mapping from HTML header fields to DC.
Syntax of the meta information file:

       <feature name>\t<feature value>\n

"Special" field names are
      url   
      title
      date
      detected-charset 

=head1 METHODS

=head2 new()

Options:

    text    The text of a meta information file.

=head2 parse($meta)

Maps the features to the Dublin Core set (dc:title etc.). 

"Special" field names are
      url   
      title
      date
      detected-charset 

=head2 get_dcs()

Returns all Dublin Core mapped features as 
([<name>,<value>],[<name>,<value>],...)

=head2 get($param)

Returns the setting for the attribute. 
"Special" parameters are

      url   
      title
      date
      detectedCharSet 


=head2 set($param,$value)

Sets the value for a meta information attribute.

=head2 errmsg()



=head1 SEE ALSO

Alvis::Document, Alvis::Convert

=head1 AUTHOR

Kimmo Valtonen, E<lt>kimmo.valtonen@hiit.fiE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kimmo Valtonen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
