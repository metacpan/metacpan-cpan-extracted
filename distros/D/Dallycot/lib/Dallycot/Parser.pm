package Dallycot::Parser;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Parse Dallycot source into an abstract syntax tree

use strict;
use warnings;

use utf8;
use experimental qw(switch);

use Marpa::R2;
use Math::BigRat;

use Dallycot::Value::String;
use Dallycot::Value::URI;

use Scalar::Util qw(blessed);
use String::Escape qw(unbackslash unquote);

use Dallycot::AST::Sequence;
use Dallycot::AST::Apply;
use Dallycot::Value::URI;

my $grammar = Marpa::R2::Scanless::G->new(
  { action_object  => __PACKAGE__,
    bless_package  => 'Dallycot::AST',
    default_action => 'copy_arg0',
    source         => do { local ($/) = undef; my $s = <DATA>; \$s; }
  }
);

sub new {
  my ($class) = @_;

  $class = ref($class) || $class;
  return bless {} => $class;
}

sub grammar { return $grammar; }

sub wants_more {
  my ( $self, $val ) = @_;

  if ( @_ == 2 ) {
    $self->{wants_more} = $val;
  }
  return $self->{wants_more};
}

sub error {
  my ( $self, $val ) = @_;

  if ( @_ == 2 ) {
    $self->{error} = $val;
  }
  return $self->{error};
}

sub warnings {
  my ( $self, $warnings ) = @_;

  if ( @_ == 2 ) {
    $self->{warnings} = $warnings;
  }
  if (wantarray) {
    return @{ $self->{warnings} };
  }
  else {
    return @{ $self->{warnings} } != 0;
  }
}

sub parse {
  my ( $self, $input ) = @_;

  my $re = Marpa::R2::Scanless::R->new( { grammar => $self->grammar } );

  $self->error(undef);
  $self->warnings( [] );

  my $worked = eval {
    $re->read( \$input );
    1;
  };
  if ($@) {
    $@ =~ s{Marpa::R2\s+exception\s+at.*$}{}xs;
    $self->error($@);
    return;
  }
  elsif ( !$worked ) {
    $self->error("Unable to parse.");
    return;
  }
  my $parse = $re->value;
  my $result;

  if ($parse) {
    $result = [$$parse];
  }
  else {
    $result = [ bless [] => 'Dallycot::AST::Expr' ];
  }

  # my @warnings = map {
  #   $_ -> check_for_common_mistakes
  # } @$result;
  #
  # if(@warnings) {
  #   $self -> warnings(\@warnings);
  # }

  $self->wants_more( $re->exhausted );

  return $result;
}

#--------------------------------------------------------------------

sub copy_arg0 {
  my ( undef, $arg0 ) = @_;
  return $arg0;
}

sub block {
  my ( undef, @statements ) = @_;

  if ( @statements > 1 ) {
    return Dallycot::AST::Sequence->new(@statements);
  }
  else {
    return $statements[0];
  }
}

sub ns_def {
  my ( undef, $ns, $href ) = @_;

  $ns =~ s{^(xml)?ns:}{}x;

  if(blessed($href) && $href -> isa('Dallycot::Value::URI')) {
    $href = Dallycot::Value::String->new($href -> value -> as_string);
  }

  return bless [ $ns, $href ] => 'Dallycot::AST::XmlnsDef';
}

sub add_uses {
  my ( undef, $ns ) = @_;

  return bless [$ns] => 'Dallycot::AST::Uses';
}

sub lambda {
  my ( undef, $expression, $arity ) = @_;

  $arity //= 1;

  return bless [
    $expression,

    (   $arity == 0 ? []
      : $arity == 1 ? ['#']
      :               [ map { '#' . $_ } 1 .. $arity ]
    ),
    [],
    {}
  ] => 'Dallycot::AST::Lambda';
}

sub negate {
  my ( undef, $expression ) = @_;

  given ( blessed $expression) {
    when ('Dallycot::AST::Negation') {
      return $expression->[0];
    }
    default {
      return bless [$expression] => 'Dallycot::AST::Negation';
    }
  }
}

sub invert {
  my ( undef, $expression ) = @_;

  given ( blessed $expression) {
    when ('Dallycot::AST::Invert') {
      return $expression->[0];
    }
    default {
      return bless [$expression] => 'Dallycot::AST::Invert';
    }
  }
}

