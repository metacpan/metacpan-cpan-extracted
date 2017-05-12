use strict;
use warnings;

use Carp qw/croak/;
use JavaScript::Duktape;
use Data::Visitor::Callback;
use Data::JSONSchema::Ajv::src;

=head1 NAME

Data::JSONSchema::Ajv - JSON Schema Validator wrapping Ajv

=head1 VERSION

version 0.02

=head1 DESCRIPTION

JSON Schema Validator wrapping Ajv

=head1 SYNOPSIS

    use Test::More;
    use Data::JSONSchema::Ajv;

    my $ajv_options = {};
    my $my_options  = { convert_boolean => 1 };

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

Light-weight may be a misleading statement. It relies on L<JavaScript::Duktape>
which in turn relies on L<Inline::C>. The very first time you run this, expect
an instantiation time of ~20 seconds. After that, it's fast.

Light-weight in this context just means it's only 50 lines or so of actual Perl.

=head1 METHODS

=head2 new

  my $ajv = Data::JSONSchema::Ajv->new(
      { v5 => JavaScript::Duktape::Bool->true },
      { convert_boolean => 1 },
  );

Instantiates a new L<JavaScript::Duktape> environment and loads C<Ajv> into it.
Accepts two hashrefs (or undefs). The first is passed straight through to
C<Ajv>, whose options are documented L<here|https://epoberezkin.github.io/ajv/>.

The second is options for this module. Currently only C<convert_boolean> is
allowed (default: false), and specifies whether incoming data-structures should
have various Perl JSON's modules boolean values converted to
L<JavaScript::Duktape>'s boolean values. See L<BOOLEANS> below.

=head2 make_validator

  my $validator = $ajv->make_validator( $hashref_schema );

Compiles your schema using C<Ajv> and return a
C<Data::JSONSchema::Ajv::Validator> object, documented immediately below.

=head1 Data::JSONSchema::Ajv::Validator

Single method object:

=head2 validate

  my $errors = $validator->validate( $data_structure );

Validate a data-structure against the schema. Returns C<undef> on success, and
a data-structure complaining on failure. The data-structure is whatever C<Ajv>
produces - you can either read its documentation, or be lazy and simply
L<Data::Dumper> it.

=head1 BOOLEANS

Perl has no special Boolean types. JSON (and indeed JavaScript) does. On load,
this module creates a package singleton called C<$visitor> which recognizes and
converts common workarounds for this in to L<JavaScript::Duktape::Bool>.

Currently that's a small list consisting of L<Types::Serialiser::BooleanBase>'s
and L<JSON::Boolean>'s Boolean values, but you can easily overwrite the
C<$visitor> object and send me a patch for your favourite type.

If you've set C<convert_boolean> to true, then calls to C<make_validator> and
C<validate> will run their input through the visitor object, and convert their
Booleans. This means you can push data in that you've read with, say,
L<JSON::XS> without having to think about it.

Also: C<undef> --> L<JavaScript::Duktape::NULL>.

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
$Data::JSONSchema::Ajv::VERSION = '0.02';
my $convert = sub {
        my ( $v, $obj ) = @_;
        if ($obj) {
            return JavaScript::Duktape::Bool->true;
        }
        else {
            return JavaScript::Duktape::Bool->false;
        }
    };

    our $visitor = Data::Visitor::Callback->new(
        'Types::Serialiser::BooleanBase' => $convert,
        'JSON::Boolean'                  => $convert,
        # undef -> JavaScript::Duktape->null
        value => sub { $_ // JavaScript::Duktape->null }
    );

    sub new {
        my ( $class, $ajv_options, $my_options ) = @_;

        $ajv_options ||= {};
        $my_options  ||= {};

        my $convert_boolean
            = ( delete $my_options->{'convert_boolean'} ) || 0;
        if ( keys %$my_options ) {
            croak( "Unknown options: " . ( join ', ', keys %$my_options ) );
        }

        my $js = JavaScript::Duktape->new();
        $js->eval($Data::JSONSchema::Ajv::src::src);
        $js->set( ajvOptions => $ajv_options );
        $js->eval('var ajv = new Ajv(ajvOptions);');

        return bless {
            '_convert' => $convert_boolean,
            '_context' => $js,
            '_counter' => 0,
        }, $class;
    }

    sub make_validator {
        my ( $self, $schema ) = @_;

        my $counter        = $self->{'_counter'}++;
        my $schema_name    = "schemaDef_$counter";
        my $validator_name = "validator_$counter";

        if ( $self->{'_convert'} ) {
            $schema = $visitor->visit($schema);
        }
        $self->{'_context'}->set( $schema_name, $schema );
        $self->{'_context'}
            ->eval("var $validator_name = ajv.compile($schema_name);");
        return bless [ $self => $validator_name ],
            'Data::JSONSchema::Ajv::Validator';
    }

};

package Data::JSONSchema::Ajv::Validator {
$Data::JSONSchema::Ajv::Validator::VERSION = '0.02';
use strict;
    use warnings;

    sub validate {
        my ( $self,   $input ) = @_;
        my ( $parent, $name )  = @$self;
        my $js = $parent->{'_context'};

        if ( $self->[0]->{'_convert'} ) {
            $input = $Data::JSONSchema::Ajv::visitor->visit($input);
        }

        my $data_name = "data_$name";

        $js->set( $data_name, $input );
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
