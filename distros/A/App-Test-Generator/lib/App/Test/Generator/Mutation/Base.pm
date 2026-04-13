package App::Test::Generator::Mutation::Base;

use strict;
use warnings;

our $VERSION = '0.32';

=head1 VERSION

Version 0.32

=cut

sub new { bless {}, shift }

sub applies_to {
	die 'applies_to() must be implemented by subclass';
}

sub mutate {
	die 'mutate() must be implemented by subclass';
}

1;