sub build_sum_product {
  my ( undef, $sum_class, $negation_class, $left_value, $right_value ) = @_;

  my @expressions;

  # combine left/right as appropriate into a single sum
  given ( blessed $left_value ) {
    when ($sum_class) {
      @expressions = @{$left_value};
      given ( blessed $right_value ) {
        when ($sum_class) {
          push @expressions, @{$right_value};
        }
        default {
          push @expressions, $right_value;
        }
      }
    }
    default {
      given ( blessed $right_value ) {
        when ($sum_class) {
          @expressions = ( $left_value, @{$right_value} );
        }
        default {
          @expressions = ( $left_value, $right_value );
        }
      }
    }
  }

  # now go through an consolidate sums and differences
  my ( @differences, @sums );

  foreach my $expr (@expressions) {
    given ( blessed $expr ) {
      when ($sum_class) {
        foreach my $sub_expr ( @{$expr} ) {
          given ( blessed $sub_expr ) {
            when ($negation_class) {    # adding -(...)
              given ( blessed $sub_expr->[0] ) {
                when ($sum_class) {     # adding -(a+b+...)
                  push @differences, @{ $sub_expr->[0] };
                }
                default {
                  push @sums, $sub_expr;
                }
              }
            }
            default {
              push @sums, $sub_expr;
            }
          }
        }
      }
      when ($negation_class) {
        given ( blessed $expr->[0] ) {
          when ($sum_class) {
            foreach my $sub_expr ( @{ $expr->[0] } ) {
              given ( blessed $sub_expr ) {
                when ($negation_class) {
                  push @sums, $sub_expr->[0];
                }
                default {
                  push @differences, $sub_expr->[0];
                }
              }
            }
          }
          when ($negation_class) {
            push @sums, $expr->[0];
          }
          default {
            push @differences, $expr->[0];
          }
        }
      }
      default {
        push @sums, $expr;
      }
    }
  }

  given ( scalar(@differences) ) {
    when (0) { }
    when (1) {
      push @sums, bless [ $differences[0] ] => $negation_class
    }
    default {
      push @sums, bless [ bless [@differences] => $sum_class ] => $negation_class;
    }
  }

  return bless \@sums => $sum_class;
}

sub product {
  my ( undef, $left_value, $right_value ) = @_;

  return build_sum_product( undef, 'Dallycot::AST::Product',
    'Dallycot::AST::Reciprocal', $left_value, $right_value );
}

sub divide {
  my ( undef, $numerator, $dividend ) = @_;

  return product( undef, $numerator, ( bless [$dividend] => 'Dallycot::AST::Reciprocal' ) );
}

sub modulus {
  my ( undef, $expr, $mod ) = @_;

  given ( blessed $expr) {
    when ('Dallycot::AST::Modulus') {
      push @{$expr}, $mod;
      return $expr;
    }
    default {
      return bless [ $expr, $mod ] => 'Dallycot::AST::Modulus';
    }
  }
}

sub sum {
  my ( undef, $left_value, $right_value ) = @_;

  return build_sum_product( undef, 'Dallycot::AST::Sum',
    'Dallycot::AST::Negation', $left_value, $right_value );
}

sub subtract {
  my ( undef, $left_value, $right_value ) = @_;

  return sum( undef, $left_value, bless [$right_value] => 'Dallycot::AST::Negation' );
}

my %ops = qw(
  <  Dallycot::AST::StrictlyIncreasing
  <= Dallycot::AST::Increasing
  =  Dallycot::AST::Equality
  <> Dallycot::AST::Unique
  >= Dallycot::AST::Decreasing
  >  Dallycot::AST::StrictlyDecreasing
);

sub inequality {
  my ( undef, $left_value, $op, $right_value ) = @_;

  if ( ref $left_value eq $ops{$op} && ref $right_value eq ref $left_value ) {
    push @{$left_value}, @{$right_value};
    return $left_value;
  }
  elsif ( ref $left_value eq $ops{$op} ) {
    push @{$left_value}, $right_value;
    return $left_value;
  }
  elsif ( ref $right_value eq $ops{$op} ) {
    unshift @{$right_value}, $left_value;
    return $right_value;
  }
  else {
    return bless [ $left_value, $right_value ] => $ops{$op};
  }
}

sub all {
  my ( undef, $left_value, $right_value ) = @_;

  if ( ref $left_value eq 'Dallycot::AST::All' ) {
    push @{$left_value}, $right_value;
    return $left_value;
  }
  else {
    return bless [ $left_value, $right_value ] => 'Dallycot::AST::All';
  }
}

sub any {
  my ( undef, $left_value, $right_value ) = @_;

  if ( ref $left_value eq 'Dallycot::AST::Any' ) {
    push @{$left_value}, $right_value;
    return $left_value;
  }
  else {
    return bless [ $left_value, $right_value ] => 'Dallycot::AST::Any';
  }
}

sub stream {
  my ( undef, $expressions ) = @_;

  return bless $expressions => 'Dallycot::AST::BuildList';
}

sub empty_stream {
  return bless [] => 'Dallycot::AST::BuildList';
}

sub compose {
  my ( undef, @functions ) = @_;

  return
    bless [ map { ( blessed $_ eq 'Dallycot::AST::Compose' ) ? @{$_} : $_ } @functions ] =>
    'Dallycot::AST::Compose';
}

sub compose_map {
  my ( undef, $left_term, $right_term ) = @_;

  if ( $right_term->isa('Dallycot::AST::BuildMap') ) {
    if ( $left_term->isa('Dallycot::AST::BuildMap') ) {
      push @$left_term, @$right_term;
      return $left_term;
    }
    else {
      unshift @$right_term, $left_term;
      return $right_term;
    }
  }
  else {
    return bless [ $left_term, $right_term ] => 'Dallycot::AST::BuildMap';
  }
}

sub compose_filter {
  my ( undef, @functions ) = @_;

  return bless [@functions] => 'Dallycot::AST::BuildFilter';
}

sub build_string_vector {
  my ( undef, $lit ) = @_;

  my $lang = 'en';

  if ( $lit =~ s{\@([a-z][a-z](_[A-Z][A-Z])?)$}{}x ) {
    $lang = $1;
  }

  $lit =~ s/^<<//;
  $lit =~ s/>>$//;
  my @matches = map { unbackslash($_) }
    map { unbackslash_spaces($_) }
    split( m{(?<!\\)\s+}x, $lit );

  return
    bless [ map { bless [ $_, $lang ] => 'Dallycot::Value::String'; } @matches ] =>
    'Dallycot::Value::Vector';
}

