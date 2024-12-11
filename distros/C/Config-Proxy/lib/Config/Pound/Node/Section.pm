package Config::Pound::Node::Section;
use parent 'Config::Proxy::Node::Section';

sub append_node {
    my $self = shift;
    my $last = $self->last;
    if ($last && $last->is_statement && lc($last->kw) eq 'end') {
	$self->insert_node($last->index, @_);
    } else {
	$self->SUPER::append_node(@_);
    }
}

1;

=head1 NAME

Config::Pound::Node::Section - pound proxy configuration section

=head1 DESCRIPTION

Objects of this class represent a C<section> (or a C<compound statement>),
in B<Pound> configuration file.  It is basically the same as its parent
class B<Config::Proxy::Node::Section> (which see), except that its
B<append_node> method ensures that no statements are added after the
terminating B<End> keyword.

=head1 SEE ALSO

L<Config::Pound>, L<Config::Proxy::Node::Section>.

=cut

