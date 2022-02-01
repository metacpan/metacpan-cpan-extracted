package Catalyst::TraitFor::Request::StructuredParameters;

our $VERSION = '0.008';

use Moose::Role;
use Catalyst::Utils::StructuredParameters;

# Yeah there's copy pasta here just right now I'm not sure we won't need more 
# customization so I'm just going to leave it.

sub structured_body {
  my ($self, @args) = @_;
  my $strong = Catalyst::Utils::StructuredParameters->new(
    src => 'body',
    flatten_array_value => 1,
    context => $self->body_parameters||+{}
  );
  $strong->permitted(@args) if @args;
  return $strong;
}

sub structured_query {
  my ($self, @args) = @_;
  my $strong = Catalyst::Utils::StructuredParameters->new(
    src => 'query',
    flatten_array_value => 1,
    context => $self->query_parameters||+{}
  );
  $strong->permitted(@args) if @args;
  return $strong;
}

sub structured_data {
  my ($self, @args) = @_;
  my $strong = Catalyst::Utils::StructuredParameters->new(
    src => 'data',
    flatten_array_value => 0,
    context => $self->body_data||+{}
  );
  $strong->permitted(@args) if @args;
  return $strong;
}

1;

=head1 NAME

Catalyst::TraitFor::Request::StructuredParameters - Enforce structural rules on your body and data parameters

=head1 SYNOPSIS

For L<Catalyst> v5.90090+
 
    package MyApp;
 
    use Catalyst;
 
    MyApp->request_class_traits(['Catalyst::TraitFor::Request::StructuredParameters']);
    MyApp->setup;
 
For L<Catalyst> older than v5.90090
 
    package MyApp;
 
    use Catalyst;
    use CatalystX::RoleApplicator;
 
    MyApp->apply_request_class_roles('Catalyst::TraitFor::Request::StructuredParameters');
    MyApp->setup;
 
In a controller:

    package MyApp::Controller::User;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub user :Local {
      my ($self, $c) = @_;

      # Basically this is like a whitelist for the allowed parameters.  This is not a replacement
      # for form validation but rather prior layer to make sure the incoming is semantically
      # acceptable.  It also does some sanity cleanup like flatten unexpected arrays.  The following
      # would accept body parameters like the following:
      #
      # $c->req->body_parameters == +{
      #   username => 'jnap',
      #   password => 'youllneverguess',
      #   password_confirmation => 'youllneverguess'
      #   'name.first' => 'John',
      #   'name.last' => 'Napiorkowski',
      #   'email[0]' => 'jjn1056@example1.com',
      #   'email[1]' => 'jjn1056@example2.com',
      # }

      my %body_parameters = $c->req->structured_body
        ->permitted('username', 'password', 'password_confirmation', name => ['first', 'last'], +{email=>[]} )
        ->to_hash;

      # %body_parameters then looks like this, which is a form suitable for validating and creating
      # or updating a database.
      #
      # %body_parameters == (
      #   username => 'jnap',
      #   password => 'youllneverguess',
      #   password_confirmation => 'youllneverguess'
      #   name => +{
      #     first => 'John',
      #     last => 'Napiorkowski',
      #   },
      #   email => ['jjn1056@example1.com', 'jjn1056@example2.com'],
      # );

      # Ok so now you know %body_parameters are 'well-formed', you can use them to do stuff like
      # value validation and updating a databases, etc.

      my $new_user = $c->model('Schema::User')->validate_and_create(\%body_parameters);
    }

=head1 DESCRIPTION

This replaces L<Catalyst::TraitFor::Request::StrongParameters>.   If you were using that you should switch
to this.   This is right now just a name change but any bug fixes will happen here.   Sooner or later I'll
remove L<Catalyst::TraitFor::Request::StrongParameters> from the indexes.

WARNING: This is a quick midnight hack and the code could have sharp edges.   Happy to take broken
test cases.

When your web application receives incoming POST body or data you should treat that data with suspicion.
Even prior to validation you need to make sure the incoming structure is well formed (this is most
important when you have deeply nested structures, which can be a major security risk both in parsing
and in using that data to do things like update a database). L<Catalyst::TraitFor::Request::StructuredParameters>
offers a structured approach to whitelisting your incoming POSTed data, as well as a safe way to introduce
nested data structures into your classic HTML Form posted data.  It is also compatible for POSTed data
(such as JSON POSTed data) although in the case of body data such as JSON we merely whitelist the fields
and structure since JSON can already support nested data structures.

This is similar to a concept called 'strong parameters' in Rails although my implementation is somewhat
different based on the varying needs of the L<Catalyst> framework.   However I consider this beta code
and subject to change should real life use cases arise that indicate a different approach is warranted.

=head1 METHODS