sub unbackslash_spaces {
  my ($text) = @_;
  $text =~ s/\\ / /g;
  return $text;
}

sub integer_literal {
  my ( undef, $lit ) = @_;

  return bless [ Math::BigRat->new($lit) ] => 'Dallycot::Value::Numeric';
}

sub rational_literal {
  my ( undef, $num, $den ) = @_;

  return bless [
    do {
      my $rat = Math::BigRat->new( Math::BigInt->new($num), Math::BigInt->new($den) );
      $rat->bnorm();
      $rat;
      }
  ] => 'Dallycot::Value::Numeric';
}

sub float_literal {
  my ( undef, $lit ) = @_;
  return bless [ Math::BigRat->new($lit) ] => 'Dallycot::Value::Numeric';
}

sub string_literal {
  my ( undef, $lit ) = @_;

  my $lang = 'en';

  if ( $lit =~ s{\@([a-z][a-z](_[A-Z][A-Z])?)$}{}x ) {
    $lang = $1;
  }

  $lit = unbackslash( unquote($lit) );

  return bless [ $lit, $lang ] => 'Dallycot::Value::String';
}

sub bool_literal {
  my ( undef, $val ) = @_;

  return Dallycot::Value::Boolean->new( $val eq 'true' );
}

sub uri_literal {
  my ( undef, $lit ) = @_;
  return Dallycot::Value::URI -> new(
    substr( $lit, 1, length($lit) - 2 )
  );
}

sub duration_literal {
  my ( undef, $lit ) = @_;

  $lit =~ /^P(\d+Y)?(\d+M)?(\d+D)?(T(\d+H)?(\d+M)?(\d+S)?)?$/;
  my(%args);
  @args{qw(years months days hours minutes seconds)} = map {
    s/[^1-9]//g; $_
  } map {
    defined($_) ? "$_" : 0
  } $1, $2, $3, $5, $6, $7;

  return Dallycot::Value::Duration->new(%args);
}

sub uri_expression {
  my ( undef, $expression ) = @_;

  return bless [$expression] => 'Dallycot::AST::BuildURI';
}

sub undef_literal {
  return bless [] => 'Dallycot::Value::Undefined';
}

sub combine_identifiers_options {
  my ( undef, $bindings, $options ) = @_;

  $bindings //= [];
  $options  //= [];

  if ( 'HASH' eq ref $bindings ) {
    return +{
      bindings               => $bindings->{'bindings'},
      bindings_with_defaults => $bindings->{'bindings_with_defaults'},
      options                => { map {@$_} @$options }
    };
  }
  else {
    return +{
      bindings               => $bindings,
      bindings_with_defaults => [],
      options                => { map {@$_} @$options }
    };
  }
}

sub relay_options {
  my ( undef, $options ) = @_;
  return +{
    bindings => [],
    options  => { map {@$_} @$options }
  };
}

sub fetch {
  my ( undef, $ident ) = @_;

  if($ident =~ /^P(\d+Y)?(\d+M)?(\d+D)?(T(\d+H)?(\d+M)?(\d+S)?)?$/) {
    my(%args);
    @args{qw(years months days hours minutes seconds)} = map {
      s/[^1-9]//g; $_
    } map {
      defined($_) ? "$_" : 0
    } $1, $2, $3, $5, $6, $7;

    return Dallycot::Value::Duration->new(%args);
  }

  my @bits = split( /:/, $ident );

  return bless \@bits => 'Dallycot::AST::Fetch';
}

sub assign {
  my ( undef, $ident, $expression ) = @_;

  if($ident =~ /^(xml)?ns:/) {
    if($expression -> isa('Dallycot::Value::String') || $expression -> isa('Dallycot::Value::URI')) {
      return ns_def(undef, $ident, $expression);
    }
  }

  return bless [ $ident, $expression ] => 'Dallycot::AST::Assign';
}

sub apply {
  my ( undef, $function, $bindings ) = @_;

  return bless [ $function, $bindings->{bindings}, $bindings->{options} ] => 'Dallycot::AST::Apply';
}

sub apply_sans_params {
  my ( undef, $function ) = @_;

  return bless [ $function, [], {} ] => 'Dallycot::AST::Apply';
}

sub list {
  my ( undef, @things ) = @_;

  return \@things;
}

sub head {
  my ( undef, $expression ) = @_;

  return bless [$expression] => 'Dallycot::AST::Head';
}

sub tail {
  my ( undef, $expression ) = @_;

  return bless [$expression] => 'Dallycot::AST::Tail';
}

sub cons {
  my ( undef, $scalar, $stream ) = @_;

  if ( ref $stream eq 'Dallycot::AST::Cons' ) {
    push @{$stream}, $scalar;
    return $stream;
  }
  elsif ( ref $scalar eq 'Dallycot::AST::Cons' ) {
    unshift @{$scalar}, $stream;
    return $scalar;
  }
  else {
    return bless [ $stream, $scalar ] => 'Dallycot::AST::Cons';
  }
}

