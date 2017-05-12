use 5.006;    # our
use strict;
use warnings;

package CPAN::Changes::Markdown::Filter::Node::PlainText;

# ABSTRACT: A text node that contains markup-free text.

our $VERSION = '1.000002';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

























use Moo qw( with has );

with 'CPAN::Changes::Markdown::Role::Filter::Node';







has content => ( is => rw =>, required => 1 );









sub create {
  my ( $self, $content ) = @_;
  return $self->new( content => $content );
}







sub to_s {
  my ( $self, ) = @_;
  return $self->content;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Changes::Markdown::Filter::Node::PlainText - A text node that contains markup-free text.

=head1 VERSION

version 1.000002

=head1 SYNOPSIS

    use CPAN::Changes::Markdown::Filter::NodeUtil qw( :all );

    my $plaintext = mk_node_plaintext("The text here");

    $plaintext->to_s()    # The text here
    $plaintext->content() # The text here

=head1 METHODS

=head2 C<create>

Slightly shorter hand for C<new>

    $class->create( $text ) == $class->new( content => $text )

=head2 C<to_s>

Represent this node back as text.

=head1 ATTRIBUTES

=head2 C<content>

  rw, required

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"CPAN::Changes::Markdown::Filter::Node::PlainText",
    "does":"CPAN::Changes::Markdown::Role::Filter::Node",
    "interface":"class",
    "inherits":"Moo::Object"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
