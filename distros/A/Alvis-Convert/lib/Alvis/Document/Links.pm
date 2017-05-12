package Alvis::Document::Links;

########################################################################
#
# Storage class for link information
#
#   -- Kimmo Valtonen
#
########################################################################

use strict;
use warnings;

use Carp;
use Data::Dumper;

use strict;

#########################################################################

my ($ERR_OK,
    $ERR_NO_URL,
    $ERR_NO_TYPE
    )=(0..2);

my %ErrMsgs=($ERR_OK=>"",
	     $ERR_NO_URL=>"It would be nice if a URL actually pointed " .
	     "at something.",
	     $ERR_NO_TYPE=>"No type given."
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

sub add
{
    my $self=shift;
    my $url=shift;
    my $anchor_txt=shift;
    my $type=shift;
 
    if (defined($url))
    {
	if (!defined($type))
	{
	    $self->_set_err_state($ERR_NO_TYPE,"URL:$url");
	    return 0;
	}
	if (defined($anchor_txt))
	{
	    $self->{url}{$url}{texts}{$anchor_txt}{type}{$type}++;
	}
	else
	{
	    $self->{url}{$url}{noText}{$type}++;
	}
    }
    else
    {
	my $err_str;
	if (defined($anchor_txt))
	{
	    $err_str="Text:\"$anchor_txt\"";
	}
	$self->_set_err_state($ERR_NO_URL,$err_str);
	return 0;
    }

    return 1;
}

sub get
{
    my $self=shift;

    my @links=();

    for my $url (keys %{$self->{url}})
    {
	for my $text (keys %{$self->{url}{$url}{texts}})
	{
 	    for my $type (keys %{$self->{url}{$url}{texts}{$text}{type}})
	    {
		push(@links,[$url,$text,$type]);
	    }
	}
	if (exists($self->{url}{$url}{noText}))
	{
 	    for my $type (keys %{$self->{url}{$url}{noText}})
	    {
		push(@links,[$url,undef,$type]);
	    }
	}
    }

    return @links;
}

1;
__END__

=head1 NAME

Alvis::Document::Links - Perl extension for representing links
occurring in documents.

=head1 SYNOPSIS

 use Alvis::Document::Links;

 # Create a new instance
 my $l=Alvis::Document::Links->new();
 if (!defined($l))
 {
    die('Ugh!');
 }

 if (!$links->add($url,$anchor_txt,$type))
 {
    die("Faulty link information: " . $links->errmsg());
 }

 for my $link ($links->get())
 {
    my ($url,$anchor_text,$type)=@$link;
    # Do something with the link 
 }

=head1 DESCRIPTION

A module for link information.

=head1 METHODS

=head2 new()

Returns a new instance.

=head2 add($url,$anchor_txt,$type)

Adds a new link. $url and $type are mandatory. 

=head2 get()

Returns all links as ([<url>,<anchor text>,<type>],
                      [<url>,<anchor text>,<type>],...)
If there is no <anchor text>, it is undef.

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