sub list_cons {
  my ( undef, $first_stream, $second_stream ) = @_;

  if( ref $first_stream eq 'Dallycot::AST::ListCons' ) {
    if( ref $second_stream eq 'Dallycot::AST::ListCons' ) {
      push @$first_stream, @$second_stream;
    }
    else {
      push @$first_stream, $second_stream;
    }
    return $first_stream;
  }
  elsif( ref $second_stream eq 'Dallycot::AST::ListCons' ) {
    unshift @$second_stream, $first_stream;
    return $second_stream;
  }
  else {
    return bless [ $first_stream, $second_stream ] => 'Dallycot::AST::ListCons';
  }
}

sub stream_vectors {
  my ( undef, @vectors ) = @_;

  return bless [@vectors] => 'Dallycot::AST::ConsVectors';
}

sub lambda_definition_sans_args {
  my ( undef, $expression ) = @_;

  return lambda_definition(
    undef,
    { bindings               => [],
      bindings_with_defaults => []
    },
    $expression
  );
}

sub function_definition_sans_args {
  my ( undef, $identifier, $expression ) = @_;

  return function_definition(
    undef,
    $identifier,
    { bindings               => [],
      bindings_with_defaults => []
    },
    $expression
  );
}

sub function_definition {
  my ( undef, $identifier, $args, $expression ) = @_;

  if ( ref $args ) {
    return bless [ $identifier,
      bless [ $expression, $args->{bindings}, $args->{bindings_with_defaults}, $args->{options} ] =>
        'Dallycot::AST::Lambda' ] => 'Dallycot::AST::Assign';
  }
  else {
    return bless [
      $identifier,
      bless [
        $expression,
        [ (   $args == 0 ? []
            : $args == 1 ? ['#']
            :              [ map { '#' . $_ } 1 .. $args ]
          ),
          []
        ],
        {}
      ] => 'Dallycot::AST::Lambda'
    ] => 'Dallycot::AST::Assign';
  }
}

sub lambda_definition {
  my ( undef, $args, $expression ) = @_;

  if ( ref $args ) {
    return
      bless [ $expression, $args->{bindings}, $args->{bindings_with_defaults}, $args->{options} ] =>
      'Dallycot::AST::Lambda';
  }
  else {
    return bless [
      $expression,
      [ (   $args == 0 ? []
          : $args == 1 ? ['#']
          :              [ map { '#' . $_ } 1 .. $args ]
        ),
        []
      ],
      {}
    ] => 'Dallycot::AST::Lambda';
  }
}

sub option {
  my ( undef, $identifier, $default ) = @_;

  return [ $identifier, $default ];
}

sub combine_parameters {
  my ( undef, $identifiers, $identifiers_with_defaults ) = @_;

  return +{
    bindings               => $identifiers,
    bindings_with_defaults => $identifiers_with_defaults
  };
}

sub parameters_only {
  my ( undef, $bindings ) = @_;

  return +{
    bindings               => $bindings,
    bindings_with_defaults => []
  };
}

sub parameters_with_defaults_only {
  my ( undef, $bindings ) = @_;
  return +{
    bindings               => [],
    bindings_with_defaults => $bindings
  };
}

sub placeholder {
  return bless [] => 'Dallycot::AST::Placeholder';
}

sub append_remainder_placeholder {
  my ( undef, $bindings ) = @_;
  push @{$bindings}, bless [] => 'Dallycot::AST::FullPlaceholder';
  return $bindings;
}

sub condition_list {
  my ( undef, $conditions, $otherwise ) = @_;

  return
    bless [ @$conditions, ( defined($otherwise) ? ( [ undef, $otherwise ] ) : () ) ] =>
    'Dallycot::AST::Condition';
}

sub condition {
  my ( undef, $guard, $expression ) = @_;

  return [ $guard, $expression ];
}

sub json_object {
  my ( undef, $prop_list ) = @_;

  # my @props = map {
  #   _convert_to_json_array($_)
  # } @$prop_list;
  my @props = @$prop_list;
  return bless \@props => 'Dallycot::AST::JSONObject';
}

# sub _convert_to_json_array {
#   my($ast) = @_;
#
#   if($ast -> isa('Dallycot::AST::Assign') && $ast->[1]->isa('Dallycot::AST::BuildList')) {
#     bless $ast->[1] => 'Dallycot::AST::JSONArray';
#   }
#   return $ast;
# }

sub json_prop_list {
  my( undef, @props ) = @_;

  return \@props;
}

sub json_prop {
  my( undef, $string, $value ) = @_;

  if(blessed($value) && $value->isa('Dallycot::AST::BuildList')) {
    $value = bless $value => 'Dallycot::AST::JSONArray';
  }

  return bless [ $string, $value ] => 'Dallycot::AST::JSONProperty';
}

sub json_prop_name {
  my( undef, $string ) = @_;

  return substr($string, 1, length($string)-2);
}

sub json_array {
  my( undef, $values ) = @_;

  $values //= [];

  return bless $values => 'Dallycot::AST::JSONArray';
}

sub prop_request {
  my ( undef, $node, $req ) = @_;

  if ( ref $node eq 'Dallycot::AST::PropWalk' ) {
    push @{$node}, $req;
    return $node;
  }
  else {
    return bless [ $node, $req ] => 'Dallycot::AST::PropWalk';
  }
}

sub forward_prop_request {
  my ( undef, $expression ) = @_;

  return bless [$expression] => 'Dallycot::AST::ForwardWalk';
}

sub reverse_prop_request {
  my ( undef, $expression ) = @_;

  return bless [$expression] => 'Dallycot::AST::ReverseWalk';
}

