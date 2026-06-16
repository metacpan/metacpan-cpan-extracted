package CPAN::MetaCurator::Validate;

use boolean;
use feature 'say';
use open qw(:std :utf8);
use parent 'CPAN::MetaCurator::Database';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().
use DateTime::Tiny;

use File::Slurper 'read_lines';
use File::Spec;

use Syntax::Keyword::Match;

use Types::Standard 'Enum';

our %seen;

our $VERSION = '1.23';

# --------------------------------------------------

sub parse_topic
{
	my($self, $pad, $topic)	= @_;
	my(@lines)				= split(/\n/, $$topic{text});
	@lines					= grep{length} map{s/^\s+//; s/:\s*$//; $_} @lines;
	my($index)				= -1;
	my($context_enum)		= Enum['acronym', 'faq', 'module', 'pre_pre', 'see_also', 'text'];

	my($context, $current_token);
	my($description);
	my($href);
	my($line);
	my(%node_type);
	my($token);

	while ($index < $#lines)
	{
		$index++;

		$line	= $lines[$index];
		$token	= '';

		if ($$topic{title} eq 'Acronyms')
		{
			$context = 'acronym';
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
			$context		= 'module';
			$current_token	= $token = $1;

			if ($$pad{module_names}{$token} && ! $seen{$token})
			{
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
			}
			case('faq')
			{
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
			}
			case('see_also')
			{
			}
			case('pre_pre')
			{
			}
			case('text')
			{
				$self -> logger -> debug("Token: $current_token. Double-quote found") if ($line =~ /"/); # Extra " to keep UEX happy.
			}
		} # End match.
	}

} # End of parse_topic.

# -----------------------------------------------

sub run
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	my($pad)	= $self -> build_pad;
	my($root)	= shift @{$$pad{topics} }; # I.e.: {parent_id => 1, text => 'Root', title => 'MetaCurator'}.
	my($id)		= $$pad{topic_html_ids}{$$root{title} };

	$self -> logger -> info($self -> visual_break);
	$self -> logger -> info("Topic: id: $id. html_id: $$pad{topic_html_ids}{$$root{title}}. title: $$root{title}");
	$self -> logger -> info($self -> visual_break);

	for my $topic (@{$$pad{topics} })
	{
		$self -> logger -> info("Topic: id: $$topic{id}. html_id: $$pad{topic_html_ids}{$$topic{title}}. title: $$topic{title}");
		$self -> parse_topic($pad, $topic);
		$self -> logger -> info($self -> visual_break);
	}

	return 0;

} # End of run.

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
