package Alvis::Wikipedia::XMLDump;

use warnings;
use strict;

$Alvis::Wikipedia::XMLDump::VERSION = '0.1';

use Storable;
use Parse::MediaWikiDump;
use Digest::MD5;
use Encode;
use Data::Dumper;

use Alvis::Wikipedia::WikitextParser;
use Alvis::Wikipedia::Variables;
use Alvis::Wikipedia::CatGraph;
use Alvis::Canonical;

########################################################################
#
#  Exported constants
#
#######################################################################

# Record output formats
our ($OUTPUT_HTML,
     $OUTPUT_ALVIS
     )=(0..1);

############################################################################
#
#  Error message stuff
#
############################################################################

my ($ERR_OK,
    $ERR_VAR,
    $ERR_PARSER,
    $ERR_FIRST_PASS,
    $ERR_SECOND_PASS,
    $ERR_TEMPL_ADD,
    $ERR_EXPAND,
    $ERR_DUMP,
    $ERR_TABLE_PARSE,
    $ERR_REC_CB,
    $ERR_HTML,
    $ERR_CAN_DOC_CONV,
    $ERR_ALVIS,
    $ERR_BUILD_CAT_GRAPH,
    $ERR_CATEGORIES,
    $ERR_XML_PARSER,
    $ERR_CAN_DOC_CONVERSION,
    $ERR_ID,
    $ERR_TITLE,
    $ERR_CAT_PAGE_LINKS_ADD,
    $ERR_CAT_GRAPH,
    $ERR_LOAD_TEMPLATES,
    $ERR_CAT_GRAPH_DUMP,
    $ERR_UNK_OUTPUT_FORMAT
    )=(0..23);
