package App::Toodledo::NotebookRole;

use Moose::Role;

our $VERSION = '1.00';

has id           => ( is => 'rw', isa => 'Int' );
has title        => ( is => 'rw', isa => 'Str' );
has folder       => ( is => 'rw', isa => 'Int' );
has modified     => ( is => 'rw', isa => 'Int' );
has added        => ( is => 'rw', isa => 'Int' );
has private      => ( is => 'rw', isa => 'Bool' );
has text         => ( is => 'rw', isa => 'Str' );

no Moose;

1;

__END__

=head1 NAME

App::Toodledo::NotebookRole - internal attributes of a notebook.

=head1 SYNOPSIS

For internal L<App::Toodledo> use only.

=head1 DESCRIPTION

For internal L<App::Toodledo> use only.

=head1 ATTRIBUTES

The attributes of a notebook are defined here.  They should match
what Toodledo publishes in their API.  They are:


=head2 id

=head2 title

=head2 folder

=head2 modified

=head2 added

=head2 private

=head2 text

=head1 AUTHOR

Peter Scott C<cpan at psdt.com>

=cut
