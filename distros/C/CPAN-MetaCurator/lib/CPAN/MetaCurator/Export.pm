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

use HTML::Escape 'escape_html';

use Moo;

use Syntax::Keyword::Match;

use Types::Standard qw/Str/;

has test_topics_path =>
(
	default		=> sub{return '/tmp/test.topics.txt'},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

our %seen;

our $VERSION = '1.23';

# -----------------------------------------------

sub export_tree
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

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
	my(%wanted);

	# Read data/testing.topics.txt for topic names to process. This just limits the output.
	# See also data/special.topic.txt.

	if (-e $self -> test_topics_path)
	{
		my($test_topics)	= $self -> read_csv_file($self -> test_topics_path);
		$wanted{$_}			= true for (@$test_topics);
	}

	# If the file is empty, activate all topics.
	# Fix me. Add file name & purpose to POD.

	my(@keys) = keys %wanted;

	for ($#keys == 0)
	{
		$wanted{$$_{title} } = true for (@{$$pad{topics} });
	}

	for my $topic (@{$$pad{topics} })
	{
		next if (! $wanted{$$topic{title} });

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

=pod
	# Modules.
	# There is a db table called modules so we need another name for the hash
	# where the keys are the names of the modules and the values are db ids.

	$$pad{module_names}				= {};
	$$pad{module_names}{$$_{name} }	= $$_{id} for (@{$$pad{modules} });
	my($module_count)				= $#{$$pad{module_names} } + 1;

	$self -> logger -> info("Records in the module table: $module_count");
=cut

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

	$self -> logger -> debug("Topic: $$topic{title}. Line count: $#lines");

	my(%button);
	my($description);
	my(@extras);
	my($href);
	my(%inside, $item, @items);
	my($line, $line_count);
	my($module);
	my(%node_type);
	my(@pre_pre);
	my(@see_also);
	my($token);

	$button{extras}		= '';
	$button{faq}		= '';
	$button{pre_pre}	= "<span>&nbsp;&nbsp;</span><button id='toggle-btn'>TBA: [pre.../pre]</button>";
	$button{see_also}	= "<button id='toggle-btn'>TBA: [See also]</button>";
	$inside{pre_pre}	= false;
	$inside{see_also}	= false;

	while ($index < $#lines)
	{
		$index++;

		$item	= {href => '', id => ++$line_id, text => ''};
		$line	= $lines[$index];
		$token	= ($line =~ /^o (.+)/) ? $1 : '';

		$self -> logger -> debug("Processing line $index: <$line>. token: $token");

		# $token ne '':
		# a. See also
		# b. An acronym
		# Otherwise:
		# c. A description
		# d. A href
		# e. <pre>
		# f. </pre>

		if ($token eq 'See also')
		{
			$inside{see_also}	= true;
			$$item{html}		= $button{see_also};
			$$item{text}		= '';

			push @items, $item;
		}
		elsif ($token)
		{
			$description		= '';
			$href				= '';
			$inside{see_also}	= false;
			$line_count			= 0;
			$module				= $token;

			# Fix me. Should be checking known modules.

#			if ($$pad{module_names}{$token} && ! $seen{$token})
			if (! $seen{$module})
			{
				$seen{$module} = $self -> insert_hashref('modules', {name => $module});

				$self -> gather_statistics(\%node_type, $pad, $module, $topic);
#				$self -> logger -> debug("Topic: $$topic{title}. Module: $token");
			}
		}
		elsif ($line =~ /<pre>/)
		{
			# Fix me. What happens if there are 2 sets of <pre>...</pre> within 1 topic?

			$inside{pre_pre}	= true;
#			$$item{html}		= $button{pre_pre};
#			$$item{text}		= '';
#
#			push @items, $item;
		}
		elsif ($line =~ m|</pre>|)
		{
			$inside{pre_pre} = false;
		}
		elsif ($inside{pre_pre})
		{
			$$item{html}	= '';
			$$item{text}	= $line;

			push @pre_pre, $item;
		}
		else
		{
			$line_count++;

			$token = ($line =~ /^- (.+)/) ? $1 : '';

			if ($inside{see_also})
			{
				push@see_also, $token;
			}
			elsif ($line_count == 1)
			{
				$description = $token;
			}
			elsif ($line_count == 2)
			{
				$href			= $token;
				$$item{html}	= "<span><a href = '" . escape_html($href) . "' target = '_blank'>$module - $description</a></span><span>.</span>";
				$$item{text}	= '';

				push @items, $item;
			}
			else
			{
				push @extras, $token,
			}
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
