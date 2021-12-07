package DataStructure::Roles;

=pod

=over 4

=item DataStructure::Queue

Implemented by L<DataStructure::LinkedList> and L<DataStructure::DoubleList>

Has the following methods C<shift()>, C<push($value)>, C<values()>, C<empty()>, C<size()>.

Nodes have the following methods: C<value()>.

Synonym: C<DataStructure::FIFO>.

=item DataStructure::Stack

Implemented by L<DataStructure::LinkedList> (with the C<reverse> option) and
L<DataStructure::DoubleList>.

Has the following methods C<first()>, C<push($value)>, C<pop()>, C<values()>,
C<empty()>, C<size()>.

Nodes have the following methods: C<value()>, C<insert_after($value)>, C<next()>.

Note that, without the C<reverse> option a L<DataStructure::LinkedList> can also
behave like a stack but you would need to use the less common C<shift> and
C<unshift> pair of methods.

Synonym: C<DataStructure::LIFO>.

=item DataStructure::OrderedSet

Implemented by L<DataStructure::BTree>

Has the following methods C<insert($value)>, C<find($value)>,
C<delete($value | $node)>, C<values()>, C<empty()>, C<size()>.

=back

=cut

1;
