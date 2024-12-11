package Config::Proxy::Node::Empty;
use parent 'Config::Proxy::Node';

=head1 NAME

Config::Proxy::Node::Empty - empty proxy configuration node

=head1 DESCRIPTION

Objects of this class represent empty lines in proxy configuration file.

=head1 METHODS

=head2 is_empty

Always true.

=head2 orig

Returns original line as it appeared in the configuration file.

=head2 locus

Returns the location of this statement in the configuration file (the
B<Text::Locus> object).

=head1 SEE ALSO

L<Config::Proxy::Node>, L<Text::Locus>.

=cut

sub is_empty { 1 }

1;
