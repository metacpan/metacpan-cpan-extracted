package CPAN::MetaCurator::Export;

use boolean;
use feature 'say';
use open qw(:std :utf8);
use parent 'CPAN::MetaCurator::HTML';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().
use DateTime::Tiny;

use File::Slurper 'read_lines';
use File::Spec;

use Syntax::Keyword::Match;

use Types::Standard 'Enum';

our %seen;

our $VERSION = '1.21';

# -----------------------------------------------

sub export_tree
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	say 'export_tree()';
	say 'home_path:        ', $self -> home_path;
	say 'include_packages: ', $self -> include_packages;
	say 'log_level:        ', $self -> log_level;
	say 'output_path:      ', $self -> output_path;

	my($pad)					= $self -> build_pad;
	my($header, $body, $footer)	= $self -> build_html($pad); # Returns templates.
	my(@list)					= '<ul>';
	my($root)					= shift @{$$pad{topics} }; # I.e.: {parent_id => 1, text => 'Root', title => 'MetaCurator'}.
	my($id)						= $$pad{topic_html_ids}{$$root{title} };

	$self -> logger -> info($self -> visual_break);
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
# Some names might be acronyms & module names & topic names.
# Example: RSS.

sub gather_statistics
{
	my($self, $node_type, $pad, $token, $topic) = @_;

	$$node_type{acronym}	= $$topic{title} eq 'Acronyms'	? true : false;
	$$node_type{topic}		= $$pad{topic_names}{$token}	? true : false;
	$$node_type{known}		= $$pad{module_names}{$token}	? true : false;
	$$node_type{unknown}	= ! ($$node_type{acronym} || $$node_type{known} || $$node_type{topic});

	$$pad{count}{acronym}++	if ($$node_type{acronym});
	$$pad{count}{known}++	if ($$node_type{known});

	if ($$node_type{unknown} && ($token ne 'See also') )
	{
		$$pad{count}{unknown}++;

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
	my($index)							= -1;

	my(%button);
	my($context);
	my($description);
	my($href);
	my($item, @items);
	my($line);
	my(%node_type);
	my($token);

	$button{extras}		= '';
	$button{faq}		= '';
	$button{pre_pre}	= "<span>&nbsp;&nbsp;</span><button id='toggle-btn'>[pre.../pre]</button>";
	$button{see_also}	= "<button id='toggle-btn'>[See also]</button>";
	my($context_enum)	= Enum['acronym', 'faq', 'module', 'pre_pre', 'see_also', 'text'];

	while ($index < $#lines)
	{
		$index++;

		$line	= $lines[$index];
		$item	= {href => '', id => ++$line_id, text => ''};
		$token	= '';

		if ($$topic{title} eq 'Acronyms')
		{
			$context = 'acronym';

			$self -> gather_statistics(\%node_type, $pad, $token, $topic);
			$self -> logger -> debug("Topic: $$topic{title}. Acronym: $line");
		}
		elsif ($$topic{title} eq 'FAQ')
		{
			$context = 'faq';
		}
		elsif ($line =~ /^o See also:/)
		{
			$context = 'see_also';
		}
		elsif ( ($context eq 'see_also') && ($line =~ /^- /) )
		{
			# No change to context.
		}
		elsif ($line =~ /<pre>/)
		{
			$context = 'pre_pre';
		}
		elsif ($line =~ m|</pre>|)
		{
			$context = 'text';
		}
		elsif ($line =~ /^o (.+)$/)
		{
			$context	= 'module';
			$token		= $1;

			if ($$pad{module_names}{$token} && ! $seen{$token})
			{
				$seen{$token} = $self -> insert_hashref('modules', {name => $token});

				$self -> gather_statistics(\%node_type, $pad, $token, $topic);
				$self -> logger -> debug("Topic: $$topic{title}. Module: $token");
			}
		}
		else
		{
			$context = 'text';
		}

		match($context : eq)
		{
			case('acronym')
			{
				$token			= ($line =~ /^o (.+)$/) ? $1 : $line;
				$description	= $lines[++$index]; substr($description, 0, 2) = '';	# Remove '^- '.
				$href			= $lines[++$index]; substr($href, 0, 2) = '';			# "
				$$item{html}	= "<span><a href = '$href' target = '_blank'>$token - $description</a></span><span>.</span>$button{extras}";
				$$item{text}	= '';

				push @items, $item;
			}
			case('faq')
			{
				$$item{html}	= '';
				$$item{text}	= $line;

				push @items, $item;
			}
			case('module')
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

				$description	= $lines[++$index]; substr($description, 0, 2) = '';	# Remove '^- '.
				$href			= $lines[++$index]; substr($href, 0, 2) = '';			# "
				$$item{html}	= "<span><a href = '$href' target = '_blank'>$token - $description</a></span><span>.</span>$button{extras}";
				$$item{text}	= '';

				$self -> logger -> debug("href: $href");

				push @items, $item;

				#while ($lines[$index + 1] != /^o /){$index++}; # Skip empty line (up to next 'o ...').
			}
			case('see_also')
			{
			}
			case('pre_pre')
			{
			}
			case('text')
			{
			}
		} # End match.
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