# implied object is the enclosing node definition
sub left_prop {
  my ( undef, $prop, $subject ) = @_;

  return bless [ $subject, $prop, undef ] => 'Dallycot::AST::Property';
}

# implied subject is the enclosing node definition
sub right_prop {
  my ( undef, $prop, $object ) = @_;

  return bless [ undef, $prop, $object ] => 'Dallycot::AST::Property';
}

sub build_node {
  my ( undef, $expressions ) = @_;

  return bless [@$expressions] => 'Dallycot::AST::BuildNode';
}

sub prop_literal {
  my ( undef, $lit ) = @_;

  return bless [ split( /:/, $lit ) ] => 'Dallycot::AST::PropertyLit';
}

sub prop_alternatives {
  my ( undef, $left_value, $right_value ) = @_;

  if ( ref $left_value eq 'Dallycot::AST::AnyProperty' ) {
    push @{$left_value}, $right_value;
    return $left_value;
  }
  else {
    return bless [ $left_value, $right_value ] => 'Dallycot::AST::AnyProperty';
  }
}

sub prop_closure {
  my ( undef, $prop ) = @_;

  return bless [$prop] => 'Dallycot::AST::PropertyClosure';
}

sub build_vector {
  my ( undef, $expressions ) = @_;

  return bless $expressions => 'Dallycot::AST::BuildVector';
}

sub empty_vector {
  return bless [] => 'Dallycot::Value::Vector';
}

sub vector_constant {
  my ( undef, $constants ) = @_;

  return bless $constants => 'Dallycot::Value::Vector';
}

sub empty_set {
  return bless [] => 'Dallycot::Value::Set';
}

sub build_set {
  my ( undef, $expressions ) = @_;

  my @expressions = map { flatten_union($_) } @$expressions;

  return bless \@expressions => 'Dallycot::AST::BuildSet';
}

sub flatten_union {
  my ($thing) = @_;

  if ( $thing->isa('Dallycot::AST::Union') ) {
    return @$thing;
  }
  else {
    return $thing;
  }
}

sub stream_constant {
  my ( undef, $constants ) = @_;

  if (@$constants) {
    my $result = bless [ pop @$constants, undef ] => 'Dallycot::Value::Stream';
    while (@$constants) {
      $result = bless [ pop @$constants, $result ] => 'Dallycot::Value::Stream';
    }
    return $result;
  }
  else {
    return bless [] => 'Dallycot::Value::EmptyStream';
  }
}

sub _flatten_binary {
  my ( undef, $class, $left_value, $right_value ) = @_;

  if ( ref $left_value eq $class ) {
    if ( $right_value eq $class ) {
      push @{$left_value}, @{$right_value};
      return $left_value;
    }
    else {
      push @{$left_value}, $right_value;
      return $left_value;
    }
  }
  elsif ( ref $right_value eq $class ) {
    unshift @$right_value, $left_value;
    return $right_value;
  }
  else {
    return bless [ $left_value, $right_value ] => $class;
  }
}

sub zip {
  my ( undef, $left_value, $right_value ) = @_;

  return _flatten_binary( undef, 'Dallycot::AST::Zip', $left_value, $right_value );
}

sub set_union {
  my ( undef, $left_value, $right_value ) = @_;

  return _flatten_binary( undef, 'Dallycot::AST::Union', $left_value, $right_value );
}

sub set_intersection {
  my ( undef, $left_value, $right_value ) = @_;

  return _flatten_binary( undef, 'Dallycot::AST::Intersection', $left_value, $right_value );
}

sub vector_index {
  my ( undef, $vector, $index ) = @_;

  if ( ref $vector eq 'Dallycot::AST::Index' ) {
    push @{$vector}, $index;
    return $vector;
  }
  else {
    return bless [ $vector, $index ] => 'Dallycot::AST::Index';
  }
}

sub vector_push {
  my ( undef, $vector, $scalar ) = @_;

  if ( $vector->[0] eq 'Push' ) {
    push @{$vector}, $scalar;
    return $vector;
  }
  else {
    return [ Push => ( $vector, $scalar ) ];
  }
}

sub defined_q {
  my ( undef, $expression ) = @_;

  return bless [$expression] => 'Dallycot::AST::Defined';
}

##
# Eventually, Range will be a type representing all values between
# two endpoints.
#
# Q: how to indicate open/closed endpoints
#
# ( e1 .. e2 )
# [ e1 .. e2 )
# ( e1 .. e2 ]
# [ e1 .. e2 ]
#
sub semi_range {
  my ( undef, $expression ) = @_;

  return bless [ $expression, undef ] => 'Dallycot::AST::BuildRange';
}

sub closed_range {
  my ( undef, $left_value, $right_value ) = @_;

  return bless [ $left_value, $right_value ] => 'Dallycot::AST::BuildRange';
}

sub stream_reduction {
  my ( undef, $start, $function, $stream ) = @_;

  return Dallycot::AST::Apply->new(
    Dallycot::Value::URI->new('http://www.dallycot.net/ns/core/1.0#last'),
    [ Dallycot::AST::Apply->new(
        Dallycot::Value::URI->new('http://www.dallycot.net/ns/core/1.0#foldl'),
        [ $start, $function, $stream ], {}
      )
    ],
    {}
  );
}

