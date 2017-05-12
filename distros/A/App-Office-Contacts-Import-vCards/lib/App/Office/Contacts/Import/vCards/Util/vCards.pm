package App::Office::Contacts::Import::vCards::Util::vCards;

# Purpose:
#	Read vCards in XML format.

use JSON::XS;

use XML::SAX::ParserFactory;

use Moose;

extends (qw/Moose::Object XML::SAX::Base/);

has callback    => (is => 'rw', isa => 'CodeRef');
has caller      => (is => 'rw', isa => 'Any');
has email_type  => (is => 'rw', isa => 'Str');
has phone_type  => (is => 'rw', isa => 'Str');
has status      => (is => 'rw', isa => 'Str', default => 'OK');
has text        => (is => 'rw', isa => 'Str');
has vcard       => (is => 'rw', isa => 'HashRef');
has vcard_count => (is => 'rw', isa => 'Int', default => 0);
has xml         => (is => 'rw', isa => 'Str');

use namespace::autoclean;

our $VERSION = '1.12';

# -----------------------------------------------

sub characters
{
	my($self, $characters) = @_;

	$self -> text($self -> text . $$characters{Data});

}	# End of characters.

# -----------------------------------------------

sub end_document
{
	my($self) = @_;

}	# End of end_document.

# -----------------------------------------------

sub end_element
{
	my($self, $element) = @_;
	my($text)           = $self -> text;
	$text               =~ s/^\s+//;
	$text               =~ s/\s+$//;

	# Process text.

	my(@field);
	my($vcard);

	if ($$element{Name} eq 'vcard')
	{
		$self -> callback -> ($self -> caller, $self -> vcard_count, $self -> vcard);
	}
	elsif ($$element{Name} eq 'email')
	{
		$vcard = $self -> vcard;

		push @{$$vcard{'email'} },
		{
			address => $text,
			type    => $self -> email_type,
		};

		$self -> vcard($vcard);
	}
	elsif ($$element{Name} eq 'n')
	{
		$text =~ tr/;/;/s;

		if ($text)
		{
			@field                    = split(/;/, $text);
			$vcard                    = $self -> vcard;
			$$vcard{'surname'}        = $field[0] || '';
			$$vcard{'given_names'}    = $field[1] || '';
			$$vcard{'preferred_name'} = $$vcard{'given_names'};

			$self -> vcard($vcard);
		}
	}
	elsif ($$element{Name} eq 'tel')
	{
		$text  =~ tr/ //d;
		$vcard = $self -> vcard;

		# Convert 12345678 into 1234 5678
		# and 0421920622 into 0421 920 622.

		if (length($text) == 8)
		{
			$text = substr($text, 0, 4) . ' ' . substr($text, 4, 4);
		}
		elsif (length($text) == 10)
		{
			$text = substr($text, 0, 4) . ' ' . substr($text, 4, 3) . ' ' . substr($text, 7, 3);
		}

		push @{$$vcard{'phone'} },
		{
			number => $text,
			type   => $self -> phone_type,
		};

		$self -> vcard($vcard);
	}
	elsif ($$element{Name} eq 'adr')
	{
		$text =~ tr/;/;/s;
		$text =~ s/^;//;
		$text =~ s/;$//;

		if ($text)
		{
			$vcard = $self -> vcard;

			push @{$$vcard{'site'} }, join(';', reverse split /;/, $text);

			$self -> vcard($vcard);
		}
	}

	# Reset.

	$self -> text('');

}	# End of end_element.

# -----------------------------------------------

sub format_vcard
{
	my($self, $count, $vcard) = @_;

	my($field);
	my($i);
	my($key);
	my(@s);

	push @s, "vCard: $count";

	for $key (sort keys %$vcard)
	{
		if ($key =~ /(?:email|phone)/)
		{
			for $i (0 .. $#{$$vcard{$key} })
			{
				for $field (sort keys %{$$vcard{$key}[$i]} )
				{
					push @s, "$key @{[$i + 1]}: $field => $$vcard{$key}[$i]{$field}";
				}
			}
		}
		elsif ($key eq 'site')
		{
			for $i (0 .. $#{$$vcard{$key} })
			{
				push @s, "$key @{[$i + 1]}: $$vcard{$key}[$i]";
			}
		}
		else
		{
			push @s, "$key => $$vcard{$key}";
		}
	}

	return @s;

} # End of format_vcard.

# -----------------------------------------------

sub run
{
	my($self) = @_;

	$self -> caller -> log(debug => 'Entered run');

	my($parser) = XML::SAX::ParserFactory -> parser(Handler => $self);

	eval{$parser -> parse_string($self -> xml)};

	if ($@)
	{
		$self -> status('Unable to parse XML: ' . $@);
	}

	$self -> caller -> log(debug => 'XML Parse result: ' . $self -> status);

	return $self -> status;

}	# End of run.

# -----------------------------------------------

sub start_document
{
	my($self) = @_;

}	# End of start_document.

# -----------------------------------------------

sub start_element
{
	my($self, $element)	= @_;

	$self -> text('');

	my(%email_type) =
	(
	 HOME  => 'Private',
	 OTHER => 'Business',
	 WORK  => 'Business',
	);
	my(%phone_type) =
	(
	 CELL         => 'Business',
	 'HOME,VOICE' => 'Private',
	 'WORK,FAX'   => 'Fax',
	 'WORK,VOICE' => 'Business',
	);

	my($type);
	my($vcard);

	if ($$element{Name} eq 'vcard')
	{
		$self -> vcard({email => [], phone => [], site => []});
		$self -> vcard_count($self -> vcard_count + 1);
	}
	elsif ($$element{Name} eq 'email')
	{	# Must grab attributes at the start of the element :-(.

		$type = $$element{Attributes}{'{}type'}{Value};

		$self -> email_type($email_type{$type} ? $email_type{$type} : 'Private');
	}
	elsif ($$element{Name} eq 'n')
	{
		# Ignore.
	}
	elsif ($$element{Name} eq 'tel')
	{
		$type = $$element{Attributes}{'{}type'}{Value};

		$self -> phone_type($phone_type{$type} ? $phone_type{$type} : 'Private');
	}
	elsif ($$element{Name} eq 'adr')
	{
		# Ignore.
	}

}	# End of start_element.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
