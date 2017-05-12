package Alvis::Wikipedia::Templates;

$Alvis::Wikipedia::Templates::VERSION='0.1';

use warnings;
use strict;

use Storable;
use Alvis::Wikipedia::WikitextParser;
use Alvis::Wikipedia::Variables;

########################################################################
#
#      Global variables
#
########################################################################

my $DEBUG=0;

#
# Namespace codes and their meaning
#
my %NSCodes=(-2=>'Media',
	     -1=>'Special',
	     0=>'',
	     1=>'Talk',
	     2=>'User',
	     3=>'User talk',
	     4=>'Wikipedia',
	     5=>'Wikipedia talk',
	     6=>'Image',
	     7=>'Image talk',
	     8=>'MediaWiki',
	     9=>'MediaWiki talk',
	     10=>'Template',
	     11=>'Template talk',
	     12=>'Help',
	     13=>'Help talk',
	     14=>'Category',
	     15=>'Category talk',
	     100=>'Portal',
	     101=>'Portal talk');

#
# Variables and their meaning
#
my %VarSubst=(
	       'ns:-2'=>'Media',
	       'ns:Media'=>'Media',
	       'ns:-1'=>'Special',
	       'ns:Special'=>'Special',
	       'ns:1'=>'Talk',
	       'ns:Talk'=>'Talk',
	       'ns:2'=>'User',
	       'ns:User'=>'User',
	       'ns:3'=>'User_talk',
	       'ns:User_talk'=>'User_talk',
	       'ns:4'=>'Wikipedia',
	       'ns:Project'=>'Wikipedia',
	       'ns:5'=>'Wikipedia_talk',
	       'ns:Project_talk'=>'Wikipedia_talk',
	       'ns:6'=>'Image',
	       'ns:Image'=>'Image',
	       'ns:7'=>'Image_talk',
	       'ns:Image_talk'=>'Image_talk',
	       'ns:8'=>'MediaWiki',
	       'ns:MediaWiki'=>'MediaWiki',
	       'ns:9'=>'MediaWiki_talk',
	       'ns:MediaWiki_talk'=>'MediaWiki_talk',
	       'ns:10'=>'Template',
	       'ns:Template'=>'Template',
	       'ns:11'=>'Template_talk',
	       'ns:Template_talk'=>'Template_talk',
	       'ns:12'=>'Help',
	       'ns:Help'=>'Help',
	       'ns:13'=>'Help_talk',
	       'ns:Help_talk'=>'Help_talk',
	       'ns:14'=>'Category',
	       'ns:Category'=>'Category',
	       'ns:15'=>'Category_talk',
	       'ns:Category_talk'=>'Category_talk',
	       'ns:100'=>'Portal',
	       'ns:101'=>'Portal_talk',
	       'SITENAME'=>'wikipedia',
	       'SERVER'=>'http://en.wikipedia.org',
	       'SERVERNAME'=>'en.wikipedia.org',
	       'localurl:'=>'/wiki/',
	       'localurle:'=>'/wiki/',
	       'fullurl:'=>'http://en.wikipedia.org/wiki/'
	       );

#########################################################################
#
#   Error message stuff
#
#########################################################################

my $ErrStr;
my ($ERR_OK,
    $ERR_PARSER,
    $ERR_NORM,
    $ERR_UNK_TEMPL,
    $ERR_PARAM,
    $ERR_NO_TEXT,
    $ERR_NO_TITLE,
    $ERR_NO_NAMESPACE,
    $ERR_STORE,
    $ERR_UNDEF_DUMP,
    $ERR_RETRIEVE
    )=(0..10);
