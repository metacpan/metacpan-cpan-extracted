package CatalystX::QueryModel;

our $VERSION = '0.009';

use Class::Method::Modifiers;
use Scalar::Util;
use Moo::_Utils;
use Module::Pluggable::Object;
use Module::Runtime ();
use CatalystX::RequestModel::Utils::InvalidContentType;

require Moo::Role;
require Sub::Util;

our @DEFAULT_ROLES = (qw(CatalystX::QueryModel::DoesQueryModel));
our @DEFAULT_EXPORTS = (qw(property properties namespace content_type));
our %Meta_Data = ();

sub default_roles { return @DEFAULT_ROLES }
sub default_exports { return @DEFAULT_EXPORTS }
sub request_model_metadata { return %Meta_Data }
sub request_model_metadata_for { return $Meta_Data{shift} }

sub import {
  my $class = shift;
  my $target = caller;

  unless (Moo::Role->is_role($target)) {
    my $orig = $target->can('with');
    Moo::_Utils::_install_tracked($target, 'with', sub {
      unless ($target->can('request_metadata')) {
        $Meta_Data{$target}{'request'} = \my @data;
        my $method = Sub::Util::set_subname "${target}::request_metadata" => sub { @data };
        no strict 'refs';
        *{"${target}::request_metadata"} = $method;
      }
      &$orig;
    });
  } 

  foreach my $default_role ($class->default_roles) {
    next if Role::Tiny::does_role($target, $default_role);
    Moo::Role->apply_roles_to_package($target, $default_role);
    foreach my $export ($class->default_exports) {
      Moo::_Utils::_install_tracked($target, "__${export}_for_exporter", \&{"${target}::${export}"});
    }
  }

  my %cb = map {
    $_ => $target->can("__${_}_for_exporter");
  } $class->default_exports;

  foreach my $exported_method (keys %cb) {
    my $sub = sub {
      if(Scalar::Util::blessed($_[0])) {
        return $cb{$exported_method}->(@_);
      } else {
        return $cb{$exported_method}->($target, @_);
      }
    };
    Moo::_Utils::_install_tracked($target, $exported_method, $sub);
  }

  Class::Method::Modifiers::install_modifier $target, 'around', 'has', sub {
    my $orig = shift;
    my ($attr, %opts) = @_;

    my $predicate;
    unless($opts{required}) {
      if(exists $opts{predicate}) {
        $predicate = $opts{predicate};
      } else {
        $predicate = "__cx_q_model_has_${attr}";
        $opts{predicate} = $predicate;
      }
    }

    if(my $info = delete $opts{property}) {
      $info = +{ name=>$attr } unless (ref($info)||'') eq 'HASH';
      $info->{attr_predicate} = $predicate if defined($predicate);
      $info->{omit_empty} = 1 unless exists($info->{omit_empty});
      my $method = \&{"${target}::property"};
      $method->($attr, $info, \%opts);
    }

    return $orig->($attr, %opts);
  } if $target->can('has');
} 

sub _add_metadata {
  my ($target, $type, @add) = @_;
  my $store = $Meta_Data{$target}{$type} ||= do {
    my @data;
    if (Moo::Role->is_role($target) or $target->can("${type}_metadata")) {
      $target->can('around')->("${type}_metadata", sub {
        my ($orig, $self) = (shift, shift);
        ($self->$orig(@_), @data);
      });
    } else {
      require Sub::Util;
      my $method = Sub::Util::set_subname "${target}::${type}_metadata" => sub { @data };
      no strict 'refs';
      *{"${target}::${type}_metadata"} = $method;
    }
    \@data;
  };

  push @$store, @add;
  return;
}

1;

=head1 NAME

CatalystX::QueryModel - Inflate Models from a Request Content Body or from URL Query Parameters

=head1 SYNOPSIS

An example Catalyst Request Model:

    package Example::Model::PagingQuery;

    use Moose;
    use CatalystX::QueryModel;

    extends 'Catalyst::Model';

    namespace 'user';

    has status => (is=>'ro', property=>1); 
    has page => (is=>'ro', property=>1); 

    __PACKAGE__->meta->make_immutable();

Using it in a controller:

    package Example::Controller::User;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub root :Chained(/root) PathPart('user') CaptureArgs(0)  { }

    sub list :GET Chained('root') PathPart('') Args(0) Does(QueryModel) QueryModel(PagingQuery) {
      my ($self, $c, $query_model) = @_;
    }

    __PACKAGE__->meta->make_immutable;

Now if the incoming GET looks like this:

    [debug] Query Parameters are:
    .-------------------------------------+--------------------------------------.
    | Parameter                           | Value                                |
    +-------------------------------------+--------------------------------------+
    | user.page                           | 2                                    |
    | user.status                         | active                               |
    '-------------------------------------+--------------------------------------'

The object instance C<$query_model> would look like:

    say $query_model->page;       # 2
    say $query_model->status;     # 'active'

And C<$query_model> has additional helper public methods to query attributes marked as request
fields (via the C<property> attribute field) which you can read about below.

=head1 DESCRIPTION

