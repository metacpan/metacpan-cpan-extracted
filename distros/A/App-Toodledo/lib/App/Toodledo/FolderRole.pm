package App::Toodledo::FolderRole;

use Moose::Role;

our $VERSION = '1.00';

has id          => ( is => 'rw', isa => 'Int' );
has name        => ( is => 'rw', isa => 'Str' );
has private     => ( is => 'rw', isa => 'Int' );
has archived    => ( is => 'rw', isa => 'Int' );
has ord         => ( is => 'rw', isa => 'Int' );

no Moose;

1;

__END__

=head1 NAME

App::Toodledo::FolderRole - internal attributes of a folder.

=head1 SYNOPSIS

For internal L<App::Toodledo> use only.

=head1 DESCRIPTION

For internal L<App::Toodledo> use only.

=head1 ATTRIBUTES

The attributes of a folder are defined here.  They should match
what Toodledo publishes in their API.  They are:


=head2 id

=head2 name

=head2 private

=head2 archived

=head2 ord

=head1 AUTHOR

Peter Scott C<cpan at psdt.com>

=cut
