package Adapter::Async::Bus;
$Adapter::Async::Bus::VERSION = '0.019';
use strict;
use warnings;

use parent qw(Mixin::Event::Dispatch);
use constant EVENT_DISPATCH_ON_FALLBACK => 0;

=head1 NAME

Adapter::Async::Bus - 

=head1 VERSION

version 0.018

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

sub new { my $class = shift; bless { @_ }, $class }

=head1 EVENTS

=cut

1;

__END__

=head1 SEE ALSO

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2014-2015. Licensed under the same terms as Perl itself.
