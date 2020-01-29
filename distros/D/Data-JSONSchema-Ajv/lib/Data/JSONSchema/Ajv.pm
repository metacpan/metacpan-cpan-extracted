use strict;
use warnings;

use JavaScript::Duktape::XS;

use Data::JSONSchema::Ajv::src;
use Data::JSONSchema::Ajv::src::04;
use Data::JSONSchema::Ajv::src::06;

=head1 NAME

Data::JSONSchema::Ajv - JSON Schema Validator wrapping Ajv

=head1 VERSION

version 0.09

=head1 DESCRIPTION

JSON Schema Validator wrapping Ajv

=head1 SYNOPSIS

    use Test::More;
    use Data::JSONSchema::Ajv;

    my $ajv_options = {};
    my $my_options  = {
        draft => '04', # Defaults to '07'
    };

    my $ajv     = Data::JSONSchema::Ajv->new($ajv_options, $my_options);

    my $validator = $ajv->make_validator(
        {    # http://json-schema.org/examples.html
            title      => "Example Schema",
            type       => "object",
            properties => {
                firstName => { type => "string" },
                lastName  => { type => "string" },
                age       => {
                    description => "Age in years",
                    type        => "integer",
                    minimum     => 0
                }
            },
            required => [ "firstName", "lastName" ],
        }
    );

    my $payload = { firstName => 'Valentina', familyName => 'Tereshkova' };

    my $result = $validator->validate($payload);

    if ($result) {
        is_deeply(
            $result,
            [   {   dataPath   => "",
                    keyword    => "required",
                    message    => "should have required property 'lastName'",
                    params     => { missingProperty => "lastName" },
                    schemaPath => "#/required"
                }
            ],
            "Expected errors thrown"
        );
    } else {
        fail(
            "validate() returned a false value, which means the example " .
            "unexpectedly validated"
        );
    }

=head1 WHAT WHY

This module is an offensively light-weight wrapper
L<Ajv|https://epoberezkin.github.io/ajv/>.

Light-weight in this context just means it's not very many lines of actual Perl

=head1 METHODS

=head2 new

  my $ajv = Data::JSONSchema::Ajv->new(
      { v5 => $JSON::PP::true }, # Ajv options. Try: {},
      {}, # Module options. See below
  );

Instantiates a new L<JavaScript::Duktape::XS> environment and loads C<Ajv> into it.
Accepts two hashrefs (or undefs). The first is passed straight through to
C<Ajv>, whose options are documented L<here|https://epoberezkin.github.io/ajv/>.

The second one allows you to specify options of this module:

=over

=item ajv_src

String that contains source code of standalone version of Ajv library, which can be
found L<here|https://cdnjs.com/libraries/ajv>. This module already has some version
(possibly not last) of Ajv hardcoded inside it and will use it if this option doesn't
specified.

=item draft

A JSON Schema draft version as a string. Allowable values are C<04>, C<06>, and C<07>.
No support for multiple schemas at this time. Default is C<07>.

=back

=head2 make_validator

  my $validator = $ajv->make_validator( $hashref_schema OR $json_string );

Compiles your schema using C<Ajv> and return a
C<Data::JSONSchema::Ajv::Validator> object, documented immediately below.

=head2 compile

    $ajv->compile( $hashref_schema OR $json_string );

Same as C<make_validator>, but doesn't return validator object. You can get validator later
using C<get_validator> (see below).

=head2 get_validator

    $ajv->get_validator($schema_path);

You can get validator from schema previously compiled with C<compile> or C<make_validator>. You
can even get validator from the part of compiled schema:

    # You can compile many schemas in one ajv instance
    $ajv->compile({
        '$id' => "Schema_one", 
        token => {
        type => "string",
        minLength => 5
        },
        login => {
            params => [
                {type => "boolean"},
                {type => "string"}
            ],
            returns => { type => "number" }
        }
    });

    $ajv->compile({
        '$id' => "Schema_two", 
        type => "string",
        minLength => 5
    });

    # and then get validators using schema id and path to needed subschema
    $validator_one = $ajv->get_validator('Schema_one#/login/returns');
    $validator_two = $ajv->get_validator('Schema_two');

=head2 duktape

Need to do something else, and something magic? This is a read-only accessor
to the Duktape env.

=head1 Data::JSONSchema::Ajv::Validator

Single method object:

=head2 validate

  my $errors = $validator->validate( $data_structure );
  my $errors = $validator->validate( \$data_structure );

Validate a data-structure against the schema. Whith some options specified
(like C<removeAdditional>, C<coerceTypes>) Ajv may modify input data. If you
want to receive this modifications you need to pass your data structure by
reference: for example if you normally pass hashref or arrayref in this case
you need to pass reference to hashref or reference to arrayref. If you are
validating just a simple scalar like string or number you can also pass it
by reference, but you'll not get any data modifications because on Ajv's side
they are passed by value and can't be modified. You can try to wrap such
scalars in array with one element and modify schema a little to pass this
limitation. Returns C<undef> on success, and a data-structure complaining
on failure. The data-structure is whatever C<Ajv> produces - you can either
read its documentation, or be lazy and simply L<Data::Dumper> it.

=head1 BOOLEANS AND UNDEFINED/NULL

Perl has no special Boolean types. JSON (and indeed JavaScript) does. If you're
really brave, you can pass in a C<json> option to replace the underlying
L<Cpanel::JSON::XS> at instantiation.

=head1 SEE ALSO

This module was written because I couldn't get any of the other JSON Schema
validators to work.

