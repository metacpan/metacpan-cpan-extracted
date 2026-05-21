package CPAN::MetaCurator::Export;

use 5.36.0;
use boolean;
use open qw(:std :utf8);
use parent 'CPAN::MetaCurator::HTML';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().
use DateTime::Tiny;

use File::Slurper 'read_lines';
use File::Spec;

use Moo;

use Syntax::Keyword::Match;

our %seen;

our $VERSION = '1.17';

# -----------------------------------------------

sub export_tree
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	my($pad)					= $self -> build_pad;
	my($header, $body, $footer)	= $self -> build_html($pad); # Returns templates.

	# Populate the body.

	my(@list)	= '<ul>';
	my($root)	= shift @{$$pad{topics} }; # I.e.: {parent_id => 1, text => 'Root', title => 'MetaCurator'}.
	my($id)		= $$pad{topic_html_ids}{$$root{title} };

	$self -> logger -> info("Topic: id: $id. title: $$root{title}");

	push @list, qq|<li data-jstree='{"opened": true}' id = '$id'><a href = '#'>$$root{title}</a>|;
	push @list, '<ul>';

	my(@divs);
	my($item);
	my($leaf_id, $lines_ref);

	for my $topic (@{$$pad{topics} })
	{
		$self -> logger -> info("Topic: id: $$topic{id}. html_id: $$pad{topic_html_ids}{$$topic{title}}. title: $$topic{title}");

		$leaf_id	= $$pad{topic_html_ids}{$$topic{title} };
		$lines_ref	= $self -> parse_topic($leaf_id, $pad, $topic);

		push @list, qq|\t<li data-jstree='{"opened": false}' id = '$leaf_id'>$$topic{title}|;
		push @list, '<ul>';

		for (@$lines_ref)
		{
			$$pad{count}{leaf}++;

			push @list, $$_{html} ? "<li>$$_{html}</li>" : "<li id = '$$_{id}'>$$_{text}</li>";
		}

		push @list, '</ul>';
		push @list, '</li>';

		$self -> logger -> info($self -> visual_break);
	}

	push @list, '</ul>', '</li>', '</ul>';

	my($list)	= join("\n", @list);
	$body		=~ s/!list!/$list/;

	for $_ (keys %{$$pad{count} })
	{
		$header =~ s/!$_!/$$pad{count}{$_}/;
	}

	$self -> write_file($header, $body, $footer, $pad);
	$self -> logger -> info("$_ count: $$pad{count}{$_}") for (sort keys %{$$pad{count} });

	return 0;

} # End of export_tree.

# --------------------------------------------------

sub export_modules_table
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	my($database_path)		= File::Spec -> catfile($self -> home_path, $self -> database_path);
	my($modules_csv_path)	= File::Spec -> catfile($self -> home_path, $self -> output_path);

	$self -> logger -> info("Exporting modules table");
	$self -> logger -> info("Reading: $database_path");
	$self -> logger -> info("Writing: $modules_csv_path");

	my($command)				= `echo ".h on\n.mode csv\nselect * from modules" | sqlite3 $database_path > $modules_csv_path`;
	my($line_count)				= `wc -l $modules_csv_path`;
	my($module_count, $name)	= split(' ', $line_count);
	$module_count--; # Allow for header record.

	$self -> logger -> info("Output record count (excluding header): $module_count");

} # End of export_modules_table.

# --------------------------------------------------
# Note: Data is returned in:
# 1: $button
# 2: $index
# 3: @$inside_pre

