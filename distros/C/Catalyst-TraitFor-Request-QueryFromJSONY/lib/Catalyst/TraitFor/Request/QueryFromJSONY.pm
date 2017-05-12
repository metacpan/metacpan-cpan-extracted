package Catalyst::TraitFor::Request::QueryFromJSONY;

use Moo::Role;
use JSONY;

our $VERSION = '0.002';

has query_data_options => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'build_query_data_options');

  sub build_query_data_options {
    return +{
      param_missing => sub { my ($req, $param) = @_; return '{}' },
      parse_error => sub { my ($req, $param, $err) = @_; die $err },
    };
  }

has _jsony => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'build_jsony');

  sub build_jsony { JSONY->new }

has _query_data_cache => (
  is=>'ro',
  required=>1, 
  init_arg=>undef,
  lazy=>1,
  default=>sub { +{} });

sub query_data {
  my ($self, @params) = @_;
  my $proto = +{};

  $proto = pop @params if (@params && ref($params[-1]) eq 'HASH');
  @params = ('q') unless @params;

  my %local_options = (%{$self->query_data_options}, %$proto);

  return map {
    my $val = exists $self->query_parameters->{$_} ?
      $self->query_parameters->{$_} :
      $local_options{param_missing}->($self, $_);

    my $deserialized = eval { $self->_jsony->load($val) } 
      || $local_options{parse_error}->($self, $val, $@);

    $self->_query_data_cache->{$_} ||= $deserialized;
    } @params;
}

1;

=head1 NAME

Catalyst::TraitFor::Request::QueryFromJSONY - Handle complex query parameters using JSONY

=head1 SYNOPSIS

For L<Catalyst> v5.90090+

    package MyApp;

    use Catalyst;

    MyApp->request_class_traits(['Catalyst::TraitFor::Request::QueryFromJSONY']);
    MyApp->setup;

For L<Catalyst> older than v5.90090

    package MyApp;

    use Catalyst;
    use CatalystX::RoleApplicator;

    MyApp->apply_request_class_roles('Catalyst::TraitFor::Request::QueryFromJSONY');
    MyApp->setup;

In a controller:

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;
    use Data::Dumper;

    sub echo :Local {
      my ($self, $c) = @_;
      $c->res->body( Dumper $c->req->query_data );
    }

Example test case:

    ok my $res = request GET "/example/echo?q={'id':100,'age':['>',10]}";
    is_deeply eval $res->content, {
      'id' => 100,
      'age' => [ '>', 10 ]
    };

=head1 DESCRIPTION

This is an early access release of this module.  Experimentation as to the best
approach is ongoing.

There are cases when you'd like to express complex data structures in your URL
query part (tha bit after the '?').  There's been a number of attempts at this,
this module is yet another. In this version we allow for a query parameter 'q'
to be a L<JSONY> serialized string (L<JSONY> is basically JSON relaxed a bit to
reduce a bit of verbosity and smooth over common errors that are more pedantic
that useful).  We deserialize this string and place its value in 'query_data'.

This only happens if you request the query_data attribute, so there's no overhead
to simply having this installed.

You can have other 'classic' query parameters mixed in with the 'q' parameter, but
for no only 'q' is deserialized.  The original value of 'q' is preserved in the
original query_parameter method.

=head1 METHODS

This role defines the following methods.

=head2 query_data (?@query_params, ?\%options)

For each item in @query_params that exists in $request->query_parameters deserialize
using L<JSONY>  and return the data references (could be a hashref, or arrayref 
depending on the query construction.

If no @query_params are submitted, assume 'q' as the default.

The %options hash allows you to set callback to handle exceptional conditions. All callbacks
get invoked with two parameters, the current $request object, and the name of the
query parameter that caused the condition.  For example the follow substitutes the string
'[]' when a $key is missing from %{$c->req->query_parameters}:

    $c->req->query_data(qw/a b c/, +{ 
      param_missing => sub {
        my ($req, $key) = @_;
        return '[]';
      }
    });

Currently we support the following exceptional conditions:

=head3 param_missing

Gets $request, $key

This is the callback that gets invoked when $c->req->query_paramerters->{$key} does not
exist.  The default behavior is to return an empty string, which JSONY deserialized into
a hashref.  This allows you to request parameters that are optional and not product an
exception.  

=head3 parse_error

Gets $request, $key, $error_message

This callback is called when JSONY throws an exception trying to parse the value
associated with $key.  The default is to just rethrow the error.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst>, L<Catalyst::Request>, L<JSONY>

=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
