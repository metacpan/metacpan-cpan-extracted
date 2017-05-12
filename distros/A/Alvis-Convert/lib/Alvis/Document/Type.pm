package Alvis::Document::Type;

use warnings;
use strict;

$Alvis::Document::Type::VERSION = '0.1';

use File::Type;

#############################################################################
#
#  Tries to predict the type of a document. Currently pretty crude.
#
#     Kimmo Valtonen
#
#############################################################################

#############################################################################
#
#     Error message stuff
#
#############################################################################

my $ErrStr;
my ($ERR_OK,
    $ERR_DOC,
    $ERR_FILE_TYPE
    )=(0..2);
my %ErrMsgs=($ERR_OK=>"",
	     $ERR_DOC=>"No document.",
	     $ERR_FILE_TYPE=>"Unable to instantiate File::Type"
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

    $self->{fileType}=File::Type->new();
    if (!defined($self->{fileType}))
    {
	$self->_set_err_state($ERR_FILE_TYPE);
	return undef;
    }

    return $self;
}

sub _init
{
    my $self=shift;

    $self->{defaultType}='text';
    $self->{defaultSubType}='plain';

    if (defined(@_))
    {
        my %args=@_;
        @$self{ keys %args }=values(%args);
    }
}

#
# Returns similarly to MIME ($type,$sub_type), but is broader
#
sub guess
{
    my $self=shift;
    my $text=shift;

    $self->_set_err_state($ERR_OK);  # clean the slate

    if (!defined($text))
    {
	$self->_set_err_state($ERR_DOC);
	return undef;
    }
    
    my ($type,$sub_type);

    # Try File::Type first
    my $mime_type=$self->{fileType}->mime_type($text);
    if (!defined($mime_type))
    {
	$type=$self->{defaultType};
	$sub_type=$self->{defaultSubType};
    }
    else
    {
	($type,$sub_type)=split(/\//,$mime_type,-1);
    }

    # If the result is a generic one, check for our types of interest
    # by other means
    # BTW, File::Type should make it clear and checkable what its
    # "I dunno" reply is
    if ($type eq 'application' && $sub_type eq 'octet-stream')
    {
	if ($self->_looks_like_HTML($text))
	{
	    ($type,$sub_type)=('text','html');
	}
	elsif ($self->_looks_like_RSS($text))
	{
	    # not a MIME type
	    ($type,$sub_type)=('text','rss')
	}
    }

    return ($type,$sub_type);
}


sub _looks_like_HTML
{
    my $self=shift;
    my $text=shift;

    #
    # If we're lucky...
    #
    if ($text=~/<!DOCTYPE\s+(\S+)/isgo)
    {
	my $type=$1;
	if ($type=~/(?:html|wml)/igo)
	{
	    return 1;
	}
    }
    # Otherwise, use a weaker way of checking... a single 
    # signature start tag will do. 
    #
    if ($text=~/<(?:(?i)html|body)\W/sgo)
    {
	return 1;
    }

    return 0;
}

sub _looks_like_RSS
{
    my $self=shift;
    my $text=shift;

    #
    # If we're lucky...
    #
    if ($text=~/<!DOCTYPE\s+(\S+)/isgo)
    {
	my $type=$1;
	if ($type=~/(?:rss)/igo)
	{
	    return 1;
	}
    }
    # Otherwise, use a weaker way of checking... a single 
    # signature start tag will do. 
    #
    if ($text=~/<(?:(?i)rss|channel)\W/sgo)
    {
	return 1;
    }

    return 0;
}

1;




1;
__END__

=head1 NAME

Alvis::Document::Type - Perl extension for guessing and checking the type
of a document (an extension of MIME types).

=head1 SYNOPSIS

 use Alvis::Document::Type;

 # Create a new instance
 my $t=Alvis::Document::Type->new(defaultType=>'text',
                                  defaultSubType=>'html');
 if (!defined($t))
 {
    die('Ugh!');
 }

 my ($doc_type,$doc_sub_type)=$t->guess($doc_text);
 if (!(defined($doc_type) && defined($doc_sub_type)))
 {
    die("Guess what? " . $t->errmsg()); 
 }

=head1 DESCRIPTION

Tries to guess the type of a document similarly to MIME types
(type and a subtype).

Adds subtypes 'rss' and 'html' to MIME type 'text'.

=head1 METHODS

=head2 new()

Options:

    defaultType       The default type (text).
    defaultSubType    The default subtype (plain).

=head2 guess($text)

Tries to guess the type of $text.

=head2 errmsg()

Returns a stack of error messages, if any. Empty string otherwise.

=head1 SEE ALSO


=head1 AUTHOR

Kimmo Valtonen, E<lt>kimmo.valtonen@hiit.fiE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kimmo Valtonen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
