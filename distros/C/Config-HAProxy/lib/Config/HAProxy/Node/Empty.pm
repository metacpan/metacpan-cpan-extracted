package Config::HAProxy::Node::Empty;
use parent 'Config::HAProxy::Node';

=head1 NAME

Config::HAProxy::Node::Empty - empty HAProxy configuration node

=head1 DESCRIPTION

Objects of this class represent empty lines in HAProxy configuration file.

=head1 METHODS

=head2 is_empty

Always true.

=head2 orig

Returns original line as it appeared in the configuration file.

=head2 locus

Returns the location of this statement in the configuration file (the
B<Text::Locus> object).

=head1 SEE ALSO

B<Config::HAProxy::Node>, B<Text::Locus>.

=cut

sub is_empty { 1 }

1;