This is very similiar to <CatalystX::RequestModel> but for query parameters that are part of the request
URL.  Basically we are mapping the query params hash to a object which makes it more robust to access 
and gives you a place to do any sort of query parameter logic.  Can neaten up your controllers and give
you more reusable code.

=head2 Query options

When you include "use CatalystX::QueryModel" we apply the role L<CatalystX::QueryModel::DoesQueryModel>
to you model, which gives you some useful methods as well as the ability to store the meta data needed
to properly mapped parsed query parameters to your model.  You also get some imported subroutines and a
new field on your attribute declarations:

C<namespace>: This is an optional imported subroutine which allows you to declare the namespace under which
we expect to find the attribute mappings.  This can be useful if your fields are not top level in your
request content body (as in the example given above).  This is optional and if you leave it off we just
assume all fields are in the top level of the parsed data hash that you content parser builds based on whatever
is in the content body.

If you declare a namespace in a query model by default we don't throw an error if the namespace is missing
(unlike in request models) because I think for query parameters this is the common case where the query
is not required (for example in a paged list screen when you default to page 1 when a page is not given).
If you want the namespace required you can declare it so like this

    namespace paging => (required=>1);

C<content_type>: This is the request content type which this model is designed to handle.  For now you can
only declare one content type per model (if your endpoint can handle more than one content type you'll need
for now to define a request model for each one; I'm open to changing this to allow one than one content type
per request model, but I need to see your use cases for this before I paint myself into a corner codewise).

This is also an optional check for query parameters.

C<property>: This is a new field allowed on your attribute declarations.  Setting its value to C<1> (as in 
the example above) just means to use all the default settings for the declared content_type but you can declare
this as a hashref instead if you have special handling needs.  For example:

    has notes => (is=>'ro', property=>+{ expand=>'JSON' });

Here's the current list of property settings and what they do.  You can also request the test cases for more
examples:

=over 4

=item name

The name of the field in the request body we are mapping to the request model.  The default is to just use
the name of the attribute.

=item omit_empty

Defaults to true. If there's no matching field in the request body we leave the request model attribute
empty (we don't stick an undef in there).  If for some reason you don't want that, setting this to false
will put an undef into a scalar fields, and an empty array into an indexed one.   If has no effect on
attributes that map to a submodel since I have no idea what that should be (your use cases welcomed).

=item flatten

If the value associated with a field is an array, flatten it to a single value.  The default is based on
the body content parser.   Its really a hack to deal with HTML form POST and Query parameters since the
way those formats work you can't be sure if a value is flat or an array. This isn't a problem with
JSON encoded request bodies.  You'll need to check the docs for the Content Body Parser you are using to
see what this does.   

=item always_array

Similar to C<flatten> but opposite, it forces a value into an array even if there's just one value.  Again
mostly useful to deal with ideosyncracies of HTML form post.

B<NOTE>: The attribute property settings C<flatten> and C<always_array> are currently exclusive (only one of
the two will apply if you supply both.  The C<always_array> property always takes precedence.  At some point
in the future supplying both might generate an exception so its best not to do that.  I'm only leaving it
allowed for now since I'm not sure there's a use case for both.

=item boolean

Defaults to false. If true will convert value to the common Perl convention 0 is false, 1 is true.  The way
this is converted is partly dependent on your content body parser.

=item expand

Example the value into a data structure by parsing it.   Right now there's only one value this will take,
which is C<JSON> and will then parse the value into a structure using a JSON parser.   Again this is mostly
useful for HTML form posting and coping with some limitations you have in classic HTML form input types.

=back

=head2 Setting a required attribute

Generally it's best to not mark attributes which map to request properties as required and to handled anything
like thia via your validation layer so that you can provide more useful feedback to your application users.
If you do need to mark something required in order for your request model to be valid, please note that we
capture the exception created by Moo/se and throw L<CatalystX::RequestModel::Utils::BadRequest>.  If you are
using L<CatalystX::Errors> this will get rendered as a HTTP 400 Bad Request; otherwise you just get the 
generic L<Catalyst> HTTP 500 Server Error or as you might have written in your custom error handling code.

=head2 Nested and Indexed attributes

These work the same as in L<CatalystX::RequestModel>

=head1 METHODS

Please see L<CatalystX::QueryModel::DoesQueryModel> for the public API details.

=head1 EXCEPTIONS

This class can throw the following exceptions.  Please note all exceptions are compatible with
L<CatalystX::Errors> to make it easy and consistent to convert errors to actual error responses.

=head2 Bad Request

If your request generates an exception when trying to instantiate your model (basically when calling ->new
on it) we capture that error, log the error and throw a L<CatalystX::RequestModel::Utils::BadRequest>

=head2 Invalid Request Content Type

If the incoming content body doesn't have a content type header that matches one of the available
content body parsers then we throw an L<CatalystX::RequestModel::Utils::InvalidContentType>.  This
will get interpretated as an HTTP 415 status client error if you are using L<CatalystX::Errors>.

=head1 AUTHOR

    John Napiorkowski <jjnapiork@cpan.org>

=head1 COPYRIGHT
 
    2022

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
 
=cut

