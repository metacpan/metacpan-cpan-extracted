package Catalyst::ActionRole::QueryParameter;

use Moose::Role;
use Scalar::Util ();
requires 'attributes', 'match', 'match_captures';

our $VERSION = '0.08';

sub _resolve_query_attrs {
  @{shift->attributes->{QueryParam} || []};
}

has query_constraints => (
  is=>'ro',
  required=>1,
  isa=>'HashRef',
  lazy=>1,
  builder=>'_prepare_query_constraints');

  sub _prepare_query_constraints {
    my ($self) = @_;

    my @constraints;
    my $compare = sub {
      my ($op, $cond) = @_;

      if(defined $cond && length $cond && !defined $op) {
        die "You must use a newer version of Catalyst (5.90090+) if you want to use Type Constraint '$cond'"
          unless $self->can('resolve_type_constraint');
        my ($tc) = $self->resolve_type_constraint($cond);
        die "We think $cond is a type constraint, but its not" unless $tc;
        return sub { $tc->check(shift) };
      }

      if(defined $op) {
        die "No such op of $op" unless $op =~m/^(==|eq|!=|<=|>=|>|=~|<|gt|ge|lt|le)$/i;
        # we have an $op, make sure there's a comparator
        die "You can't have an operator without a target condition" unless defined($cond);
      } else {
        # No op mean the field just need to exist with a defined value
        return sub { defined(shift) };
      }

      return sub { my $v = shift; return defined($v) ? (Scalar::Util::looks_like_number($v) && ($v == $cond)) : 0 } if $op eq '==';
      return sub { my $v = shift; return defined($v) ? (Scalar::Util::looks_like_number($v) && ($v != $cond)) : 0 } if $op eq '!=';
      return sub { my $v = shift; return defined($v) ? (Scalar::Util::looks_like_number($v) && ($v <= $cond)) : 0 } if $op eq '<=';
      return sub { my $v = shift; return defined($v) ? (Scalar::Util::looks_like_number($v) && ($v >= $cond)) : 0 } if $op eq '>=';
      return sub { my $v = shift; return defined($v) ? (Scalar::Util::looks_like_number($v) && ($v > $cond)) : 0 } if $op eq '>';
      return sub { my $v = shift; return defined($v) ? (Scalar::Util::looks_like_number($v) && ($v < $cond)) : 0 } if $op eq '<';
      return sub { my $v = shift; return defined($v) ? ($v =~ $cond) : 0 } if $op eq '=~';
      return sub { my $v = shift; return defined($v) ? ($v ge $cond) : 0 } if $op eq 'ge';
      return sub { my $v = shift; return defined($v) ? ($v lt $cond) : 0 } if $op eq 'lt';
      return sub { my $v = shift; return defined($v) ? ($v le $cond) : 0 } if $op eq 'le';
      return sub { my $v = shift; return defined($v) ? ($v eq $cond) : 0 } if $op eq 'eq';

      die "your op '$op' is not allowed!";
    };

    if(my @attrs = $self->_resolve_query_attrs) {
      my %matched = map {
        my ($not, $attr_param, $op, $cond) =
            ref($_) eq 'ARRAY' ?
            ($_[0] eq '!' ? (@$_) :(0, @$_)) :
            ($_=~m/^([\?\!]?)([^\:]+)\:?(==|eq|!=|<=|>=|>|=~|<|gt|ge|lt|le)?(.*)$/);

        my $evaluator = $compare->($op, $cond);

        my $default = undef;
        if($attr_param =~m/=/) {
          ($attr_param, $default) = split('=', $attr_param);
        }

        if($default and ($not eq '?')) {
          die "Can't combine a default with an optional for action ${\$self->name}";
        }

        $attr_param => [ $not, $attr_param, $op, $cond, sub {
          my ($value, $ctx) = @_;
          if(!defined($value)) {
            $value = $default;
            $ctx->req->query_parameters->{$attr_param} = $value;
          }

          my $state = $evaluator->($value);
          return ($not eq '!') ? not($state) : $state;
        }];
      } @attrs;
      return \%matched;
    } else {
      return +{};
    }
  }

