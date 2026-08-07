package CPAN::MetaCurator::Validate;

use boolean;
use feature 'say';
use parent 'CPAN::MetaCurator::Export';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().

use File::Slurper 'read_lines';
use File::Spec;

our $VERSION = '1.29';

# -----------------------------------------------

sub validate
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	# Phase 1: Build the DAG_Node tree.

	my($pad)	= $self -> build_pad;
	my($root)	= $self -> build_tree($pad);

	# Phase 4; Build the JS Tree.
	# New style.

	my($description);
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
			}
			elsif ($$options{_depth} == 1) # Topics.
			{
			}
			elsif ($$options{_depth} == 2) # Module name || 'Notes for ...' || 'See also'.
			{
				$$pad{count}{leaf}++;

				$description	= $$attributes{description};
				$uri			= $$attributes{uri} || '#';
			}
			elsif ($$options{_depth} == 3) # 'Notes for ...' || 'See also' entries.
			{
			}

			$previous_depth = $$options{_depth};

			return 1;

		}, # End of callback.
		_depth => 0,
	});

	return 0;

} # End of validate.

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
