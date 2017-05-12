package CSS::Croco::StyleSheet;

1;


=head1 NAME

CSS::Croco::StyleSheet - stylesheet object

=head1 SYNOPSYS

    my $croco = CSS::Croco->new;
    my $stylesheet = $croco->parse( ' * { property: value }' );
    my $statements = $stylesheet->rules

=head1 METHODS

=head2 rules

Shows all CSS statements. Returns list of L<CSS::Croco::Statement> subclasses.

=head2 to_string

Returns string representation of stylesheet.

=cut

