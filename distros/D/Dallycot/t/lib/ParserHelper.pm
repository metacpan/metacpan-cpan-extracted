package ParserHelper;

use strict;
use warnings;

use Test::More;

use Dallycot::Parser;

use Scalar::Util qw(blessed);

use Exporter 'import';

our @EXPORT = qw(
  test_parses
  Noop
  sequence
  placeholder
  fullPlaceholder
  intLit
  floatLit
  stringLit
  durationLit
  fetch
  list
  cons
  listCons
  sum
  negation
  modulus
  product
  reciprocal
  equality
  increasing
  decreasing
  strictly_increasing
  strictly_decreasing
  unique
  assignment
  lambda
  apply
  apply_with_options
  head
  tail
  conditions
  condition
  otherwise
  map_
  filter_
  compose_
  any_
  all_
  walk_forward
  walk_reverse
  prop_walk
  propLit
  prop_closure
  prop_alternatives
  build_node
  right_property
  left_property
  uriLit
  buildUri
  vectorLit
  vector
  index_
  reduce
  type_promotion
  zip
  range
  Defined
  nsdef
  set
  jsonLit
  jsonString
  jsonNumeric
  jsonArray
  jsonObject
  jsonProperty
  xmlns_def
);

sub test_parses {
  my(%trees) = @_;

  my $parser = Dallycot::Parser->new;
  $Data::Dumper::Indent = 1;
  foreach my $expr (sort { length($a) <=> length($b) } keys %trees ) {

    my $parse = $parser->parse($expr);
    is_deeply($parse, $trees{$expr}, "Parsing ($expr)") or do {
      print STDERR "($expr): ", Data::Dumper->Dump([$parse]);
      # if('ARRAY' eq ref $parse) {
      #   print STDERR "\n   " . join("; ", map { $_ -> to_string } @$parse). "\n";
      # }
      # elsif($parse) {
      #   print STDERR "\n   " . $parse->to_string . "\n";
      # }
      print STDERR "expected: ", Data::Dumper->Dump([$trees{$expr}]);
    };
  }
}

#==============================================================================

sub Noop {
  bless [] => 'Dallycot::AST::Expr';
}

sub sequence {
  my(@things) = @_;

  my @assignments = grep { blessed($_) && $_ -> isa('Dallycot::AST::Assign') } @things;
  my @statements = grep { blessed($_) && !$_ -> isa('Dallycot::AST::Assign') } @things;
  my @identifiers = map { $_ -> identifier } @assignments;

  bless [ \@assignments, \@statements, \@identifiers, {}, [] ] => 'Dallycot::AST::Sequence';
}

sub placeholder {
  bless [] => 'Dallycot::AST::Placeholder';
}

sub fullPlaceholder {
  bless [] => 'Dallycot::AST::FullPlaceholder';
}

sub intLit {
  bless [ Math::BigRat->new(shift) ] => 'Dallycot::Value::Numeric';
}

sub floatLit {
  bless [ Math::BigRat->new(shift) ] => 'Dallycot::Value::Numeric';
}

sub durationLit {
  Dallycot::Value::Duration -> new(@_);
}

sub stringLit {
  my($val, $lang) = (@_,'en');
  bless [ $val, $lang ] => 'Dallycot::Value::String';
}

sub fetch {
  bless \@_ => 'Dallycot::AST::Fetch';
}

sub list {
  bless \@_ => 'Dallycot::AST::BuildList';
}

sub cons {
  bless \@_ => 'Dallycot::AST::Cons';
}

sub listCons {
  bless \@_ => 'Dallycot::AST::ListCons';
}

sub sum {
  bless \@_ => 'Dallycot::AST::Sum';
}

sub negation {
  bless [ shift ] => 'Dallycot::AST::Negation';
}

sub modulus {
  bless \@_ => 'Dallycot::AST::Modulus';
}

sub product {
  bless \@_ => 'Dallycot::AST::Product';
}

sub reciprocal {
  bless [ shift ] => 'Dallycot::AST::Reciprocal';
}

sub equality {
  bless \@_ => 'Dallycot::AST::Equality';
}

sub increasing {
  bless \@_ => 'Dallycot::AST::Increasing';
}

sub decreasing {
  bless \@_ => 'Dallycot::AST::Decreasing';
}

