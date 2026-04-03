package App::Test::Generator::Mutant;

use strict;
use warnings;

our $VERSION = '0.30';

=head1 VERSION

Version 0.30

=cut

sub new {
	my ($class, %args) = @_;

	for my $required (qw/id description original line transform/) {
		die "Missing required attribute: $required" unless exists $args{$required};
	}

	return bless \%args, $class;
}

sub id { $_[0]->{id} }
sub description { $_[0]->{description} }
sub original { $_[0]->{original} }
sub line { $_[0]->{line} }
sub transform   { $_[0]->{transform} }

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

Portions of this module's initial design and documentation were created with the
assistance of AI.

=cut

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