sub stream_reduction1 {
  my ( undef, $function, $stream ) = @_;

  return Dallycot::AST::Apply->new(
    Dallycot::Value::URI->new('http://www.dallycot.net/ns/core/1.0#last'),
    [ Dallycot::AST::Apply->new(
        Dallycot::Value::URI->new('http://www.dallycot.net/ns/core/1.0#foldl1'), [ $function, $stream ],
        {}
      )
    ],
    {}
  );
}

sub promote_value {
  my ( undef, $expression, $type ) = @_;

  if ( ref $expression eq 'Dallycot::AST::TypePromotion' ) {
    push @{$expression}, $type;
    return $expression;
  }
  else {
    return bless [ $expression, $type ] => 'Dallycot::AST::TypePromotion';
  }
}

sub resolve_uri {
  my ( undef, $expression ) = @_;

  return bless [$expression] => 'Dallycot::AST::Resolve';
}

1;

__DATA__

:start ::= Block

Block ::= Statement+ separator => STMT_SEP action => block

Statement ::= NSDef
            | Uses action => add_uses
            | FuncDef
            | Expression

TypeSpec ::= TypeName
           | TypeSpec PIPE TypeName

TypeName ::= Name
           | QCName


ExpressionList ::= Expression+ separator => COMMA action => list

SetExpressionList ::= Expression+ separator => PIPE action => list

DiscreteBindings ::= Binding* separator => COMMA action => list

Bindings ::= DiscreteBindings
           | DiscreteBindings (COMMA) (TRIPLE_UNDERSCORE) action => append_remainder_placeholder

Binding ::= Expression
          | (UNDERSCORE) action => placeholder

ConstantValue ::=
      Integer action => integer_literal
    | Integer (DIV) Integer action => rational_literal
    | Float action => float_literal
    | String action => string_literal
    | Boolean action => bool_literal
    | (COLON) Identifier action => prop_literal
    | (COLON) QCName action => prop_literal
    | ConstantStream action => stream_constant
    | ConstantVector action => vector_constant

ConstantStream ::= (LB) ConstantValues (RB)
                 | (LB) (RB)

ConstantVector ::= (LT) ConstantValues (GT)
                 | (LT) (GT)

ConstantValues ::= ConstantValue+ separator => COMMA action => list

Expression ::=
      Integer action => integer_literal
    | Float action => float_literal
    | String action => string_literal
    | Boolean action => bool_literal
    | Duration action => duration_literal
    | Identifier action => fetch
    | QCName action => fetch
    | JSONObject
    | LambdaArg action => fetch
    | Node
    | Lambda
    | (LP) (RP) action => undef_literal
    | Expression (LB) Expression (RB) action => vector_index
    | ConditionList
    | (LP) Block (RP) assoc => group
    | (LB) ExpressionList (RB) assoc => group action => stream
    | (LB) (RB) action => empty_stream
    | StringVector action => build_string_vector
    | (LT) ExpressionList (GT) action => build_vector
    | (LT) (GT) action => empty_vector
    | ('<>') action => empty_vector
    | (SET_START) SetExpressionList (SET_END) assoc => group action => build_set
    | (SET_START) (SET_END) action => empty_set
    | ('<||>') action => empty_set
   || Apply
   || Expression QUOTE assoc => left action => head
    | Expression DOT_DOT_DOT assoc => left action => tail
    | Expression ('^^') TypeSpec action => promote_value
   || Expression PropRequest assoc => left action => prop_request
   || ('?') Expression assoc => right action => defined_q
    | (MINUS) Expression assoc => right action => negate
    | (TILDE) Expression assoc => right action => invert
    | Expression (DOT_DOT) Expression action => closed_range
    | Expression (DOT_DOT) action => semi_range
   || Expression (Z) Expression action => zip assoc => right
   || Expression (MAP) Expression action => compose_map assoc => right
    | Expression (FILTER) Expression action => compose_filter assoc => right
   || Expression ('<<') Expression ('<<') Expression action => stream_reduction
   || Expression ('<<') Expression action => stream_reduction1 assoc => right
   || Expression (DOT) Expression action => compose
   || Expression (STAR) Expression action => product
    | Expression (DIV) Expression action => divide
   || Expression (MOD) Expression action => modulus assoc => right
   || Expression (PLUS) Expression action => sum
    | Expression (MINUS) Expression action => subtract
   || Expression (PIPE) Expression action => set_union
   || Expression (AMP) Expression action => set_intersection
   || Expression (COLON_COLON_GT) Expression action => cons assoc => right
   || Expression (LT_COLON_COLON) Expression action => vector_push assoc => left
   || Expression (COLON_COLON_COLON) Expression action => list_cons assoc => right
   || Expression Inequality Expression action => inequality
   || Expression (AND) Expression action => all
   || Expression (OR) Expression action => any
   || Identifier (COLON_EQUAL) Expression action => assign assoc => right
    | Identifier (LP) FunctionParameters (RP) (COLON_GT) Expression action => function_definition assoc => right
    | Identifier (LP) (RP) (COLON_GT) Expression action => function_definition_sans_args assoc => right
    | Identifier (SLASH) PositiveInteger (COLON_GT) Expression action => function_definition assoc => right

Duration ~ duration

Node ::=
      NodeDef
    | Graph (MOD) UriLit action => modulus
    | UriLit
    | ('<(') Expression (')>') action => uri_expression

Graph ::= NodeDef
        | NodeDef (COLON_COLON_GT) Graph action => cons assoc => right
        | (LC) (RC) action => build_node

