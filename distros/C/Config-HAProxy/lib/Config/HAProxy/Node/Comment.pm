package Config::HAProxy::Node::Comment;
use parent 'Config::HAProxy::Node';

=head1 NAME

Config::HAProxy::Node::Comment - comment node in HAProxy configuration

=head1 DESCRIPTION

Objects of this class represent comments in HAProxy configuration file.

=head1 METHODS

=head2 is_comment

Returns true.

=head2 orig

Returns original line as it appeared in the configuration file.

=head2 locus

Returns the location of this statement in the configuration file (the
B<Text::Locus> object).

=head1 SEE ALSO

B<Config::HAProxy::Node>, B<Text::Locus>.

=cut

sub is_comment { 1 }

1;

    