my %ErrMsgs=($ERR_OK=>"",
	     $ERR_PARSER=>"Unable to instantiate Alvis::Wikipedia::WikitextParser.",
	     $ERR_NORM=>"Title normalization failed.",
	     $ERR_UNK_TEMPL=>"Unrecognized template name.",
	     $ERR_PARAM=>"Application of a parameter pattern failed.",
	     $ERR_NO_TEXT=>"Undefined text to expand",
	     $ERR_NO_TITLE=>"Undefined title to expand",
	     $ERR_NO_NAMESPACE=>"Undefined namespace to expand",
	     $ERR_STORE=>"Storable::store() failed.",
	     $ERR_UNDEF_DUMP=>"Trying to dump when there are no definitions.",
	     $ERR_RETRIEVE=>"Storable::retrieve() failed."
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

sub clearerr
{
    my $self=shift;

    $self->{errstr}="";
}

#######################################################################
#
#  Public methods
#
#######################################################################

sub new
{
    my $proto=shift;

    my $class=ref($proto)||$proto;
    my $parent=ref($proto)&&$proto;
    my $self={};
    bless($self,$class);

    $self->_init(@_);

    $self->{parser}=Alvis::Wikipedia::WikitextParser->new();
    if (!defined($self->{parser}))
    {
	$self->_set_err_state($ERR_PARSER);
	return undef;
    }

    return $self;
}

sub _init
{
    my $self=shift;

    $self->{maxExpandedTextSize}=1000000;
    $self->{maxNofExpansions}=10000;

    if (defined(@_))
    {
        my %args=@_;
        @$self{ keys %args }=values(%args);
    }
}

sub dump
{
    my $self=shift;
    my $f=shift;

    if (!defined($self->{defs}))
    {
	$self->_set_err_state($ERR_UNDEF_DUMP);
	return 0;
    }

    my %defs=%{$self->{defs}};
    if (store(\%defs,$f))
    {
	return 1;
    }
    else
    {
	$self->_set_err_state($ERR_STORE,"File:\"$f\".");
	return 0;
    }
}

sub load
{
    my $self=shift;
    my $f=shift;

    my $defs=retrieve($f);
    if (!defined($defs))
    {
	$self->_set_err_state($ERR_RETRIEVE,"File:\"$f\".");
	return 0;
    }
    my %defs=%$defs;
    $self->{defs}=\%defs;

    return 1;
}

sub add
{
    my $self=shift;
    my $name=shift;
    my $def=shift;

    my $norm_name=$self->{parser}->normalize_title($name);
    if (!defined($norm_name))
    {
	$self->_set_err_state($ERR_NORM,"Name:\"$name\".");
	return 0;
    }

    $def=~s/<noinclude>.*?<\/noinclude>//sgo;
    $def=~s/<\/?includeonly>//sgo;
    
    $self->{defs}{$norm_name}=$def;

    return 1;
}

#
#  expand_for_real:  do we try to expand the templates for real
#                    (messy and error-prone) or do we simply replace
#                    with a list of the parameter values?
#
sub expand 
{
    my $self=shift;
    my $namespace=shift;
    my $title=shift;
    my $text=shift;
    my $expand_for_real=shift;

    if (!defined($namespace))
    {
	$self->_set_err_state($ERR_NO_NAMESPACE);
	return undef;
    }
    if (!defined($title))
    {
	$self->_set_err_state($ERR_NO_TITLE);
	return undef;
    }
    if (!defined($text))
    {
	$self->_set_err_state($ERR_NO_TEXT);
	return undef;
    }

    $self->{currNamespace}=$namespace;
    $self->{currTitle}=$title;
    $self->{nofExpansions}=0;

    warn "TRANSCLUDING...\n" if $DEBUG;
    my $expanded_text=$self->_transclude($text,$expand_for_real);
    warn "DONE TRANSCLUDING\n" if $DEBUG;

    return $expanded_text;
}

#
#  expand_for_real:  do we try to expand the templates for real
#                    (messy and error-prone) or do we simply replace
#                    with a list of the parameter values?
#
sub _transclude
{
    my $self=shift;
    my $text=shift;
    my $expand_for_real=shift;

    $self->{higherLevelExpandedNames}={};
    while ($text=~/(([^\{])?\{\{([ %!\"\$\&\'\(\)\*,\-\.\/0-9:;=\?\@A-Z\\\^_\`a-z\~\x80-\xFF\n]*)(\|.*?)?\}\})/sgo)
    {
	$self->{thisLevelExpandedNames}={};
	# Safeguard against malevolent templates 
	if (length($text)>$self->{maxExpandedTextSize} || 
	    $self->{nofExpansions}>$self->{maxNofExpansions})
	{
	    warn "Excessive expansion stopped for \"$self->{currNamespace}:$self->{currTitle}\"" .
		". Length of the text to expand: " .
		length($text) . ", # of expansions: " . $self->{nofExpansions};
		return $text;
	}

	warn "BEFORE VARIABLE SUBSITUTION\n" if $DEBUG;
	# Variable substitution
	$text=~s/(\{\{([ %!\"\$\&\'\(\)\*,\-\.\/0-9:;=\?\@A-Z\\\^_\`a-z\~\x80-\xFF\n]*?)\}\})/$self->_substitute_variable($1,$2)/sgeo;
	warn "TEXT AFTER VARIABLE SUBSTITUTION:$text\n" if $DEBUG;
	
	# Template substitution
	$text=~s/(([^\{])?\{\{([ %!\"\$\&\'\(\)\*,\-\.\/0-9:;=\?\@A-Z\\\^_\`a-z\~\x80-\xFF\n]*)(\|[^\{]*?)?\}\})/$self->_substitute_template($1,$2,$3,$4,$expand_for_real)/sgeo;
	
	warn "TEXT AFTER TEMPLATE SUBSTITUTION:$text\n" if $DEBUG;
    
	for my $name (keys %{$self->{thisLevelExpandedNames}})
	{
	    $self->{higherLevelExpandedNames}->{$name}=1;
	}
    }

    return $text;

}

sub _substitute_variable
{
    my $self=shift;
    my $text=shift;
    my $var_name=shift;
    
    if ($var_name=~/^(localurle?|fullurl):(.*)$/isgo)
    {
	my ($var,$rest)=($1,$2);
	if ($rest)
	{
	    return $VarSubst{$var} . $rest;
	}
	else
	{
	    return $VarSubst{$var};
	}
    }
    elsif (exists($VarSubst{$var_name}))
    {
	return $VarSubst{$var_name};
    }
    elsif ($var_name=~/^(subst|int):/isgo)
    {
	$var_name=~s/^(subst|int)://isgo;
    }
    elsif ($var_name=~/^(FULL)?PAGENAMEE?$/)
    {
	return $self->{currTitle};
    }
    elsif ($var_name=~/^NAMESPACEE?$/)
    {
	return $self->{currNamespace};
    }
    elsif ($var_name=~/^(__NOTOC__|__FORCETOC__|__TOC__|__NOEDITSECTION__|__START__|CURRENT(MONTH|MONTHNAME|MONTHNAMEGEN|MONTHABBREV|DAY|DAYNAME|YEAR|TIME)|NUMBEROFARTICLES|NUMBEROFFILES|PAGENAMEE|NAMESPACE|__END__|thumbnail|thumb|right|left|none|center|centre|framed|enframed|frame|SITENAME|SERVER|SERVERNAME|SCRIPTPATH|__NOTITLECONVERT__|__NOTC__|__NOCONTENTCONVERT__|__NOCC__|CURRENTWEEK|CURRENTDOWREVISIONID)$/go)
    {
	return "$var_name";
    }
    else
    {
	return $text;
    }
}

sub _substitute_template
{
    my $self=shift;
    my $orig_text=shift;
    my $pre_context=shift;
    my $name=shift;
    my $params=shift;
    my $expand_for_real=shift;

    my $found=0;

    my $expanded_text;
    my %arg_assignments=(); 

    $name=$self->{parser}->normalize_title($name);

    warn "substitute_template():" if $DEBUG;
    warn "PRE:\"$pre_context\"\n" if $DEBUG;
    warn "NAME:\"$name\"\n" if $DEBUG;
    warn "PARAMS:\"$params\"\n" if $DEBUG;

    # Don't parse {{{}}} because that's only for template arguments
    if (defined($pre_context) && $pre_context eq '{') 
    {
	warn "{ PRE-CONTEXT\n" if $DEBUG;
	return $orig_text;
    }

    # Ok, now expand if it's a template
    
    # Do we know this template or don't we care anyway?
    if (($name && exists($self->{defs}{$name})) || !$expand_for_real) 
    {
	warn "TEMPLATE $name FOUND\n" if $DEBUG;

	$found=1;
	
	if (defined($pre_context))
	{
	    $expanded_text=$pre_context;
	}

	#
        # Not recommended atm .. the bloody syntax seems to keep
        # on changing with each new server alpha version
	#
	if ($expand_for_real)
	{
	    $expanded_text.=$self->{defs}{$name};
	    warn "TEXT AFTER ADDING EXPANSION:$expanded_text\n" if $DEBUG;
	    
	    if (defined($params))
	    {
		# Collect the parameter assignments 
		my @actual_args=$self->_get_template_call_args($params);
		my $index=1;
		for my $arg (@actual_args)
		{
		    my $eq_pos=index($arg,'=');
		    if ($eq_pos<0) 
		    {
			warn "Adding actual arg \'$index\', value \'$arg\'\n" if $DEBUG;
			$arg_assignments{$index++}=$arg;
		    } 
		    else 
		    {
			$name=substr($arg,0,$eq_pos);
			$name=~s/^\s+//;
			$name=~s/\s+$//;
			my $value=substr($arg,$eq_pos+1);
			$value=~s/^\s+//;
			$value=~s/\s+$//;
			
			warn "Adding actual arg \'$name\', value \'$value\'\n" if $DEBUG;
			$arg_assignments{$name}=$value;
		    }
		}
	    }
	    
	    # Keep track of expanded names
	    $self->{thisLevelExpandedNames}{$name}=1;

	    # Substitute actual parameter values 
	    while ($expanded_text=~/(\{\{\{([ %!\"\$\&\'\(\)\*,\-\.\/0-9:;=\?\@A-Z\\\^_\`a-z\~\x80-\xFF\n]*?)(\|[^\{]*?)?\}\}\})/sgo)
	    {
		$expanded_text=~s/(\{\{\{([ %!\"\$\&\'\(\)\*,\-\.\/0-9:;=\?\@A-Z\\\^_\`a-z\~\x80-\xFF\n]*?)(\|[^\{]*?)?\}\}\})/$self->_substitute_param_value($1,$2,$3,\%arg_assignments)/sgeo;
		warn "TEXT AFTER PARAMETER VALUE SUBSTITUTION:$expanded_text\n" if $DEBUG;
	    }
	    
	    # If the template begins with a table or block-level
	    # element, it should be treated as beginning a new line.
	    if (defined($pre_context) && $pre_context!~/\n/ && $expanded_text=~/^(\{\||:|;|\#|\*)/) 
	    {
		warn "ADDING NEWLINE PRE-CONTEXT\n" if $DEBUG;
		$expanded_text="\n" . $expanded_text;
	    }
	    # remove comments
	    $expanded_text=~s/<!--.*?-->//isgo;   

	}
	else  # play it safe -- shouldn't matter much for search engine
              # purposes
	{
	    if (defined($params))
	    {
		# Collect the parameter assignments 
		my @actual_args=$self->_get_template_call_args($params);
		my $index=1;
		for my $arg (@actual_args)
		{
		    my $eq_pos=index($arg,'=');
		    if ($eq_pos<0) 
		    {
			warn "Adding actual arg \'$index\', value \'$arg\'\n" if $DEBUG;
			$arg_assignments{$index++}=$arg;
		    } 
		    else 
		    {
			$name=substr($arg,0,$eq_pos);
			$name=~s/^\s+//;
			$name=~s/\s+$//;
			my $value=substr($arg,$eq_pos+1);
			$value=~s/^\s+//;
			$value=~s/\s+$//;
			
			warn "Adding actual arg \'$name\', value \'$value\'\n" if $DEBUG;
			$arg_assignments{$name}=$value;
		    }
		}
	    }
	    #
	    # Simply insert the parameter values as a list
	    #
	    $expanded_text.="\n";
	    for my $p (keys %arg_assignments)
	    {
		$expanded_text.="*$arg_assignments{$p}\n";
	    }
	    # If the template begins with a table or block-level
	    # element, it should be treated as beginning a new line.
	    if (defined($pre_context) && $pre_context!~/\n/ && $expanded_text=~/^(\{\||:|;|\#|\*)/) 
	    {
		warn "ADDING NEWLINE PRE-CONTEXT\n" if $DEBUG;
		$expanded_text="\n" . $expanded_text;
	    }
	    # remove comments
	    $expanded_text=~s/<!--.*?-->//isgo if defined($expanded_text);   
	    $expanded_text.="\n";
	    $expanded_text.="----\n"; # to cause a logical section break 

	    return $expanded_text;
	}
    }
    
    if (!$found) 
    {
	warn "AT END. NOT FOUND\n" if $DEBUG;
	#
	# Have to safeguard against retrying this
	#
	return $pre_context . "UNKNOWN_TEMPLATE_$name" if $DEBUG;
    } 
    else 
    {
	$self->{nofExpansions}++;

	warn "AT END. FOUND.\n" if $DEBUG;
	return $expanded_text;
    }
}

#
# Triple brace replacement -- used for template arguments
#
sub _substitute_param_value
{
    my $self=shift;
    my $orig_text=shift;
    my $param_name=shift;
    my $default=shift;
    my $arg_assignments=shift;

    $param_name=~s/^\s+//go;
    $param_name=~s/\s+$//go;
    if (!defined($default))
    {
	$default="";
    }
    else
    {
	$default=substr($default,1); # lose the |
    }

    warn "PARAM VALUE SUBST ENTRY.\n" if $DEBUG;
    warn "ORIG TEXT:$orig_text\n" if $DEBUG;
    warn "PARAM:$param_name\n" if $DEBUG;
    warn "DEFAULT:$default\n" if $DEBUG;
    warn "ARG ASSIGNMENTS:\n" if $DEBUG;
    for my $name (keys(%$arg_assignments))
    {
	warn "\t$name -> $arg_assignments->{$name}\n" if $DEBUG;
    }

    my $subst;
    
    if (exists($arg_assignments->{$param_name})) 
    {
	warn "PARAM HAS BEEN ASSIGNED TO\n" if $DEBUG;
	$subst=$arg_assignments->{$param_name};
    }
    else
    {
	warn "USING DEFAULT\n" if $DEBUG;
	$subst=$default;
    }
    warn "SUBSTITUTE:\"$orig_text\"->\"$subst\"\n" if $DEBUG;
    
    return $subst;
}

#
# Get the actual call argument values. Watch out for bl***y piped links.
#
sub _get_template_call_args
{
    my $self=shift;
    my $args_str=shift;

    if ($args_str eq "") 
    {
	return ();
    }

    # The first char is '|'
    my @args=split(/\|/,substr($args_str,1));

    # If any of the arguments contains a '[[' but no ']]', it needs to be
    # merged with the next arg because the '|' character between belongs
    # to the link syntax and not the template parameter syntax.
    my $argc=scalar(@args);
    for (my $i=0;$i<$argc-1;$i++) 
    {
	if ($self->_substr_count($args[$i],'[[') != 
	    $self->_substr_count($args[$i],']]')) 
	{
	    $args[$i].='|' . $args[$i+1];
	    splice(@args,$i+1,1);
	    $i--;
	    $argc--;
	}
    }
    
    return @args;
}

sub _substr_count
{
    my $self=shift;
    my $string=shift;
    my $substr=shift;

    my $pos=0;
    my $N=0;
    my $match_pos=index($string,$substr,$pos);
    while ($match_pos>=$pos)
    {
        $pos=$match_pos+1;
        $match_pos=index($string,$substr,$pos);
        $N++;
    }

    return $N;
}



1;
