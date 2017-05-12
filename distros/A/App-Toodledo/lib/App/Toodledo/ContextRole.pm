package App::Toodledo::ContextRole;

use Moose::Role;

our $VERSION = '1.00';

# Minimal attributes when fetching:
has id           => ( is => 'rw', isa => 'Int' );
has name         => ( is => 'rw', isa => 'Str' );

# This may come into being soon:
has ord        => ( is => 'rw', isa => 'Int' );

no Moose;

1;

__END__

=head1 NAME

App::Toodledo::ContextRole - internal attributes of a context.

=head1 SYNOPSIS

For internal L<App::Toodledo> use only.

=head1 DESCRIPTION

For internal L<App::Toodledo> use only.

=head1 ATTRIBUTES

The attributes of a context are defined here.  They should match
what Toodledo publishes in their API.  They are:

=head2 id

=head2 name

=head2 ord



=head1 AUTHOR

Peter Scott C<cpan at psdt.com>

=cut