around $_, sub {
  my ($orig, $self, $ctx, @more) = @_;

  foreach my $constrained (keys %{$self->query_constraints}) {
    my ($not, $attr_param, $op, $cond, $evaluator) = @{$self->query_constraints->{$constrained}};

    my $req_value = exists($ctx->req->query_parameters->{$constrained}) ? 
      $ctx->req->query_parameters->{$constrained} : (($not eq '?') ? next : undef );

    my $is_success = $evaluator->($req_value, $ctx) ||0;

    if($ctx->debug) {
      my $display_req_value = defined($req_value) ? $req_value : 'undefined';
      $ctx->log->debug(
        sprintf "QueryParam value for action $self, param '$constrained' with value '$display_req_value' compared as: %s %s %s '%s'",
          (($not eq '!') ? 'not' : 'is'), $attr_param, ($op ? $op:''), ($cond ? $cond:''),
      );
      $ctx->log->debug("QueryParam for $self on key $constrained value $display_req_value has success of $is_success");
    }

    #If we fail once, game over;
    return 0 unless $is_success;
    
  }
  return $self->$orig($ctx, @more);
  #If we get this far, its all good
} for qw(match match_captures);

1;

=head1 NAME

Catalyst::ActionRole::QueryParameter - Dispatch rules using query parameters

=head1 SYNOPSIS

    package MyApp::Controller::Foo;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller:';

    ## Add the ActionRole to all the Controller's actions.  You can also
    ## selectively add the ActionRole with the :Does action attribute or in
    ## controller configuration.  See Catalyst::Controller::ActionRole for
    ## more information.

    __PACKAGE__->config(
      action_roles => ['QueryParameter'],
    );

    ## Match an incoming request matching "http://myhost/path?page=1"
    sub paged_results : Path('foo') QueryParam('page') { ... }

    ## Match an incoming request matching "http://myhost/path"
    sub no_paging : Path('foo') QueryParam('!page') { ... }

    ## Match a request using a type constraint

    use Types::Standard 'Int';
    sub an_int :Path('foo') QueryParam('page:Int') { ... }

    ## Match optionally (if the parameters exists it MUST pass the constraint
    ## BUT it is allowed to not exist

    use Types::Standard 'Int';
    sub an_int :Path('foo') QueryParam('?page:Int') { ... }

    ## Match with a default value if the query parameter does not exist'

    sub with_path :Path('foo') QueryParam('?page=1') { ... }


=head1 DESCRIPTION

Let's you require conditions on request query parameters (as you would access
via C<< $ctx->request->query_parameters >>) as part of your dispatch matching.
This ActionRole is not intended to be used for general HTML form and parameter
processing or validation, for that purpose there are many other options (such
as L<HTML::FormHandler>, L<Data::Manager> or L<HTML::FormFu>.)  What it can be
useful for is when you want to delegate work to various Actions inside your
Controller based on what the incoming query parameters say.

Generally speaking, it is not great development practice to abuse query
parameters this way.  However I find there is a limited and controlled subset
of use cases where this feature is valuable.  As a result, the features of this
ActionRole are  also limited to simple defined or undefined checking, and basic
Perl relational operators.

You can specify multiple C<QueryParam>s per Action.  If you do have more than
one we will try to match Actions that match ALL the given C<QueryParam>
attributes.

There's a functioning L<Catalyst> example application in the test directory for
your review as well.

=head1 QUERY PARAMETER CONDITION MATCHING

The value of the C<QueryParam> attribute allows for condition matching  based
on query parameter definedness and via Perl relational operators.  For example,
you can match for a particular value or if a given value is greater than another.
This can be useful when you want to perform a different Action when (for
example) your user is on page 10 of a search, which might indicate they are not
finding what they want and could use some additional help.  I also sometimes
find that I want special handling of the first page of a search result.

Although you can handle this with conditional logic inside your Action, I find
the ability to declare what I want from an Action to be one of the more valuable
aspects of L<Catalyst>.

Here are some example C<QueryParam> attributes and the queries they match:

    QueryParam('page')  ## 'page' must exist
    QueryParam('page=1') ## 'page' defaults to 1
    QueryParam('!page')  ## 'page' must NOT exist
    QueryParam('?page')  ## 'page' may optionally exist
    QueryParam('page:==1')  ## 'page' must equal numeric one
    QueryParam('page:>1')  ## 'page' must be great than one
    QueryParam('!page:>1')  ## 'page' must NOT be great than one
    QueryParam(page:Int) ## 'page' matches an Int constraint (see below)
    QueryParam('?page:Int')  ## 'page' may optionally exist, but if it does must be an Int

