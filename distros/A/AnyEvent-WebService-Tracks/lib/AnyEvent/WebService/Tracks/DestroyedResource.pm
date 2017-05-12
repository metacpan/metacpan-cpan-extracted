package AnyEvent::WebService::Tracks::DestroyedResource;

use strict;
use warnings;

use Carp ();

our $VERSION = '0.02';

sub AUTOLOAD {
    Carp::croak("Cannot call methods on a destroyed object!");
}

1;

__END__

=begin comment

Undocumented stuff (for Pod::Coverage)

=over

=item AUTOLOAD

=back

=end comment
