package App::Toodledo::GoalRole;

use Moose::Role;

our $VERSION = '1.00';

has id          => ( is => 'rw', isa => 'Int' );
has name        => ( is => 'rw', isa => 'Str' );
has level       => ( is => 'rw', isa => 'Int' );
has archived    => ( is => 'rw', isa => 'Bool' );
has contributes => ( is => 'rw', isa => 'Int' );
has goal        => ( is => 'rw', isa => 'Str' );
has note        => ( is => 'rw', isa => 'Str' );


no Moose;

1;

__END__

=head1 NAME

App::Toodledo::GoalRole - internal attributes of a goal.

=head1 SYNOPSIS

For internal L<App::Toodledo> use only.

=head1 DESCRIPTION

For internal L<App::Toodledo> use only.

=head1 ATTRIBUTES

The attributes of a goal are defined here.  They should match
what Toodledo publishes in their API.  They are:

=head2 id

=head2 name

=head2 level

=head2 archived

=head2 contributes

=head1 AUTHOR

Peter Scott C<cpan at psdt.com>

=cut