Since as I mentioned, it is generally not awesome web development practice to
make excessive use of query parameters for mapping your action logic, I have
limited the condition matching to basic Perl operators.  The general pattern
is as follows:

    ([!?]?)($parameter):?($condition?)

Which can be roughly translated as "A $parameter should match the $condition
but we can tack a "!" to the front of the expression to reverse the match.  If
you don't specify a $condition, the default condition is definedness."

Please note your $parameter my define a simple default value using the '='
operator.  This means your actual query parameter may not have a '=' in it.
Patches to fix welcomed (it would probably be easy to provide some sort of escaping
indicator).  Default may be combined with conditions, but you can't combine a
defualt AND an optional '?' indicator (will cause an error).

A C<$condition> is basically a Perl relational operator followed by a value.
Relation Operators we current support: C<< ==,eq,>,<,!=,<=,>=,gt,ge,lt,le >>.
In addition, we support the regular expression match operator C<=~>. For
documentation on Perl Relational Operators see: C<perldoc perlop>.  For 
documentation on Perl Regular Expressions see C<perldoc perlre>.

A C<$condition> may also be a L<Moose::Types> or similar type constraint.  See
below for more.

B<NOTE> For numeric comparisions we first check that the value 'looks_like_number'
via L<Scalar::Util> before doing the comparison.  If it doesn't look like a
number that is automatic fail.

B<NOTE> The ? optional indicator is probably most useful when combined with a condition
or/and a default.

=head1 USING TYPE CONSTRAINTS

To provide more flexibility and reuse in your parameter constraints, you may
use types constraints as your constraint condition if you are using a recent
build of L<Catalyst> (at least version 5.90090 or greater).  This allows you to
use an imported type constraint, such as you might get from L<MooseX::Types> 
or from L<Type::Tiny> or L<Types::Standard>.  For example:

    package MyApp::Controller::Root;

    use base 'Catalyst::Controller';
    use Types::Standard 'Int';

    sub root :Chained(/) PathPart('') CaptureArgs(0) { }

      sub int :Chained(root) Args(0) QueryParam(page:Int) {
        my ($self, $c) = @_;
        $c->res->body('order');
      }

    MyApp::Controller::Root->config(
      action_roles => ['QueryParameter'],
    );

This would require a URL with a 'page' query that is an Integer, for example,
"https://localhost/int/100".

This feature uses the type constraint resolution features built into the
new versions of L<Catalyst> so it behaves the same way.

=head1 USING CATALYST CONFIGURATION INSTEAD OF ATTRIBUTES

You may prefer to set your Query Parameter requirements via the L<Catalyst>
general application configuration, rather than in subroutine attributes.  Doing
so allows you to use different settings in different environments and it also
allows you to use more extended values.  Here's an example comparing both
approaches

    ## subroutine attribute approach
    sub first_page : Path('foo') QueryParam('page:==1') { ... }

    ## configuration approach
    __PACKAGE__->config(
      action => {
        first_page => { Path => 'foo', QueryParam => 'page:==1'},
      },
    );

Since the configuration approach allows richer use of Perl, you can replace the
string version of the QueryParam value with the following:

    ## configuration approach, richer Perl data structure
    __PACKAGE__->config(
      action => {
        first_page => { Path => 'foo', QueryParam => [['page','==','1']] },
        no_page_query => { Path => 'foo', QueryParam => [['!','page']] },
      },
    );

If you are using the configuration approach, this second option is preferred.
Please note that since each attribute or configuration key can have an array
of values, if you use the 'rich Perl data structure' approach in your
configuration you will need to place the arrayref inside an arrayref as in the
example above (that is not a typo!)

=head1 NOTE REGARDING CATALYST DISPATCH RESOLUTION

This document has been superceded by a new core documentation document.  Please
see L<Catalyst::RouteMatching>.

=head1 LIMITATIONS

Currently this only works for 'single' query parameters.  For example:

    ?foo=1&bar=2

Not:

    ?foo=1&foo=2

Patches welcomed!

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Controller::ActionRole>, L<Moose>.

=head1 COPYRIGHT & LICENSE

Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