NodeDef ::= (LC) NodePropList (RC) action => build_node
          | (STAR) UriLit action => resolve_uri

NodePropList ::= NodeProp+ action => list

JSONObject ::= (LC) JSONPropertyList (RC) action => json_object

JSONPropertyList ::= JSONProperty+ separator => COMMA action => json_prop_list

JSONProperty ::= JSONString (COLON) JSONValue action => json_prop
               | NSDef
               | FuncDef
               | Assign

JSONValue ::= JSONObject
            | JSONArray
            | Expression

JSONArray ::= (LB) JSONValues (RB) action => json_array
            | (LB) (RB) action => json_array

JSONValues ::= JSONValue+ separator => COMMA action => list

JSONString ::= jsonstring action => json_prop_name

NodeProp ::= PropIdentifier (RIGHT_ARROW) Expression action => right_prop
           | PropIdentifier (LEFT_ARROW) Expression action => left_prop

PropRequest ::= (RIGHT_ARROW) PropPattern action => forward_prop_request
              | (LEFT_ARROW) PropPattern action => reverse_prop_request

PropPattern ::= PropIdentifier
              | (STAR) PropPattern action => prop_closure
              | PropPattern (PIPE) PropPattern action => prop_alternatives
              | (LP) PropPattern (RP) assoc => group

PropIdentifier ::= (COLON) Identifier action => prop_literal
                 | ATIdentifier action => prop_literal
                 | (COLON) QCName action => prop_literal
                 | Expression

Fetched ::=
      Identifier action => fetch
    | LambdaArg action => fetch
    | QCName action => fetch

Lambda ::=
      (LC) Block (RC) action => lambda
    | (LC) Block (RC) (SLASH) NonNegativeInteger action => lambda
    | (LP) FunctionParameters (RP) (COLON_GT) Expression action => lambda_definition
    | (LP) (RP) (COLON_GT) Expression action => lambda_definition_sans_args

Apply ::= (LP) Expression (RP) (LP) FunctionArguments (RP) action => apply
       | Fetched (LP) FunctionArguments (RP) action => apply
       | Apply (LP) FunctionArguments (RP) action => apply

NSDef ::= NSName (COLON_EQUAL) StringLit action => ns_def
        | NSName (COLON_EQUAL) UriLit action => ns_def

Uses  ::= ('uses') StringLit
        | ('uses') UriLit

StringLit ::= String action => string_literal

ConditionList ::= (LP) Conditions (RP) action => condition_list
                | (LP) Conditions Otherwise (RP) action => condition_list

Conditions ::= Condition+ action => list

Condition ::= (LP) Expression (RP) (COLON) Expression action => condition

Otherwise ::= (LP) (RP) (COLON) Expression

Assign ::= Identifier (COLON_EQUAL) Expression action => assign
         | ControlWord (COLON_EQUAL) Expression action => assign

FuncDef ::= Identifier (LP) FunctionParameters (RP) (COLON_GT) Expression action => function_definition
          | Identifier (LP) (RP) (COLON_GT) Expression action => function_definition_sans_args
          | Identifier (SLASH) PositiveInteger (COLON_GT) Expression action => function_definition

FunctionParameters ::= IdentifiersWithPossibleDefaults action => combine_identifiers_options
          | OptionDefinitions action => relay_options
          | IdentifiersWithPossibleDefaults (COMMA) OptionDefinitions action => combine_identifiers_options

IdentifiersWithPossibleDefaults ::= IdentifiersWithGlob action => parameters_only
          | IdentifiersWithDefaults action => parameters_with_defaults_only
          | Identifiers (COMMA) IdentifiersWithDefaults action => combine_parameters

IdentifiersWithDefaults ::= IdentifierWithDefault+ separator => COMMA action => list

IdentifierWithDefault ::= Identifier (EQUAL) ConstantValue action => option

OptionDefinitions ::= OptionDefinition+ separator => COMMA action => list

OptionDefinition ::= Identifier (RIGHT_ARROW) ConstantValue action => option

FunctionArguments ::= Bindings action => combine_identifiers_options
          | Options action => relay_options
          | Bindings (COMMA) Options action => combine_identifiers_options

Options ::= Option+ separator => COMMA action => list

Option ::= Identifier (RIGHT_ARROW) Expression action => option

UriLit ::= Uri action => uri_literal

# String ::= StringLit action => string_literal

Boolean ~ boolean

Inequality ~ inequality

ATIdentifier ~ '@' identifier

Identifier ~ identifier | identifier '?' | qcname

StarIdentifier ~ '*' identifier

Identifiers ::= Identifier+ separator => COMMA action => list

IdentifiersWithGlob ::= Identifiers (COMMA) StarIdentifier
                      | Identifiers

ControlWord ~ controlWord

NSName ~ 'xmlns:' identifier | 'ns:' identifier

Name ~ identifier

QCName ~ qcname

Integer ~ integer

Float ~ float

PositiveInteger ~ positiveInteger

NonNegativeInteger ~ zero | positiveInteger

String ~ qqstring

StringVector ~ stringVector

Uri ~ uri

LambdaArg ~ HASH | HASH positiveInteger

