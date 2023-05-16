package CatalystX::RequestModel;

our $VERSION = '0.017';

use Class::Method::Modifiers;
use Scalar::Util;
use Moo::_Utils;
use Module::Pluggable::Object;
use Module::Runtime ();
use CatalystX::RequestModel::Utils::InvalidContentType;

require Moo::Role;
require Sub::Util;

our @DEFAULT_ROLES = (qw(CatalystX::RequestModel::DoesRequestModel));
our @DEFAULT_EXPORTS = (qw(property properties namespace content_type content_in));
our %Meta_Data = ();
our %ContentBodyParsers = ();

sub default_roles { return @DEFAULT_ROLES }
sub default_exports { return @DEFAULT_EXPORTS }
sub request_model_metadata { return %Meta_Data }
sub request_model_metadata_for { return $Meta_Data{shift} }
sub content_body_parsers { return %ContentBodyParsers }

sub content_body_parser_for {
  my $ct = shift;
  return $ContentBodyParsers{$ct} || CatalystX::RequestModel::Utils::InvalidContentType->throw(ct=>$ct);
}

sub load_content_body_parsers {
  my $class = shift;
  my @packages = Module::Pluggable::Object->new(
      search_path => "${class}::ContentBodyParser"
    )->plugins;

  %ContentBodyParsers = map {
    $_->content_type => $_;
  } map {
    Module::Runtime::use_module $_;
  } @packages;
}