sub handle_inside_pre
{
	my($self, $index, $line, $lines, $inside_pre, $special_case, $topic) = @_;

	$$special_case{inside_pre}	= true;
	@$inside_pre				= $line;

	do
	{
		$index++;

		if ($index <= $#$lines)
		{
			$line = $$lines[$index];

			if ($line =~ /^o /)
			{
				$$special_case{inside_pre} = false;
			}
			else
			{
				push @$inside_pre, $line;
			}
		}
		else
		{
			$$special_case{inside_pre} = false;
		}
	} until (! $$special_case{inside_pre});

	my($button) = "<span>&nbsp;&nbsp;</span><button id='toggle-btn'>[pre.../pre]</button>";

	$self -> logger -> debug("\t$_") for (@$inside_pre);

	return ($button, $index);

} # End of handle_inside_pre.

# --------------------------------------------------
# Note: Data is returned in:
# 1: $button
# 2: $index
# 3: @$see_also

sub handle_see_also
{
	my($self, $index, $line, $lines, $see_also, $special_case, $topic) = @_;

	$$special_case{see_also}	= true;
	@$see_also					= $line;

	do
	{
		$index++;

		if ($index <= $#$lines)
		{
			$line = $$lines[$index];

			if ($line =~ /^o /)
			{
				$$special_case{see_also} = false;
			}
			else
			{
				push @$see_also, $line;
			}

		}
		else
		{
			$$special_case{see_also} = false;
		}
	} until (! $$special_case{see_also});

	$self -> logger -> debug("\t$_") for (@$see_also);

	return $index;

} # End of handle_see_also.

# --------------------------------------------------
# Some names might be acronyms & module names & topic names.
# Example: RSS.

sub gather_statistics
{
	my($self, $node_type, $pad, $token, $topic) = @_;

	$$node_type{acronym}	= $$topic{title} eq 'Acronyms'	? true : false;
	$$node_type{topic}		= $$pad{topic_names}{$token}	? true : false;
	$$node_type{known}		= $$pad{packages}{$token}		? true : false;
	$$node_type{unknown}	= ! ($$node_type{acronym} || $$node_type{known} || $$node_type{topic});

	$$pad{count}{acronym}++	if ($$node_type{acronym});
	$$pad{count}{known}++	if ($$node_type{known});

	if ($$node_type{unknown} && ($token ne 'See also') )
	{
		$self -> logger -> debug("Unknown: $token");
	}

} # End of gather_statistics;

# --------------------------------------------------

sub parse_topic
{
	my($self, $leaf_id, $pad, $topic)	= @_;
	my(@lines)							= split(/\n/, $$topic{text});
	@lines								= grep{length} map{s/^\s+//; s/:\s*$//; $_} @lines;
	my($line_id)						= $leaf_id;
	my($index)							= 0;

	my($button, %button);
	my($description);
	my(@extras);
	my($href, @hover);
	my(@inside_pre, $item, @items);
	my($line);
	my(%node_type);
	my(%special_case, @see_also);
	my($token);

	$button{extras}				= '';
	$button{inside_pre}			= '';
	$button{see_also}			= '';
	$special_case{inside_pre}	= false;
	$special_case{see_also}		= false;

	while ($index <= $#lines)
	{
		$line = $lines[$index];

		# 1 of 2: Process non-modules.

		if ($line =~ /<pre>/)
		{
			($button{inside_pre}, $index) = $self -> handle_inside_pre($index, $line, \@lines, \@inside_pre, \%special_case, $topic);
		}
		elsif ($line =~ /^o See also/)
		{
			$index				= $self -> handle_see_also($index, $line, \@lines, \@see_also, \%special_case, $topic);
			$button{see_also}	= "<button id='toggle-btn'>[See also]</button>";
		}

		$index++;

		last if ($index > $#lines);

		# 2 of 2: Skip everything except modules (hopefully).

		next if ($line !~ /^o (.+):?/);

		$token	= $1 || '';
		$item	= {href => '', id => ++$line_id, text => ''};

		$self -> gather_statistics(\%node_type, $pad, $token, $topic);

		# Special cases, due to their formatting:
		# 1: See also.
		# 2: FAQ.

		if ($token eq 'See also')
		{
			$$item{html}	= $button{see_also};
			$$item{text}	= "";

			push @items, $item;

		}
		elsif ($$topic{title} eq 'FAQ')
		{
			$$item{html}	= '';
			$$item{text}	= $line;

			push @items, $item;
		}
		else
		{
			# Do we have a standard 3 line entry or 3+ lines? Examples are from Acronyms.
			#
			# 3 line entry:
			# o DKIM:
			# - DomainKeys Identified Mail <- $index
			# - https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail
			#
			# 3+ line entry:
			# o DMARC:
			# - Domain-based Message Authentication, Reporting, and Conformance <- $index
			# - https://en.wikipedia.org/wiki/DMARC
			# - An email authentication protocol that helps protect domain owners and recipients from email spoofing, phishing, and other email-based attacks
			# - https://datatracker.ietf.org/doc/html/draft-crocker-dmarc-bcp-03
			#
			# If the latter then stockpile lines beyond 3 & stash them in a hidden field to be popped-up on a button click.

			@extras = ();

			while ( ($index <= $#lines) && ($lines[$index] !~ /^o/) )
			{
				push @extras, $lines[$index++];
			}

			if ($#extras < 2)
			{
				#$self -> logger -> debug("Token: $token. Expected: $_ >$extras[$_]<") for (0 .. $#extras);
			}

			$self -> logger -> error("Token: $token. Missing lines"), next if ($#extras < 1);
			$self -> logger -> error("Token: $token. Missing -text"), next if ($extras[0] !~ /^-/);
			$self -> logger -> error("Token: $token. Missing -link"), next if ( ($#extras < 1) || ($extras[1] !~ /^-/) );

			$description	= shift @extras;
			$href			= shift @extras;

			$self -> logger -> error("Token: $token. Missing description"),	next if (! defined($description) );
			$self -> logger -> error("Token: $token. Missing href"), 		next if (! defined($href) );

			if ($#extras >= 0)
			{
				$button{extras} = "<span>&nbsp;&nbsp;</span><button id='toggle-btn'>[TBA]</button>";

				$self -> logger -> debug("Token: $token. Extras:");
				$self -> logger -> debug("\t$_") for (@extras);
			}
			else
			{
				$button{extras} = '';
			}

			$$item{html}	= "<span><a href = '$href' target = '_blank'>$token - $description</a></span><span>.</span>$button{extras}";
			$$item{text}	= "";

			push @items, $item;
		}

		if (! $seen{$token})
		{
			$self -> insert_hashref('modules', {name => $token});

			$seen{$token} = true;
		}
	}

	return [@items];

} # End of parse_topic.

# --------------------------------------------------

sub write_file
{
	my($self, $header, $body, $footer, $pad) = @_;
	my($encoding)		= lc $$pad{encoding};
	my($output_path)	= File::Spec -> catfile($self -> home_path, $self -> output_path);

	open(my $fh, ">$encoding", $output_path);
	print $fh $header, $body, $footer;
	close $fh;

	$self -> logger -> info("Created $output_path. Encoding: $encoding");

} # End of write_file.

# --------------------------------------------------

1;

=pod

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author.

=head1 Author

L<CPAN::MetaCurator> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2025.

My homepage: L<https://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2025, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
