package App::Toodledo::TaskRole;

use Moose::Role;

our $VERSION = '1.01';

# Minimal attributes when fetching:
has id           => ( is => 'rw', isa => 'Int' );
has title        => ( is => 'rw', isa => 'Str' );
has completed    => ( is => 'rw', isa => 'Int' );
has modified     => ( is => 'rw', isa => 'Int' );

# Optional attributes:
has tag          => ( is => 'rw', isa => 'Str' );
has folder       => ( is => 'rw', isa => 'Int' );
has context      => ( is => 'rw', isa => 'Str' );
has goal         => ( is => 'rw', isa => 'Int' );
has location     => ( is => 'rw', isa => 'Int' );
has parent       => ( is => 'rw', isa => 'Int' );
has children     => ( is => 'rw', isa => 'Int' );
has order        => ( is => 'rw', isa => 'Int' );
has duedate      => ( is => 'rw', isa => 'Int' );
has duedatemod   => ( is => 'rw', isa => 'Int' );
has startdate    => ( is => 'rw', isa => 'Int' );
has duetime      => ( is => 'rw', isa => 'Int' );
has repeat       => ( is => 'rw', isa => 'Str' );
has repeatfrom   => ( is => 'rw', isa => 'Int' );
has status       => ( is => 'rw', isa => 'Int' );
has length       => ( is => 'rw', isa => 'Int' );
has priority     => ( is => 'rw', isa => 'Int' );
has star         => ( is => 'rw', isa => 'Int' );
has added        => ( is => 'rw', isa => 'Int' );
has timer        => ( is => 'rw', isa => 'Int' );
has timeron      => ( is => 'rw', isa => 'Int' );
has note         => ( is => 'rw', isa => 'Str' );
has meta         => ( is => 'rw', isa => 'Str' );

no Moose;

1;

__END__

=head1 NAME

App::Toodledo::TaskRole - internal attributes of a task.

=head1 SYNOPSIS

For internal L<App::Toodledo> use only.

=head1 DESCRIPTION

For internal L<App::Toodledo> use only.

=head1 ATTRIBUTES

The attributes of a task are defined here.  They should match
what Toodledo publishes in their API.  They are:

=head2 id

=head2 title

=head2 completed

=head2 modified

=head2 tag

=head2 folder

=head2 context

=head2 goal

=head2 location

=head2 parent

=head2 children

=head2 order

=head2 duedate

=head2 duedatemod

=head2 startdate

=head2 duetime

=head2 repeat

=head2 repeatfrom

=head2 status

=head2 length

=head2 priority

=head2 star

=head2 added

=head2 timer

=head2 timeron

=head2 note

=head2 meta

=head1 AUTHOR

Peter Scott C<cpan at psdt.com>

=cut