AMP ~ '&'
AND ~ 'and'
COLON ~ ':'
#COLON_COLON ~ '::'
COLON_COLON_GT ~ '::>'
COLON_COLON_COLON ~ ':::'
COLON_EQUAL ~ ':='
COLON_GT ~ ':>'
COMMA ~ ','
DIV ~ 'div'
DOT ~ '.'
DOT_DOT ~ '..'
DOT_DOT_DOT ~ '...'
DQUOTE ~ '"'
EQUAL ~ '='
FILTER ~ '%'
HASH ~ '#'
GT ~ '>'
GT_GT ~ '>>'
LB ~ '['
LC ~ '{'
SET_START ~ '<|'
LEFT_ARROW ~ '<-'
LP ~ '('
LP_STAR ~ '(*'
LT ~ '<'
LT_COLON_COLON ~ '<::'
LT_LT ~ '<<'
MAP ~ '@'
MINUS ~ '-'
MOD ~ 'mod'
OR ~ 'or'
PIPE ~ '|'
PLUS ~ '+'
QUOTE ~ [']
# '
RB ~ ']'
RC ~ '}'
SET_END ~ '|>'
RIGHT_ARROW ~ '->'
RP ~ ')'
SLASH ~ '/'
STAR ~ '*'
STAR_RP ~ '*)'
TILDE ~ '~'
UNDERSCORE ~ '_'
TRIPLE_UNDERSCORE ~ '___'
Z ~ 'Z'

STMT_SEP ~ ';'

<any char> ~ [\d\D\n\r]

boolean ~ 'true' | 'false'

digits ~ [_\d] | digits [_\d]

controlWord ~ '@' <identifier bit>

inequality ~ '<' | '<=' | '=' | '<>' | '>=' | '>'

integer ~ negativeInteger | zero | positiveInteger

negativeInteger ~ '-' positiveInteger

nonZeroDigit ~ '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'

positiveInteger ~ nonZeroDigit | nonZeroDigit digits | 'inf'

float ~ negativeFloat | zero '.' zero | positiveFloat

negativeFloat ~ '-' positiveFloat

<positiveFloat integer part> ~ nonZeroDigit | nonZeroDigit digits

<positiveFloat fractional part> ~ digits

<positiveFloat exponent> ~ [eE] [-+] <integer>

positiveFloatSansExponent ~ <positiveFloat integer part> '.' zero
                          | <positiveFloat integer part> '.' <positiveFloat fractional part>
                          | zero '.' <positiveFloat fractional part>

positiveFloat ~ positiveFloatSansExponent
              | positiveFloatSansExponent <positiveFloat exponent>
              | <positiveFloat integer part> <positiveFloat exponent>

duration ~ 'P' calendarDuration
         | 'P' calendarDuration 'T' clockDuration
         | 'P' 'T' clockDuration

calendarDuration ~ yearDuration monthlyDuration
                 | monthlyDuration

monthlyDuration ~ monthDuration dayDuration
                | dayDuration

yearDuration ~ zero 'Y'
             | positiveInteger 'Y'

monthDuration ~ zero 'M'
              | positiveInteger 'M'

dayDuration ~ zero 'D'
            | positiveInteger 'D'

clockDuration ~ hourDuration minutelyDuration
              | minutelyDuration

minutelyDuration ~ minuteDuration secondDuration
                 | secondDuration

hourDuration ~ zero 'H'
             | positiveInteger 'H'

minuteDuration ~ zero 'M'
               | positiveInteger 'M'

secondDuration ~ zero 'S'
               | positiveFloatSansExponent 'S'

identifier ~ <identifier bit> | identifier '-' <identifier bit>

<identifier bit> ~ [\w]+

qcname ~ identifier ':' identifier

# TODO: add @"lang" to end of string
#
qqstring ~ <qqstring value> | <qqstring value> '@' <qqstring lang>

jsonstring ~ <qqstring value>

<qqstring value> ~ DQUOTE qqstringContent DQUOTE | DQUOTE DQUOTE

qqstringChar ~ [^\"] | '\' <any char>
#"

<qqstring lang> ~ [a-z][a-z] | [a-z][a-z] '_' [A-Z][A-Z]

qqstringContent ~ qqstringChar | qqstringContent qqstringChar

stringVector ~ <stringVector value> | <stringVector value> '@' <qqstring lang>

<stringVector value> ~ LT_LT stringVectorContent GT_GT | LT_LT GT_GT

stringVectorContent ~ stringVectorChar | stringVectorContent stringVectorChar

stringVectorChar ~ [^>] | '>' [^>] | '\' <any char>
#'

uri ~ '<' uriScheme '://' uriAuthority '/' uriPath '>'
    | '<' uriScheme '://' uriAuthority '/' '>'
    | '<' uriScheme '://' uriAuthority '>'
    | '<' identifier ':' uriPath '>'

uriScheme ~ [a-z] | uriScheme [-a-z0-9+.]

uriAuthority ~ uriHostname | uriHostname ':' positiveInteger

uriPath ~ [^\s]+

uriHostname ~ <uriHostname bit> '.' <uriHostname bit> | uriHostname '.' <uriHostname bit>

<uriHostname bit> ~ [-a-z0-9]+

zero ~ '0'

:discard ~ whitespace
whitespace ~ [\s]+
# allow comments
:discard ~ <comment>
<comment> ~ LP_STAR <comment body> STAR_RP
<comment body> ~ <comment char>*
#<statement sep char> ~ [;\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}\n\r]
<comment char> ~ [^*)] | '*' [^)] | [^*] ')'
