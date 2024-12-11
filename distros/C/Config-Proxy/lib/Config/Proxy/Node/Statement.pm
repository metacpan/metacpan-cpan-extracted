package Config::Proxy::Node::Statement;
use parent 'Config::Proxy::Node';

=head1 NAME

Config::Proxy::Node::Statement - simple statement node in proxy tree

=head1 DESCRIPTION

Objects of this class represent simple statements in proxy configuration
file.

=head1 METHODS

=head2 is_statement

Returns true.

=head2 kw

Returns the configuration keyword.

=head2 argv

Returns the list of arguments to the configuration keyword.

=head2 arg

    $s = $node->arg($n)

Returns the B<$n>th argument.

=head2 orig

Returns original line as it appeared in the configuration file.

=head2 locus

Returns the location of this statement in the configuration file (the
B<Text::Locus> object).

=head1 SEE ALSO

L<Config::Proxy::Node>, L<Config::Proxy::Section>, L<Config::Proxy>,
L<Text::Locus>.

=cut

sub is_statement { 1 }

1;
