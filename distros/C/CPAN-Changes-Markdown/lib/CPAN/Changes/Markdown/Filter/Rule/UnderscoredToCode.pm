use 5.006;    # our
use strict;
use warnings;

package CPAN::Changes::Markdown::Filter::Rule::UnderscoredToCode;

# ABSTRACT: Quote things containing an underscore as Code

our $VERSION = '1.000002';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( with );
use CPAN::Changes::Markdown::Filter::NodeUtil qw( mk_node_plaintext mk_node_delimitedtext );
























with 'CPAN::Changes::Markdown::Role::Filter::Rule::PlainText';

# _Pulp__5010_qr_m_propagate_properly
## no critic (Compatibility::PerlMinimumVersionAndWhy)
my $re_prefix = qr/(\A|\A.*?\s) ( _+ [^_\s]+         (?: _+ [^_\s]+ )*   ) (\z|\s.*\z)/msx;
my $re_suffix = qr/(\A|\A.*?\s) ( [^_\s]+ _+         (?: [^_\s]+ _+ )*   ) (\z|\s.*\z)/msx;
my $re_infix  = qr/(\A|\A.*?\s) ( [^_\s]+ _+ [^_\s]+ (?: _+ [^_\s]+ )*   ) (\z|\s.*\z)/msx;
## use critic

sub _inject_code_delim {
  my ( $self, $out, $before, $code, $after ) = @_;
  push @{$out}, mk_node_plaintext($before);
  push @{$out}, mk_node_delimitedtext( q{`}, $code, q{`} );
  push @{$out}, $self->filter_plaintext( mk_node_plaintext($after) );
  return @{$out};
}





sub filter_plaintext {
  my ( $self, $input ) = @_;
  if ( $input->content =~ $re_prefix ) {
    return $self->_inject_code_delim( [], $1, $2, $3 );
  }
  if ( $input->content =~ $re_suffix ) {
    return $self->_inject_code_delim( [], $1, $2, $3 );
  }
  if ( $input->content =~ $re_infix ) {
    return $self->_inject_code_delim( [], $1, $2, $3 );
  }
  return $input;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Changes::Markdown::Filter::Rule::UnderscoredToCode - Quote things containing an underscore as Code

=head1 VERSION

version 1.000002

=head1 SYNOPSIS

    use CPAN::Changes::Markdown::Filter::RuleUtil qw(:all);

    my $instance = rule_UnderscoredToCode( @args );

This filter translates things with _ as part of their token to code spans.

=head1 METHODS

=head2 C<filter_plaintext>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"CPAN::Changes::Markdown::Filter::Rule::UnderscoredToCode",
    "interface":"class",
    "inherits":"Moo::Object",
    "does":"CPAN::Changes::Markdown::Role::Filter::Rule::PlainText"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