sub import {
  my $class = shift;
  my $target = caller;

  $class->load_content_body_parsers;

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
        $predicate = "__cx_req_model_has_${attr}";
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

CatalystX::RequestModel - Inflate Models from a Request Content Body or from URL Query Parameters

=head1 SYNOPSIS

An example Catalyst Request Model:

    package Example::Model::RegistrationRequest;

    use Moose;
    use CatalystX::RequestModel;

    extends 'Catalyst::Model';

    namespace 'person';
    content_type 'application/x-www-form-urlencoded';

    has username => (is=>'ro', property=>1);   
    has first_name => (is=>'ro', property=>1);
    has last_name => (is=>'ro', property=>1);
    has password => (is=>'ro', property=>1);
    has password_confirmation => (is=>'ro', property=>1);

    __PACKAGE__->meta->make_immutable();

Using it in a controller:

    package Example::Controller::Register;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub root :Chained(/root) PathPart('register') CaptureArgs(0)  { }

    sub update :POST Chained('root') PathPart('') Args(0) Does(RequestModel) BodyModel(RegistrationRequest) {
      my ($self, $c, $request_model) = @_;
      ## Do something with the $request_model (instance of 'Example::Model::RegistrationRequest').
    }

    sub list :GET Chained('root') PathPart('') Args(0) Does(RequestModel) QueryModel(PagingModel) {
      my ($self, $c, $paging_model) = @_;
    }


    __PACKAGE__->meta->make_immutable;

Now if the incoming POST /update looks like this:

    .-------------------------------------+--------------------------------------.
    | Parameter                           | Value                                |
    +-------------------------------------+--------------------------------------+
    | person.username                     | jjn                                  |
    | person.first_name [multiple]        | 2, John                              |
    | person.last_name                    | Napiorkowski                         |
    | person.password                     | abc123                               |
    | person.password_confirmation        | abc123                               |
    '-------------------------------------+--------------------------------------'

The object instance C<$request_model> would look like:

    say $request_model->username;       # jjn
    say $request_model->first_name;     # John
    say $request_model->last_name;      # Napiorkowski

And if the incoming is GET /list looks like

    [debug] Query Parameters are:
    .-------------------------------------+--------------------------------------.
    | Parameter                           | Value                                |
    +-------------------------------------+--------------------------------------+
    | page                                | 2                                    |
    | status                              | active                               |
    '-------------------------------------+--------------------------------------'

The object instance C<$paging_model> would look like:

    say $paging_model->page;       # 2
    say $paging_model->status;     # 'active'


And C<$request_model> has additional helper public methods to query attributes marked as request
fields (via the C<property> attribute field) which you can read about below.

See L<CatalystX::RequestModel::ContentBodyParser::JSON> for an example of using this with JSON
request content.

=head1 DESCRIPTION

Dealing with incoming POSTed (or PUTed/ PATCHed, etc) request content bodies is one of the most common
code issues we have to deal with.  L<Catalyst> has generic capacities for handling common incoming
content types such as form URL encoded (common with HTML forms) and JSON as well as the ability to
add in parsing for other types of contents (see L<Catalyst#DATA-HANDLERS>).   However these parsers
only check that a given body content is well formed and not that it's valid for your given problem
domain.  Additionally I find that we spend a lot of code lines in controllers that are doing nothing
but munging and trying to wack incoming parameters into a form that can be actually used.

I've seen this approach of mapping incoming content bodies to models put to good use in frameworks
in other languages.  Mapping to a model gives you a clear place to do any data reformating you
need as well as the type of pre validation work we often perform in a controller.  Think of it as a
type of command class pattern subtype.  It promotes looser binding between your controller and your
applications models, and it makes for neater, smaller controllers as well as separating out the
types of work we do into smaller, more comprehendible classes.   Lastly we encapsulate some of the
more common types of issues into configuration (for example dealing with how HTML form POSTed
parameters can cause you issues when they are sometimes in array form) as well as improve security
by having an explict interface to the model.

Also once we have a model that defines an expected request, we should be able to build upon the meta data
it exposed to do things like auto generate Open API / JSON Schema definition files (TBD but possible).

Basically you convert an unknown hash of values into a well defined object.  This should reduce typo
induced errors at the very least.

The main downside here is the time you need to inflate the additional classes as well as some documentation
efforts needed to help new programmers understand this approach.

If you hate this idea but still like the thought of having more structure in mapping your incoming
random parameters you might want to check out L<Catalyst::TraitFor::Request::StructuredParameters>.

B<NOTE> This is work in progress / late beta code.   What I mean by that is that I will try to maintain
the public API of this code (as described in the documentation) and only change it if absolutely 
needed to move the code forward.  However the non public code is subject to change at any time.
So if you are subclassing this and overriding non public methods you need to check carefully at each
new release, but if you are just using the code as described you just need to review the changelog
for any deprecation / breaking changes notices.

=head2 Declaring a model to accept request content bodies

To create a L<Catalyst> model that is ready to accept incoming content body data mapped to its attributes
you just need to use L<CatalystX::RequestModel>:

    package Example::Model::RegistrationRequest;

    use Moose;
    use CatalystX::RequestModel;  # <=== The important bit

    extends 'Catalyst::Model';

    namespace 'person';  # <=== Optional but useful when you have nested form data
    content_type 'application/x-www-form-urlencoded';  <=== Required so that we know which content parser to use

    has username => (is=>'ro', property=>1);   
    has first_name => (is=>'ro', property=>1);
    has last_name => (is=>'ro', property=>1);

    __PACKAGE__->meta->make_immutable();

When you include "use CatalystX::RequestModel" we apply the role L<CatalystX::RequestModel::DoesRequestModel>
to you model, which gives you some useful methods as well as the ability to store the meta data needed
to properly mapped parsed content bodies to your model.  You also get two imported subroutines and a
new field on your attribute declarations:

C<namespace>: This is an optional imported subroutine which allows you to declare the namespace under which
we expect to find the attribute mappings.  This can be useful if your fields are not top level in your
request content body (as in the example given above).  This is optional and if you leave it off we just
assume all fields are in the top level of the parsed data hash that you content parser builds based on whatever
is in the content body.

C<content_type>: This is the request content type which this model is designed to handle.  For now you can
only declare one content type per model (if your endpoint can handle more than one content type you'll need
for now to define a request model for each one; I'm open to changing this to allow one than one content type
per request model, but I need to see your use cases for this before I paint myself into a corner codewise).

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

Very often you will have incoming request data that is complex (or is trying to be, as in the case with
HTML form post where you use a serialization format to flatten a deep structure into a flat list)  In that
case your body parser will attempt to deserialize that into a deep structure.  In the case when you have
a nested structure you can indicate that via mapping an attribute to a sub Catalyst model.  For example:

    package Example::Model::AccountRequest;

    use Moose;
    use CatalystX::RequestModel;

    extends 'Catalyst::Model';
    namespace 'person';
    content_type 'application/x-www-form-urlencoded';

    has username => (is=>'ro', required=>1, property=>{ always_array=>1 });  
    has first_name => (is=>'ro', property=>1);
    has last_name => (is=>'ro', property=>1);
    has profile => (is=>'ro', property=>+{ model=>'AccountRequest::Profile' });

    __PACKAGE__->meta->make_immutable();

    package Example::Model::AccountRequest::Profile;

    use Moose;
    use CatalystX::RequestModel;

    extends 'Catalyst::Model';

    has id => (is=>'ro', property=>1);
    has address => (is=>'ro', property=>1);
    has city => (is=>'ro', property=>1);
    has state_id => (is=>'ro', property=>1);
    has zip => (is=>'ro', property=>1);
    has phone_number => (is=>'ro', property=>1);
    has birthday => (is=>'ro', property=>1);

    __PACKAGE__->meta->make_immutable();

If you had incoming body parameters like this (using the Form Content Body Parser):

    .-------------------------------------+--------------------------------------.
    | Parameter                           | Value                                |
    +-------------------------------------+--------------------------------------+
    | person.username                     | jjn                                  |
    | person.first_name                   | John                                 |
    | person.last_name                    | Napiorkowski                         |
    | person.profile.id                   | 1                                    |
    | person.profile.address              | 15604 Harry Lind Road                |
    | person.profile.city                 | Elgin                                |
    | person.profile.state_id             | 2                                    |
    | person.profile.zip                  | 78621                                |
    | person.profile.phone_number         | 16467081837                          |
    | person.profile.birthday             | 2000-01-01                           |
    '-------------------------------------+--------------------------------------'

It would parse and inflate a request model like

    my $request_model = $c->model('AccountRequest');

    $request_model->username;         # jjn
    $request_model->first_name;       # John
    $request_model->last_name;        # Napiorkowski
    $request_model->profile->address; # 15604 Harry Lind Road
    $request_model->profile->city;    # Elgin

...and so on.

If your nested models are directly under the main request model's namespace (as in the
above example) you can shorten the value of the C<model> option to include only the
affix.   For example the following:

    has profile => (is=>'ro', property=>+{ model=>'AccountRequest::Profile' });

Could be shortened to:

    has profile => (is=>'ro', property=>+{ model=>'::Profile' });

In the case when your deep structure also is an array/list you can mark that so via the
C<indexed> option of the property field as in the following example:

    package Example::Model::AccountRequest;

    use Moose;
    use CatalystX::RequestModel;

    extends 'Catalyst::Model';
    namespace 'person';
    content_type 'application/x-www-form-urlencoded';

    has username => (is=>'ro', required=>1, property=>{always_array=>1});  
    has first_name => (is=>'ro', property=>1);
    has last_name => (is=>'ro', property=>1);
    has credit_cards => (is=>'ro', property=>+{ indexed=>1, model=>'AccountRequest::CreditCard' });

    __PACKAGE__->meta->make_immutable();

    package Example::Model::AccountRequest::CreditCard;

    use Moose;
    use CatalystX::RequestModel;

    extends 'Catalyst::Model';

    has id => (is=>'ro', property=>1);
    has card_number => (is=>'ro', property=>1);
    has expiration => (is=>'ro', property=>1);

Now if your incoming request looks like this it will be parsed into a deep structure by the
correct body parser and mapped to the request object:

    .-------------------------------------+--------------------------------------.
    | Parameter                           | Value                                |
    +-------------------------------------+--------------------------------------+
    | person.username                     | jjn                                  |
    | person.first_name                   | John                                 |
    | person.last_name                    | Napiorkowski                         |
    | person.credit_cards[0].card_number  | 123123123123123                      |
    | person.credit_cards[0].expiration   | 3000-01-01                           |
    | person.credit_cards[0].id           | 1                                    |
    | person.credit_cards[1].card_number  | 4444445555556666                     |
    | person.credit_cards[1].expiration   | 4000-01-01                           |
    | person.credit_cards[1].id           | 2                           
    '-------------------------------------+--------------------------------------'

It would parse and inflate a request model like

    my $request_model = $c->model('AccountRequest');

    $request_model->username;                       # jjn
    $request_model->first_name;                     # John
    $request_model->last_name;                      # Napiorkowski
    $request_model->credit_cards->[0]->card_number; # 123123123123123
    $request_model->credit_cards->[0]->expiration;  # 3000-01-01
    $request_model->credit_cards->[1]->card_number; # 4444445555556666
    $request_model->credit_cards->[1]->expiration;  # 4000-01-01

Please note the difference between a request property that is marked as C<indexed> versus
C<always_array>.  An C<indexed> property is required to have an array value while C<always_array>
merely coerces a scalar to an array if the value isn't already an array.  You cannot use
C<indexed> and C<always_array> in the same request property.

B<NOTE> You can use the C<indexed> attribute property with simple scalar values as well as
deep structured objects.  See test cases for more.

Please see L<CatalystX::RequestModel::ContentBodyParser::JSON> for an example JSON request body
with nesting.  JSON is actually easier since we don't need a parsing convention to turn the
flat list you get with HTML Form post into a deep structure, nor deal with some of form posting's
idiocracies.

=head2 Endpoints with more than one request model

If an endpoint can handle more than one type of incoming content type you can define that
via the subroutine attribute and the code will pick the right one or throw an exception if none match
(See L</EXCEPTIONS> for more).

    sub update :POST Chained('root') PathPart('') Args(0) 
      Does(RequestModel) 
      RequestModel(RegistrationRequestForm) 
      RequestModel(RegistrationRequesJSON)
    {
      my ($self, $c, $request_model) = @_;
      ## Do something with the $request_model
    }

Also see L<Catalyst::ActionRole::RequestModel>.

=head1 QUERY PARAMETERS

See L<CatalystX::QueryModel>.

=head2 Requests with mixed query and body models

You might have a request that has both query parameters (via the URL) as well as a content body request.
In that case you make the content body request in the same way as you normally do and then add a second
request model that specifies the query parameters.  For example you might have a form post with mixed
query and body parameters.  You create your models as normal:

    package Example::Model::InfoQuery;

    use Moose;
    use CatalystX::QueryModel;

    extends 'Catalyst::Model';

    has page => (is=>'ro', required=>1, property=>1);  
    has offset => (is=>'ro', property=>1);
    has search => (is=>'ro', property=>1);

    __PACKAGE__->meta->make_immutable();

    package Example::Model::LoginRequest;

    use Moose;
    use CatalystX::RequestModel;

    extends 'Catalyst::Model';
    content_type 'application/x-www-form-urlencoded';

    has username => (is=>'ro', required=>1, property=>1);  
    has password => (is=>'ro', property=>1);

    __PACKAGE__->meta->make_immutable();

And in your action you list the request models:

    sub postinfo :Chained(/) Args(0) Does(RequestModel) RequestModel(LoginRequest) QueryModel(InfoQuery)  {
      my ($self, $c, $login_request, $info_query) = @_;
    }

Now if you get a request like this:

    [debug] Query Parameters are:
    .-------------------------------------+--------------------------------------.
    | Parameter                           | Value                                |
    +-------------------------------------+--------------------------------------+
    | offset                              | 100                                  |
    | page                                | 10                                   |
    | search                              | nope                                 |
    '-------------------------------------+--------------------------------------'
    [debug] Body Parameters are:
    .-------------------------------------+--------------------------------------.
    | Parameter                           | Value                                |
    +-------------------------------------+--------------------------------------+
    | password                            | abc123                               |
    | username                            | jjn                                  |
    '-------------------------------------+--------------------------------------'

You'll get two models like this:

    print $login_request->username;   # "jjn"
    print $login_request->password;   # "abc123"

    print $info_query->offset;        # 100
    print $info_query->page;          # 10
    print $info_query->search;        # "nope"

You can also do nesting and indexing with query params (See L<CatalystX::QueryModel::QueryParser> and
L<CatalystX::QueryModel::DoesQueryModel>)

B<IMPORTANT NOTE>: Due to a limitation in how Catalyst finds subroutine attributes on an action we cannot
determine the order of declaration of dissimilar attributes (such as BodyModel and QueryModel).  As a
result when you have both attibutes on an action we will process and add to the arguments list first the
Body Models and then the Query models, even if you list the Query model first in the method
declaration.

=head1 CONTENT BODY PARSERS

This distribution comes bundled with the following content body parsers for handling common needs.  If
you need to create you own you should subclass L<CatalystX::RequestModel::ContentBodyParser> and place
the class in the C<CatalystX::RequestModel::ContentBodyParser> namespace.

=head2 Form URL Encoded

When a model declares its content_type to be 'application/x-www-form-urlencoded' we use
L<CatalystX::RequestModel::ContentBodyParser::FormURLEncoded> to parse it.  Please see the documention
for more regarding how we parse the flat list of posted body content into a deep structure.

This handles both POST HTML form content as well as query parameters.

=head2 Multi Part Uploads

This handles content types of 'multipart/form-data'.  Uploads are mapped to attributes with a value that
is an instance of L<Catalyst::Request::Upload>.

=head2 JSON

When a model declares its content_type to be 'application/json' we use
L<CatalystX::RequestModel::ContentBodyParser::JSON> to parse it.

=head1 METHODS

Please see L<CatalystX::RequestModel::DoesRequestModel> for the public API details.

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
 
    2023

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
 
=cut

