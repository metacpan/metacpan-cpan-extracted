package Brackup::Dict::Null;

sub new { bless {}, shift }
sub get {}
sub set {}
sub each {}
sub delete {}
sub count { 0 }
sub backing_file {}

1;

__END__

=head1 NAME

Brackup::Dict::Null - noop key-value dictionary implementation, 
discarding everything it receives

=head1 DESCRIPTION

Brackup::Dict::Null is a noop implementation of the Brackup::Dict
inteface - it just discards all data it receives, and returns undef
to all queries. 

Intended for TESTING ONLY.

Ignores all instantiation parameters, and doesn't use any files.

=head1 SEE ALSO

L<brackup>

L<Brackup>

L<Brackup::Dict::SQLite>

=cut
