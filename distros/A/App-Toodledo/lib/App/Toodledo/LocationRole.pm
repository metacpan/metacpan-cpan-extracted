package App::Toodledo::LocationRole;

use Moose::Role;

our $VERSION = '1.00';

has id          => ( is => 'rw', isa => 'Int' );
has name        => ( is => 'rw', isa => 'Str' );
has description => ( is => 'rw', isa => 'Str' );
has lat         => ( is => 'rw', isa => 'Num' );
has lon         => ( is => 'rw', isa => 'Num' );

no Moose;

1;

__END__

=head1 NAME

App::Toodledo::LocationRole - internal attributes of a role.

=head1 SYNOPSIS

For internal L<App::Toodledo> use only.

=head1 DESCRIPTION

For internal L<App::Toodledo> use only.

=head1 ATTRIBUTES

The attributes of a location are defined here.  They should match
what Toodledo publishes in their API.  They are:

=head2 id

=head2 name

=head2 description

=head2 lat

=head2 lon

=head1 AUTHOR

Peter Scott C<cpan at psdt.com>

=cut
