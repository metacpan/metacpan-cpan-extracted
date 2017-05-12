package Alvis::Convert;

$Alvis::Convert::VERSION = '0.4';

########################################################################
#
# A general "set of document files in some format" -> 
# "set of files in ALVIS format" converter.
#
#   -- Kimmo Valtonen
#
########################################################################

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Encode;
use XML::LibXML;

use Alvis::Canonical;
use Alvis::Document;
use Alvis::Document::Encoding;
use Alvis::Document::Meta;
use Alvis::Document::Links;
use Alvis::Document::Type;
use Alvis::AinoDump;
use Alvis::Wikipedia::XMLDump;


############################################################################
#
#  Global variables
#
############################################################################

# Types of documents handled
our ($UNKNOWN_FILE_TYPE,$DIR,$META,$HTML,$NEWS_XML,$AINODUMP,
     $WIKIPEDIA_XML_DUMP)=(0..6);
my %RecognizedEntryTypeDescs=($UNKNOWN_FILE_TYPE=>"Guess the file type",
			      $DIR=>"Directory",
			      $META=>"Meta information",
			      $HTML=>"HTML",
			      $NEWS_XML=>
			      "XML information about a news article",
			      $AINODUMP=>"ainodump",
			      $WIKIPEDIA_XML_DUMP=>"Wikipedia XML dump");

############################################################################
#
#  Error message stuff
#
############################################################################

my ($ERR_OK,
    $ERR_CANONICAL,
    $ERR_ASSEMBLER,
    $ERR_CANDOC_CONV,
    $ERR_META,
    $ERR_LINKS,
    $ERR_LINK_ADD,
    $ERR_ASSEMBLE,
    $ERR_NO_NEWS_XML_TEXT,
    $ERR_XML_PARSER,
    $ERR_XML_PARSE,
    $ERR_NO_URL,
    $ERR_ENCODING_WIZARD,
    $ERR_UTF8_CONV,
    $ERR_ENCODING_CONV,
    $ERR_TYPE_SUFFIX,
    $ERR_READ_HTML,
    $ERR_READ_NEWS_XML,
    $ERR_ALVIS_CONV,
    $ERR_ALVIS_SUFFIX,
    $ERR_NO_OUTPUT_ROOT_DIR,
    $ERR_WRITING_OUTPUT,
    $ERR_DIR_CONV,
    $ERR_NO_HTML_F,
    $ERR_META_F,
    $ERR_HTML_F,
    $ERR_NEWS_XML_F,
    $ERR_DOC_ALVIS_CONV,
    $ERR_NEWS_XML_PARSE,
    $ERR_MULTIPLE_SUFFIX_MEANING,
    $ERR_OUTPUT_ALVIS,
    $ERR_OUTPUT_SET_OF_RECORDS,
    $ERR_AINODUMP,
    $ERR_OPEN_AINODUMP,
    $ERR_AINODUMP_PROCESS,
    $ERR_DOC_TYPE_WIZARD,
    $ERR_TYPE_GUESS,
    $ERR_UNK_FILE_TYPE,
    $ERR_WIKIPEDIA,
    $ERR_OPEN_WIKIPEDIA,
    $ERR_WIKIPEDIA_CONV
    )=(0..40);

