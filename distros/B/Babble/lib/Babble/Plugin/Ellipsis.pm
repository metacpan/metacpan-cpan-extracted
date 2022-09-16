package Babble::Plugin::Ellipsis;

use Moo;

sub transform_to_plain {
  my ($self, $top) = @_;
  $top->each_match_within(Statement => [
    '\.\.\.'
  ] => sub {
    my ($m) = @_;
    $m->replace_text(q|die 'Unimplemented'|);
  });
}

1;
__END__

=head1 NAME

Babble::Plugin::Ellipsis - Plugin for ellipsis / yada yada yada statement

=head1 SYNOPSIS

Converts usage of the ellipsis syntax from

    ...

to

    die 'Unimplemented'

=head1 SEE ALSO

L<... syntax|Syntax::Construct/...>

=cut
