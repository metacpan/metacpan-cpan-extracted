package CPAN::MetaCurator::Util::Export;

use 5.40.0;
use boolean;
use constant id_scale_factor => 10000;
use open qw(:std :utf8);
use parent 'CPAN::MetaCurator::Util::HTML';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().
use DateTime::Tiny;

use File::Spec;

use Moo;

our $VERSION = '1.00';

# -----------------------------------------------

sub export_as_tree
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	my($pad)					= $self -> build_pad;
	$$pad{topic_count}			= $#{$$pad{topics} } + 1;
	my($header, $body, $footer)	= $self -> build_html($pad);

	# Populate the body.

	my(@list)	= '<ul>';
	my($root)	= shift @{$$pad{topics} };

	push @list, qq|<li data-jstree='{"opened": true}' id = '$$root{id}'><a href = '#'>$$root{title}</a>|;
	push @list, '<ul>';

	my(@divs);
	my($item);
	my($lines);

	for my $topic (@{$$pad{topics} })
	{
		$self -> logger -> info("New topic record. id: $$topic{id}. title: $$topic{title}");

		push @list, qq|\t<li id = '$$topic{id}'>$$topic{title}|;
		push @list, '<ul>';

		$$topic{id}	= id_scale_factor * $$topic{id}; # Fake id offset for leaf.
		$lines		= $self -> format_text($pad, $topic);

		for (@$lines)
		{
			$$pad{leaf_count}++;

			$item = $$_{href} ? "<a href = '$$_{href}'>$$_{text}</a>" : $$_{text};

			push @list, "<li id = '$$_{id}'>$item</li>";
		}

		push @list, '</ul>';
		push @list, '</li>';

		$self -> logger -> info($self -> separator);
		$self -> logger -> info($self -> separator);
	}

	push @list, '</ul>', '</li>', '</ul>';

	my($list)	= join("\n", @list);
	$body		=~ s/!list!/$list/;
	my(%data)	= (leaf_count => $$pad{leaf_count}, topic_count => $$pad{topic_count});

	for $_ (keys %data)
	{
		$header =~ s/!$_!/$data{$_}/;
	}

	$self -> write_file($header, $body, $footer, $pad);

	$self -> logger -> info("Leaf count:  $$pad{leaf_count}");
	$self -> logger -> info("Topic count: $$pad{topic_count}\n");

	return 0;

} # End of export_as_tree.

# --------------------------------------------------

