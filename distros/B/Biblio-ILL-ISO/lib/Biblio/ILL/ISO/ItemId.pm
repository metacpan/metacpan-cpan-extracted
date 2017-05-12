package Biblio::ILL::ISO::ItemId;

=head1 NAME

Biblio::ILL::ISO::ItemId

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ILLString;
use Biblio::ILL::ISO::ItemType;
use Biblio::ILL::ISO::MediumType;

use Carp;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.07.15 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::ItemId is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ILLString
 Biblio::ILL::ISO::ItemType
 Biblio::ILL::ISO::MediumType

=head1 USED IN

 Biblio::ILL::ISO::Request

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Item-Id ::= SEQUENCE {
	item-type	[0]	IMPLICIT Item-Type OPTIONAL,
	held-medium-type	[1]	IMPLICIT Medium-Type OPTIONAL,
	call-number	[2]	ILL-String OPTIONAL,
	author	[3]	ILL-String OPTIONAL,
	title	[4]	ILL-String OPTIONAL,
	sub-title	[5]	ILL-String OPTIONAL,
	sponsoring-body	[6]	ILL-String OPTIONAL,
	place-of-publication 	[7]	ILL-String OPTIONAL,
	publisher	[8]	ILL-String OPTIONAL,
	series-title-number 	[9]	ILL-String OPTIONAL,
	volume-issue	[10]	ILL-String OPTIONAL,
	edition	[11]	ILL-String OPTIONAL,
	publication-date	[12]	ILL-String OPTIONAL,
	publication-date-of-component	[13] ILL-String OPTIONAL,
	author-of-article	[14]	ILL-String OPTIONAL,
	title-of-article	[15]	ILL-String OPTIONAL,
	pagination	[16]	ILL-String OPTIONAL,
 -- DC - 'EXTERNAL' is not currently supported
 --	national-bibliography-no	[17]	EXTERNAL OPTIONAL,
	iSBN	[18]	ILL-String OPTIONAL, -- (SIZE (10))
		-- must conform to ISO 2108-1978
	iSSN	[19]	ILL-String OPTIONAL, -- (SIZE (8))
		-- must conform to ISO 3297-1986
 -- DC - 'EXTERNAL' is not currently supported
 --	system-no	[20]	EXTERNAL OPTIONAL,
	additional-no-letters	[21] ILL-String OPTIONAL,
	verification-reference-source	[22] ILL-String OPTIONAL
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( [$title [, $author [, $call-number]]] )

Creates a new ItemId object. 
 Expects either no paramaters, or
 a title (text string), author (text string), and/or call number (text string).

 These tend to be the most common / minimalist Item identifiers.

 Example:
 my $iid = new Biblio::ILL::ISO::ItemId("My Book","David Christensen","CHR001.1");
 $iid->set_item_type("monograph");
 $iid->set_medium_type("printed");
 $iid->set_pagination("456");
 $iid->set_publication_date("2003");

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($title, $author, $callno) = @_;
	
	$self->{"title"} = new Biblio::ILL::ISO::ILLString($title) if ($title);
	$self->{"author"} = new Biblio::ILL::ISO::ILLString($author) if ($author);
	$self->{"call-number"} = new Biblio::ILL::ISO::ILLString($callno) if ($callno);
    }

    bless($self, ref($class) || $class);
    return ($self);
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 from_asn($href)

Given a properly formatted hash, builds the object.

=cut
sub from_asn {
    my $self = shift;
    my $href = shift;

    foreach my $k (keys %$href) {
	#print ref($self) . "...$k\n";

	if ($k =~ /^item-type$/) {
	    $self->{$k} = new Biblio::ILL::ISO::ItemType();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^held-medium-type$/) {
	    $self->{$k} = new Biblio::ILL::ISO::MediumType();
	    $self->{$k}->from_asn($href->{$k});

	} elsif (($k =~ /^call-number$/)
		 || ($k =~ /^author$/)
		 || ($k =~ /^title$/)
		 || ($k =~ /^sub-title$/)
		 || ($k =~ /^sponsoring-body$/)
		 || ($k =~ /^place-of-publication$/)
		 || ($k =~ /^publisher$/)
		 || ($k =~ /^series-title-number$/)
		 || ($k =~ /^volume-issue$/)
		 || ($k =~ /^edition$/)
		 || ($k =~ /^publication-date$/)
		 || ($k =~ /^publication-date-of-component$/)
		 || ($k =~ /^author-of-article$/)
		 || ($k =~ /^title-of-article$/)
		 || ($k =~ /^pagination$/)
		 || ($k =~ /^iSBN$/)
		 || ($k =~ /^iSSN$/)
		 || ($k =~ /^additional-no-letters$/)
		 || ($k =~ /^verification-reference-source$/)
		 ) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLString();
	    $self->{$k}->from_asn($href->{$k});

	} else {
	    croak "invalid " . ref($self) . " element: [$k]";
	}

    }
    return $self;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_item_type( $itemtype )

 Sets the item's item-type.  
 Expects a valid Biblio::ILL::ISO::ItemType.