This role defines the following methods:

=head2 structured_body

Returns an instance of L<Catalyst::Utils::StructuredParameters> preconfigured with the current contents
of ->body_parameters. Any arguments are passed to that instances L</permitted> methods before return.

=head2 structured_query

Parses the URI query string; otherwise same as L</structured_body>.

=head2 structured_data

The same as L</structured_body> except aimed at body data such as JSON post.   Basically works
the same except the default for handling array values is to leave them alone rather than to flatten.

=head1 PARAMETER OBJECT METHODS

The instance of L<Catalyst::Utils::StructuredParameters> which is returned by any of the three builder
methods above (L</structured_body>, L</structured_query and L</structured_data>) supports the following methods.

=head2 namespace (\@fields)

Sets the current 'namespace' to start looking for fields and values.  Useful when all the fields are
under a key.  For example if the value of ->body_parameters is:

    +{
        'person.name' => 'John',
        'person.age' => 52,
    }

If you set the namespace to C<['person']> then you can create rule specifications that assume to be
'under' that key.  See the L</SYNOPSIS> for an example.

=head2 permitted (?\@namespace, @rules)

An array of rule specifications that are used to filter the current parameters as passed by the user
and present a sanitized version that can safely be used in your code. 

If the first argument is an arrayref, that value is used to set the starting L</namespace>.

=head2 required (?\@namespace, @rules)

An array of rule specifications that are used to filter the current parameters as passed by the user
and present a sanitized version that can safely be used in your code. 