my %ErrMsgs=($ERR_OK=>"",
	     $ERR_CANONICAL=>"Could not instantiate Alvis::Canonical.",
	     $ERR_ASSEMBLER=>"Could not instantiate Alvis::Document.",
	     $ERR_CANDOC_CONV=>"Conversion to canonicalDocument failed.",
	     $ERR_META=>"Could not instantiate Alvis::Document::Meta.",
	     $ERR_LINKS=>"Could not instantiate Alvis::Document::Links.",
	     $ERR_LINK_ADD=>"Adding a link failed.",
	     $ERR_ASSEMBLE=>"Assembling a document failed.",
	     $ERR_NO_NEWS_XML_TEXT=>"Unable to extract the content from News" .
	     " XML format.",
	     $ERR_XML_PARSER=>"Could not instantiate XML::LibXML.",
	     $ERR_XML_PARSE=>"Parsing the XML failed.",
	     $ERR_NO_URL=>"No URL.",
	     $ERR_ENCODING_WIZARD=>"Unable to instantiate " .
	     "Alvis::Document::Encoding.",
	     $ERR_UTF8_CONV=>"Trying to convert to UTF-8 failed.",
	     $ERR_ENCODING_CONV=>"Converting from the supposed source " .
	     "encoding to UTF-8 failed.",
	     $ERR_TYPE_SUFFIX=>"No suffix given for a type.",
	     $ERR_READ_HTML=>"Reading the HTML failed.",
	     $ERR_READ_NEWS_XML=>"Reading the news XML failed.",
	     $ERR_ALVIS_CONV=>"Conversion to Alvis format failed.",
	     $ERR_ALVIS_SUFFIX=>"No Alvis suffix defined.",
	     $ERR_NO_OUTPUT_ROOT_DIR=>"No output root directory.",
	     $ERR_WRITING_OUTPUT=>"Writing the output failed.",
	     $ERR_DIR_CONV=>"Converting a directory failed.",
	     $ERR_NO_HTML_F=>"No HTML file.",
	     $ERR_META_F=>"Opening the meta file failed.",
	     $ERR_HTML_F=>"Opening the HTML file failed.",
	     $ERR_NEWS_XML_F=>"Opening the news XML file failed.",
	     $ERR_DOC_ALVIS_CONV=>"Converting a document to Alvis format failed.",
	     $ERR_NEWS_XML_PARSE=>"Parsing the news XML failed.",
	     $ERR_MULTIPLE_SUFFIX_MEANING=>
	     "Multiple meanings for a single suffix.",
	     $ERR_OUTPUT_ALVIS=>"Outputting the Alvis records failed.",
	     $ERR_OUTPUT_SET_OF_RECORDS=>"Outputting a set of records to a " .
	     "file as a documentCollection  failed.",
	     $ERR_AINODUMP=>"Instantiating Alvis::AinoDump failed.",
	     $ERR_OPEN_AINODUMP=>"Opening an ainodump file failed.",
	     $ERR_AINODUMP_PROCESS=>"Processing an ainodump file failed.",
	     $ERR_DOC_TYPE_WIZARD=>"Instantiating Alvis::Document::Type " .
	                           "failed.",
	     $ERR_TYPE_GUESS=>"Guessing the document's type failed.",
	     $ERR_UNK_FILE_TYPE=>"Unrecognized file type.",
	     $ERR_WIKIPEDIA=>"Instantiating Alvis::Wikipedia::XMLDump failed.",
	     $ERR_OPEN_WIKIPEDIA=>"Opening the Wikipedia XML dump file failed.",
	     $ERR_WIKIPEDIA_CONV=>"Extracting the articles from the Wikipedia" .
	                          " XML dump failed." 
	     );

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

