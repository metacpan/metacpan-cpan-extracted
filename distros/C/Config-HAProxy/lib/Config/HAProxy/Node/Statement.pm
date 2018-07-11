package Config::HAProxy::Node::Statement;
use parent 'Config::HAProxy::Node';

=head1 NAME

Config::HAProxy::Node::Statement - simple statement node in HAProxy tree

=head1 DESCRIPTION

Objects of this class represent simple statements in HAProxy configuration
file. A C<simple statement> is any statement excepting: B<global>, B<defaults>,
B<frontend>, and B<backend>.

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

B<Config::HAProxy::Node>, B<Config::HAProxy>, B<Text::Locus>.

=cut

sub is_statement { 1 }

1;
