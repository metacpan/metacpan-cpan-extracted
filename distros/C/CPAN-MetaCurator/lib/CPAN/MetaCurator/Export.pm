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

use Tree::DAG_Node;

use Types::Standard qw/Str/;

has test_topics_path =>
(
	default		=> sub{return '/tmp/test.topics.txt'},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

our $leaf_id;
our %seen;

our $VERSION = '1.24';

# -----------------------------------------------

sub export_tree
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	my($pad)					= $self -> build_pad;
	my($header, $body, $footer)	= $self -> build_html($pad); # Returns templates.
	my(@list)					= '<ul>';
	my($origin)					= shift @{$$pad{topics} }; # I.e.: {parent_id => 1, text => 'Root', title => 'MetaCurator'}.
	my($not_used)				= $$pad{topic_html_ids}{$$origin{title} };
	$leaf_id					= 0;
	my($root)					= Tree::DAG_Node -> new({name => $$origin{title}, attributes => {id => $leaf_id} });

	$self -> logger -> info($self -> visual_break);
	$self -> logger -> info("Topic: id: $leaf_id. title: $$origin{title}");

	push @list, qq|<li data-jstree='{"opened": true}' id = '$leaf_id'><a href = '#'>$$origin{title}</a>|;
	push @list, '<ul>';

	my(%wanted);

	# Read data/testing.topics.txt for topic names to process. This just limits the output.
	# See also data/special.topic.txt.

	if (-e $self -> test_topics_path)
	{
		my($test_topics)	= $self -> read_csv_file($self -> test_topics_path);
		$wanted{$_}			= true for (@$test_topics);
	}

	# If the file is absent or empty, activate all topics.

	my(@keys) = keys %wanted;

	for ($#keys == 0)
	{
		$wanted{$$_{title} } = true for (@{$$pad{topics} });
	}

	my($daughter);
	my($item, $items_ref);
	my($see_also_ref);

	for my $topic (@{$$pad{topics} })
	{
		next if (! $wanted{$$topic{title} });

		$self -> logger -> info("Topic: id: $$topic{id}. html_id: $$pad{topic_html_ids}{$$topic{title}}. title: $$topic{title}");

		$daughter = Tree::DAG_Node -> new({name => $$topic{title}, attributes => {id => ++$leaf_id} });

		$root -> add_daughter($daughter);

		($items_ref, $see_also_ref) = $self -> parse_topic($daughter, $pad, $topic);

		$self -> logger -> info("parse_topic() returned: $#$items_ref, $#$see_also_ref");

		++$leaf_id;

		push @list, qq|\t<li data-jstree='{"opened": false}' id = '$leaf_id'>$$topic{title}|;
		push @list, '<ul>';

		for $item (@$items_ref)
		{
			++$leaf_id;
			$$pad{count}{leaf}++;

			if ($$item{text} eq 'See also')
			{
				push @list, qq|\t<li data-jstree='{"opened": false}' id = '$leaf_id'>See also|;
				push @list, "\t<ul>";
				push @list, qq|\t\t<li>$$_{text}</li>| for (@$see_also_ref);
				push @list, "\t</ul>";
				push @list, "\t</li>";
			}
			else
			{
				push @list, $$item{html} ? "<li>$$item{html}</li>" : "<li id = '$$item{id}'>$$item{text}</li>";
			}
		}

		push @list, '</ul>', '</li>';

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

	# This works. It's very plain.
	#say $root -> name;
	#say map{"\t" . $_ -> name . "\n"} $root -> daughters;
	#
	# This works. It's nicer.
	#say map("$_\n", @{$root->tree2string});

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
	my($self, $daughter, $pad, $topic) = @_;
	my(@lines)	= split(/\n/, $$topic{text});
	@lines		= grep{length} map{s/^\s+//; s/:\s*$//; $_} @lines;
	my($index)	= -1;

	$self -> logger -> debug("Topic: $$topic{title}. Line count: $#lines");

	my(@components);
	my($description);
	my(@extras);
	my($href);
	my(%inside, $is_topic, $item, @items);
	my($line, $line_count);
	my($module, $module_leaf);
	my(%node_type);
	my(@pre_pre);
	my($see_also_root, $see_also_1, @see_also);
	my($token);

	$inside{pre_pre}	= false;
	$inside{see_also}	= false;

	while ($index < $#lines)
	{
		$index++;

		$item	= {href => '', id => ++$leaf_id, text => ''};
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
			$$item{text}		= 'See also';

			push @items, $item;

			$see_also_root = Tree::DAG_Node -> new({name => 'See also', attributes => {id => ++$leaf_id} });

			$daughter -> add_daughter($see_also_root);
		}
		elsif ($token)
		{
			$description		= '';
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

			$inside{pre_pre} = true;
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
				# Sample from topic AbCeDarian:
				# It means in abcd order, i.e. alphabetical, so I can put it first in the list of topics :-)
				# Sample from topic AiEngines:
				# [[Acronyms]]

				$$item{text}	= $token;
				@components		= split(' - ', $token); # [0] may be text or Topic.
				$components[0]	= $token if ($#components < 0);

				# Must allow for topics AssemblerX86 & UTF8.

				if ($components[0] =~ m/^\[\[([A-Za-z]+\d?\d?)\]\]/)
				{
					$components[0]	= $1;
					$$item{text}	= $1;
				}

				$components[0]	= '' if ($components[0] !~ m/^[A-Za-z]+\d{0,2}$/);
				$is_topic		= $$pad{topic_names}{$components[0]}; # Defined => it's a topic.
				$$item{text}	= "[Topic] $$item{text}" if ($is_topic && ($$item{text} !~ m/^http/) );
				$$item{text}	= $token if ($token =~ /^http/);

				push@see_also, $item;

				$see_also_1	= Tree::DAG_Node -> new({name => $$item{text}, attributes => {id => ++$leaf_id} });

				$see_also_root -> add_daughter($see_also_1);
			}
			elsif ($line_count == 1)
			{
				$description = $token;
			}
			elsif ($line_count == 2)
			{
				$href			= $token;
				$$item{html}	= "<a href = '" . escape_html($href) . "' target = '_blank'>$module - $description</a>";
				$$item{text}	= '';

				push @items, $item;

				$module_leaf = Tree::DAG_Node -> new({name => $module, attributes => {id => ++$leaf_id} });

				$daughter -> add_daughter($module_leaf);
			}
			else
			{
				push @extras, $token,
			}
		}
	}

	return ([@items], [@see_also]);

} # End of parse_topic.

# --------------------------------------------------

sub write_file
{
	my($self, $header, $body, $footer, $pad) = @_;
	my($output_path) = File::Spec -> catfile($self -> home_path, $self -> output_path);

	# $$pad{encoding} has a : prefix, & the value is from the constants table, which is from
	# /home/ron/perl.modules/CPAN-MetaCurator/data/cpan.metacurator.constants.csv.

	open(my $fh, ">$$pad{encoding}", $output_path);
	print $fh $header, $body, $footer;
	close $fh;

	$self -> logger -> info("Created $output_path. Encoding: $$pad{encoding}");

} # End of write_file.

# --------------------------------------------------

1;

=pod

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Test data

There is a mechanism to restrict processing to a tiny number of topics.

To this end there is an option called test_topics_path, which takes a file name.
If this file is present it is read, & each line in it is assumed to be a topic name.

Topics listed are wanted, & so the program skips processing any other topics.

There is a special case. If the file is present but empty, or absent, all topics are deemed
to appear in the file & hence are processed.

Default: /tmp/test.topics.txt.

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
