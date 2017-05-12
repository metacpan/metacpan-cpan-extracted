package Adapter::Async;
# ABSTRACT: common API for linking data sources and views
use strict;
use warnings;

our $VERSION = '0.019';

=head1 NAME

Adapter::Async - provides a way to link a data source with a view

=head1 VERSION

version 0.018

=head1 DESCRIPTION

C<WARNING> - this is extremely experimental and utterly unoptimised.
Expect the API to change between versions until this reaches 1.0+.
Primarily being released to allow work to continue on various L<Tickit>
widgets and web framework components.

=cut

use Future;
use curry;

use Adapter::Async::Bus;

=head1 METHODS

=cut

=head2 new

Instantiate, applying any parameters directly to the instance hashref.

=cut

sub new {
	my $class = shift;
	bless { @_ }, $class
}

=head2 bus

Accessor for the L<Adapter::Async::Bus> instance, will create one as
required.

=cut

sub bus { shift->{bus} ||= Adapter::Async::Bus->new }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.
