package App::Office::Contacts::Import::vCards::Controller::Import;

use parent 'App::Office::Contacts::Import::vCards::Controller';
use strict;
use warnings;

use CGI;

use App::Office::Contacts::Import::vCards::Util::vCards;
use App::Office::Contacts::Util::Validator;

use Text::GenderFromName ();

use Text::vFile::toXML;

use Time::Elapsed;

# We don't use Moose because we isa CGI::Application.

our $VERSION = '1.12';

# -----------------------------------------------

sub check_validation
{
	my($self, $name, $result) = @_;

	my($status);

	if ($result -> success)
	{
		# The output from report_add() is too complex to display without further work,
		# so we rig the output to say OK.

		$status = $self -> param('view') -> person -> report_add($self -> param('user_id'), $result);
		$status = 'OK';
	}
	else
	{
		$status = $self -> param('db') -> util -> build_brief_error_report($result, $self -> param('template') );
	}

	return $status;

} # End of check_validation.

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> log(debug => 'Entered display');

	my($field_name) = 'vfile_name';
	my($vfile_name) = $self -> query -> param($field_name);

	if (! $vfile_name)
	{
		return $self -> param('view') -> viewer -> format([{name => 'No file name provided', status => 'Error'}])
	}

	# Build some of the progress report.
	# Note: This report, @progress, is not actually output.

	my($fh)        = $self -> query -> upload($field_name);
	my($mime_type) = ${$self -> query -> uploadInfo($vfile_name)}{'Content-Type'};

	my(@progress);

	push @progress, "file_name => $vfile_name";
	push @progress, 'file_size => ' . (-s $fh);
	push @progress, "mime_type => $mime_type";

	# Parse the VCF into XML and then into text.

	my($start_time) = time;
	my($xml)        = Text::vFile::toXML -> new(filehandle => $fh) -> to_xml;

	# We pass in $self as caller, so that when the callback is finally called,
	# from App::Office::Contacts::Import::vCards::Util::vCards, sub end_element,
	# $self can be the first parameter, which makes sub import_callback a real, live method.
	# That means that from inside the callback we can access the 5 params a few lines down.

	my($importer) = App::Office::Contacts::Import::vCards::Util::vCards -> new(callback => \&import_callback, caller => $self, xml => $xml);

	# Stash some things for validation.

	$self -> param(email_address_types => $self -> param('db') -> util -> get_email_address_types);
	$self -> param(phone_number_types  => $self -> param('db') -> util -> get_phone_number_types);
	$self -> param(titles              => $self -> param('db') -> util -> get_titles);
	$self -> param(template            => $self -> load_tmpl('update.report.tmpl') );
	$self -> param(vcard               => []); # Used by the callback to stockpile output.

	# This calls the callback sub import_callback() declared below.
	# That, in turn, stashes records in $self -> param('vcard');

	push @progress, 'parse_status => ' . $importer -> run;
	push @progress, 'vcard_count  => ' . $importer -> vcard_count;

	# Display the peoples' names.

	my($vcard) = $self -> param('vcard');

	my(@line, $line);
	my(@name, @name_loop);
	my(@status);

	for my $i (0 .. $#$vcard)
	{
		# Call generic formatter, and then extract data to display.

		@line = $importer -> format_vcard( ($i + 1), $$vcard[$i]);
		@name = ();

		# Select a few fields to display: Given name, surname and status.

		for $line (@line)
		{
			if ($line =~ /(?:name)/)
			{
				push @name, $line;
			}
			elsif ($line =~ /^(?:status) => (.+)/)
			{
				push @status, $1;
			}
		}

		push @name_loop, join(', ', @name);
	}

	my(@tr_loop);

	for my $i (0 .. $#name_loop)
	{
		push @tr_loop,
		{
			count  => ($i + 1),
			name   => $name_loop[$i],
			status => $status[$i],
		};
	}

	push @progress, 'elapsed_time => ' . Time::Elapsed::elapsed(time - $start_time);

	return $self -> param('view') -> viewer -> format(\@tr_loop);

} # End of display.

# -----------------------------------------------

sub import_callback
{
	my($self, $count, $card) = @_;

	$self -> log(debug => 'Entered import_callback');

	my($person) = {sid => $self -> param('session') -> id};

	# Process menus which apply to all imported people.
	# Matches code in App::Office::Contacts::Import::vCards::View::Import,
	# sub build_import_vcards_form().

	my(%default);
	my($id, @id);

	for my $table (qw/broadcasts communication_types roles/)
	{
		($id = $table) =~ s/s$/_id/;
		$default{$id}  = $self -> query -> param($id);

		push @id, $id;
	}

	# When adding a person with App::Office::Contacts, there will be a fake
	# target_id, and when updating a person there will be a real target_id,
	# which is the person's primary key in the database table 'people'.
	# Since we call the same validation code, we now fabricate a target_id.

	$id           = 'target_id';
	$default{$id} = 0;

	push @id, $id;

	# Phase 1: Build up a hash ref as though the data came from a CGI form.
	# Part a: Constant data.

	my($key);

	for $key (@id)
	{
		$$person{$key} = $default{$key};
	}

	# Part b: The vCard data.

	my(@key) = (qw/given_names preferred_name surname/);

	for $key (@key)
	{
		$$person{$key} = $$card{$key};
	}

	my($persons_name) = "$$person{'given_names'} $$person{'surname'}";

	# Part c: Gender.

	my(%gender) =
	(
		'-' => 1,
		'f' => 2,
		'm' => 3,
	);

	if ($$person{'given_names'})
	{
		my($gender)           = Text::GenderFromName::gender($$person{'given_names'}, 9) || '';
		$$person{'gender_id'} = $gender{$gender} ? $gender{$gender} : $gender{'-'};
	}
	else
	{
		$$person{'gender_id'} = $gender{'-'};
	}

	# Part d: Title.
	# Note: Keys for %title are values from %gender.

	my(%title) =
	(
		1 => '-',
		2 => 'Ms',
		3 => 'Mr',
	);

	my($title)           = $title{$$person{'gender_id'} } || '-';
	$$person{'title_id'} = ${$self -> param('titles')}{$title};

	# Part e: Constants not in the vCard.

	for $key (qw/home_page/)
	{
		$$person{$key} = '';
	}

	# Part f: Email addresses.

	my($index) = 0;
	my($types) = $self -> param('email_address_types');

	my($name);

	for $key (@{$$card{'email'} })
	{
		if (! $$key{'address'} || ! $$key{'type'})
		{
			#$self -> log(debug => "$persons_name has no email address or type");

			next;
		}

		if (! $$types{$$key{'type'} })
		{
			$self -> log(info => "$persons_name: Unknown email type: $$key{'type'}");

			next;
		}

		$index++;

		if ($index <= 4)
		{
			$name           = "email_$index";
			$$person{$name} = $$key{'address'};
			$name           = "email_address_type_id_$index";
			$$person{$name} = $$types{$$key{'type'} };
		}
	}

	# Part g: Phone numbers.

	$index = 0;
	$types = $self -> param('phone_number_types');

	for $key (@{$$card{'phone'} })
	{
		if (! $$key{'number'} || ! $$key{'type'})
		{
			#$self -> log(debug => "$persons_name has no phone number or type");

			next;
		}

		if (! $$types{$$key{'type'} })
		{
			$self -> log(info => "$persons_name: Unknown phone type: $$key{'type'}");

			next;
		}

		$index++;

		if ($index <= 4)
		{
			$name           = "phone_$index";
			$$person{$name} = $$key{'number'};
			$name           = "phone_number_type_id_$index";
			$$person{$name} = $$types{$$key{'type'} };
		}
	}

	# Dump a couple of people's fields to the log.

	if ($count < 3)
	{
		for my $key (sort keys %$person)
		{
			$self -> log(debug => "$count: $key => " . ($$person{$key} || 'N/A') );
		}
	}

	# Phase 2: Push the data back into $cgi, so it's available to Data::Verifier.
	# Warning: The CGI -> new() cannot be hoisted into display(), because
	# then it would accumulate parameters across multiple people. new() it here!
	# Also, we use CGI and not e.g. CGI::Simple since we're using CGI::Fast already.

	my($cgi) = CGI -> new;

	for $key (keys %$person)
	{
		$cgi -> param($key => $$person{$key});
	}

	# App::Office::Contacts::Util::Validator is normally called from within one of the
	# controllers based on App::Office::Contacts::Controller, with a query object of
	# type CGI::Fast. So, we replace that query object with the one we just fabricated,
	# so App::Office::Contacts::Util::Validator will access the 'correct' parameters.

	my($result) = App::Office::Contacts::Util::Validator -> new
		(
		config => $self -> param('config'),
		db     => $self -> param('db'),
		query  => $cgi,
		) -> person;

	my($vcard) = $self -> param('vcard');

	push @$vcard,
	{
		count  => $count,
		name   => $persons_name,
		status => $self -> check_validation($persons_name, $result),
	};

	$self -> param(vcard => $vcard);

	$self -> log(debug => scalar @$vcard . ": Finish: $persons_name");

} # End of import_callback.

# -----------------------------------------------

1;
