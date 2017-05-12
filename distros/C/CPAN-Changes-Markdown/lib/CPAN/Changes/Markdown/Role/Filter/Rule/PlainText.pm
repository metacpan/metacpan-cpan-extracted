use 5.006;    # our
use strict;
use warnings;

package CPAN::Changes::Markdown::Role::Filter::Rule::PlainText;

# ABSTRACT: A rule that only filters 'plaintext' nodes.

our $VERSION = '1.000002';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY
















use Role::Tiny qw( requires with );





requires 'filter_plaintext';

with 'CPAN::Changes::Markdown::Role::Filter::Rule';

















sub filter {
  my ( $self, @input ) = @_;
  my @output;
  for my $input (@input) {
    if ( not $input->isa('CPAN::Changes::Markdown::Filter::Node::PlainText') ) {
      push @output, $input;
      next;
    }
    push @output, $self->filter_plaintext($input);
  }
  return @output;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Changes::Markdown::Role::Filter::Rule::PlainText - A rule that only filters 'plaintext' nodes.

=head1 VERSION

version 1.000002

=head1 SYNOPSIS

    package Example::Rule;

    use Role::Tiny::With;

    with 'CPAN::Changes::Markdown::Role::Filter::Rule::PlainText';

    sub filter_plaintext {
        my ( $self, @nodes ) = @_;
        return ( @nodes );
    }

=head1 ROLE REQUIRES

=head2 C<filter_plaintext>

=head1 METHODS

=head2 C<filter>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"CPAN::Changes::Markdown::Role::Filter::Rule::PlainText",
    "interface":"role",
    "does":"CPAN::Changes::Markdown::Role::Filter::Rule"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
