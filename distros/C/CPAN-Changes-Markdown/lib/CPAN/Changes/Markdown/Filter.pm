use 5.006;    # our
use strict;
use warnings;

package CPAN::Changes::Markdown::Filter;

# ABSTRACT: a simple plug-in based, staged text filter for Markdown translation

our $VERSION = '1.000002';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY











use Moo 1.000008 qw( with has );
use CPAN::Changes::Markdown::Filter::NodeUtil qw(mk_node_plaintext);














with 'CPAN::Changes::Markdown::Role::Filter';







has rules => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    [];
  },
);







sub process {
  my ( $self, $input ) = @_;
  my (@input) = ( mk_node_plaintext($input) );
  for my $rule ( @{ $self->rules } ) {
    @input = $rule->filter(@input);
  }
  return join q{}, map { $_->to_s } @input;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Changes::Markdown::Filter - a simple plug-in based, staged text filter for Markdown translation

=head1 VERSION

version 1.000002

=head1 SYNOPSIS

    use CPAN::Changes::Markdown::Filter::RuleUtil qw(:all);
    use CPAN::Changes::Markdown::Filter;
    my $filter = CPAN::Changes::Markdown::Filter->new(
        rules => [ rule_NumericToCode ]
    );

=head1 METHODS

=head2 C<rules>

=head2 C<process>

    my $output = $filter->process( $input );

=head1 ATTRIBUTES

=head2 C<rules>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"CPAN::Changes::Markdown::Filter",
    "interface":"class",
    "inherits":"Moo::Object",
    "does":"CPAN::Changes::Markdown::Role::Filter"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
