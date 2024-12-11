package Config::Proxy::Node::Comment;
use parent 'Config::Proxy::Node';

=head1 NAME

Config::Proxy::Node::Comment - comment node in proxy configuration

=head1 DESCRIPTION

Objects of this class represent comments in proxy configuration file.

=head1 METHODS

=head2 is_comment

Returns true.

=head2 orig

Returns original line as it appeared in the configuration file.

=head2 locus

Returns the location of this statement in the configuration file (the
B<Text::Locus> object).

=head1 SEE ALSO

L<Config::proxy::Node>, L<Text::Locus>.

=cut

sub is_comment { 1 }

1;
