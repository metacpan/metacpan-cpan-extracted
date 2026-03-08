use strict;
use warnings;

package Data::ZPath;

use Carp          qw(croak);

use Data::ZPath::_Ctx;
use Data::ZPath::_Lexer;
use Data::ZPath::Node;
use Data::ZPath::NodeList;
use Data::ZPath::_Parser;
use Data::ZPath::_ScalarProxy;
use Data::ZPath::_Evaluate;

our $DEBUG = 0;

our $VERSION = '0.001000';

our @CARP_NOT = qw(
	Data::ZPath::_Ctx
	Data::ZPath::_Lexer
	Data::ZPath::Node
	Data::ZPath::NodeList
	Data::ZPath::_Parser
	Data::ZPath::_ScalarProxy
	Data::ZPath::_Evaluate
);

for my $pkg ( @CARP_NOT ) {
	no strict 'refs';
	*{"${pkg}::CARP_NOT"} = \@CARP_NOT;
}

our $Epsilon      = 1e-08;
our $UseBigInt    = !!1;
our $XmlIgnoreWS  = !!1;

sub new {
	my ( $class, $expr ) = @_;
	croak "Missing expression" unless defined $expr;

	my $self = bless {
		expr_src => $expr,
		terms    => Data::ZPath::_Parser::_parse_top_level_terms($expr),
	}, $class;

	return $self;
}

sub evaluate {
	my ( $self, $root, %opts ) = @_;
	my $wantarray = wantarray;

	my $ctx = Data::ZPath::_Ctx->new($root);
	my @out;

	for my $term (@{$self->{terms}}) {
		push @out, Data::ZPath::_Evaluate::_eval_expr($term, $ctx);
		last if ( $opts{first} and @out );
	}

	return Data::ZPath::NodeList->_new_or_list(@out);
}

sub all {
	my ( $self, $root ) = @_;
	map $_->value, $self->evaluate( $root )->all;
}

sub first {
	my ( $self, $root ) = @_;
	my $found = $self->evaluate($root, first => 1)->first
		or return undef;
	return $found->value;
}

sub last {
	my ( $self, $root ) = @_;
	my $found = $self->evaluate($root)->last
		or return undef;
	return $found->value;
}

sub each {
	my ( $self, $root, $cb ) = @_;
	croak "each() requires a coderef" unless ref($cb) eq 'CODE';

	my $ctx = Data::ZPath::_Ctx->new($root);
	for my $term (@{$self->{terms}}) {
		my @res = Data::ZPath::_Evaluate::_eval_expr($term, $ctx);

		for my $node (@res) {
			my $slot = $node->slot;
			croak "each() can only mutate Perl map/list scalars (not XML)" unless $slot && ref($slot) eq 'CODE';

			tie my $proxy, 'Data::ZPath::_ScalarProxy', $slot;
			$cb->() for $proxy;
		}
	}

	return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Data::ZPath - ZPath implementation for Perl

=head1 SYNOPSIS

  use Data::ZPath;
  use XML::LibXML;

  my $path = Data::ZPath->new('./foo/bar');
  my $dom  = XML::LibXML->load_xml( string => '<foo><bar>5</bar></foo>' );

  my $result  = $path->first($dom);      # 5
  my @results = $path->all($dom);        # ( 5 )

  my $hashref = { foo => { bar => 6 } };
  my $result2 = $path->first($hashref);  # 6

  $path->each($hashref, sub { $_ *= 2 }); # increments bar -> 12

=head1 DESCRIPTION

Implements the ZPath grammar and core functions described at https://zpath.me.

Key parsing rules from zpath.me:

=over

=item *

Paths are UNIX-like segments separated by "/".

=item *

Segments can be: "*", "**", ".", "..", "..*", a name, "#n", "name#n", a function call, and any segment can have qualifiers "[expr]" (zero or more).

=item *

Binary operators require whitespace on both sides.

=item *

Ternary "? :" requires whitespace around "?" and ":".

=item *

Top-level expression may be a comma-separated list of expressions.

=back

=head1 METHODS

=head2 C<< new($expr) >>

Compile a ZPath expression.

=head2 C<< first($root) >>

Evaluate and return the first primitive value.

=head2 C<< all($root) >>

Evaluate and return all primitive values.

=head2 C<< evaluate($root) >>

Evaluate matches.

In list context, returns a list of L<Data::ZPath::Node>
objects. In scalar context, returns a
L<Data::ZPath::NodeList> object wrapping those nodes.

This is the low-level API used by the convenience methods.

=head2 C<< last($root) >>

Evaluate and return the last primitive value.

=head2 C<< each($root, $callback) >>

Evaluate and invoke callback for each matched Perl scalar, aliasing C<$_> so modifications write back.

=cut

=head1 PACKAGE VARIABLES

=over

=item C<< $Data::ZPath::Epsilon >>

The desired error tolerance when the zpath C<< == >> and C<< != >> operators
compare floating point numbers for equality. Defaults to 1e-08.

If you need to change this, it is recommended that you use C<local> in the
smallest scope possible.

=item C<< $Data::ZPath::UseBigInt >>

If true, the C<< number("123...") >> function will return a L<Math::BigInt>
object for any numbers too big to be represented accurately by Perl's native
numeric type. Defaults to true.

=item C<< $Data::ZPath::XmlIgnoreWS >>

Ignore XML text nodes consisting only of whitespace. Default true.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-data-zpath/issues>.

=head1 SEE ALSO

L<https://zpath.me>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
