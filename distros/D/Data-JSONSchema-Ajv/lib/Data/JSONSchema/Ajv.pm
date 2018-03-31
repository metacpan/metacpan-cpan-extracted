use strict;
use warnings;

use JavaScript::Duktape::XS;
use Types::Serialiser;

use Data::JSONSchema::Ajv::src;
use Data::JSONSchema::Ajv::Types;

=head1 NAME

Data::JSONSchema::Ajv - JSON Schema Validator wrapping Ajv

=head1 VERSION

version 0.03

=head1 DESCRIPTION

JSON Schema Validator wrapping Ajv

=head1 SYNOPSIS

    use Test::More;
    use Data::JSONSchema::Ajv;

    my $ajv_options = {};
    my $my_options  = {};

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

Light-weight in this context just means it's only 50 lines or so of actual Perl.

=head1 METHODS

=head2 new

  my $ajv = Data::JSONSchema::Ajv->new(
      { v5 => $JSON::PP::true }, # Ajv options. Try: {},
      {}, # Module options. None at this time
  );

Instantiates a new L<JavaScript::Duktape::XS> environment and loads C<Ajv> into it.
Accepts two hashrefs (or undefs). The first is passed straight through to
C<Ajv>, whose options are documented L<here|https://epoberezkin.github.io/ajv/>.

There are no options at this time to pass this module itself.

You *must* read the section on SCHEMA VERSIONING below.

=head2 make_validator

  my $validator = $ajv->make_validator( $hashref_schema );

Compiles your schema using C<Ajv> and return a
C<Data::JSONSchema::Ajv::Validator> object, documented immediately below.

=head2 duktape

Need to do something else, and something magic? This is a read-only accessor
to the Duktape env.

=head1 Data::JSONSchema::Ajv::Validator

Single method object:

=head2 validate

  my $errors = $validator->validate( $data_structure );

Validate a data-structure against the schema. Returns C<undef> on success, and
a data-structure complaining on failure. The data-structure is whatever C<Ajv>
produces - you can either read its documentation, or be lazy and simply
L<Data::Dumper> it.

=head1 BOOLEANS AND UNDEFINED/NULL

Perl has no special Boolean types. JSON (and indeed JavaScript) does. On load,
this module does a bit of magic in the very simple L<Data::JSONSchema::Ajv::Types>
module, which recognizes and converts common Perl-defined standins for this in to
L<JavaScript::Duktape::XS::Bool>.

Currently that's a small list consisting of the boolean objects from
L<Types::Serialiser::BooleanBase>, L<JSON::Boolean>, and L<JSON::PP::Boolean>
but you can easily overwrite the C<$visitor> object and send me a patch for your
favourite type.

Calls to C<make_validator> and
C<validate> will run their input through the visitor object, and convert their
Booleans. This means you can push data in that you've read with, say,
L<JSON::XS> without having to think about it.

Also: C<undef> --> will be converted to JS null values -- undefined isn't
value in JSON.

=head1 SCHEMA VERSIONING

The Ajv docs have the somewhat confusing messages about schema versions, and
when trying to support the most recent Ajv, I got confusing message about
Duktape. As a result, we're using Ajv 4.11.8 which supports draft-04 style
schemas only. This will probably change in the future, but life's too short
right now and I need something that works. Patches encouraged.

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
    use Storable qw/dclone/;

    sub new {
        my ( $class, $ajv_options, $my_options ) = @_;

        $ajv_options = {
            logger => $Types::Serialiser::false,
            %{ $ajv_options || {} }
        };

        $my_options ||= {};
        if ( keys %$my_options ) {
            croak( "Unknown options: " . ( join ', ', keys %$my_options ) );
        }

        my $js = JavaScript::Duktape::XS->new();
        $js->eval($Data::JSONSchema::Ajv::Types::src);
        $js->eval($Data::JSONSchema::Ajv::src::src);

        my $self = bless {
            '_context' => $js,
            '_counter' => 0,
        }, $class;

        $self->_inject_escaped( ajvOptions => $ajv_options );
        $js->eval('var ajv = new Ajv(ajvOptions);');

        return $self;
    }

    sub make_validator {
        my ( $self, $schema ) = @_;

        my $counter        = $self->{'_counter'}++;
        my $schema_name    = "schemaDef_$counter";
        my $validator_name = "validator_$counter";

        $self->_inject_escaped( $schema_name, $schema );

        $self->{'_context'}
            ->eval("var $validator_name = ajv.compile($schema_name);");
        return bless [ $self => $validator_name ],
            'Data::JSONSchema::Ajv::Validator';
    }

    sub duktape { my $self = shift; return $self->{'_context'}; }

    sub _inject_escaped {
        my ( $self, $name, $data ) = @_;

        my $js = $self->duktape;

        # Change various markers to be magic strings
        $data = dclone( [$data] );
        $data = $Data::JSONSchema::Ajv::Types::visitor->visit( $data->[0] );

        # Push that input into JS land
        $js->set( $name, $data );

        # Change them back in JS land if needed
        $js->eval("$name = data_json_schema_ajv_type_exchange($name);");
    }
}
$Data::JSONSchema::Ajv::VERSION = '0.03';;

package Data::JSONSchema::Ajv::Validator {
$Data::JSONSchema::Ajv::Validator::VERSION = '0.03';
use strict;
    use warnings;

    sub validate {
        my ( $self,   $input ) = @_;
        my ( $parent, $name )  = @$self;
        my $js = $parent->{'_context'};

        my $data_name = "data_$name";
        $parent->_inject_escaped( $data_name, $input );

        $js->eval("var result = $name($data_name)");
        $js->set( $data_name, undef );

        my $result = $js->get('result');

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
