package Data::Microformat::hCard;
use base qw(Data::Microformat);

use strict;
use warnings;

our $VERSION = "0.04";

use Data::Microformat::adr;
use Data::Microformat::geo;
use Data::Microformat::hCard::type;
use Data::Microformat::hCard::name;
use Data::Microformat::hCard::organization;

sub class_name { "vcard" }
sub singular_fields { qw(fn n bday tz geo sort_string uid class) }
sub plural_fields { qw(adr agent category email key label logo mailer nickname note org photo rev role sound tel title url) }

sub is_representative
{
	my $self = shift;
	if ($self->{_representative})
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub from_tree
{
	my $class = shift;
	my $tree = shift;

	my $representative_url = shift;
	if ($representative_url)
	{
		$representative_url = _normalize_url($representative_url);
	}
	

	my $rel_me = "";
	
	my @all_cards;
	my @cards = $tree->look_down("class", qr/vcard/);
	
	#First: build the list of things we recognize;
	my $recognized_regex = "(";
	foreach my $field (	(   Data::Microformat::adr->singular_fields,
							Data::Microformat::adr->plural_fields,
							Data::Microformat::adr->class_name,
							Data::Microformat::geo->singular_fields,
							Data::Microformat::geo->plural_fields,
							Data::Microformat::geo->class_name,
							Data::Microformat::hCard::name->singular_fields,
							Data::Microformat::hCard::name->plural_fields,
							Data::Microformat::hCard::name->class_name,
							Data::Microformat::hCard::organization->singular_fields,
							Data::Microformat::hCard::organization->plural_fields,
							Data::Microformat::hCard::organization->class_name,
							Data::Microformat::hCard::type->singular_fields,
							Data::Microformat::hCard::type->plural_fields,
							Data::Microformat::hCard::type->class_name,
							Data::Microformat::hCard->singular_fields,
							Data::Microformat::hCard->plural_fields,
							Data::Microformat::hCard->class_name, ))
	{
		$field =~ s/\_/\-/;
		$recognized_regex .= '(^|\s)'.$field.'($|\s)|';
	}
	chop($recognized_regex);
	$recognized_regex .= ")";
	

	foreach my $card_tree (@cards)
	{
		# Walk the tree looking for useless bits
		# Where class is undefined
		my @useless = $card_tree->look_down("class", undef);
		foreach my $element (@useless)
		{
			my @kids = $element->detach_content;
			my $parent = $element->detach;
			if (@kids)
			{
				$parent->push_content(@kids);
			}
			$element->delete;
		}
		
		@useless = $card_tree->look_down(sub{
			if ($_[0]->attr('class'))
			{
				return $_[0]->attr('class') !~ m/$recognized_regex/;
			}
			else
			{
				return 1;
			}});
		
		foreach my $element (@useless)
		{
			my @kids = $element->detach_content;
			my $parent = $element->detach;
			if (@kids)
			{
				$parent->push_content(@kids);
			}
			$element->delete;
		}
		
		my $card = Data::Microformat::hCard->new;
        $card->{_no_dupe_keys} = 1;

		my @bits = $card_tree->content_list;
		
		foreach my $bit (@bits)
		{
			if (ref($bit) eq "HTML::Element")
			{
				my $nested_goes_here;
				my $hcard_class = $bit->attr('class');
				next unless $hcard_class;
				
				#Check for nested vcard.
				if ($hcard_class =~ m/vcard/)
				{
					#We have a nested class in here. Mark where it needs to go.
					my $temp_hcard_class = $hcard_class;
					$temp_hcard_class =~ s/vcard//;
					$temp_hcard_class = $class->_trim($temp_hcard_class);
					my @types = split(" ", $temp_hcard_class);
					if (scalar @types > 0)
					{
						$nested_goes_here = $types[0];
						$hcard_class =~ s/$nested_goes_here//;
						$hcard_class = $class->_trim($hcard_class);
						#We do this so that if the type is, for instance,
						# "agent vcard," that we just put the vcard in
						# agent, and not anywhere else.
						# vcard *MUST* have another class, otherwise we''ll
						# discard it.
					}
				}
				my @types = split(" ", $hcard_class);
				foreach my $type (@types)
				{
					$type =~ s/\-/\_/;
					$type = $class->_trim($type);
					
					my $data;
					my @cons = $bit->content_list;
					
					unless (scalar @cons > 1)
					{
						$data = $class->_trim($cons[0]);
						if ($bit->tag eq "abbr" && $bit->attr('title'))
						{
							$data = $class->_trim($bit->attr('title'));
						}
						elsif ($bit->tag eq "a" && $bit->attr('href'))
						{
							if ($type =~ m/(photo|logo|agent|sound|url)/)
							{
								$data = $class->_trim($class->_url_decode($bit->attr('href')));
								if ($bit->attr('rel') && $bit->attr('rel') eq "me")
								{
									$rel_me = $data;
								}
							}
						}
						elsif ($bit->tag eq "object" && $bit->attr('data'))
						{
							if ($type =~ m/(photo|logo|agent|sound|url)/)
							{
								$data = $class->_trim($bit->attr('data'));
							}
						}
						elsif ($bit->tag eq "img")
						{
							if ($type =~ m/(photo|logo|agent|sound|url)/ && $bit->attr('src'))
							{
								$data = $class->_trim($bit->attr('src'));
							}
							elsif ($bit->attr('alt'))
							{
								$data = $class->_trim($bit->attr('alt'));
							}
						}
					}
					
					if ($type eq "vcard")
					{
						my $nestedcard = $class->from_tree($bit);
						if ($nested_goes_here)
						{
							$card->$nested_goes_here($nestedcard);
						}
					}
					elsif ($type eq "tel")
					{
						my $tel = Data::Microformat::hCard::type->from_tree($bit);
						$card->tel($tel);
					}
					elsif ($type eq "email")
					{
						my $email = Data::Microformat::hCard::type->from_tree($bit);
						$card->email($email);
					}
					elsif ($type eq "n")
					{
						my $name = Data::Microformat::hCard::name->from_tree($bit);
						$card->n($name);
					}
					elsif ($type eq "adr")
					{
						my $adr = Data::Microformat::adr->from_tree($bit);
						$card->adr($adr);
					}
					elsif ($type eq "geo")
					{
						my $geo = Data::Microformat::geo->from_tree($bit);
						$card->geo($geo);
					}
					elsif ($type eq "org")
					{
						my $org = Data::Microformat::hCard::organization->from_tree($bit);
						$card->org($org);
					}
					else
					{
						eval { $card->$type($data); };
						if ($@)
						{
							print STDERR "Didn't recognize type $type.\n";
						}
					}
				}
			}
		}
	

		
		# Check: Implied N Optimization?
		if (!$card->n && $card->fn && (!$card->org || (!$card->fn eq $card->org)))
		{
			my $n = Data::Microformat::hCard::name->new;
			my @arr = split(" ", $card->fn);
			if ($arr[1])
			{
				$arr[1] =~ s/\.//;
			}
			if ($arr[0] =~ m/\,/ && length $arr[1] == 1)
			{
				$arr[0] =~ s/\,//;
				$n->family_name($class->_trim($arr[0]));
				$n->given_name($class->_trim($arr[1]));
			}
			else
			{
				$n->family_name($class->_trim($arr[1]));
				$n->given_name($class->_trim($arr[0]));
			}
			$card->n($n);
		}
		
		# Check: Org?
		if (($card->org) && (($card->fn || "") eq $card->org->organization_name))
		{
			my $name = Data::Microformat::hCard::name->new;
			$name->family_name(" ");
			$name->given_name(" ");
			$name->additional_name(" ");
			$name->honorific_prefix(" ");
			$name->honorific_suffix(" ");
			$card->n($name);
		}
		
		# Check: Nickname Optimization?
		if ($card->fn)
		{
			my @words = split(" ", $card->fn);
			if (($card->org && (!$card->org->organization_name eq $card->fn)) && (!$card->n) && (scalar @words == 1))
			{
				$card->nickname($card->fn);
				my $name = Data::Microformat::hCard::name->new;
				$name->family_name("");
				$name->given_name("");
				$name->additional_name("");
				$name->honorific_prefix("");
				$name->honorific_suffix("");
				$card->n($name);
			}
		}
        $card->{_no_dupe_keys} = 0;
		push (@all_cards, $card);
	}
	
	$tree->delete;
	
	# Check: Representative hCard?
	if ($representative_url)
	{
		if (scalar @all_cards == 1)
		{
			$all_cards[0]->{_representative} = 1;
		}
		else
		{
			my $found_one = 0;
			foreach my $card (@all_cards)
			{
				if ($card->url && $card->uid && $card->url eq $card->uid && _normalize_url($card->url) eq _normalize_url($representative_url))
				{
					$card->{_representative} = 1;
					$found_one = 1;
					last;
				}
			}
			if (!$found_one)
			{
				foreach my $card (@all_cards)
				{
					if ($card->url && $card->url eq $rel_me)
					{
						$card->{_representative} = 1;
						last;
					}
				}
			}
		}
	}
	
	if (wantarray)
	{
		return @all_cards;
	}
	else
	{
		return $all_cards[0];
	}
}

sub _normalize_url
{
	my $url = shift;
	$url =~ s/[A-Z]/[a-z]/;
	$url =~ s/\/$//;
	return $url;
}

1;

__END__

=head1 NAME

Data::Microformat::hCard - A module to parse and create hCards

=head1 VERSION

This documentation refers to Data::Microformat::hCard version 0.03.

=head1 SYNOPSIS

	use Data::Microformat::hCard;

	my $card = Data::Microformat::hCard->parse($a_web_page);

	print "The nickname we found in this hCard was:\n";
	print $card->nickname."\n";

	# To create a new hCard:
	my $new_card = Data::Microformat::hCard->new;
	$new_card->fn("Brendan O'Connor");
	$new_card->nickname("USSJoin");

	my $new_email = Data::Microformat::hCard::type->new;
	$new_email->kind("email");
	$new_email->type("Perl");
	$new_email->value("perl@ussjoin.com");
	$new_card->email($new_email);

	print "Here's the new hCard I've just made:\n";
	print $new_card->to_hcard."\n";

=head1 DESCRIPTION

=head2 Overview

This module exists both to parse existing hCards from web pages, and to create
new hCards so that they can be put onto the Internet.

To use it to parse an existing hCard (or hCards), simply give it the content
of the page containing them (there is no need to first eliminate extraneous
content, as the module will handle that itself):

	my $card = Data::Microformat::hCard->parse($content);

If you would like to get all the hCards on the webpage, simply ask using an
array:

	my @cards = Data::Microformat::hCard->parse($content);
	
The module respects nested hCards using the parsing rules defined in the spec,
so if one hCard contains another, it will return one hCard with the other held
in the relevant subpart, rather than two top-level hCards.

To create a new hCard, first create the new object:
	
	my $card = Data::Microformat::hCard->new;
	
Then use the helper methods to add any data you would like. When you're ready
to output the hCard, simply write

	my $output = $card->to_hcard;

And $output will be filled with an hCard representation, using <div> tags
exclusively with the relevant class names.

If you would like to have the parser determine the representative hCard for a
page, simply pass the page's URL as an additional parameter to the C<parse> or
C<from_tree> methods, and the appropriate property will be found if it can
be determined.

For information on precisely what types of strings are intended for each
hCard property, it is recommended to consult the vCARD specification, RFC 2426.

=head2 The Helper Methods

Each module in Data::Microformat provides two methods, singular_fields and
plural_fields. These methods list the fields on that object that can have
exactly one value, or multiple values, respectively. Their documentation also
tries to provide some hint as to what the field might be used for.

To set a value in a field, simply write

	$object->field_name($value);

For instance,

	$my_hcard->nickname("Happy");

To get a value, for either singular or plural fields, you may write

	my $value = $object->field_name;

For plural fields, to get all the values, just make the call in array context;
for instance,

	my @values = $my_hcard->nickname;
	
A plural value with multiple values set will return just the first one when
called in scalar context.

=head1 SUBROUTINES/METHODS

=head2 Data::Microformat::organization->from_tree($tree [, $source_url])

This method overrides but provides the same functionality as the
method of the same name in L<Data::Microformat>, with the optional
addition of $source_url. If present, this latter term will trigger a search to
find the "representative hCard" for the given page, using the specifications
for representative hCard parsing; a card's status of representative or not can
be found by calling the C<is_representative> method on it.

=head2 $card->is_representative

This method returns 1 if the card is known to be a "representative hCard," and
0 otherwise. Note that for the representative hCard to have been determined,
the URL for the source webpage must have been passed to the C<parse> or
C<from_tree> method that created the hCard.

=head2 class_name

The hCard class name for an hCard; to wit, "vcard."

=head2 singular_fields

This is a method to list all the fields on an hCard that can hold exactly one value.

They are as follows:

=head3 bday

The birthday of the hCard.

=head3 class

The class of the hCard, such as "public" or "private."

=head3 fn

The familiar name of the hCard.

=head3 geo

The geolocation of the hCard, which should be a
L<Data::Microformat::geo|Data::Microformat::geo>
object.

=head3 n

The name of the hCard, which should be a L<Data::Microformat::hCard::name>
object.

=head3 sort_string

The sorting string of the hCard.

=head3 uid

The globally unique identifier for the hCard.

=head3 tz

The time zone for the hCard.

=head2 plural_fields

This is a method to list all the fields on an hCard that can hold multiple values.

They are as follows:

=head3 adr

The address of the hCard.

=head3 agent

The agent, which can be either a string or an hCard itself.

=head3 category

The category of the hCard.

=head3 email

The cemail attached to the hCard, which should be a
L<Data::Microformat::hCard::type|Data::Microformat::hCard::type>
object.

=head3 key

The key (especially, the encryption key) of the hCard.

=head3 label

The label of the hCard.

=head3 logo

The logo of the hCard; usually a URI for the logo.

=head3 mailer

The mailer for the hCard.

=head3 nickname

The nickname for the hCard.

=head3 note

The note for the hCard.

=head3 org

The organization for the hCard, which should be a L<Data::Microformat::hCard::organization>
object.

=head3 photo

The photo of the hCard; usually a URI for the photo.

=head3 rev

The revision of the hCard.

=head3 role

The role of the hCard.

=head3 sound

The sound of the hCard; usually a URI for the sound.

=head3 tel

The telephone number of the hCard, which should be a
L<Data::Microformat::hCard::type|Data::Microformat::hCard::type>
object.

=head3 title

The title of the hCard.

=head3 url

The URL for the hCard.

=head1 DEPENDENCIES

This module relies upon the following other modules:

L<Data::Microformat::adr|Data::Microformat::adr>

L<Data::Microformat::geo|Data::Microformat::geo>

They are distributed in the same distribution as this module.

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-data-microformat at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Microformat>.  I will be
notified,and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 AUTHOR

Brendan O'Connor, C<< <perl at ussjoin.com> >>

=head1 COPYRIGHT

Copyright 2008, Six Apart Ltd. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but without any warranty; without even the
implied warranty of merchantability or fitness for a particular purpose.