sub clearerr
{
    my $self=shift;
    
    $self->{errstr}="";
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

sub new
{
    my $proto=shift;
 
    my $class=ref($proto)||$proto;
    my $parent=ref($proto)&&$proto;
    my $self={};
    bless($self,$class);

    $self->_set_err_state($ERR_OK);

    $self->_init(@_);

    if (defined($self->{urlBase}))
    {
	if ($self->{urlBase}!~/\/$/)
	{
	    $self->{urlBase}.='/';
	}
    }

    $self->{canonicalConverter}=Alvis::Canonical->new();
    if (!defined($self->{canonicalConverter}))
    {
	$self->_set_err_state($ERR_CANONICAL);
	return undef;
    }

    $self->{documentAssembler}=
	Alvis::Document->new(includeOriginalDocument=>
			     $self->{includeOriginalDocument});
    if (!defined($self->{documentAssembler}))
    {
	$self->_set_err_state($ERR_ASSEMBLER);
	return undef;
    }

    $self->{XMLParser}=XML::LibXML->new();
    if (!defined($self->{XMLParser}))
    {
	$self->_set_err_state($ERR_XML_PARSER);
	return undef;
    }

    $self->{encodingWizard}=
	Alvis::Document::Encoding->new(defaultEncoding=>undef);
    if (!defined($self->{encodingWizard}))
    {
	$self->_set_err_state($ERR_ENCODING_WIZARD);
	return undef;
    }

    $self->{wikipediaConverter}=
	Alvis::Wikipedia::XMLDump->new(expandVariables=>1,
				       skipRedirects=>0,
				       dumpCategoryData=>1,
				       dumpTemplateData=>1);
    if (!defined($self->{wikipediaConverter}))
    {
	$self->_set_err_state($ERR_WIKIPEDIA);
	return undef;
    }

    $self->{docTypeWizard}=
	Alvis::Document::Type->new(defaultType=>
				   $self->{defaultDocType},
				   defaultSubType=>
				   $self->{defaultDocSubType});
    if (!defined($self->{docTypeWizard}))
    {
	$self->_set_err_state($ERR_DOC_TYPE_WIZARD);
	return undef;
    }

    return $self;
}

sub _init
{
    my $self=shift;

    $self->{fileType}=undef;
    $self->{sourceEncoding}=undef;
    $self->{urlFromBasename}=0;
    $self->{outputAtSameLocation}=0;
    $self->{alvisSuffix}='alvis';
    $self->{outputRootDir}='.';
    $self->{outputNPerSubdir}=1000;
    $self->{defaultDocType}='text';
    $self->{defaultDocSubType}='html';
    $self->{defaultEncoding}='iso-8859-1';
    $self->{includeOriginalDocument}=1;
    $self->{ainodumpWarnings}=1;
    $self->{sourceEncodingFromMeta}=0;

    if (defined(@_))
    {
        my %args=@_;
        @$self{ keys %args }=values(%args);
    }

}

#
# in UTF-8
#
sub HTML
{
    my $self=shift;
    my $html=shift;   
    my $meta_txt=shift;
    my $opts=shift;

    $self->_set_err_state($ERR_OK);

    my $meta=Alvis::Document::Meta->new(text=>$meta_txt);
    if (!defined($meta))
    {
	$self->_set_err_state($ERR_META,
			      "Meta text:\"$meta_txt\".");
	return undef;
    }

    my $src_enc;
    if ($opts->{sourceEncoding})
    {
	$src_enc=$opts->{sourceEncoding};
    }
    elsif (!exists($opts->{sourceEncoding}) && $self->{sourceEncoding})
    {
	$src_enc=$self->{sourceEncoding};
    }
    else
    {
#	warn "NO SOURCE ENCODING GIVEN IN OPTIONS TO HTML() OR IN new()";
    }

    if ($opts->{sourceEncodingFromMeta} || $self->{sourceEncodingFromMeta})
    {
	my $detected=$meta->get('detectedCharSet');
	if ($detected)
	{
	    $src_enc=$detected;
	}
    }
    
    my ($can_doc,$header)=
	$self->{canonicalConverter}->HTML($html,
					  {title=>1,
					   baseURL=>1,
					   sourceEncoding=>$src_enc});
    if (!defined($can_doc))
    {
	$self->_set_err_state($ERR_CANDOC_CONV,
			      $self->{canonicalConverter}->errmsg());
	return undef;
    }

    if (!defined($meta->get('title')))
    {
	$meta->set('title',$header->{title});
    }
    if (!defined($meta->get('url')))
    {
	$self->_set_err_state($ERR_NO_URL);
	return undef;
    }
    else
    {
	if (!defined($meta->get('baseURL')))
	{
	    if (defined($header->{baseURL}))
	    {
		$meta->set('baseURL',$header->{baseURL});
	    }
	    else
	    {
		my $base_URL=$meta->get('url');
		$base_URL=~s/\/[^\/]+?$/\//isgo;
		$meta->set('baseURL',$base_URL);
	    }
	}
    }

    my $links=Alvis::Document::Links->new();
    if (!defined($links))
    {
	$self->_set_err_state($ERR_LINKS);
	return undef;
    }
    for my $link (@{$header->{links}})
    {
	my ($url,$text,$type);
	if (exists($link->{url}))
	{
	    $url=$link->{url};
	}
	if (exists($link->{text}))
	{
	    $text=$link->{text};
	}
	if (exists($link->{type}))
	{
 	    if ($link->{type}=~/^\s*a\s*$/isgo)
	    {
		$type='a';
	    }
 	    elsif ($link->{type}=~/^\s*i?frame\s*$/isgo)
	    {
		$type='frame';
	    }
 	    elsif ($link->{type}=~/^\s*img\s*$/isgo)
	    {
		$type='img';
	    }
	}
	
	if (!$links->add($url,$text,$type))
	{
	    $self->_set_err_state($ERR_LINK_ADD,
				  $links->errmsg());
	    return undef;
	}
    }

    my $alvisXML=
	$self->{documentAssembler}->assemble({canDoc=>$can_doc,
					      links=>$links,
					      meta=>$meta,
					      origText=>$html});
    if (!defined($alvisXML))
    {
	$self->_set_err_state($ERR_ASSEMBLE,
			      $self->{documentAssembler}->errmsg());
	return undef;
    }

    return $alvisXML;
}

sub newsXML
{
    my $self=shift;
    my $newsXML=shift;   
    my $meta_txt=shift;
    my $orig_txt=shift;

    $self->_set_err_state($ERR_OK);

    my $meta=Alvis::Document::Meta->new(text=>$meta_txt);
    if (!defined($meta))
    {
	$self->_set_err_state($ERR_META,
			      "Meta text:\"$meta_txt\".");
	return undef;
    }

    my @alvisXMLs=();

    my $articles=$self->_parse_newsXML($newsXML);
    if (!defined($articles))
    {
	$self->_set_err_state($ERR_NEWS_XML_PARSE);
	return undef;
    }
    for my $article (@$articles)
    {
	my ($text,$iso_date,$title,$links)=@$article;
	if (!defined($text))
	{
	    $self->_set_err_state($ERR_NO_NEWS_XML_TEXT,
				  "News XML text:\"$newsXML\".");
	    # OK, ignore
	    next;
#	    return undef;
	}
	$text='<HTML><BODY>' . $text . '</BODY></HTML>';
	
	# Check that the ISO date actually is in ISO format...
	if (defined($iso_date))
	{
	    $meta->set('dc:date',$iso_date);
	}
	
	my ($can_doc,$header)=
	    $self->{canonicalConverter}->HTML($text,
					      {sourceEncoding=>'utf8'});
	if (!defined($can_doc))
	{
	    $self->_set_err_state($ERR_CANDOC_CONV,
				  $self->{canonicalConverter}->errmsg());
	    return undef;
	}
	
	if (defined($title))
	{
	    $meta->set('title',$title);
	}
	if (!defined($meta->get('url')))
	{
	    $self->_set_err_state($ERR_NO_URL);
	    return undef;
	}
	else
	{
	    if (!defined($meta->get('baseURL')))
	    {
		my $base_URL=$meta->get('url');
		$base_URL=~s/\/[^\/]+?$/\//isgo;
		$meta->set('baseURL',$base_URL);
	    }
	}
	
	my $alvisXML=
	    $self->{documentAssembler}->assemble({canDoc=>$can_doc,
						  meta=>$meta,
						  links=>$links,
						  origText=>$orig_txt});
	if (!defined($alvisXML))
	{
	    $self->_set_err_state($ERR_ASSEMBLE,
				  $self->{documentAssembler}->errmsg());
	    return undef;
	}
	push(@alvisXMLs,$alvisXML);
    }

    return \@alvisXMLs;
}

sub ainodump
{
    my $self=shift;
    my $f=shift;   

    # No meta needed -- one per record in the dump
    #
    if (!defined(open(AINO,"<:raw",$f)))
    {
	$self->_set_err_state($ERR_OPEN_AINODUMP,
			      "File: \"$f\"");
	return 0;
    }
    if (!$self->{ainodumpConverter}
	->process_dump(*AINO,
		       [\&_process_ainodump_doc,$self]))
    {
	$self->_set_err_state($ERR_AINODUMP_PROCESS,
			      "File: \"$f\"");
	return 0;
    }
    close(AINO);
 
    return 1;
}

#
# output_cb: [\&_output_wikipedia_article,$arg1,$arg2,...]
#               will be called like this:
#          _output_wikipedia_article($arg1,$arg2,...,
#                                    $title,$output_format,
#                                    $record_txt,$is_redir)
#
#  where $output_format is a global defined in Alvis::Wikipedia::XMLDump
#  as $OUTPUT_*
#
#
# progress_cb: [\&_wikipedia_progress,$arg1,$arg2,...]     OPTIONAL
#               will be called like this:
#          _wikipedia_progress($arg1,$arg2,...,
#                              $prog_txt,$N,$n,$mess)
#
#   where $N is the total number of records processed and $n the number of hits
#
# opts:  a hash of options with these possible fields:
#
#     namespaces              ref to a list of namespace identifiers whose
#                             records to extract
#     expandTemplates         flag for true template expansion
#     templateDumpF           template dump file
#     outputFormat            format for result records 
#                             ($Alvis::Wikipedia::XMLDump::OUTPUT_*)
#     categoryWord            category namespace identifier (changes with
#                             language)
#     templateWord            template namespace identifier (changes with
#                             language)
#     rootCategory            root category identifier (changes with
#                             language)
#     date                    the date of the dump
#     dumpCatGraph            flag for dumping the category graph
#     catGraphDumpF           category graph dump file
#
sub wikipedia
{
    my $self=shift;
    my $f=shift;   
    my $output_cb=shift;  
    my $opts=shift;
    my $progress_cb=shift;

    if (!defined(open(WIKIPEDIA,"<:utf8",$f)))
    {
	$self->_set_err_state($ERR_OPEN_WIKIPEDIA,
			      "File: \"$f\"");
	return 0;
    }
    if (!$self->{wikipediaConverter}->extract_records(\*WIKIPEDIA,
						      $output_cb,
						      $opts,
						      $progress_cb))
    {
	$self->_set_err_state($ERR_WIKIPEDIA_CONV,
			      "File: \"$f\"");
	return 0;
    }

    close(WIKIPEDIA);

    return 1;
}

sub set
{
    my $self=shift;
    my $param=shift;
    my $value=shift;

    $self->{$param}=$value;
}

sub read_HTML
{
    my $self=shift;
    my $f=shift;
    my $meta_txt=shift;

    my $html_txt="";

    # Stupid duplicating of "how the f**k do you read UTF8 in Perl?" fix
    my $meta=Alvis::Document::Meta->new(text=>$meta_txt);
    if (!defined($meta))
    {
        $self->_set_err_state($ERR_META,
                              "Meta text:\"$meta_txt\".");
        return undef;
    }

    my $src_enc;
    if ($self->{sourceEncoding})
    {
	$src_enc=$self->{sourceEncoding};
    }
    if ($self->{sourceEncodingFromMeta})
    {
        my $detected=$meta->get('detectedCharSet');
        if ($detected)
        {
            $src_enc=$detected;
        }
    }

    if (defined($src_enc) && $src_enc=~/^\s*utf\s*\-?\s*8\s*$/i)
    {
	if (!defined(open(H,"<:utf8",$f)))
        {
            $self->_set_err_state($ERR_HTML_F,
                                  "File: \"$f\".");
            return undef;
        }
        while (my $l=<H>)
        {
            $html_txt.=$l;
        }
        close(H);
    }
    else
    {
	if (!defined(open(H,"<$f")))
	{
	    $self->_set_err_state($ERR_HTML_F,
				  "File: \"$f\".");
	    return undef;
	}
	while (my $l=<H>)
	{
	    $html_txt.=$l;
	}
	close(H);
    }

    return $html_txt;
}

sub read_meta
{
    my $self=shift;
    my $f=shift;

    my $meta_txt="";

    if (defined($self->{metaEncoding}))
    {
	if ($self->{metaEncoding}=~/^\s*utf\s*\-?\s*8\s*$/i)
	{
	    if (!defined(open(M,"<:utf8",$f)))
            {
                $self->_set_err_state($ERR_META_F,
                                      "File: \"$f\".");
                return undef;
            }
            while (my $l=<M>)
            {
                $meta_txt.=$l;
            }
            close(M);
	}
	else  # non-UTF8
	{
	    if (!defined(open(M,"<$f")))
	    {
		$self->_set_err_state($ERR_META_F,
				      "File: \"$f\".");
		return undef;
	    }
	    while (my $l=<M>)
	    {
		$meta_txt.=$l;
	    }
	    close(M);
	    
	    eval
            {
	      Encode::from_to($meta_txt,
			      $self->{metaEncoding},'utf-8',Encode::FB_WARN);
            };
            if ($@)
            {
                $self->_set_err_state($ERR_ENCODING_CONV,
                                      "$@. Supposed source encoding of \"$f\":" .
                                      "\"$self->{metaEncoding}\".");
                return undef;
            }
	}
    }
    else # encoding unknown
    {
	if (!defined(open(M,"<$f")))
	{
	    $self->_set_err_state($ERR_META_F,
				  "File: \"$f\".");
	    return undef;
	}
	my $meta_txt="";
	while (my $l=<M>)
	{
	    $meta_txt.=$l;
	}
	close(M);
	
	$meta_txt=$self->{encodingWizard}->try_to_convert_to_utf8($meta_txt,
								  'text',
								  'plain');
	if (!defined($meta_txt))
	{
	    $self->_set_err_state($ERR_UTF8_CONV,
				  $self->{encodingWizard}->errmsg());
	    return undef;
	}
    }

    return $meta_txt;
}

sub read_news_XML
{
    my $self=shift;
    my $f=shift;

    if (!defined(open(X,"<:utf8",$f)))
    {
	$self->_set_err_state($ERR_NEWS_XML_F,
			      "File: \"$f\".");
	return undef;
    }
    my $txt="";
    while (my $l=<X>)
    {
	$txt.=$l;
    }
    close(X);

    return $txt;
}

sub init_output
{
    my $self=shift;
    
    $self->{outputN}=0;
}

sub output_Alvis
{
    my $self=shift;
    my $alvis_records=shift;
    my $base_name=shift;
    
    $self->{recordN}=0;
    for my $alvis_record (@$alvis_records)
    {
	if (!defined($alvis_record))
	{
	    $self->_set_err_state($ERR_DOC_ALVIS_CONV,
				  "Base name:\"$base_name\"," .
				  "# of record: $self->{recordN}");
	    return 0;
	}

	my $out_f;
	if (!defined($self->{alvisSuffix}))
	{
	    $self->_set_err_state($ERR_ALVIS_SUFFIX);
	    return 0;
	}
	if ($self->{outputAtSameLocation})
	{
	    $out_f=$base_name . "." . $self->{articleN} . '.' .
		$self->{alvisSuffix};
	    $self->{articleN}++;
	    if (!$self->_output_set_of_records($alvis_record,$out_f))
	    {
		$self->_set_err_state($ERR_OUTPUT_SET_OF_RECORDS);
		return 0;
	    }
	    $self->{outputN}++;
	    print "$self->{outputN}\r";
	}
	else
	{
	    if (!defined($self->{outputRootDir}))
	    {
		$self->_set_err_state($ERR_NO_OUTPUT_ROOT_DIR);
		return 0;
	    }
	    my $dir=$self->{outputRootDir} . '/' . 
		int($self->{outputN} / $self->{outputNPerSubdir});
	    if ($self->{outputN} % $self->{outputNPerSubdir}==0)
	    {
		mkdir($dir);
	    }
	    $out_f=$dir . '/' . $self->{outputN} . '.' .
		$self->{alvisSuffix};
	    
	    if (!$self->_output_set_of_records($alvis_record,$out_f))
	    {
		$self->_set_err_state($ERR_OUTPUT_SET_OF_RECORDS);
		return 0;
	    }
	    
	    $self->{outputN}++;
	    print "$self->{outputN}\r";
	}
    }

    return 1;
}

############################################################################
#
#          Private methods
#
############################################################################

sub _process_ainodump_doc
{
    my $self=shift;
    my $text=shift;
    my $header=shift;

#    print Dumper($header);
#    print "\n";

    my ($type,$sub_type)=$self->{docTypeWizard}->guess($text);
    if (!(defined($type) && defined($sub_type)))
    {
	$self->_set_err_state($ERR_TYPE_GUESS,
			      $self->{docTypeWizard}->errmsg());
	return 0;
    }

#    print "TYPE:$type,SUBTYPE:$sub_type\n";
    
    if ($type eq 'text' && $sub_type eq 'html')
    {
	my $meta_txt;
	if (defined($header->{url}))
	{
	    $meta_txt.="url\t$header->{url}\n";
	}
	if (defined($header->{time}))
	{
	    $meta_txt.="date\t$header->{time}\n";
	}
 	
	my $base_name;
	if (defined($header->{id}))
	{
	    $base_name=$header->{id};
	}
	else 
	{
	    warn "Ainodump document had no ID. URL,time:" .
		"($header->{url},$header->{time})\n" if $self->{ainodumpWarnings};
	    return 1;
	}

	my $srcenc_setting=$self->{sourceEncoding};
	$self->{sourceEncoding}=undef;
	my $alvisXML=$self->HTML($text,$meta_txt);
	$self->{sourceEncoding}=$srcenc_setting;
	if (!defined($alvisXML))
	{
	    $self->_set_err_state($ERR_ALVIS_CONV);
	    return 0;
	}

	if (!$self->output_Alvis([$alvisXML],$base_name))
	{
	    $self->_set_err_state($ERR_OUTPUT_ALVIS,
				  "Base name: \"$base_name\"");
	    return 0;
	}
    }
    else
    {
	warn "Ainodump document $header->{id} was not of a convertible " .
	     "type: $type/$sub_type.\n" if $self->{ainodumpWarnings};
    }

    return 1;
}

sub _output_set_of_records
{
    my $self=shift;
    my $set_of_records_txt=shift;
    my $path=shift;

    if (!defined(open(OUT,">:utf8",$path)))
    {
	$self->_set_err_state($ERR_WRITING_OUTPUT,"Output file: " .
			      "\"$path\"");
	return 0;
    }
    print OUT "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    print OUT "<documentCollection xmlns=\"http://alvis.info/enriched/\">\n";
    print OUT $set_of_records_txt;
    print OUT "</documentCollection>\n";
    close(OUT);
    
    return 1;
}

sub _get_HTML_txt
{
    my $self=shift;
    my $file_versions=shift;
    my $base_name=shift;
    my $html_suffix=shift;

    my ($html_txt);
    if (defined($html_suffix) && 
	exists($file_versions->{$base_name}{$html_suffix}))
    {
	my $html_f=$base_name . "." . $html_suffix;
	$html_txt=$self->_read_HTML($html_f);
	if (!defined($html_txt))
	{
	    $self->_set_err_state($ERR_READ_HTML,"File:\"$html_f\"");
	    return undef;
	}
    }
    else # no HTML file
    {
	$self->_set_err_state($ERR_NO_HTML_F,"Base name:\"$base_name\"");
	return undef;
    }

    return $html_txt;
}


sub _read_HTML
{
    my $self=shift;
    my $f=shift;

    if (!defined(open(H,"<$f")))
    {
	$self->_set_err_state($ERR_HTML_F,
			      "File: \"$f\".");
	return undef;
    }
    my $txt="";
    while (my $l=<H>)
    {
	$txt.=$l;
    }
    close(H);

    return $txt;
}

sub _parse_newsXML
{
    my $self=shift;
    my $newsXML=shift;

    if ($newsXML=~/^\s*$/isgo)
    {
	return [];
    }

    my @articles=();
    my ($text,$iso_date,$title,$links);

    my $doc;
    eval
    {
	$doc=$self->{XMLParser}->parse_string($newsXML);
    };
    if ($@)
    {
	$self->_set_err_state($ERR_XML_PARSE,"$@");
	return undef;
    }
    
    my $root=$doc->documentElement();

    for my $article ($root->getChildrenByTagName('article'))
    {
	$links=Alvis::Document::Links->new();
	if (!defined($links))
	{
	    $self->_set_err_state($ERR_LINKS);
	    return undef;
	}

	for my $t ($article->getChildrenByTagName('title'))
	{
	    $title=$t->textContent();
	}
	for my $i_d ($article->getChildrenByTagName('iso-date'))
	{
	    $iso_date=$i_d->textContent();
	}
	for my $c ($article->getChildrenByTagName('content'))
	{
	    $text=$c->textContent();
	}
	for my $ls ($article->getChildrenByTagName('links'))
	{
	    for my $l ($ls->getChildrenByTagName('link'))
	    {
		my ($l_text,$l_url);
		my $l_type=$l->getAttribute('type');
		for my $l_t ($l->getChildrenByTagName('anchorText'))
		{
		    $l_text=$l_t->textContent();
		}
		for my $l_u ($l->getChildrenByTagName('location'))
		{
		    $l_url=$l_u->textContent();
		}

		if (!$links->add($l_url,$l_text,$l_type))
		{
		    $self->_set_err_state($ERR_LINK_ADD,
					  "Title:\"$title\", " . $links->errmsg());
		    next;
		}

	    }
	}
	push(@articles,[$text,$iso_date,$title,$links]);
    }

    return \@articles;
}


1;

__END__

=head1 NAME

Alvis::Convert - Perl extension for converting documents from a number of 
different source formats to Alvis XML format.

=head1 SYNOPSIS

 use Alvis::Convert;

 # Create a new instance, outputting under 'out'. Get the detected
 # encoding from sourceEncodingFromMeta.
 #
 my $C=Alvis::Convert->new(outputRootDir=>'out',
	   		   outputNPerSubdir=>1000,
			   outputAtSameLocation=>0,
			   includeOriginalDocument=>0,
                           sourceEncodingFromMeta=>1);
 # Restart output counters
 $C->init_output();

 # Convert e.g. HTML
 for my $html_text (@html)
 {
     my $alvisXML=$C->HTML($html_txt,$meta_txt);
     if (!defined($alvisXML))
     {
	warn $C->errmsg();
	$C->clearerr();
	next;
     }
 
     if (!$C->output_Alvis([$alvisXML]))
     {
         warn $C->errmsg();
         $C->clearerr();
         next;
     }
 }

=head1 DESCRIPTION

Converts document collections of different formats to Alvis XML
format.

=head1 METHODS

=head2 new()

Options:

    fileType                 the MIME type of the source file to convert. 
                             Default: guess.
    sourceEncoding           encoding of the source document. Default: guess.  
    urlFromBasename          extract URL from basename. Default: no.
    outputAtSameLocation     output Alvis XML to the same directories as the
                             source documents. Default: no.
    alvisSuffix              suffix of the output Alvis XML records. Default:
                             'alvis'.
    outputRootDir            root directory for output files. Default: '.'
    outputNPerSubdir         number of records output per subdirectory.
                             Default: 1000
    defaultDocType           first guess document (MIME) type. Default: 'text'.
    defaultDocSubType        first guess document subtype. Default: 'html'.
    defaultEncoding          first guess encoding. Default: 'iso-8859-1'.
    includeOriginalDocument  include original document in the output?
                             Default: yes.
    ainodumpWarnings         issue warnings concerning ainodump conversion?
                             Default: yes.
    sourceEncodingFromMeta   read source encoding from Meta information?
                             Default: no.
    

=head2 HTML()

     my $alvisXML=$C->HTML($html_txt,$meta_txt,
                           {sourceEncoding=>'utf8',
                            sourceEncodingFromMeta=>0
                            });
     if (!defined($alvisXML))
     {
	warn $C->errmsg();
	$C->clearerr();
	next;
     }

=head2 newsXML()

     $meta_txt=$C->read_meta($news_xml_entries{$base_name}{metaF});
     if (!defined($meta_txt))
     {
         warn "Reading meta file " .
              "\"$news_xml_entries{$base_name}{metaF}\" failed. " .
              $C->errmsg();
         $C->clearerr();
         next;
     }
     my $alvisXMLs;
     $xml_txt=$C->read_news_XML($news_xml_entries{$base_name}{xmlF});
     if (!defined($xml_txt))
     {
         warn "Reading the news XML for basename \"$base_name\" failed. " .
               $C->errmsg();
         $C->clearerr();
         next;
     }
     $alvisXMLs=$C->newsXML($xml_txt,$meta_txt,$original_document_text);
     if (!defined($alvisXMLs))
     {
         warn "Obtaining the Alvis versions of the documents inside " .
              "\"$base_name\"'s XML file failed. " . $C->errmsg();
         $C->clearerr();
         next;
     }

=head2 ainodump()

    if (!$C->ainodump($ainodump_file))
    {
       warn "Obtaining the Alvis version of the " .
            "ainodump file \"$dump_entries{$base_name}{ainoF}\" " .
            "failed. " . $C->errmsg() if
              $Warnings;
       $C->clearerr();
    }


=head2 set()

    $C->set('alvisSuffix','foo');

=head2 read_HTML()

    $html_txt=$C->read_HTML($html_file,$meta_txt);
     if (!defined($html_txt))
     {
         warn "Reading the HTML failed. " .
               $C->errmsg();
         $C->clearerr();
         next;
     }

=head2 read_meta()

=head2 read_news_XML()

=head2 init_output()

    Initializes output counters.

=head2 output_alvis()

    $alvisXML=$C->HTML($html_txt,$meta_txt);
    if (!$C->output_Alvis([$alvisXML],$base_name))
    {
        warn "Outputting the Alvis records failed. " . $C->errmsg() if
                $Warnings;
        $C->clearerr();
        next;
    }


=head2 errmsg()

Returns a stack of error messages, if any. Empty string otherwise.

=head1 SEE ALSO

Alvis::Document

=head1 AUTHOR

Kimmo Valtonen, E<lt>kimmo.valtonen@hiit.fiE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kimmo Valtonen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