Toby Inkster wrote L<JSON::Schema>, which I had high hopes for, because he's a
smart cookie, but it seems like it's very out of date compared to modern
schemas.

I was unable to get L<JSON::Validator> to fail validation for any schema I gave
it. That's probably due to having miswritten my schemas, but it didn't give me
any hints, and I did get some errors along the lines of
L<Can't locate method validate_HASH(blahblah)> and so I gave up. I also find it
mildly offensive that (the most excellent) L<Mojolicious> is a dependency for
a JSON tool. Additionally it doesn't validate the schemas themselves, and I'm
too stupid to use a tool like that.

L<Test::JSON::Schema::Acceptance> provides some schema tests. This passes all
of thems except the ones that require going and downloading external schemas.

=head1 AUTHOR

All the hard work was done by the guy who wrote Ajv,
L<Evgeny Poberezkin|https://github.com/epoberezkin>.

This Perl wrapper written by Peter Sergeant.

=cut

package Data::JSONSchema::Ajv {
    use Carp qw/croak/;
    use Cpanel::JSON::XS;

    sub new {
        my ( $class, $ajv_options, $my_options ) = @_;

        $ajv_options = {
            logger => $Cpanel::JSON::XS::false,
            %{ $ajv_options || {} }
        };

        $my_options ||= {};
        my $draft_version = delete $my_options->{'draft'} // '07';
        my $ajv_src = delete $my_options->{ajv_src};
        my $json_obj = delete $my_options->{'json'}
            // Cpanel::JSON::XS->new->ascii->allow_nonref;
        if ( keys %$my_options ) {
            croak( "Unknown options: " . ( join ', ', keys %$my_options ) );
        }

        my $js = JavaScript::Duktape::XS->new();
        $js->eval($ajv_src || $Data::JSONSchema::Ajv::src::src);

        # Setup appropriately for different version of the schema
        if ( $draft_version eq '04' ) {
            warn "Over-riding 'schemaId' as you specified draft-04"
                if exists $ajv_options->{'schemaId'};
            $ajv_options->{'schemaId'} = 'id';
            warn "Over-riding 'meta' as you specified draft-04"
                if exists $ajv_options->{'meta'};
            $ajv_options->{'meta'}
                = $json_obj->decode($Data::JSONSchema::Ajv::src::04::src);
        }
        elsif ( $draft_version eq '06' ) {
            warn "Over-riding 'meta' as you specified draft-06"
                if exists $ajv_options->{'meta'};
            $ajv_options->{'meta'}
                = $json_obj->decode($Data::JSONSchema::Ajv::src::06::src);
        }
        elsif ( $draft_version ne '07' ) {
            die "Can only accept draft versions: '04', '06', '07'";
        }

        my $self = bless {
            '_context' => $js,
            '_counter' => 0,
            '_json'    => $json_obj,
        }, $class;

        $js->set( ajvOptions => $ajv_options );

        $js->eval('var ajv = new Ajv(ajvOptions);');
        $js->typeof('ajv') ne 'undefined'
            or die "Can't create ajv object. Bad `ajv_src' specified?";

        return $self;
    }
    
    sub compile {
        my ( $self, $schema ) = @_;

        my $counter        = $self->{'_counter'}++;
        my $schema_name    = "schemaDef_$counter";
        my $validator_name = "validator_$counter";

        if ( ref $schema ) {
            $self->{'_context'}->set( $schema_name, $schema );
            $self->{'_context'}
                ->eval("var $validator_name = ajv.compile($schema_name);");
        }
        else {
            $self->{'_context'}
                ->eval("var $validator_name = ajv.compile($schema);");
        }
        
        $self->{'_context'}->typeof($validator_name) ne 'undefined'
            or die "Can't compile schema passed";

        return $validator_name;
    }

    sub make_validator {
        my ( $self, $schema ) = @_;

        my $validator_name = $self->compile($schema);

        return bless [ $self => $validator_name ],
            'Data::JSONSchema::Ajv::Validator';
    }
    
    sub get_validator {
        my ( $self, $pointer ) = @_;
        
        my $counter        = $self->{'_counter'}++;
        my $validator_name = "validator_$counter";
        
        $self->{'_context'}
                ->eval("var $validator_name = ajv.getSchema('$pointer');");
        
        $self->{'_context'}->typeof($validator_name) ne 'undefined'
            or die "Can't find such validator";
        
        return bless [ $self => $validator_name ],
            'Data::JSONSchema::Ajv::Validator';
    }

    sub duktape { my $self = shift; return $self->{'_context'}; }
}
$Data::JSONSchema::Ajv::VERSION = '0.09';;

package Data::JSONSchema::Ajv::Validator {
$Data::JSONSchema::Ajv::Validator::VERSION = '0.09';
use strict;
    use warnings;

    sub validate {
        my ( $self,   $input ) = @_;
        my ( $parent, $name )  = @$self;
        my $js = $parent->{'_context'};
        
        my $input_reftype = ref $input;

        my $data_name = "data_$name";
        $js->set( $data_name, $input_reftype eq 'REF' || $input_reftype eq 'SCALAR' ? $$input : $input );

        $js->eval("var result = $name($data_name)");

        my $result = $js->get('result');
        
        if ( $input_reftype eq 'REF' ) {
            $$input = $js->get($data_name);
        }

        $js->set( $data_name, undef );

        if ($result) {
            return;
        }
        else {
            $js->eval("var errors = $name.errors");
            my $errors = $js->get('errors');
            return $errors;
        }

    }

};

1;
