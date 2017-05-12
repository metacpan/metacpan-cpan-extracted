package Alvis::Canonical;

use warnings;
use strict;

use Alvis::HTML;

$Alvis::Canonical::VERSION = '0.31';

#############################################################################
#
# Converts an original document in some format to an Alvis canonicalDocument
#
#############################################################################

#############################################################################
#
#     Global variables & constants
#
##############################################################################

my $DEF_WARNINGS=0;    # add warning comments about fixes to the doc? 
my $DEF_CONVERT_CHAR_ENTS=1; # convert "relevant" char ents
my $DEF_CONVERT_NUM_ENTS=1;  # convert numerical entities
my $DEF_SRC_ENC=undef; # guess the source encoding

my $DEBUG=0;

#############################################################################
#
#     Error message stuff
#
#############################################################################

my $ErrStr;
my ($ERR_OK,
    $ERR_NO_HTML_CONV,
    $ERR_HTML_CONV,
    $ERR_CONT2CAN_DOC,
    $ERR_NO_HTML_CLEAN,
    $ERR_MISFORMED_REL_URL,
    $ERR_REL_URL_VS_BASE_MISMATCH
    )=(0..6);
my %ErrMsgs=($ERR_OK=>"",
	     $ERR_NO_HTML_CONV=>"Unable to instantiate the HTML converter",
	     $ERR_HTML_CONV=>"Extracting the contents of HTML failed",
	     $ERR_CONT2CAN_DOC=>"Converting the HTML's contents failed",
	     $ERR_NO_HTML_CLEAN=>"Unable to instantiate the HTML cleaner",
	     $ERR_MISFORMED_REL_URL=>"Misformed relative URL",
	     $ERR_REL_URL_VS_BASE_MISMATCH=>"Cannot match a relative URL " .
	     "and the URL base"
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

sub errmsg
{
    my $self=shift;

    return $self->{errstr};
}

#############################################################################
#
#      Methods
#
##############################################################################
 
sub new
{
    my $proto=shift;

    my $class=ref($proto)||$proto;
    my $parent=ref($proto)&&$proto;
    my $self={};
    bless($self,$class);


    $self->_init(@_);

    $self->_set_err_state($ERR_OK);

    # Removes uninteresting HTML tags, fixes the interesting tags and
    # converts natural language relevant <=#255 character entities to
    # characters and UTF-8 numerical entities to characters if wanted
    $self->{htmlConverter}=
	Alvis::HTML->new(alvisKeep=>0,
			 alvisRemove=>1,
			 obsolete=>1,
			 proprietary=>1,
			 xhtml=>1,
			 wml=>1,
			 keepAll=>1,
			 assertHTML=>0,
			 convertCharEnts=>$self->{convertCharEnts},
 			 convertNumEnts=>$self->{convertNumEnts},
			 sourceEncoding=>$self->{sourceEncoding}
			 ); 
    if (!defined($self->{htmlConverter}))
    {
	$self->_set_err_state($ERR_NO_HTML_CONV,
			      $self->{htmlConverter}->errmsg());
	return undef;
    }

    #
    # Used for removing all HTML tags from parts of the document
    # that don't allow any (like section titles)
    #
    $self->{htmlTagCleaner}=
	Alvis::HTML->new(alvisKeep=>1,
			 alvisRemove=>1,
			 obsolete=>1,
			 proprietary=>1,
			 xhtml=>1,
			 wml=>1,
			 keepAll=>1,
			 assertHTML=>0,
			 convertCharEnts=>$self->{convertCharEnts},
			 convertNumEnts=>$self->{convertNumEnts},
			 sourceEncoding=>$self->{sourceEncoding}
			 );
    if (!defined($self->{htmlTagCleaner}))
    {
	$self->_set_err_state($ERR_NO_HTML_CLEAN,
			      $self->{htmlTagCleaner}->errmsg());
	return undef;
    }

    return $self;
}

sub _init
{
    my $self=shift;

    $self->{warnings}=$DEF_WARNINGS;
    $self->{convertCharEnts}=$DEF_CONVERT_CHAR_ENTS;
    $self->{convertNumEnts}=$DEF_CONVERT_NUM_ENTS;
    $self->{sourceEncoding}=$DEF_SRC_ENC;

    if (defined(@_))
    {
        my %args=@_;
        @$self{ keys %args }=values(%args);
    }
}

#########################################################################
#
#      Public methods
#
######################################################################

#
# Converts (hopefully) any old dirty HTML to Alvis MS3.2 DTD -valid
# canonicalDocument's contents.
#
sub HTML
{
    my $self=shift;
    my $html=shift;
    my $opts=shift;    # if a title/base URL is wished for as well, they are
                    # returned in a header hash with the same keys
                    #  
                    #     title
                    #     baseURL
                    #     sourceEncoding
    
    $self->_set_err_state($ERR_OK);  # clean the slate

    my ($title,$baseURL,$src_enc);
    $title=$opts->{title} if exists($opts->{title} );
    $baseURL=$opts->{title} if exists($opts->{baseURL} );
    $src_enc=$self->{sourceEncoding};
    $src_enc=$opts->{sourceEncoding} if exists($opts->{sourceEncoding} );

    my ($contents,$header)=
	$self->{htmlConverter}->clean($html,
				      {title=>$title,
				       baseURL=>$baseURL,
				       sourceEncoding=>$src_enc});
    if (!defined($contents))
    {
	$self->_set_err_state($ERR_HTML_CONV,"In HTML converter: " . 
			      $self->{htmlConverter}->errmsg());
	return (undef,$header)
    }

    if ($DEBUG)
    {
	open(F,">candoc.cleaned");
	print F $contents;
	close(F);
    }


    # To safeguard the element contents with regard to XML
    $contents=$self->_make_txt_XML_safe($contents);

    # Here goes
    my $can_doc=$self->_contents2canDoc($contents,$header,$src_enc);
    if (!defined($can_doc))
    {
	$self->_set_err_state($ERR_CONT2CAN_DOC);
	return (undef,$header);
    }

    return ($can_doc,$header);
}

#########################################################################
#
#      Private methods
#
######################################################################

sub _contents2canDoc
{
    my $self=shift;
    my $contents=shift; # contains relevant HTML markup
    my $header=shift;   # will be updated with information like links
    my $source_encoding=shift;    

    my $can_doc;

    if ($DEBUG)
    {
	open(F,">candoc.cleanNXMLSafe");
	print F $contents;
	close(F);
    }
    # Convert in order of importance to the structure
    $can_doc=$self->_handle_sections($contents,$source_encoding);
    if ($DEBUG)
    {
	my $can_doc2=$self->_to_alvis($can_doc);
	$can_doc2=$self->_pretty_print($can_doc2);
	open(F,">candoc.aftersections");
	print F $can_doc2;
	close(F);
    }
    $can_doc=$self->_handle_lists($can_doc);
    if ($DEBUG)
    {
	my $can_doc2=$self->_to_alvis($can_doc);
	$can_doc2=$self->_pretty_print($can_doc2);
	open(F,">candoc.afterlists");
	print F $can_doc2;
	close(F);
    }
    $can_doc=$self->_handle_links($can_doc,$header);

    if ($DEBUG)
    {
	my $can_doc2=$self->_to_alvis($can_doc);
	$can_doc2=$self->_pretty_print($can_doc2);
	open(F,">candoc.afterlinks");
	print F $can_doc2;
	close(F);
    }
    # OK, time to put some make-up on and go out
    $can_doc=$self->_to_alvis($can_doc);
    if ($DEBUG)
    {
	my $can_doc2=$self->_pretty_print($can_doc);
	open(F,">candoc.aftertoalvis");
	print F $can_doc2;
	close(F);
    }
    $can_doc=$self->_pretty_print($can_doc);
    if ($DEBUG)
    {
	open(F,">candoc.afterprettyprint");
	print F $can_doc;
	close(F);
    }

    

    return $can_doc;
}

#
# &lt;foo&gt; => <foo> for Alvis tags
#
sub _to_alvis
{
    my $self=shift;
    my $can_doc=shift;

    $can_doc=~s/\&lt;((?:\/)?(?:section|list|item|ulink)(?:\s.*?)?)\&gt;/$self->_alvis_tags2chars($1)/sgoe;

    return $can_doc;
}

#
# Indent and remove empty space
#
sub _pretty_print
{
    my $self=shift;
    my $can_doc=shift; 

    # Remove all extra space 
    $can_doc=~s/\n/ /sgo;
    $can_doc=~s/\s+/ /sgo;

    # Remove emptiness
    $can_doc=~s/<item>\s*<\/item>//sgo;
    $can_doc=~s/<list>\s*<\/list>//sgo;
    $can_doc=~s/<section>\s*<\/section>//sgo;
    $can_doc=~s/<((?:item|list|section)(?:\s.*?)?)>\s+/<$1>/sgo;
    $can_doc=~s/\s+<\/((?:item|list|section)(?:\s.*?)?)>/<\/$1>/sgo;

    # Indent
    $self->{tagLevel}=-1;
    $can_doc=~s/(<(\/)?(section|list|item)(?:\s.*?)?>)/$self->_indent($1,$2,$3)/esgo;

    return $can_doc;
}

sub _indent 
{
    my $self=shift;
    my $all=shift;
    my $end=shift;
    my $tag=shift;

    if ($end)
    {
	$self->{tagLevel}--;
	return $all;
    }
    else
    {
	$self->{tagLevel}++;
	my $ind=join("",("  " x $self->{tagLevel}));
	return "\n$ind$all";
    }
    
}

#
# Find the basic <section> structure. We might add to it, if any 
# potential <list> would contain anything created here. 
#
sub _handle_sections
{
    my $self=shift;
    my $contents=shift;
    my $source_encoding=shift;      

    my $can_doc;

    # Headers first
    #   Fix the headers -- no interleaving allowed. Makes
    #   any subsequent decisions much easier.
    $self->{headerOpen}=0;
    $self->{headerLevel}=0;
    $contents=~s/(\&lt;(\/)?(?:(?i)H(\d))(?:\s.*?)?\&gt;)/$self->_fix_headers($1,$2,$3)/sgoe;
    #   Convert headers to sections with proper structure
    $self->{stack}=();
    $contents=~s/\&lt;(?:(?i)H(\d))(?:\s.*?)?\&gt;(.*?)\&lt;\/[Hh]\1\&gt;/$self->_header($1,$2,$source_encoding)/iesgo;
    #   Close any open headers
    while (defined(my $open_header=pop(@{$self->{stack}})))
    {
	$contents.="\&lt;/section\&gt;";
    }
    #   There can be free text at either end
    $contents="\&lt;section\&gt;\n$contents\&lt;/section\&gt;";

    if ($DEBUG)
    {
	open(F,">candoc.afterheaders");
	my $c2=$self->_to_alvis($contents);
	$c2=$self->_pretty_print($c2);
	print F $c2;
	close(F);
    }
    # Now, do DIVs & Ps, in that order, but similarly. They are thought 
    # to define paragraphs and be overruled by headers. 
    $self->{stack}=();
    $contents=~s/(\&lt;(\/)?((?:(?i)DIV)|section)(?:\s.*?)?\&gt;)/$self->_paragraph($1,$2,$3)/sgoe;
    # Close all tags left open with </section>
    while (defined(my $open_alvis_tag=pop(@{$self->{stack}})))
    {
	if ($open_alvis_tag=~/^(section|div)$/o)
	{
	    $contents.="\&lt;/section\&gt;";
	}
	else
	{
	    die("Should be impossible: non-section/div opening tag " .
		"($open_alvis_tag) left on stack.");
	}
    }

    if ($DEBUG)
    {
	open(F,">candoc.afterdivs");
	my $c2=$self->_to_alvis($contents);
	$c2=$self->_pretty_print($c2);
	print F $c2;
	close(F);
    }

    $self->{stack}=();
    $contents=~s/(\&lt;(\/)?((?:(?i)P)|section)(?:\s.*?)?\&gt;)/$self->_paragraph($1,$2,$3)/sgoe;
    # close all tags left open with </section>
    while (defined(my $open_alvis_tag=pop(@{$self->{stack}})))
    {
	if ($open_alvis_tag=~/^(section|p)$/o)
	{
	    $contents.="\&lt;/section\&gt;";
	}
	else
	{
	    die("Should be impossible: non-section/div opening tag " .
		"($open_alvis_tag) left on stack.");
	}
    }
    if ($DEBUG)
    {
	open(F,">candoc.afterps");
	my $c2=$self->_to_alvis($contents);
	$c2=$self->_pretty_print($c2);
	print F $c2;
	close(F);
    }


    return $contents;
}

#
#  List-type things into <list>s, or <section>s if they would contain any
#  already defined <section>s.
#
sub _handle_lists
{
    my $self=shift;
    my $contents=shift;

    my $can_doc;

    if ($DEBUG)
    {
	open(F,">contents.beforelists");
	print F $contents;
	close(F);
    }
    # OL,UL,DL,TABLE
    #    First pass: Find out which ones do NOT contain already defined 
    #                <section>s => <list>s, others => <section>s
    #
    $self->{stack}=();
    $self->{listTagTypes}=(); # list of types, i.e. 'list' or 'section' 
                              # in order of appearance for each potential 
                              # <list> 
    $contents=~s/(\&lt;(\/)?(DL|UL|OL|TABLE|section)(?:\s.*?)?\&gt;)/$self->_lists_first_pass($1,$2,$3)/isgoe;
    #                Mark all list-type tags left open as <list>s
    while (defined(my $open_tag=pop(@{$self->{stack}})))
    {
	push(@{$self->{listTagTypes}},'list');
    }

    #
    # Second pass: Convert proper list-type tags, including item-type tags,
    #              make others <section>s, and delete any loose end tags
    #
    $self->{stack}=();
    $contents=~s/\&lt;(\/)?(((?i)DL|UL|OL|TABLE|LI|DD|DT|TH|TD|CAPTION))(?:\s.*?)?\&gt;/$self->_lists_second_pass($1,$2)/sgoe;
    # close all tags left open 
    while (defined(my $open_alvis_tag=pop(@{$self->{stack}})))
    {
	if ($open_alvis_tag=~/^(section|list|item)$/)
	{
	    $contents.="\&lt;/$open_alvis_tag\&gt;";
	}
	else
	{
	    die("Should be impossible: non-section/list/item opening tag " .
		"($open_alvis_tag) left on stack.");
	}
    }

    return $contents;
}

#
# Convert a single header tag of a given level 1,..,6
#
sub _header
{
    my $self=shift;
    my $level=shift;
    my $contents=shift;
    my $source_encoding=shift;
    
    my ($l,$txt,$title);
    $txt="";
    #
    # Close all headers that do not overwrap this one 
    #
    while (defined($l=pop(@{$self->{stack}})) && $l >= $level)
    {
	$txt.="\&lt;/section\&gt;";
    }
    push(@{$self->{stack}},$l) if defined $l;
    push(@{$self->{stack}},$level);

    #
    # Remove all HTML tags from the title that goes into the attribute of
    # <section>, and make it otherwise a valid XML attribute value.
    # But leave the title as is for the first subsection. 
    #
    $title=$contents;
    $title=$self->_struct_ents2chars($title);
    my $header;
    ($title,$header)=$self->{htmlTagCleaner}->clean($title,
						    {title=>undef,
						     baseURL=>undef,
						     sourceEncoding=>
							 $source_encoding});
    if (defined($title))
    {
	$title=$self->_make_txt_XML_safe($title);
	$title=$self->_make_attr_XML_safe($title);
	$title=$self->_make_title_safe($title);
	$title=~s/\n/ /sgo;
	$title=~s/\s+/ /sgo;
	$title=~s/^\s*//sgo;
	$title=~s/\s*$//sgo;

	$txt.="\&lt;section title=\"$title\"\&gt;\n";
	$txt.="\&lt;section\&gt;$contents\&lt;/section\&gt;\n";
    }
    else
    {
	$txt.="\&lt;section\&gt;\n";
    }

    return $txt;
}

#
# Make it so no headers interleave. If one opens inside another, close
# the previous one. If one closes inside another, remove. Either it
# has already been closed, or it has no start tag.
#
sub _fix_headers
{
    my $self=shift;
    my $all=shift;
    my $end=shift;
    my $level=shift;
    
    my $txt="";
    if ($end)
    {
	if ($self->{headerOpen} && $level==$self->{headerLevel})
	{
	    $self->{headerOpen}=0;
	    $self->{headerLevel}=0;
	    $txt.=$all;
	}
	else
	{
	    if ($self->{warnings})
	    {
		$txt.="\&lt;!-- Alvis::Canonical warning: H$level close tag " .
		    "inside another header tag. Fixed. --\&gt;";
	    }
	}
    }
    else # a start tag
    {
	if ($self->{headerOpen})
	{
	    if ($self->{warnings})
	    {
		$txt.="\&lt;!-- Alvis::Canonical warning: H$level start " .
		    "tag while waiting for a H$self->{headerLevel} " .
		    "closing tag. Fixed. --\&gt;";
	    }
	    $txt.="\&lt;\/H$self->{headerLevel}\&gt;";
	}
	$self->{headerOpen}=1;
	$self->{headerLevel}=$level;
	$txt.=$all;
    }

    return $txt;
}

#
# Convert a DIV or a P. Semantics: make a paragraph break
# and let the header-induced section structure prevail.
#
sub _paragraph
{
    my $self=shift;
    my $all=shift;
    my $end=shift;
    my $tag=shift;

    my $txt="";
    # If it's an end tag
    if ($end)
    {
	if ($tag=~/^(div|p)$/io)
	{
	    if (defined(my $context=pop(@{$self->{stack}})))
	    {
		if ($context=~/^(div|p)$/o)
		{
		    $txt.="\&lt;/section\&gt;"; # clean closing
		}
		else
		{
		    # Make a break and restore stack
#		    $txt.="\&lt;/section\&gt;\n\&lt;section\&gt;";
		    push(@{$self->{stack}},$context);
		}
	    }
	    # Otherwise, remove...it's a loose end tag
	}
	elsif ($tag eq 'section')
	{
	    my $context;
	    while (defined($context=pop(@{$self->{stack}})) &&
		   $context=~/^(div|p)$/o)
	    {
		# Close any open "paragraph"
		$txt.="\&lt;/section\&gt;\n";
	    }
	    if (!defined($context))
	    {
		die("Should be impossible: no open section.");
	    }
	    if ($context ne 'section')
	    {
		die("Should be impossible: open tag not a section or DIV/P.");
	    }
	    $txt.=$all;
	}
	else
	{
	    die("Should be impossible: unrecognized stack item ($tag).");
	}
    }
    else # a start tag
    {
	if ($tag eq 'section')
	{
	    # Close all immediate DIV/P sections in the context and
	    # restore a header-induced section tag, if any
	    if (defined(my $context=pop(@{$self->{stack}})))
	    {
		if ($context=~/^(div|p)$/o)
		{ 
		    my $open_tag;
		    $txt.="\&lt;/section\&gt;";
		    while (defined($open_tag=pop(@{$self->{stack}})) &&
			   $open_tag=~/^(div|p)$/o)
		    {
			$txt.="\&lt;/section\&gt;";
		    }
		    if (defined($open_tag))
		    {
			push(@{$self->{stack}},$open_tag);
		    }
		}
		else
		{
		    push(@{$self->{stack}},$context);
		}
	    }
	    $txt.=$all;
	}
	elsif ($tag=~/^(div|p)$/io)
	{
	    $txt.="\&lt;section\&gt;";
	}
	else
	{
	    die("Should be impossible: A tag that is neither a " .
		"section,DIV or P ($tag).");
	}

	push(@{$self->{stack}},lc($tag)); # remember to normalize
    }

    return $txt;
}

#
# Make a first pass over potential lists, and separate them to
# those that contain already-defined <section>s and the rest.
# The whole purpose is to build $self->{listTagTypes}, a list
# of <list>-type tag result types in order of appearance.
#
sub _lists_first_pass
{
    my $self=shift;
    my $all=shift;
    my $end=shift;
    my $tag=shift;

    if ($DEBUG)
    {
	warn "FIRST: TAG:$end$tag";
	warn "FIRST: STACK:",join(",",@{$self->{stack}}) if defined($self->{stack});
	warn "FIRST: TLIST:",join(",",@{$self->{listTagTypes}}) if defined($self->{listTagTypes});
}
    
    # If it's an end tag
    if ($end)
    {
	if ($tag=~/^(dl|ol|ul|table)$/io)
	{
	    # OK, the immediate preceding tag is good for a <list>
	    if (defined(my $context=pop(@{$self->{stack}})))
	    {
		push(@{$self->{listTagTypes}},'list');
	    }
	}
	elsif ($tag eq 'section')
	{
	    # mark all preceding open <list>-type tags as sections
	    while (defined(my $context=pop(@{$self->{stack}})))
	    {
		push(@{$self->{listTagTypes}},'section');
	    }
	}
	else
	{
	    die("Should be impossible: a non-section/<list>-type start " .
		"tag ($tag).");
	}
    }
    else # a start tag
    {
	if ($tag eq 'section')
	{
	    # ALL <list>-type tags above need to become sections
	    while (defined(my $context=pop(@{$self->{stack}})))
	    {
		push(@{$self->{listTagTypes}},'section');
	    }
	}
	elsif ($tag=~/^(dl|ol|ul|table)$/io)
	{
	    push(@{$self->{stack}},lc($tag)); # remember to normalize
	}
	else
	{
	    die("Should be impossible: a non-section/<list>-type start tag " .
		"($tag)");
	}
    }

    return $all;
}

#
# Make the second pass. This is by far the most complex step.
# canonicalDocument lists consist of <list>s that contain <item>s, 
# and the corresponding HTML tags might occur anywhere, since we
# make no assumptions about the cleanliness of the HTML.
#
sub _lists_second_pass
{
    my $self=shift;
    my $end=shift;
    my $tag=shift;

    if ($DEBUG)
    {
	warn "2nd: TAG:$end$tag";
	warn "2nd: STACK:",join(",",@{$self->{stack}}) if defined($self->{stack});
	warn "2nd: TLIST:",join(",",@{$self->{listTagTypes}}) if defined($self->{listTagTypes});
    }
    my $txt="";
    #
    # If it's an end tag
    #
    if ($end)
    {
	my $context;
	if (defined($context=pop(@{$self->{stack}})))
	{
	    if ($tag=~/^(dl|ol|ul|table)$/io)
	    {
		if ($context eq 'list')
		{
		    $txt.="\&lt;/list\&gt;";
		}
		elsif ($context eq 'section')
		{
		    $txt.="\&lt;/section\&gt;";
		}
		elsif ($context eq 'item')
		{
		    $txt.="\&lt;/item\&gt;";
		    $context=pop(@{$self->{stack}});
		    if (!defined($context))
		    {
			die("Should be impossible: item-type tag on " .
			    "stack without a context.");
		    }
		    if ($context ne 'list')
		    {
			die("Should be impossible: item-type tag on " .
			    "stack with a non-list-type context.");
		    }
		    $txt.="\&lt;/list\&gt;";
		}
		else
		{
		    die("Should be impossible: unrecognized stack item.");
		}
	    }
	    elsif ($tag=~/^(li|dd|dt|th|td|caption)$/io) # item-type tag
	    {
		if ($context eq 'item')
		{
		    $txt.="\&lt;/item\&gt;";
		    # just in case there's some loose text at the end of list
		    $txt.="\&lt;item\&gt;";
		    push(@{$self->{stack}},'item');
		}
		else 
		{
		    #
		    # ignore i.e. remove and restore stack
		    #
		    push(@{$self->{stack}},$context);
		    $txt=""; 
		}
	    }
	    else
	    {
		die("Should be impossible: non-list type tag ($tag).");
	    }
	}
	# otherwise, remove a loose end tag
    }
    else # a start tag
    {
	if ($tag=~/^(table|dl|ol|ul)$/io)
	{
	    # Check out this tag's type (as determined during the 1st pass)
	    my $type=shift(@{$self->{listTagTypes}});
	    if (defined($type))
	    {
		if ($type eq 'list')
		{
		    my $context=pop(@{$self->{stack}});
		    if (defined($context))
		    {
			if ($context eq 'section')
			{
			    $txt.="\n\&lt;list\&gt;";
			    push(@{$self->{stack}},$context);
			    push(@{$self->{stack}},'list');
			    # just in case there's some loose text in the
			    # beginning
			    $txt.="\&lt;item\&gt;";
			    push(@{$self->{stack}},'item');
			}
			elsif ($context=~/^(list|item)$/o)
			{
			    # otherwise ignore silently .. 1-D lists only
			    # for simplicity + restore the stack
			    push(@{$self->{stack}},$context);
			    
			}
			else
			{
			    die("Should be impossible: Unrecognized " .
				"context type (not 'list', 'item' or " .
				"'section')($context)");
			}
		    }
		    else # No context to worry about
		    {
			$txt.="\n\&lt;list\&gt;";
			push(@{$self->{stack}},'list');
			# just in case there's some loose text in the beginning
			$txt.="\&lt;item\&gt;";
			push(@{$self->{stack}},'item');
		    }
		}
		elsif ($type eq 'section') # section-type list start tag
		{
		    my $context=pop(@{$self->{stack}});
		    if (defined($context))
		    {
			if ($context eq 'section')
			{
			    $txt.="\n\&lt;section\&gt;";
			    push(@{$self->{stack}},$context);
			    push(@{$self->{stack}},'section');
			}
			elsif ($context=~/^(list|item)$/o)
			{
			    # Close the previous lists/items and remove 
			    # from the stack
			    $txt.="\&lt;/$context\&gt;";
			    while (defined($context=pop(@{$self->{stack}})) &&
				   $context=~/^(list|item)$/o)
			    {
				$txt.="\&lt;/$context\&gt;";
			    }
			    if (defined($context))
			    {
				if ($context eq 'section')
				{
				    # restore a section context, if any
				    push(@{$self->{stack}},$context);
				}
				else
				{
				    die("Should be impossible: non-section/" .
					"list/item type context ($context)");
				}
			    }

			    $txt.="\n\&lt;section\&gt;";
			    push(@{$self->{stack}},'section');
			}
			else
			{
			    die("Should be impossible: Unrecognized " .
				"context type (non-section/list/item) " .
				"($context)");
			}
		    }
		    else # no context for a section start tag
		    {
			$txt.="\n\&lt;section&gt;";
			push(@{$self->{stack}},'section');
		    }
		}
		else # non-list/section type
		{
		    die("Should be impossible: list start " .
			"tag with a funky type ($type).");
		}
	    }
	    else # no predefined type
	    {
		die("Should be impossible: list start tag " .
		    "with no corresponding type.");
	    }
	}
	elsif ($tag=~/^(li|dd|dt|th|td|caption)$/io) # a potential item start tag
	{
	    my $context=pop(@{$self->{stack}});
	    if (defined($context))
	    {
		my $type;
		if ($context eq 'list')
		{
		    $txt.="\n  \&lt;item\&gt;";
		    push(@{$self->{stack}},$context);
		    push(@{$self->{stack}},'item');
		    
		}
		elsif ($context eq 'item')
		{
		    # close the previous item
		    $txt.="\&lt;/item\&gt;\n  \&lt;item\&gt;";
		    push(@{$self->{stack}},'item');
		}
		elsif ($context eq 'section')
		{
		    # List start tag missing or converted to a section.
		    # Several alternatives would make sense, but for now,
		    # close the preceding section and start a new one.
		    # Avoids unnecessary structural depth.
		    $txt.="\&lt;/section\&gt;\n  \&lt;section\&gt;";
		    push(@{$self->{stack}},$context);
		}
	    }
	    # Otherwise it's a loose item-type start tag => remove
	}
	else
	{
	    die("Should be impossible: a list tag that is neither of " .
		"<list> or <item> type ($tag).");
	}
    }

    return $txt;
}

sub _handle_links
{
    my $self=shift;
    my $can_doc=shift;
    my $header=shift;

    #
    # Fix links which contain already defined Alvis structures or other 
    # links (links cannot nest in Alvis)
    #
    if ($DEBUG)
    {
	my $can_doc2=$self->_to_alvis($can_doc);
	$can_doc2=$self->_pretty_print($can_doc2);
	open(F,">candoc.before");
	print F $can_doc2;
	close(F);
    }

    $self->{stack}=();
    $can_doc=~s/(\&lt;(\/)?((?:(?i)A|FRAME|IFRAME)|section|list|item)(?:\s.*?)?\&gt;)/$self->_fix_links($1,$2,$3)/sgoe;
    # close all tags left open 
#    warn "STACK:", join("|",@{$self->{stack}});
    while (defined(my $open_alvis_tag=pop(@{$self->{stack}})))
    {
	if ($open_alvis_tag=~/^(a|frame|iframe)$/o)
	{
	    $can_doc.="\&lt;/$open_alvis_tag\&gt;";
	}
	else
	{
	    die("Should be impossible: non-link opening tag " .
		"($open_alvis_tag) left on stack.");
	}
    }

    if ($DEBUG)
    {
	$can_doc=$self->_to_alvis($can_doc);
	$can_doc=$self->_pretty_print($can_doc);
	open(F,">candoc.after");
	print F $can_doc;
    }

    $self->{stack}=();
    $can_doc=~s/\&lt;(A|FRAME|IFRAME)(\s.*?)?\&gt;(.*?)\&lt;\/\1\&gt;/$self->_link($1,$2,$3,$header)/isgoe;

    if ($DEBUG)
    {
	my $can_doc2=$self->_to_alvis($can_doc);
	$can_doc2=$self->_pretty_print($can_doc2);
	open(F,">candoc.after_link");
	print F $can_doc2;
    }

    return $can_doc;
}

#
# Fixes links so they do not interleave with each other or ANY kind of element
#
sub _fix_links
{
    my $self=shift;
    my $all=shift;
    my $end=shift;
    my $tag=shift;

    if ($DEBUG)
    {
	warn "ALL:$all";
	warn "STACK NOW:",join("|",@{$self->{stack}}) if defined($self->{stack});
    }

    my $txt="";
    # If it's an end tag
    if ($end)
    {
	if ($tag=~/^(a|frame|iframe)$/io)
	{
	    # Close an immediate matching link tag in the context, if any 
	    if (defined(my $context=pop(@{$self->{stack}})))
	    {
		if ($context eq lc($tag))
		{
		    $txt.="\&lt;/$context\&gt;";
		}
		else
		{
		    # ignore this closing tag, it's misplaced/overruled
		    push(@{$self->{stack}},$context);
		}
	    }
	    # ignore this closing tag, it's misplaced/overruled
	}
	elsif ($tag=~/^(section|list|item)$/o) 
	{
	    # Close an immediate link tag in the context, if any 
	    if (defined(my $context=pop(@{$self->{stack}})))
	    {
		if ($context=~/^(a|frame|iframe)$/)
		{
		    $txt.="\&lt;/$context\&gt;";
		    # close the surrounding structure
		    if (defined(my $context=pop(@{$self->{stack}})))
		    {
			if ($tag ne $context)
			{
			    die("Should be impossible: mismatch of already " .
				"fixed immediate Alvis opening tag ($context) " .
				"and closing tag ($tag).");
			}
			
		    }
		    else
		    {
			die("Should be impossible: no already fixed " .
			    "immediate Alvis $tag tag to close surrounding " .
			    "a link tag.");
		    }
		}
		else # non-link context
		{
		    if ($tag ne $context)
		    {
			die("Should be impossible: mismatch of already " .
			    "fixed immediate Alvis opening tag ($context) " .
			    "and closing tag ($tag).");
		    }
		}
	    }
	    else # no context to close...wtf?
	    {
		die("Should be impossible: no already fixed immediate Alvis " .
		    "$tag tag to close");
	    }
	    $txt.=$all;
	}
	else
	{
	    die("Should be impossible: unrecognized closing tag type ($tag).");
	}
    }
    else # a start tag
    {
	# Whatever the tag is,
	# close an immediate matching link tag in the context, if any 
	if (defined(my $context=pop(@{$self->{stack}})))
	{
	    if ($context=~/^(a|frame|iframe)$/)
	    {
		$txt.="\&lt;/$context\&gt;";
	    }
	    else
	    {
		push(@{$self->{stack}},$context);
	    }
	}

	push(@{$self->{stack}},lc($tag)); # remember to normalize

	$txt.=$all;
    }

    return $txt;
}

sub _link
{
    my $self=shift;
    my $tag=shift;
    my $params=shift;
    my $text=shift;
    my $header=shift;

    my $txt="";
    my $url;

    my %link=();
    $link{type}=lc($tag);
    if ($link{type} eq 'a')
    {
	if (defined($params) && $params=~/href\s*=\s*([\"\'])(.*?)\1/isgo)
	{
	    $url=$self->_handle_url($2,$header->{baseURL});
	}
    }
    elsif ($link{type}=~/^(frame|iframe)$/o)
    {
	if (defined($params) && $params=~/src\s*=\s*([\'\"])(.*?)\1/isgo)
	{
	    $url=$self->_handle_url($2,$header->{baseURL});
	}
    }
    else
    {
	die("Should be impossible: Unrecognized link type ($tag).");
    }

    $text=~s/^\s+//isgo;
    $text=~s/\s+$//isgo;

    # If the URL is ok, proceed
    if (defined($url))
    {
	$url=$self->_make_attr_XML_safe($url);

	$link{url}=$url;

	if (defined($text))
	{
	    $link{text}=$text;
	}
	
	push(@{$header->{links}},\%link);

	if (defined($text))
	{
	    $txt="\&lt;ulink url=\"$link{url}\"\&gt;$text\&lt;/ulink\&gt;";
	}
	else
	{
	    $txt="\&lt;ulink url=\"$link{url}\"\&gt;\&lt;/ulink\&gt;";
	}
    }
    else # remove this non-interesting link (but retain the anchor text)
    {
	if (defined($text))
	{
	    $txt="$text";
	}
	else
	{
	    $txt="";
	}
    }

    return $txt;
}

sub _handle_url
{
    my $self=shift;
    my $url=shift;
    my $base=shift;

    if ($url=~/^\#/)
    {
	return undef; # doc-internal
    }
    elsif ($url=~/^javascript:/)
    {
	return undef;
    }
    elsif (defined($base))
    {
	if ($url=~/^\.\.\//)
	{
	    # a relative path
	    my $u=$url;
	    my $n=0;
	    while ($u=~/^\.\.\/(.*)$/o)
	    {
		$u=$1;
		$n++;
	    }
	    if (!defined($u))
	    {
		$self->_set_err_state($ERR_MISFORMED_REL_URL,"($url)");
		return undef;
	    }
	    while ($base=~/^(.*\/).*?\/?$/o && $n>0)
	    {
		$base=$1;
		$n--;
	    }
	    if (defined($base))
	    {
		$url=$base . $u;
	    }
	    else
	    {
		$self->_set_err_state($ERR_REL_URL_VS_BASE_MISMATCH);
		return undef;
	    }
	}
	elsif ($url!~/^(?:\w*(?:\w|\d|\+|\-|\.)):/iso)
	{
	    # Base-relative
	    $url=$base . $url;
	}
    }

    return $url;
}

sub _loose_txt_at_list_start2items
{
    my $self=shift;
    my $text=shift;
    my $next_tag=shift;

    my $txt="";
    if ($text!~/\&lt;(item|section|list)\&gt;/sgo)
    {
	# loose text
	$txt="\&lt;list\&gt;\&lt;item\&gt;$text\&lt;/item\&gt;\&lt;$next_tag\&gt;";
    }
    else
    {
	$txt="\&lt;list\&gt;$text\&lt;$next_tag\&gt;";
    }

    return $txt;
}

sub _loose_txt_at_list_end2items
{
    my $self=shift;
    my $text=shift;

    my $txt="";
    if ($text=~/\S/sgo && $text!~/\&lt;\/?(item|section|list)\&gt;/go)
    {
	# loose text
	$txt="\&lt;/item\&gt;\&lt;item\&gt;$text\&lt;/item\&gt;\&lt;/list\&gt;";
    }
    else
    {
	$txt="\&lt;/item\&gt;$text\&lt;/list\&gt;";
    }

    return $txt;
}

sub _loose_txt_btw_items2items
{
    my $self=shift;
    my $text=shift;

    my $txt="";
    if ($text=~/\S/sgo && $text!~/\&lt;\/?(item|section|list)\&gt;/go)
    {
	# loose text
	$txt="\&lt;/item\&gt;\&lt;item\&gt;$text\&lt;/item\&gt;\&lt;item\&gt;";
    }
    else
    {
	$txt="\&lt;/item\&gt;\&lt;item\&gt;";
    }

    return $txt;
}

sub _struct_chars2ents
{
    my $self=shift;
    my $text=shift;
    
    if (!defined($text))
    {
	return undef;
    }

    $text=~s/\&/\&amp;/go;
    $text=~s/</\&lt;/go;
    $text=~s/>/\&gt;/go; 

    return $text;
}

sub _struct_ents2chars
{
    my $self=shift;
    my $text=shift;
    
    if (!defined($text))
    {
	return undef;
    }

    $text=~s/\&amp;/\&/go;
    $text=~s/\&lt;/</go;
    $text=~s/\&gt;/>/go;

    return $text;
}

sub _make_title_safe
{
    my $self=shift;
    my $text=shift;
    
    if (!defined($text))
    {
	return undef;
    }

    return $self->_make_txt_XML_safe($text);
}

sub _make_txt_XML_safe
{
    my $self=shift;
    my $text=shift;

    if (!defined($text))
    {
	return undef;
    }

    $text=$self->_struct_chars2ents($text);

    #
    # Remove illegal chars (What a pain XML is!)
    #
    $text=~tr/\000-\010\013-\014\016-\037//d;

    return $text;
}

sub _make_attr_XML_safe
{
    my $self=shift;
    my $text=shift;

    if (!defined($text))
    {
	return undef;
    }

     $text=~s/\"/\&quot;/go;

    return $text;
}

sub _alvis_tags2chars
{
    my $self=shift;
    my $contents=shift;

    return "<$contents>";
}

1;
__END__

=head1 NAME

Alvis::Canonical - Perl extension for converting documents in various formats into the Alvis canonical format for documents 

=head1 SYNOPSIS

 use Alvis::Canonical;

 # Create a new instance, specify the conversion of both numeric and 
 # symbolic character entities to Unicode characters
 my $C=Alvis::Canonical->new(convertCharEnts=>1,
                             convertNumEnts=>1);
 if (!defined($C))
 {
     die("Unable to instantiate Alvis::Canonical.");
 }

 # Convert an HTML document text in UTF-8 to the canonical format.
 # Specify that you want the title and baseURL as well, if any can be
 # determined.
 my ($txt,$header)=$C->HTML($html,
                            {title=>1,
         		     baseURL=>1});
 if (!defined($txt))
 {
    die $C->errmsg();
 }

=head1 DESCRIPTION

Assumes the input is in UTF-8 and does NOT contain '\0's (or rather that 
they carry no meaning and are removable). 

=head1 METHODS

=head2 new()

Available options:

    warnings         Issue warnings about badly faulty original HTML where
                     we have to resort to an heuristic solution.
                     Puts a warning to STDERR documenting the error and
                     the solution. Default: no.
    convertCharEnts  Convert HTML symbolic character entities to UTF-8 
                     characters? Default: yes.
    convertNumEnts   Convert HTML numerical character entities to UTF-8 
                     characters? Default: yes.
    sourceEncoding   the encoding of the source documents. Default: undef,
                     which means it is guessed.  
     
  my $C=Alvis::Canonical->new(convertCharEnts=>1,
                              convertNumEnts=>1);
  if (!defined($C))
  {
    die die("Unable to instantiate Alvis::Canonical.");
  }

=head2 HTML($html,$options)

Converts dirty HTML to a valid Alvis canonicalDocument. $options is
a mechanism for returning the title and base URL of the document.
If their extraction is desired, set fields 'title' and 'baseURL'
to a defined value. If you know the encoding of the source document,
set option 'sourceEncoding', e.g. 

  my ($txt,$header)=$C->HTML($html,
                            {title=>1,
         		     baseURL=>1,
                             sourceEncoding=>'iso-8859-2'});

=head2 errmsg()

Returns a stack of error messages, if any. Empty string otherwise.

=head1 SEE ALSO

Alvis::Convert

=head1 AUTHOR

Kimmo Valtonen, E<lt>kimmo.valtonen@hiit.fiE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kimmo Valtonen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
