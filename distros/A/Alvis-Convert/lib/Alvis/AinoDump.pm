package Alvis::AinoDump;

use warnings;
use strict;

use Data::Dumper;

$Alvis::AinoDump::VERSION = '0.1';

##############################################################################
#
#  Error messages
#
#############################################################################

my $ErrStr;
my ($ERR_OK,
    $ERR_BYTE_LENGTH,
    $ERR_TOO_SHORT_DOC,
    $ERR_SPLIT,
    $ERR_PROCESS,
    $ERR_READ
    )=(0..5);
my %ErrMsgs=($ERR_OK=>"",
	     $ERR_BYTE_LENGTH=>"No byte length given for a doc.",
	     $ERR_TOO_SHORT_DOC=>"Too short a document.",
	     $ERR_SPLIT=>"Splitting the doc to text and header failed",
	     $ERR_PROCESS=>"Processing the text and the header failed.",
	     $ERR_READ=>"Reading from the filehandle failed."
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
            $ErrStr="";
        }
        else
        {
            $ErrStr.=" " . $ErrMsgs{$errcode};
            if (defined($errmsg))
            {
                $ErrStr.=" " . $errmsg;
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
    return $ErrStr;
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

####################################################################3
#
#  Public methods
#
####################################################################

#
# Has to be a ':raw' stream for the length to work properly
#
sub process_dump
{
    my $self=shift;
    my $fh=shift;
    my $process_cb=shift;
    
    while (my $l=<$fh>)
    {
	chomp $l;
	if ($l!~/^\d+$/)
	{
	    $self->_set_err_state($ERR_BYTE_LENGTH,
				  "Supposed byte length info line:\"$l\".");
	    return 0;
	}
	my $nof_bytes=$l;

	my $doc;
	my $nof_read=sysread($fh,$doc,$nof_bytes);
	if (!defined($nof_read))
	{
	    $self->_set_err_state($ERR_READ);
	    return 0;
	}
	if ($nof_read!=$nof_bytes)
	{
	    $self->_set_err_state($ERR_TOO_SHORT_DOC,
				  "Supposed to be " .
				  "$nof_bytes, filehandle exhausted after " .
				  "$nof_read bytes.");
	    return 0;
	}

	my ($header,$text)=split(/\n---\n/,$doc);
	if (!defined($header) || !defined($text))
	{
	    $self->_set_err_state($ERR_SPLIT,"Doc:\"$doc\".");
	    return 0;
	}
	
	my %header=();
	if ($header=~/^ID\s*(.*)$/mo)
	{
	    $header{id}=$1;
	}
	if ($header=~/^URL\s*(.*)$/mo)
	{
	    $header{url}=$1;
	}
	if ($header=~/^TIME\s*(.*)$/mo)
	{
	    $header{time}=$1;
	}

	my ($cb,@args);
	if (ref($process_cb) eq 'ARRAY')
	{
	    ($cb,@args)=@$process_cb;
	}
	else
	{
	    $cb=$process_cb;
	}

	if (!&{$cb}(@args,$text,\%header))
	{
	     $self->_set_err_state($ERR_PROCESS,"Text:\"$text\",header:",
				   Dumper(%header),".");
	    return 0;
	}
    }

    return 1;
}

1;
