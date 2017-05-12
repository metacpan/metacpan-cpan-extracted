use 5.006;    # our
use strict;
use warnings;

package CPAN::Changes::Markdown::Filter::NodeUtil;

# ABSTRACT: short-hand node construction functions

our $VERSION = '1.000002';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY




















use Sub::Exporter::Progressive -setup => { exports => [qw( mk_node_plaintext mk_node_delimitedtext )] };





## no critic ( RequireArgUnpacking )

sub mk_node_plaintext {
  require CPAN::Changes::Markdown::Filter::Node::PlainText;
  return CPAN::Changes::Markdown::Filter::Node::PlainText->create(@_);
}





sub mk_node_delimitedtext {
  require CPAN::Changes::Markdown::Filter::Node::DelimitedText;
  return CPAN::Changes::Markdown::Filter::Node::DelimitedText->create(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Changes::Markdown::Filter::NodeUtil - short-hand node construction functions

=head1 VERSION

version 1.000002

=head1 SYNOPSIS

    use CPAN::Changes::Markdown::Filter::NodeUtil;

    my $node = mk_node_plaintext('text');

=head1 EXPORTS

=head2 C<mk_node_plaintext>

=head2 C<mk_node_delimitedtext>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"CPAN::Changes::Markdown::Filter::NodeUtil",
    "interface":"exporter"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
