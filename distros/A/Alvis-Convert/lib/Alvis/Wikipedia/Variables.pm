package Alvis::Wikipedia::Variables;

use warnings;
use strict;

$Alvis::Wikipedia::Variables::VERSION='0.1';

use Alvis::Wikipedia::WikitextParser;
use Alvis::Wikipedia::Templates;

########################################################################
#
#  Global variables
#
#######################################################################



############################################################################
#
#  Error message stuff
#
############################################################################

my ($ERR_OK,
    $ERR_PARSER,
    $ERR_TEMPL,
    $ERR_SEP,
    $ERR_TEMPL_ADD,
    $ERR_EXP,
    $ERR_TEMPL_DUMP,
    $ERR_TEMPL_LOAD
    )=(0..7);
my %ErrMsgs=($ERR_OK=>"",
	     $ERR_PARSER=>"Unable to instantiate WikiLiki::WikitextParser.",
	     $ERR_TEMPL=>"Unable to instantiate WikiLiki::Templates.",
	     $ERR_SEP=>"Separation of markup failed.",
	     $ERR_TEMPL_ADD=>"Adding the definition of a template failed.",
	     $ERR_EXP=>"Variable expansion failed.",
	     $ERR_TEMPL_DUMP=>"Dumping the templates failed.",
	     $ERR_TEMPL_LOAD=>"Loading the templates failed."
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

    $self->{parser}=Alvis::Wikipedia::WikitextParser->new();
    if (!defined($self->{parser}))
    {
	$self->_set_err_state($ERR_PARSER);
	return undef;
    }
    $self->{templates}=Alvis::Wikipedia::Templates->new();
    if (!defined($self->{templates}))
    {
	$self->_set_err_state($ERR_TEMPL);
	return undef;
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

sub add_template
{
    my $self=shift;
    my $name=shift;
    my $def=shift;

    if (!$self->{templates}->add($name,$def))
    {
	$self->_set_err_state($ERR_TEMPL_ADD,
			      "Name:\"$name\", Definition:\"$def\".");
	return 0;
    }

    return 1;
}

sub dump_templates
{
    my $self=shift;
    my $f=shift;
    
    if (!$self->{templates}->dump($f))
    {
	$self->_set_err_state($ERR_TEMPL_DUMP,$self->{templates}->errmsg());
	return 0;
    }

    return 1;
}

sub load_templates
{
    my $self=shift;
    my $f=shift;
    
    if (!$self->{templates}->load($f))
    {
	$self->_set_err_state($ERR_TEMPL_LOAD,$self->{templates}->errmsg());
	return 0;
    }

    return 1;
}

sub expand
{
    my $self=shift;
    my $namespace=shift;
    my $title=shift;
    my $text=shift;
    my $expand_templates_for_real=shift; # do we expand the templates fully?

    #
    # Problems: <math>,<nowiki>...safeguard them
    #
    my $sep_text=$self->{parser}->separate_markup($text);
    if (!defined($sep_text))
    {
	$self->_set_err_state($ERR_SEP,"Text:\"$text\"");
	return "";
    }
    
    my $exp_text="";

    for my $s (@$sep_text)
    {
	my ($type,$t)=@$s;

	if ($type eq $Alvis::Wikipedia::WikitextParser::MARKUP)
	{
#	    warn "MARKUP TO EXPAND:$t\n";

            my $exp_t=$self->{templates}->expand($namespace,$title,$t,
						 $expand_templates_for_real);
            if (!defined($exp_t))
	    {
		$self->_set_err_state($ERR_EXP,"Text:\"$t\"");
		return undef;
	    }
            else
	    {
		$exp_text.=$exp_t;
	    }
	}
	else
	{
	    $exp_text.=$t;
	}
    }
    
    return $exp_text;
}

1;