sub format_text
{
	my($self, $pad, $topic)	= @_;
	my(@text)				= grep{length} split(/\n/, $$topic{text});
	@text					= map{s/^-\s+//; s/\s+$//; s/:$//; $_} @text;
	my($inside_see_also)	= false;
	my($module_name_re)		= qr/^([A-Z]+[a-z0-9]{0,}|[a-z]+)/o; # A Perl module, hopefully. Eg: X11:XCB
	my($topic_name_re)		= qr/\[\[(.+)\]\]/o; # A topic name, eg [[XS]].

	my($href);
	my($item);
	my(@lines);
	my(@see_also);

	$self -> logger -> info("Called format_text. title: $$topic{title}. id: $$topic{id}. text: $$topic{text}");

	for (0 .. $#text)
	{
		$$topic{id}++;

		$self -> logger -> info("Starting leaf: id: $$topic{id}. $text[$_]");

		$item = {href => '', id => $$topic{id}, text => ''};

		if ($text[$_] =~ /^o\s+/)
		{
			$$item{text} = substr($text[$_], 2); # Chop off 'o ' prefix.

			$self -> logger -> error("Missing text @ line $_") if (length($text[$_]) == 0);

			if ($inside_see_also)
			{
				$inside_see_also = false;
			}

			if ($$item{text} =~ /^[A-Z]+$/) # Eg: Acronyms.
			{
				$$item{text} .= " => $text[$_ + 1]";
			}
			elsif ($$item{text} =~ /^http/) # Eg: AdventPlanet.
			{
				$$item{href} = $$item{text};
			}
			elsif ($$item{text} =~ /^See also/) # Eg: ApacheStuff.
			{
				$inside_see_also = true;

				next; # Discard this line. Add it back below, with a ':'.
			}
			elsif ($_ <= $#text - 2)
			{
				if ($text[$_ + 1] =~ /^http/) # Eg: AudioVisual.
				{
					$$item{href} = $text[$_ + 1];
				}
				elsif ($$item{text} =~ $module_name_re) # Eg: builtins, Imager, GD and GD::Polyline.
				{
					$$item{text} = "<a href = 'https://metacpan.org/pod/$$item{text}'>$$item{text} - $text[$_ + 1]</a>";
				}
				else
				{
					$$item{text} .= " => $text[$_ + 1]";

					if ($text[$_ + 2] =~ /^http/) # Eg: Most entries.
					{
						$$item{href} = $text[$_ + 2];
					}
				}
			}

			push @lines, $item;
		}
		elsif ($inside_see_also)
		{
			$$item{text} = $text[$_];

			push @see_also, $item;
		}
	}

	my($count) = 0;

	my($entry);
	my(@pieces);
	my($text_is_topic, $topic_id, $topic_name);

	$self -> logger -> info("AAA. Size of see_also: @{[$#see_also + 1]}");

	for $item (@see_also)
	{
		$count++;

		$self -> logger -> info("Starting see_also: id: $$item{id}. $$item{text}");

		if ($count == 1)
		{
			push @lines, {href => '', id => 0, text => 'See also:'};
		}

		@pieces			= split(/ - /, $$item{text});
		$pieces[0]		= $1 if ($pieces[0] =~ $topic_name_re); # Eg: [[XS]].
		$$item{text}	= $pieces[0];
		$pieces[1]		= '' if (! $pieces[1]);
		$topic_id		= $$pad{topic_names}{$pieces[0]} || 0;
		$text_is_topic	= ($topic_id > 0) ? true : false;

		if ($$item{text} =~ /^http/) # Eg: https://perldoc.perl.org/ - PerlDoc
		{
			$self -> logger -> info("A: $$item{text} starts with http");

			$pieces[1]		= $pieces[1] ? "$pieces[0] - $pieces[1]" : $pieces[0];
			$$item{text}	.= "<a href = '$pieces[0]'>$pieces[1]</a>";
		}
		elsif ($text_is_topic) # Eg: GeographicStuff or [[HTTPHandling]] or CryptoStuff - re Data::Entropy
		{
			$self -> logger -> info("B: $$item{text} is a topic");

			$topic_name		= $pieces[0];
			$topic_name		= $pieces[1] ? "$pieces[0] - $pieces[1]" : $pieces[0];

			$self -> logger -> info("page_name:  $$pad{page_name}");
			$self -> logger -> info("topic_name: $topic_name");
			$self -> logger -> info("pieces[0]:  $pieces[0]");
			$self -> logger -> info("pieces[1]:  $pieces[1]");
			$self -> logger -> info("topic_id:   $topic_id");
			$self -> logger -> error("Missing id for topic") if ($topic_id == 0);

			$$item{text}	= "$topic_name (topic)";
			#$$item{text}	= "<a href = '#$topic_id'>$topic_name (topic)</a>";
			#$$item{text}	= qq|<button onclick="\$('#jstree_div').jstree(true).select_node('$topic_id');">$topic_name (topic)</button>|;
			#$$item{text}	= qq|<button onclick="\$('#jstree_div').jstree(true).select_node('#$topic_id');">$topic_name (topic)</button>|;
			#$$item{text}	= qq|<button onclick="\$('#jstree_div').jstree(true).select_node('\#$topic_id');">$topic_name (topic)</button>|;
		}
		else # Eg: builtins, Imager, GD and GD::Polyline. Not ChartingAndPlotting.
		{
			$self -> logger -> info("C: $$item{text} is a module");

			$$item{text} .= "<a href = 'https://metacpan.org/pod/$$item{text}'>$$item{text}</a>";
		}

		push @lines, $item;
	}

	$self -> logger -> info("Line $_: <$lines[$_]{text}> & <$lines[$_]{href}>") for (0 .. $#lines);
	$self -> logger -> info("ZZZ. Count: $count");

	return \@lines;

} # End of format_text.

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
