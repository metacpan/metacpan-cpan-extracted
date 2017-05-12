package Alvis::Wikipedia::WikitextParser;

$Alvis::Wikipedia::WikitextParser::VERSION = '0.1';

use warnings;
use strict;

########################################################################
#
#  Exported constants
#
########################################################################
#
# Text section types
#
our ($MARKUP,$NOWIKI,$PRE,$MATH,$HIERO,$GALLERY)=
    ('wiki markup','nowiki','pre','math','hiero','gallery');

#######################################################################
#
#  Error message stuff
#
######################################################################

my ($ERR_OK,
    $ERR_UNK_SECTION_TYPE,
    $ERR_NO_TEXT,
    $ERR_UNDEF_TITLE,
    $ERR_ONLY_UNDERSCORES_LEFT,
    $ERR_RELATIVE_PATH,
    $ERR_OVERLONG_TITLE,
    $ERR_HTML_CONVERSION,
    $ERR_MARKUP_SEPARATION
    )=(0..8);
my %ErrMsgs=($ERR_OK=>"",
	     $ERR_UNK_SECTION_TYPE=>"Unrecognized text section type.",
	     $ERR_NO_TEXT=>"No text to separate markup",
	     $ERR_UNDEF_TITLE=>"Undefined title to normalize.",
	     $ERR_ONLY_UNDERSCORES_LEFT=>"Only underscores left in the " .
	     "title to normalize.",
	     $ERR_RELATIVE_PATH=>"Title to be normalized is a path relative " .
	     "to the working directory.",
	     $ERR_OVERLONG_TITLE=>"Title to be normalized is too long.",
	     $ERR_HTML_CONVERSION=>"HTML conversion failed.",
	     $ERR_MARKUP_SEPARATION=>"Separating the wikitext to different " .
	     "categories failed."
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

####################################################################
#
#   Public methods
#
####################################################################

sub new
{
    my $proto=shift;

    my $class=ref($proto)||$proto;
    my $parent=ref($proto)&&$proto;
    my $self={};
    bless($self,$class);

    $self->_init(@_);

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

sub normalize_title
{
    my $self=shift;
    my $title=shift;

    if (!defined($title))
    {
	$self->_set_err_state($ERR_UNDEF_TITLE);
	return undef;
    }

    #
    # subst:, template:, msg: etc.
    #
    $title=~s/^\w*://isgo;

    #
    # Do a bunch of ill-documented & idiotic normalizations.
    # 50,000,000 flies can't be wrong.
    #
    #  space/underscore
    $title=~s/^\s+//isgo;
    $title=~s/\s+$//isgo;
    $title=~s/[ ]+/\_/isgo;
    $title=~s/\_+/\_/isgo;
    $title=~s/^\_+//isgo;
    $title=~s/\_+$//isgo;
    if ($title=~/^\_+$/)
    {
	$self->_set_err_state($ERR_ONLY_UNDERSCORES_LEFT);
	return undef;
    }

    if ($title=~/^\.\.?\/?$/)
    {
	$self->_set_err_state($ERR_RELATIVE_PATH);
	return undef;
    }

    $title=~s/\?/\%3F/isgo;
    $title=~s/\//\&\#47;/isgo;

    #
    # There's also a set of characters which "cannot occur" in 
    # titles, but no info on what to do with them...remove/fail?
    # I'll ignore for now.
    #

    if (length($title)>256)
    {
	$self->_set_err_state($ERR_OVERLONG_TITLE);
	return undef;
    }

    $title=ucfirst($title);

    return $title;
}

sub to_HTML
{
    my $self=shift;
    my $text=shift;

    my $HTML=$self->_convert($text);
    if (!defined($HTML))
    {
	$self->_set_err_state($ERR_HTML_CONVERSION);
	return undef;
    }

    return $HTML;
}

#
# This is no great shakes, a two-pass parser that first
# separates main types of text and then converts them
# according to type 
# Maybe should be replaced by a Wikitext parser library if one
# exists somewhere
sub _convert
{
    my $self=shift;
    my $text=shift;

    my $sep_text=$self->separate_markup($text);
    if (!defined($sep_text))
    {
	 $self->_set_err_state($ERR_MARKUP_SEPARATION," Text:$text");
	 return undef;
    }
    my $res="";
    for my $s (@$sep_text)
    {
	my ($type,$t)=@$s;

	if ($type eq $MARKUP)
	{
	    $t=$self->_convert_markup($t);
	}
	elsif ($type eq $NOWIKI)
	{
	    $t=$self->_convert_nowiki($t);
	}
	elsif ($type eq $PRE)
	{
	    $t=$self->_convert_pre($t);
	}
	elsif ($type eq $MATH)
	{
	    $t=$self->_convert_math($t);
	}
	elsif ($type eq $HIERO)
	{
	    $t=$self->_convert_hiero($t);
	}
	elsif ($type eq $GALLERY)
	{
	    $t=$self->_convert_gallery($t);
	}
	else
	{
	    $self->_set_err_state($ERR_UNK_SECTION_TYPE,
				  " Type:$type");
	}
	
	$res.=$t;
    }

    return $res;
}

sub separate_markup
{
    my $self=shift;
    my $text=shift;

    if (!defined($text))
    {
	$self->_set_err_state($ERR_NO_TEXT);
	return undef;
    }
    #
    # separate no-markup sections first
    #
    my @text=();
    while ($text=~/^(.*?)<nowiki>(.*?)<\/nowiki>(.*?)$/isgo)
    {
	push(@text,[$MARKUP,$1]);
	push(@text,[$NOWIKI,$2]);
	$text=$3;
    }
    push(@text,[$MARKUP,$text]);

    my @text2=();
    for my $t (@text)
    {
	my ($type,$text)=@$t;
	if ($type eq $MARKUP)
	{
	    while ($text=~/^(.*?)<math>(.*?)<\/math>(.*?)$/isgo)
	    {
		push(@text2,[$MARKUP,$1]);
		push(@text2,[$MATH,$2]);
		$text=$3;
	    }
	    push(@text2,[$MARKUP,$text]);
	}
	else
	{
	    push(@text2,[$type,$text]);
	}
    }
    
    my @text3=();
    for my $t (@text2)
    {
	my ($type,$text)=@$t;
	if ($type eq $MARKUP)
	{
	    while ($text=~/^(.*?)<hiero>(.*?)<\/hiero>(.*?)$/isgo)
	    {
		push(@text3,[$MARKUP,$1]);
		push(@text3,[$HIERO,$2]);
		$text=$3;
	    }
	    push(@text3,[$MARKUP,$text]);
	}
	else
	{
	    push(@text3,[$type,$text]);
	}
    }
    
    my @text4=();
    for my $t (@text3)
    {
	my ($type,$text)=@$t;
	if ($type eq $MARKUP)
	{
	    while ($text=~/^(.*?)<gallery>(.*?)<\/gallery>(.*?)$/isgo)
	    {
		push(@text4,[$MARKUP,$1]);
		push(@text4,[$GALLERY,$2]);
		$text=$3;
	    }
	    push(@text4,[$MARKUP,$text]);
	}
	else
	{
	    push(@text4,[$type,$text]);
	}
    }
    
    return \@text4;
}

sub _convert_nowiki
{
    my $self=shift;
    my $t=shift;
    
    return $t;
}

sub _convert_math
{
    my $self=shift;
    my $t=shift;
    
    return "<PRE>$t</PRE>";
}

sub _convert_hiero
{
    my $self=shift;
    my $t=shift;
    
    return "";
}

sub _convert_gallery
{
    my $self=shift;
    my $t=shift;
    
    my $t_g;
    my @rows=split(/\n/,$t);
    for my $r (@rows)
    {
	if ($r=~/^\s*Image:(.*)$/)
	{
	    $t_g.=$self->_handle_images($1);
	}
    }

    return $t_g;
}

sub _convert_template
{
    my $self=shift;
    my $t=shift;
    
    return $t;
}

sub _convert_markup
{
    my $self=shift;
    my $t=shift;

    my $res="";

    my @r=split(/\n/,$t);
    for (my $i=0;$i<scalar(@r);$i++)
    {
	if ($r[$i]=~/^[ ](.*)$/)
	{
	    $res.="<PRE>\n";
	    $res.="$1\n";
	    $i++;
	    while ($i<scalar(@r) && $r[$i]=~/^[ ](.*)$/)
	    {
		$res.="$1\n";
		$i++;
	    }
	    $res.="</PRE>\n";	    
	    if ($i<scalar(@r))
	    {
		$i--; # rewind
	    } 
	}
	elsif ($r[$i]=~/^=====(.*?)=====/)
	{
	     my $text=$self->_handle_text($1);
	    $res.="\n<H5>$text</H5>\n"
	}
	elsif ($r[$i]=~/^====(.*?)====/)
	{
	    my $text=$self->_handle_text($1);
	    $res.="\n<H4>$text</H4>\n"
	}
	elsif ($r[$i]=~/^===(.*?)===/)
	{
	    my $text=$self->_handle_text($1);
	    $res.="\n<H3>$text</H3>\n"
	}
	elsif ($r[$i]=~/^==(.*?)==/)
	{
	    my $text=$self->_handle_text($1);
	    $res.="\n<H2>$text</H2>\n"
	}
	elsif ($r[$i]=~/^([\*\#]+)(.*?)$/)
	{
	    my @stars=split(//,$1);
	    my $text=$self->_handle_text($2);
	    $res.="\n<UL>\n<LI>$text</LI>\n";
	    $i++;
	    my $nof_levels_open=1;
	    my $curr_level=scalar(@stars);
	    while ($i<scalar(@r) && $r[$i]=~/^([\*\#]+)(.*?)$/)
	    {
		@stars=split(//,$1);
		my $text=$self->_handle_text($2);
		my $level=scalar(@stars);
		if ($level>$curr_level)
		{
		    $res.="\n<UL>\n<LI>$text</LI>\n";
		    $nof_levels_open++;
		}
		elsif ($level==$curr_level)
		{
		    
		    $res.="\n<LI>$text</LI>\n";
		}
		else
		{
		    $res.="\n</UL>\n</UL>\n<UL>\n<LI>$text\n";
		    $nof_levels_open=$curr_level--;
		}
		$curr_level=$level;
		$i++;
	    }

	    while ($nof_levels_open--)
	    {
		$res.="\n</UL>\n";	
	    }
	    if ($i<scalar(@r))
	    {
		$i--; # rewind
	    } 
	}
	elsif ($r[$i]=~/^;(.*?):(.*)$/)
	{
	    my $term=$self->_handle_text($1);
	    my $definition=$self->_handle_text($2);
	    $res.="\n<DL>\n<DT>$term</DT>\n<DD>$definition</DD>\n</DL>\n"
	}
 	elsif ($r[$i]=~/^;([^:]*?)$/)
	{
	    my $term=$self->_handle_text($1);
	    $res.="\n<DL>\n<DT>$term</DT>\n";
	    $i++;
	    if ($i<scalar(@r) && $r[$i]=~/^:(.*)$/)
	    {
		my $definition=$self->_handle_text($1);
		$res.="<DD>$definition</DD>\n";
	    }
	    $res.="</DL>\n";
	}
 	elsif ($r[$i]=~/^:(.*?)$/)
	{
	    $res.="<DL><DD>";
	    my $text=$r[$i];
	    $text=~s/^://;
	    $res.=$self->_convert_markup($text);
	    $res.="</DD></DL>\n";
	}
	elsif ($r[$i]=~/^----/)
	{
	    $res.="\n<HR>\n";
	}
	elsif ($r[$i]=~/^$/)
	{
	    $res.="\n<P>\n";
	}
	elsif ($r[$i]=~/^\{\| (.*)$/)
	{
	    $res.="\n<TABLE $1>\n"
	}
	elsif ($r[$i]=~/^\|\}/)
	{
	    $res.="\n</TABLE>\n"
	}
	elsif ($r[$i]=~/^\|\+(?:.*)(?:\|(.*))$/)
	{
	    my $text=$self->_handle_text($1);
	    $res.="\n<CAPTION>$text</CAPTION>\n"
	}
	elsif ($r[$i]=~/^\|\-(.*?)$/)
	{
	    $res.="\n<TR $1>\n";
	}
	elsif ($r[$i]=~/^\!(.*?)(?:\|(.*))$/)
	{
	    my $text=$self->_handle_text($2);
	    $res.="\n<TH $1>$text</TH>\n";
	}
	elsif ($r[$i]=~/^\|(.*)$/)
	{
	    my $cells=$self->_handle_text($1);
	    my @cells=split(/\|\|/,$cells);
	    for my $c (@cells)
	    {
		my ($param,$cell)=split(/\|/,$c);
		if (!defined($cell))
		{
		    $cell=$param;
		    $param="";
		}
		if (defined($param) && defined($cell))
		{
		    $res.="\n<TD $param>$cell</TD>\n";
		}
	    }
	}
	else
	{
	    my $text=$self->_handle_text($r[$i]);
	    $res.="$text\n";
	}
    }

#    $res=$self->_handle_text($res);

    return $res;
}

sub _handle_text
{
    my $self=shift;
    my $txt=shift;
    
    #
    # This is not 100% correct, but the corresponding Parser.php
    # is hacky as h*ll as well and very complicated. Awesome language
    # design. 
    #
    $txt=~s/\'\'\'(.*?)\'\'\'/<STRONG>$1<\/STRONG>/isgo;
    $txt=~s/\'\'(.*?)\'\'/<EM>$1<\/EM>/isgo;

    #
    # References & footnotes
    #
    $txt=~s/<\s*references\s*\/\s*>//isgo;
    $txt=~s/<\s*ref\s*>/<OL><LI>/isgo;
    $txt=~s/<\s*\/ref\s*>/<\/LI><\/OL>/isgo;

    #
    #
    # Lame, but this is basically what Parser.php is forced to fall upon
    # as well. What you design is what you get.
    #
    $txt=~s/\[\[([^\[]*?)\]\]/$self->_handle_internal_link($1)/isgoe;
    $txt=~s/\[\[Image:(.*?)\]\]/$self->_handle_images($1)/isgoe;
    $txt=~s/\[([^\[]*?)\]/$self->_handle_external_link($1)/isgoe;
    
    return $txt;
}

sub _handle_images
{
    my $self=shift;
    my $link_txt=shift;

    my @parts=split(/\|/,$link_txt);

    if (scalar(@parts)==1)
    {
	my $link=$parts[0];
	$link=~s/ /_/sgo;
	return "<IMG src=\"wikipedia/images/$link\">$link</IMG>";
    }
    elsif (scalar(@parts)>=2)
    {
	my ($link,$title)=($parts[0],$parts[$#parts]);
 	$link=~s/ /_/sgo;
	my $title_txt=$self->_handle_text($title);
	if (!defined($title_txt))
	{
	    $title_txt="";
	}
	else
	{
	    $title_txt=~s/^\s+//sgo;
	    $title_txt=~s/\s+$//sgo;
	}
	return "<IMG src=\"wikipedia/images/$link\">$title_txt</IMG>";
    }
    else
    {
	return "[[$link_txt]]";
    }
}

sub _handle_external_link
{
    my $self=shift;
    my $link_txt=shift;

    if ($link_txt=~/^Image:/i)
    {
	return "[$link_txt]";
    }

    my @parts=split(/ /,$link_txt);
    if (scalar(@parts)>1)
    {
	my $text=join(" ",@parts[1..$#parts]);
	
 	$parts[0]=~s/ /_/sgo;
	$text=~s/^\s+//isgo;
	$text=~s/\s+$//isgo;
	return "<A href=\"$parts[0]\">$text</A>";
    }
    elsif (scalar(@parts)==1)
    {
        $parts[0]=~s/ /_/sgo; 
	return "<A href=\"$parts[0]\"></A>";
    }
    else
    {
	return "[$link_txt]"; # Probably sth is wrong...
    }
}

sub _handle_internal_link
{
    my $self=shift;
    my $link_txt=shift;

    if ($link_txt=~/^Image:/i)
    {
	return "[[$link_txt]]";
    }

    my @parts=split(/\|/,$link_txt);
    if (scalar(@parts)==1)
    {
	my $link=$parts[0];
	my $text=$link;
	$text=~s/^\s+//isgo;
	$text=~s/\s+$//isgo;
 	$link=~s/ /_/sgo;
	return "<A href=\"wikipedia/$link\">$text</A>";
    }
    elsif (scalar(@parts)==2)
    {
	my ($link,$title)=@parts[0..1];
	$title=$self->_handle_text($title);
 	$link=~s/ /_/sgo;
	$title=~s/^\s+//isgo;
	$title=~s/\s+$//isgo;
	return "<A href=\"wikipedia/$link\">$title</A>";
    }
    else
    {
	return "[[$link_txt]]";
    }
}

1;
