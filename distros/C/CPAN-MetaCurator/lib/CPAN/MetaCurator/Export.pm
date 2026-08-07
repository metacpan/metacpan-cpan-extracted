package CPAN::MetaCurator::Export;

use boolean;
use feature 'say';
use parent 'CPAN::MetaCurator::HTML';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().
use DateTime::Tiny;

use File::Slurper qw/read_lines write_text/;

use File::Spec;

use HTML::Escape 'escape_html';

use Mew;

use Switch::Declare;		# For switch.
use Syntax::Keyword::Match;	# For match.

use Tree::DAG_Node;

has -dag_nodetree_path => (Str, default => sub{return ''}, chained => 1);

has jstree_html_path => (Str, default => sub{return ''}, chained => 1);

our $leaf_id;
our %seen;

our $VERSION = '1.29';

# --------------------------------------------------

sub build_dag_tree
{
	my($self, $daughter, $pad, $topic) = @_;
	my(@lines)		= split(/\n/, $$topic{text});
	@lines			= grep{length} map{s/^\s+//; s/:\s*$//; $_} @lines;
	my($index)		= -1;

	my(@components);
	my($entry);
	my(%inside, $item);
	my($leaf, $line, $line_count);
	my($module);
	my(%node_type, $note, $note_count);
	my(@pre_pre);
	my($see_also_root);
	my($text, $token, $type);

	$inside{pre_pre}	= false;
	$inside{see_also}	= false;
	$item				= {description => '', href => '', id => 0, text => '', uri => ''};

	while ($index < $#lines)
	{
		$index++;

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
			$see_also_root		= Tree::DAG_Node -> new({name => 'See also', attributes => {id => ++$leaf_id, description => '', uri => ''} });

			$daughter -> add_daughter($see_also_root);
		}
		elsif ($token)
		{
			$inside{see_also}	= false;
			$line_count			= 0;
			$module				= $token;
			$note_count			= 0;

			$self -> gather_statistics(\%node_type, $pad, $module, $topic);

			if (! $seen{$module} && ($$topic{title} ne 'Acronyms') )
			{
				$seen{$module} = $self -> insert_hashref('modules', {name => $module});
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
		}
		else
		{
			$line_count++;

			$token = ($line =~ /^- (.+)/) ? $1 : '';

			if ($inside{see_also})
			{
				# Fix me. References to topics can be forward references.

				@components	= split(' - ', $token);
				$text		= ($#components < 1) ? $components[0] : $components[1];
				$type		= switch ($components[0])
				{
					case /^\[?\[?[A-Za-z]+\d?\d?\]?\]?$/	{'topic'}
					case /^http/							{'uri'}
					default									{'text'}
				};

				match ($type : eq)
				{
					case('topic')	{
										$$item{text} = ($components[0] =~ /^\[?\[?([A-Za-z]+\d?\d?)\]?\]?$/) ? $1 : $components[0];
										$$item{text} = "[Topic] <button class='btn btn-info'>$$item{text}</button>"
									}
					case('uri')		{$$item{text} = "<a href = '" . escape_html($components[0]) . "' target = '_blank'>$text</a>"}
					case('text')	{$$item{text} = $token}
				}

				$leaf = Tree::DAG_Node -> new({name => $$item{text}, attributes => {id => ++$leaf_id, description => '', uri => $$item{text}} });

				$see_also_root -> add_daughter($leaf);
			}
			elsif ($line_count == 1)
			{
				$$item{description} = $token;
			}
			elsif ($line_count == 2)
			{
				$$item{text}	= $token;
				$leaf			= Tree::DAG_Node -> new({name => $module, attributes => {id => ++$leaf_id, description => $$item{description}, uri => $$item{text}} });

				$daughter -> add_daughter($leaf);
			}
			else
			{
				$note_count++;

				if ($note_count == 1)
				{
					$note = Tree::DAG_Node -> new({name => "Notes for: $module", attributes => {id => ++$leaf_id, description => '', uri => ''} });

					$daughter -> add_daughter($note);
				}

				$entry = Tree::DAG_Node -> new({name => $token, attributes => {id => ++$leaf_id, description => '', uri => ''} });

				$note -> add_daughter($entry);
			}
		}
	}

} # End of build_dag_tree.

# -----------------------------------------------

sub build_tree
{
	my($self, $pad)	= @_;
	my($origin)		= shift @{$$pad{topics} }; # I.e.: {id => 1, parent_id => 1, text => 'Root', title => 'MetaCurator'}.
	$leaf_id		= 0;
	my($root)		= Tree::DAG_Node -> new({name => $$origin{title}, attributes => {id => $leaf_id, description => 'Root'} });

	my($daughter);

	for my $topic (@{$$pad{topics} })
	{
		$daughter = Tree::DAG_Node -> new({name => $$topic{title}, attributes => {id => ++$leaf_id, description => 'Topic'} });

		$root -> add_daughter($daughter);

		$self -> build_dag_tree($daughter, $pad, $topic);
	}

	return $root;

} # End of build_tree.

# -----------------------------------------------

sub export_tree
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	# Phase 1: Build the DAG_Node tree.

	my($pad)	= $self -> build_pad;
	my($root)	= $self -> build_tree($pad);

	# Phase 2: Save the DAG_Node tree to disk.

	if ($self -> dag_nodetree_path)
	{
		write_text($self -> dag_nodetree_path, join("\n", @{$root -> tree2string}) . "\n");
	}

	# Phase 3: Scan the DAG_Node tree to get the topic ids.
	# These will be used to resolve forward references of topics.

	my($attributes);
	my($id);
	my($name);
	my(%topic_id_map);

	$root -> walk_down
	({
		callbackback => sub
		{
			my($node, $options)	= @_;
			$attributes			= $node -> attributes;
			$name       		= $node -> name;

			if ($$options{_depth} == 1) # Topics.
			{
				$topic_id_map{$name} = $$attributes{id};
			}

		}, # End of callbackback.
		_depth => 0,
	});

	# Phase 4; Build the JS Tree.
	# New style.

	my($description);
	my(@list);
	my($previous_depth);
	my($uri);

	$root -> walk_down
	({
		callback => sub
		{
			my($node, $options)	= @_;
			$attributes			= $node -> attributes;
			$name       		= $node -> name;

			if ($$options{_depth} == 0) # Root.
			{
				push @list, '<ul>'; # Open global li.
				push @list, qq|<li data-jstree='{"opened": true}' id = '$$attributes{id}'>$name|;
				push @list, '<ul>'; # Open ul for subtree below root.
			}
			elsif ($$options{_depth} == 1) # Topics.
			{
				push @list, '</li>'				if ($previous_depth == 1); # Close li opened at this depth.
				push @list, '</ul></li>'		if ($previous_depth == 2); # Close ul & li opened in subtree below.
				push @list, '</ul></li></ul>'	if ($previous_depth == 3); # Close ul & li opened in subtree below. Eg: CssStuff with no entries below See also.
				push @list, qq|\t<li data-jstree='{"opened": false}' id = '$$attributes{id}'>$name|;
			}
			elsif ($$options{_depth} == 2) # Module name || 'Notes for ...' || 'See also'.
			{
				$$pad{count}{leaf}++;

				$description	= $$attributes{description};
				$uri			= $$attributes{uri} || '#';
				$uri			= ($name =~ qr/Notes for|See also/) ? "&#8853; $name" : "<a href = '" . escape_html($uri) . "' target = '_blank'>$name - $description</a>";

				push @list, '<ul>'			if ($previous_depth == 1); # Open ul for subtree at this level.
				push @list, '</li>'			if ($previous_depth == 2); # Close li opened at this depth.
				push @list, '</ul></li>'	if ($previous_depth == 3); # Close ul & li opened in subtree below.
				push @list, qq|\t<li data-jstree='{"opened": false}' id = '$$attributes{id}'>$uri|;
			}
			elsif ($$options{_depth} == 3) # 'Notes for ...' || 'See also' entries.
			{
				push @list, '<ul>'			if ($previous_depth == 2); # Open ul for subtree at this level.
				push @list, qq|\t<li data-jstree='{"opened": false}' id = '$$attributes{id}'>$name</li>|;
			}

			$previous_depth = $$options{_depth};

			return 1;

		}, # End of callback.
		_depth => 0,
	});

	push @list, '</ul>'; # Close ul for subtree opened at root.
	push @list, '</li>'; # CLose li opened at root.
	push @list, '</ul>'; # Close global li.

	# Phase 5: Build the web page which uses JSTree.
	# And save it to html/cpan.metacurator.tree.html

	$$pad{jstree_html_path}		= $self -> jstree_html_path;
	my($header, $body, $footer)	= $self -> build_html($pad); # Returns templates.
	my($list)					= join("\n", @list);
	$body						=~ s/!list!/$list/;

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

	$$node_type{acronym}	= $$topic{title} eq 'Acronyms'			? true : false;
	$$node_type{topic}		= exists($$pad{topic_names}{$token})	? true : false;
	$$node_type{known}		= exists($$pad{module_names}{$token})	? true : false;
	$$node_type{unknown}	= ( (! $$node_type{acronym}) && (! $$node_type{known}) && (! $$node_type{topic}) ) ? true : false;

	$$pad{count}{acronym}++	if ($$node_type{acronym});
	$$pad{count}{known}++	if ($$node_type{known});
	$$pad{count}{unknown}++	if ($$node_type{unknown} && ($token ne 'See also') );

} # End of gather_statistics;

# --------------------------------------------------

sub write_file
{
	my($self, $header, $body, $footer, $pad) = @_;
	my($output_path) = File::Spec -> catfile($self -> home_path, $self -> jstree_html_path);

	# $$pad{encoding} has a ':' prefix, & the value is from the constants table, which is from
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