=cut
sub set_item_type {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"item-type"} = new Biblio::ILL::ISO::ItemType($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_medium_type( $mt )

 Sets the item's held-medium-type.
 Expects a valid Biblio::ILL::ISO::MediumType.

=cut
sub set_medium_type {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"held-medium-type"} = new Biblio::ILL::ISO::MediumType($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_call_number( $s )

 Sets the item's call-number.
 Expects a text string.

=cut
sub set_call_number {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"call-number"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_author( $s )

 Sets the item's author.
 Expects a text string.

=cut
sub set_author {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"author"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_title( $s )

 Sets the item's title.
 Expects a text string.

=cut
sub set_title {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"title"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_subtitle( $s )

 Sets the item's sub-title.
 Expects a text string.

=cut
sub set_subtitle {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"sub-title"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_sponsoring_body( $s )

 Sets the item's sponsoring-body.
 Expects a text string.

=cut
sub set_sponsoring_body {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"sponsoring-body"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_place_of_publication( $s )

 Sets the item's place-of-publication.
 Expects a text string.

=cut
sub set_place_of_publication {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"place-of-publication"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_publisher( $s )

 Sets the item's publisher.
 Expects a text string.

=cut
sub set_publisher {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"publisher"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_series_title_number( $s )

 Sets the item's series-title-number.
 Expects a text string.

=cut
sub set_series_title_number {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"series-title-number"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_volume_issue( $s )

 Sets the item's volume-issue.
 Expects a text string.

=cut
sub set_volume_issue {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"volume-issue"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_edition( $s )

 Sets the item's edition.
 Expects a text string.

=cut
sub set_edition {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"edition"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_publication_date( $s )

 Sets the item's publication-date.
 Expects a text string.

=cut
sub set_publication_date {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"publication-date"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_publication_date_of_component( $s )

 Sets the item's publication-date-of-component.
 Expects a text string.

=cut
sub set_publication_date_of_component {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"publication-date-of-component"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_author_of_article( $s )

 Sets the item's author-of-article.
 Expects a text string.

=cut
sub set_author_of_article {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"author-of-article"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_title_of_article( $s )

 Sets the item's title-of-article.
 Expects a text string.

=cut
sub set_title_of_article {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"title-of-article"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_pagination( $s )

 Sets the item's pagination (page count).
 Expects a text string.

=cut
sub set_pagination {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"pagination"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_isbn( $s )

 Sets the item's iSBN.
 Expects a text string.

=cut
sub set_isbn {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"iSBN"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_issn( $s )

 Sets the item's iSSN.
 Expects a text string.

=cut
sub set_issn {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"iSSN"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_additional_no_letters( $s )

 Sets the item's additional-no-letters.
 Expects a text string.

=cut
sub set_additional_no_letters {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"additional-no-letters"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_verification_reference_source( $s )

 Sets the item's verification-reference-source.
 Expects a text string.

 Ie - where did this ItemId information come from?

=cut
sub set_verification_reference_source {
    my $self = shift;
    my ($s) = @_;
    
    $self->{"verification-reference-source"} = new Biblio::ILL::ISO::ILLString($s) if ($s);

    return;
}

=head1 SEE ALSO

See the README for system design notes.
See the parent class(es) for other available methods.

For more information on Interlibrary Loan standards (ISO 10160/10161),
a good place to start is:

http://www.nlc-bnc.ca/iso/ill/main.htm

=cut

=head1 AUTHOR

David Christensen, <DChristensenSPAMLESS@westman.wave.ca>

=cut


=head1 COPYRIGHT AND LICENSE

Copyright 2003 by David Christensen

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