If user submitted parameters do not match the spec an exception is throw (L<Catalyst::Exception::MissingParameter>
If you want to use required parameters then you should add code to catch this error and handle it
(see below for more)

If the first argument is an arrayref, that value is used to set the starting L</namespace>.

=head2 flatten_array_value ($bool)

Switch to indicated if you want to flatten any arrayref values to 'pick last'.   This is true by default
for body and query parameters since its a common hack around quirks with certain types of HTML form controls
(like checkboxes) which don't return a value when not selected or checked.

=head2 max_array_depth (number)

Prevent incoming parameters from having too many items in an array value.  Default is 1,000.  You may wish
to set a different value based on your requirements.  Throws L<Catalyst::Exception::InvalidArrayLength> if violated.

=head2 to_hash

Returns the currently filtered parameters based on the current permitted and/or required specifications. 

=head2 keys

Returns an unorderd list of all the top level keys

=head2 get (@key_names)

Given a list of key names, return values.   Doesn't currently do anything if you use a key name that
doesn't exist (you just get 'undef').

=head1 CHAINING

All the public methods for L<Catalyst::Utils::StructuredParameters> return the current instance so that
you can chain methods easily (except for L</to_hash>).   If you chain L</permitted> and L</required>
the accepted hashrefs are merged.

=head1 RULE SPECIFICATIONS

L<Catalyst::TraitFor::Request::StructuredParameters> offers a concise DSL for describing permitted and required
parameters, including flat parameters, hashes, arrays and any combination thereof.

Given body_parameters of the following:

    +{
      'person.name' => 'John', 
      'person.age' => '52',
      'person.address.street' => '15604 Harry Lind Road',
      'person.address.zip' => '78621',
      'person.email[0]' => 'jjn1056@gmail.com',
      'person.email[1]' => 'jjn1056@yahoo.com',
      'person.credit_cards[0].number' => '245345345345345',
      'person.credit_cards[0].exp' => '2024-01-01',
      'person.credit_cards[1].number' => '666677777888878',
      'person.credit_cards[1].exp' => '2024-01-01',
      'person.credit_cards[].number' => '444444433333',
      'person.credit_cards[].exp' => '4024-01-01',
    }

    my %data = $c->req->strong_body
      ->namespace(['person'])
      ->permitted('name','age');

    # %data = ( name => 'John', age => 53 );
    
    my %data = $c->req->structured_body
      ->namespace(['person'])
      ->permitted('name','age', address => ['street', 'zip']); # arrayref means the following are subkeys

    # %data = (
    #   name => 'John', 
    #   age => 53, 
    #   address => +{
    #     street => '15604 Harry Lind Road',
    #     zip '78621',
    #   }
    # );

    my %data = $c->req->structured_body
      ->namespace(['person'])
      ->permitted('name','age', +{email => []} );  # wrapping in a hashref mean 'under this is an arrayref

    # %data = (
    #   name => 'John', 
    #   age => 53,
    #   email => ['jjn1056@gmail.com', 'jjn1056@yahoo.com']
    # );
    
    # Combine hashref and arrayref to indicate array of subkeyu
    my %data = $c->req->structured_body
      ->namespace(['person'])
      ->permitted('name','age', +{credit_cards => [qw/number exp/]} ); 

    # %data = (
    #   name => 'John', 
    #   age => 53,
    #   credit_cards => [
    #     {
    #       number => "245345345345345",
    #       exp => "2024-01-01",
    #     },
    #     {
    #       number => "666677777888878",
    #       exp => "2024-01-01",
    #     },
    #     {
    #       number => "444444433333",
    #       exp => "4024-01-01",
    #     },
    #   ]
    # );

You can specify more than one specification for the same key.  For example if body
parameters are:

    +{
      'person.credit_cards[0].number' => '245345345345345',
      'person.credit_cards[0].exp' => '2024-01-01',
      'person.credit_cards[1].number' => '666677777888878',
      'person.credit_cards[1].exp.year' => '2024',
      'person.credit_cards[1].exp.month' => '01',
    }

    my %data = $c->req->structured_body
      ->namespace(['person'])
      ->permitted(+{credit_cards => ['number', 'exp', exp=>[qw/year month/] ]} ); 

    # %data = (
    #   credit_cards => [
    #     {
    #       number => "245345345345345",
    #       exp => "2024-01-01",
    #     },
    #     {
    #       number => "666677777888878",
    #       exp => +{
    #         year => '2024',
    #         month => '01'
    #       },
    #     },
    #   ]
    # );


=head2 ARRAY DATA AND ARRAY VALUE FLATTENING

Please note this only applies to L</structured_body> / L</structured_query>

In the situation when you have a array value for a given namespace specification such as
the following :

    'person.name' => 2,
    'person.name' => 'John', # flatten array should jsut pick the last one

We automatically pick the last POSTed value.  This can be a useful hack around some HTML form elements
that don't set an 'off' value (like checkboxes).

=head2 'EMPTY' FINAL INDEXES

Please note this only applies to L</structured_body> / L</structured_query>

Since the index values used to sort arrays are not preserved (they indicate order but are not used to
set the index since that could open your code to potential hackers) we permit final 'empty' indexes:

    'person.credit_cards[0].number' => '245345345345345',
    'person.credit_cards[0].exp' => '2024-01-01',
    'person.credit_cards[1].number' => '666677777888878',
    'person.credit_cards[1].exp' => '2024-01-01',
    'person.credit_cards[].number' => '444444433333',
    'person.credit_cards[].exp' => '4024-01-01',

This 'empty' index will always be considered the final element when sorting.  You may have more than
one final empty index as well when its either the last rule or the rule only contains a single index

    'person.notes[]' => 'This is a note',
    'person.notes[]' => 'This is another note',
    'person.person_roles[1].role_id' => '1',
    'person.person_roles[2].role_id' => '2',
    'person.person_roles[].role_id' => '3',
    'person.person_roles[].role_id' => '4',

Would produce:

    +{
      person => {
        notes => [
          'This is a note',
          'This is another note',
        ],
        person_roles => [
          {
            role_id => 1,
          },
          {
            role_id => 2,
          },
          {
            role_id => 3,
          },
          {
            role_id => 4,
          },
        ],
      },
    };

=head1 EXCEPTIONS

The following exceptions can be raised by these methods and you should add code to recognize and
handle them.  For example you can add a global or controller scoped 'end' action:

    sub end :Action {
      my ($self, $c) = @_;
      if(my $error = $c->last_error) {
        $c->clear_errors;
        if(blessed($error) && $error->isa('Catalyst::Exception::StructuredParameter')) {
          # Handle the error perhaps by forwarding to a view and setting a 4xx 
          # bad request response code.
        }
      }
    }

Alternatively (and probably neater) just use L<CatalystX::Error>.

    sub end :Action Does(RenderError) { }

You'll need to add the included L<Catalyst::Plugin::Errors> plugin to your application class in order
to use this ActionRole.

=head2 Exception: Base Class

L<Catalyst::Exception::StructuredParameter>

There's a number of different exceptions that this trait can throw but they all inherit from
L<Catalyst::Exception::StructuredParameter> so you can just check for that since those are all going
to be considered 'Bad Request' type issues.  This also inherits from L<CatalystX::Utils::HttpException>
so you can use the L<CatalystX::Errors> package to neaten up / regularize your error control.

=head2 EXCEPTION: MISSING PARAMETER

L<Catalyst::Exception::MissingParameter> ISA L<Catalyst::Exception::StructuredParameter>

If you use L</required> and a parameter is not present you will raise this exception, which will
contain a message indicating the first found missing parameter.  For example:

    "Required parameter 'username' is missing."

This will not be an exhaustive list of the missing parameters and this feature in not intended to
be used as a sort of form validation system.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst>, L<Catalyst::Request>

=head1 COPYRIGHT & LICENSE
 
Copyright 20121, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