my %ErrMsgs=($ERR_OK=>"",
	     $ERR_VAR=>"Unable to instantiate Alvis::Wikipedia::Variables.",
	     $ERR_PARSER=>
	         "Unable to instantiate Alvis::Wikipedia::WikitextParser.",
	     $ERR_FIRST_PASS=>"The first pass over the records failed.",
	     $ERR_SECOND_PASS=>"The main pass over the records failed.",
	     $ERR_TEMPL_ADD=>"Adding the definition of a template failed.",
	     $ERR_EXPAND=>"Variable and template expansion failed.",
	     $ERR_DUMP=>"Opening the SQL dump file failed.",
	     $ERR_TABLE_PARSE=>"Parsing a subtable failed.",
	     $ERR_REC_CB=>"Record handling callback failed.",
	     $ERR_HTML=>"Wikitext -> HTML failed.",
	     $ERR_CAN_DOC_CONV=>
	     "Creating a new instance of Alvis::Canonical failed.",
	     $ERR_ALVIS=>"Converting to Alvis failed",
	     $ERR_BUILD_CAT_GRAPH=>"Adding to the category graph failed.",
	     $ERR_CATEGORIES=>"Determining the categories of an article " .
	     "failed.",
	     $ERR_XML_PARSER=>"Unable to instantiate Parse::MediaWikiDump",
	     $ERR_CAN_DOC_CONVERSION=>"Converting the text from HTML to " .
	     "canonicalDocument format failed",
	     $ERR_ID=>"Calculating the id failed.",
	     $ERR_TITLE=>"Malformed title",
	     $ERR_CAT_PAGE_LINKS_ADD=>"Adding the links of a category page " .
	     "to the graph failed",
	     $ERR_CAT_GRAPH=>"Instantiating CatGraph failed",
	     $ERR_LOAD_TEMPLATES=>"Loading the templates failed.",
	     $ERR_CAT_GRAPH_DUMP=>"Dumping the category graph failed.",
	     $ERR_UNK_OUTPUT_FORMAT=>"Unrecognized XML dump record output " .
	     "format."
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

##########################################################################
#
# Public methods
#
##########################################################################

sub new
{
    my $proto=shift;

    my $class=ref($proto)||$proto;
    my $parent=ref($proto)&&$proto;
    my $self={};
    bless($self,$class);

    $self->_set_err_state($ERR_OK);

    $self->_init(@_);

    $self->{variables}=Alvis::Wikipedia::Variables->new();
    if (!defined($self->{variables}))
    {
	$self->_set_err_state($ERR_VAR);
	return undef;
    }

    $self->{parser}=Alvis::Wikipedia::WikitextParser->new();
    if (!defined($self->{parser}))
    {
	$self->_set_err_state($ERR_PARSER);
	return undef;
    }

    $self->{canDocConverter}=Alvis::Canonical->new(convertCharEnts=>1,
						   convertNumEnts=>1,
						   sourceEncoding=>'utf8');
    if (!defined($self->{canDocConverter}))
    {
	$self->_set_err_state($ERR_CAN_DOC_CONV);
	return undef;
    }

    $self->{catGraph}=Alvis::Wikipedia::CatGraph->new();
    if (!defined($self->{catGraph}))
    {
	$self->_set_err_state($ERR_CAT_GRAPH);
	return undef;
    }

    return $self;
}

sub _init
{
    my $self=shift;

    $self->{expandTemplates}=0;
    $self->{outputFormat}=$OUTPUT_HTML;
    $self->{skipRedirects}=0;
    $self->{categoryWord}='Category';
    $self->{templateWord}='Template';
    $self->{dumpCategoryData}=1;
    $self->{dumpTemplateData}=1;
    $self->{catGraphDumpF}='CatGraph.storable';
    $self->{templateDumpF}='Templates.storable';

    if (defined(@_))
    {
        my %args=@_;
        @$self{ keys %args }=values(%args);
    }
}

#
# opts: hash with fields
#
#     namespaces              ref to a list of namespace identifiers whose
#                             records to extract
#     expandTemplates         flag for true template expansion
#     templateDumpF           template dump file
#     outputFormat            format for result records ($OUTPUT_HTML,
#                             $OUTPUT_ALVIS),...
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
sub extract_records
{
    my $self=shift;
    my $fd=shift;   # dump fd ref 
    my $cb=shift;  # [\&foo,$arg1,$arg2], callback for each [record title,text]
    my $opts=shift;
    my $prog_cb=shift;  # [\&foo,$arg1,$arg2], optional callback for progress 
                        # ('N records processed')

    if (!defined($cb))
    {
	$self->_set_err_state($ERR_XML_PARSER);
	return 0;
    }

    my $prog_txt="";

    my $expand_templates;
    if (exists($self->{expandTemplates}))
    {
	$expand_templates=$self->{expandTemplates};
    }
    if (exists($opts->{expandTemplates}))
    {
	$expand_templates=$opts->{expandTemplates};
    }

    my %namespaces;

    if ($expand_templates)
    {
	if ($opts->{templateDumpF})
	{
	    if (defined($prog_cb))
	    {
		my @prog_cb=@$prog_cb;
		&{$prog_cb[0]}(@prog_cb[1..$#prog_cb],"Loading the templates");
	    }
	    if (!$self->{variables}->load_templates($opts->{templateDumpF}))
	    {
		$self->_set_err_state($ERR_LOAD_TEMPLATES);
		return 0;
	    }
	}
	else # Have to do a pass first to collect the templates
	{
	    $self->{XMLParser}=Parse::MediaWikiDump::Pages->new($fd);
	    if (!defined($self->{XMLParser}))
	    {
		$self->_set_err_state($ERR_XML_PARSER);
		return 0;
	    }
	    
	    my $template_word;
	    if (exists($self->{templateWord}))
	    {
		$template_word=$self->{templateWord};
	    }
	    if (exists($opts->{templateWord}))
	    {
		$template_word=$opts->{templateWord};
	    }

	    $prog_txt="Collecting templates";
	    %namespaces=($template_word=>1);
	    if (!$self->_pass_over_records(\%namespaces,
					   [\&_collect_templates,$self],
					   [$prog_cb,$prog_txt]))
	    {
		$self->_set_err_state($ERR_FIRST_PASS);
		return 0;
	    }
	    
	    if ($self->{dumpTemplateData})
	    {
		$self->{variables}->dump_templates($opts->{templateDumpF});
	    }
	}
    }

    $prog_txt="Expanding variables and converting";
    #
    # Just in case we did a first pass, destroy old instance
    #
    undef $self->{XMLParser};
    $self->{XMLParser}=Parse::MediaWikiDump::Pages->new($fd);
    if (!defined($self->{XMLParser}))
    {
	$self->_set_err_state($ERR_XML_PARSER);
	return 0;
    }

    my $category_word;
    if (exists($self->{categoryWord}))
    {
	$category_word=$self->{categoryWord};
    }
    if (exists($opts->{categoryWord}))
    {
	$category_word=$opts->{categoryWord};
    }

    my $date;
    if ($opts->{date})
    {
	$date=$opts->{date};
    }
    else # pick the current date
    {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=
	    localtime();
	$date=sprintf("%04d%02d%02d",1900+$year,1+$mon,$mday);
    }

    my $output_format;
    if (exists($self->{outputFormat}))
    {
	$output_format=$self->{outputFormat};
    }
    if (exists($opts->{outputFormat}))
    {
	$output_format=$opts->{outputFormat};
    }

    # Pick articles and category pages
    %namespaces=(''=>1,$category_word=>1);
    #
    # Add any other wanted namespaces
    #
    if ($opts->{namespaces})
    {
	for my $ns ($opts->{namespaces})
	{
	    $namespaces{$ns}=1;
	}
    }
    my $p_cb=[@$prog_cb,$prog_txt];
    if (!$self->_pass_over_records(\%namespaces,
				   [\&_return_alvis_record,
				    $self,$cb,$date,$category_word,
				    $expand_templates,$output_format],
				   $p_cb))
    {
	$self->_set_err_state($ERR_SECOND_PASS);
	return 0;
    }

    my $dump_cat_graph;
    if (exists($self->{dumpCatGraph}))
    {
	$dump_cat_graph=$self->{dumpCatGraph};
    }
    if (exists($opts->{dumpCatGraph}))
    {
	$dump_cat_graph=$opts->{dumpCatGraph};
    }

    if ($dump_cat_graph)
    {
	my $cat_graph_f;
	if (exists($self->{catGraphDumpF}))
	{
	    $cat_graph_f=$self->{catGraphDumpF};
	}
	if (exists($opts->{catGraphDumpF}))
	{
	    $cat_graph_f=$opts->{catGraphDumpF};
	}
	if (!$self->{catGraph}->dump_graph($cat_graph_f))
	{
	    $self->_set_err_state($ERR_CAT_GRAPH_DUMP);
	    return 0;
	}
    }

    return 1;
}

#########################################################################
#
#    Private methods
#
#########################################################################

sub _collect_templates 
{ 
    my $self=shift; 
    my $namespace=shift; 
    my $title=shift; 
    my $text=shift;

    if ($namespace eq $self->{templateWord})
    {
	if (!$self->{variables}->add_template($title,$text))
	{
	    $self->_set_err_state($ERR_TEMPL_ADD);
	    return 0;
	}
    }

    return 1;
}

sub _return_alvis_record
{
    my $self=shift;
    my $cb=shift;
    my $mod_date=shift;
    my $category_word=shift;
    my $expand_templates=shift;
    my $output_format=shift;
    my $namespace=shift;
    my $title=shift;
    my $text=shift;
    my $is_redir=shift;

    my $orig_text=$text;
    my $expansion;
    
    $text=~s/<!--.*?-->//sgo;
    
    $title=$self->{parser}->normalize_title($title);
    if (!defined($title))
    {
	$self->_set_err_state($ERR_TITLE,"title: \"$title\"");
	return 0;
    }
    
    $expansion=$self->{variables}->expand($namespace,$title,$text,
					  $expand_templates);
    if (!defined($expansion))
    {
	$self->_set_err_state($ERR_EXPAND);
	return 0;
    }
    $text=$expansion;
    
    if ($namespace ne '')
    { 
	$title="$namespace/$title";
    }
    
    if ($namespace eq $category_word && $self->{dumpCategoryData})
    {
	if (!$self->_add_cat_page_links_to_graph($title,$text))
	{
	    $self->_set_err_state($ERR_CAT_PAGE_LINKS_ADD,
				  "title: \"$title\"");
	    return 0;
	}
    }
    
    my @cb;
    
    if ($output_format eq $OUTPUT_HTML)
    {
	my $html=$self->{parser}->to_HTML($text);
	if (!defined($html))
	{
	    $self->_set_err_state($ERR_HTML);
	    return 0;
	}
	$html="<HTML>\n<BODY>\n" . $html . "</BODY>\n</HTML>\n";	    
	
	@cb=@$cb;
	&{$cb[0]}(@cb[1..$#cb],$title,$mod_date,$output_format,$html,
		  $is_redir,$namespace);
    }
    elsif ($output_format eq $OUTPUT_ALVIS)
    {
	; # Skip HTML and convert directly to Alvis XML to save time
	die("NOT IMPLEMENTED YET!");
	my $alvis_XML;
	
	@cb=@$cb;
	&{$cb[0]}(@cb[1..$#cb],$title,$mod_date,$output_format,
		  $alvis_XML,$is_redir,$namespace);
    }
    else
    {
	$self->_set_err_state($ERR_UNK_OUTPUT_FORMAT,
			      "format: \"$output_format\"");
	return 0;
    }

    return 1;
}

sub _add_cat_page_to_graph
{
    my $self=shift;
    my $namespace=shift;
    my $title=shift;
    my $text=shift;
    my $is_redir=shift;

    my $orig_text=$text;
    my $expansion;
    
    $text=~s/<!--.*?-->//sgo;
    
    $title=$self->{parser}->normalize_title($title);
    if (!defined($title))
    {
	$self->_set_err_state($ERR_TITLE,"title: \"$title\"");
	return 0;
    }
    
    $expansion=$self->{variables}->expand($namespace,$title,$text);
    if (!defined($expansion))
    {
	$self->_set_err_state($ERR_EXPAND);
	return 0;
    }
    $text=$expansion;

    if (!$self->_add_cat_page_links_to_graph($title,$text))
    {
	$self->_set_err_state($ERR_CAT_PAGE_LINKS_ADD,
			      "title: \"$title\"");
	return 0;
    }

    return 1;
}

sub _add_cat_page_links_to_graph
{
    my $self=shift;
    my $title=shift;  # already normalized
    my $text=shift;

    my $cat=$title;

    $text=~s/\[\[(?:(?i)$self->{categoryWord}):(.*?)\]\]/$self->_add_cat_link($cat,$1)/sgoe;

    return 1;
}

sub _add_cat_link
{
    my $self=shift;
    my $cat=shift;
    my $parent_spec=shift;

    my @parts=split(/\|/,$parent_spec);

    my $parent=$self->{parser}->normalize_title($parts[0]);
    if (!defined($parent))
    {
	$self->_set_err_state($ERR_TITLE,
			      "category parent title: \"$parts[0]\"");
	return 0;
    }

    $self->{catGraph}->add_link($cat,$parent);
}

sub _pass_over_records
{
    my $self=shift;
    my $target_namespaces=shift;
    my $cb=shift;
    my $prog_cb=shift;


    $self->{'N'}=0;
    $self->{'n'}=0;

    while (defined(my $page=$self->{XMLParser}->page())) 
    {
	my $namespace;
	my $title=$page->title();
	if ($title=~/^(.*?):(.*)$/)
	{
	    $namespace=$1;
	    $title=$2;
	}
	else
	{
	    $namespace='';
	}

	if (exists($target_namespaces->{$namespace}))
	{
	    my $is_redirect=0;

	    if (defined($page->redirect()))
	    {
		if ($self->{skipRedirects})
		{
		    next;
		}
		else
		{
		    $is_redirect=1;
		}
	    }
	
	    my $text=${$page->text()};
	    $text=$self->_dequote_txt($text);

	    my @cb=@$cb;
	    if (!&{$cb[0]}(@cb[1..$#cb],$namespace,$title,$text,$is_redirect))
	    {
		$self->_set_err_state($ERR_REC_CB,
				      "Title:\"$title\".");
		warn "Handling \"$title\" failed: " . 
		    $self->errmsg();
	    }
	    else
	    {
		$self->{'n'}++;
	    }
	}
	    
	my @prog_cb=@$prog_cb;
	&{$prog_cb[0]}(@prog_cb[1..$#prog_cb],++$self->{'N'},$self->{'n'}) if 
	    defined($prog_cb);
    }

    return 1;
}

sub _dequote_txt
{
    my $self=shift;
    my $text=shift;
    
    $text=~s/\\\'/\'/isgo;
    $text=~s/\\\"/\"/isgo;
    $text=~s/\\n/\n/isgo;

    return $text;
}

sub txt2XMLsafe
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

    return $text;
}


1;