sub strictly_increasing {
  bless \@_ => 'Dallycot::AST::StrictleIncreasing';
}

sub strictly_decreasing {
  bless \@_ => 'Dallycot::AST::StrictlyDecreasing';
}

sub unique {
  bless \@_ => 'Dallycot::AST::Unique';
}

sub assignment {
  my($identifier, $expression) = @_;
  bless [ $identifier, $expression ] => 'Dallycot::AST::Assign';
}

sub lambda {
  my($bindings, $options, $expression) = @_;

  bless [ $expression, $bindings, [], $options ] => 'Dallycot::AST::Lambda';
}

sub apply {
  bless [ shift, \@_, {} ] => 'Dallycot::AST::Apply';
}

sub apply_with_options {
  my($expression, $options, @bindings) = @_;

  bless [ $expression, \@bindings, $options ] => 'Dallycot::AST::Apply';
}

sub head {
  bless [ shift ] => 'Dallycot::AST::Head'
}

sub tail {
  bless [ shift ] => 'Dallycot::AST::Tail'
}

sub conditions {
  bless \@_ => 'Dallycot::AST::Condition'
}

sub condition {
  [ @_ ]
}

sub otherwise {
  [ undef, $_[0] ]
}

sub map_ {
  bless \@_ => 'Dallycot::AST::Map'
}

sub filter_ {
  bless \@_ => 'Dallycot::AST::BuildFilter'
}

sub compose_ {
  bless \@_ => 'Dallycot::AST::Compose'
}

sub any_ {
  bless \@_ => 'Dallycot::AST::Any'
}

sub all_ {
  bless \@_ => 'Dallycot::AST::All'
}

sub walk_forward {
  bless [ shift ] => 'Dallycot::AST::ForwardWalk'
}

sub walk_reverse {
  bless [ shift ] => 'Dallycot::AST::ReverseWalk'
}

sub prop_walk {
  bless \@_ => 'Dallycot::AST::PropWalk'
}

sub propLit {
  bless [ split(/:/, shift) ] => 'Dallycot::AST::PropertyLit'
}

sub prop_closure {
  bless [ shift ] => 'Dallycot::AST::PropertyClosure'
}

sub prop_alternatives {
  bless \@_ => 'Dallycot::AST::AnyProperty'
}

sub build_node {
  bless \@_ => 'Dallycot::AST::BuildNode'
}

sub right_property {
  bless [ undef, $_[0], $_[1] ] => 'Dallycot::AST::Property'
}

sub left_property {
  bless [ $_[1], $_[0], undef ] => 'Dallycot::AST::Property'
}

sub uriLit {
  bless [ shift ] => 'Dallycot::Value::URI'
}

sub buildUri {
  bless \@_ => 'Dallycot::AST::BuildUri'
}

sub vectorLit {
  bless \@_ => 'Dallycot::Value::Vector'
}

sub vector {
  bless \@_ => 'Dallycot::AST::BuildVector'
}

sub set {
  if(@_) {
    bless \@_ => 'Dallycot::AST::BuildSet';
  }
  else {
    bless [] => 'Dallycot::Value::Set';
  }
}

sub index_ {
  bless \@_ => 'Dallycot::AST::Index'
}

sub reduce {
  apply(
    uriLit('http://www.dallycot.net/ns/core/1.0#last'),
    apply(
      uriLit('http://www.dallycot.net/ns/core/1.0#foldl'),
      @_
    )
  );
}

sub type_promotion {
  bless \@_ => 'Dallycot::AST::TypePromotion'
}

sub zip {
  bless \@_ => 'Dallycot::AST::Zip'
}

sub range {

  bless [ $_[0], $_[1] ] => 'Dallycot::AST::BuildRange'
}

sub Defined {
  bless [ $_[0] ] => 'Dallycot::AST::Defined'
}

sub nsdef {
  bless \@_ => 'Dallycot::AST::XmlnsDef'
}

sub jsonArray {
  bless \@_ => 'Dallycot::AST::JSONArray'
}

sub jsonObject {
  bless \@_ => 'Dallycot::AST::JSONObject'
}

sub jsonProperty {
  bless \@_ => 'Dallycot::AST::JSONProperty'
}

sub xmlns_def {
  bless \@_ => 'Dallycot::AST::XmlnsDef';
}

1;
