use 5.010001;
use strict;
use warnings;

package BSON;
# ABSTRACT: BSON serialization and deserialization (EOL)

use base 'Exporter';
our @EXPORT_OK = qw/encode decode/;

use version;
our $VERSION = 'v1.12.2';

use Carp;
use Config;
use Scalar::Util qw/blessed looks_like_number/;

use Moo 2.002004; # safer generated code
use boolean;
use BSON::OID;

use constant {
    HAS_INT64 => $Config{use64bitint},
    HAS_LD    => $Config{uselongdouble},
};

use if !HAS_INT64, "Math::BigInt";

my $bools_re = qr/::(?:Boolean|_Bool|Bool)\z/;

use namespace::clean -except => 'meta';

my $max_int32 = 2147483647;

# Dependency-free equivalent of what we need from Module::Runtime
sub _try_load {
    my ( $mod, $ver ) = @_;
    ( my $file = "$mod.pm" ) =~ s{::}{/}g;
    my $load = eval { require $file; $mod->VERSION($ver) if defined $ver; 1 };
    delete $INC{$file} if !$load; # for old, broken perls
    die $@ if !$load;
    return 1;
}

BEGIN {
    my ($class, @errs);
    if ( $class = $ENV{PERL_BSON_BACKEND} ) {
        eval { _try_load($class) };
        if ( my $err = $@ ) {
            $err =~ s{ at \S+ line .*}{};
            die "Error: PERL_BSON_BACKEND '$class' could not be loaded: $err\n";
        }
        unless ($class->can("_encode_bson") && $class->can("_decode_bson") ) {
            die "Error: PERL_BSON_BACKEND '$class' does not implement the correct API.\n";
        }
    }
    elsif ( eval { _try_load( $class = "BSON::XS" ) } or do { push @errs, $@; 0 } ) {
        # module loaded; nothing else to do
    }
    elsif ( eval { _try_load( $class = "BSON::PP" ) } or do { push @errs, $@; 0 } ) {
        # module loaded; nothing else to do
    }
    else {
        s/\n/ /g for @errs;
        die join( "\n* ", "Error: Couldn't load a BSON backend:", @errs ) . "\n";
    }

    *_encode_bson = $class->can("_encode_bson");
    *_decode_bson = $class->can("_decode_bson");
    *_backend_class = sub { $class }; # for debugging
}

# LOAD AFTER XS/PP, so that modules can pick up right version of helpers
use BSON::Types (); # loads types for extjson inflation

#--------------------------------------------------------------------------#
# public attributes
#--------------------------------------------------------------------------#

#pod =attr error_callback
#pod
#pod This attribute specifies a function reference that will be called with
#pod three positional arguments:
#pod
#pod =for :list
#pod * an error string argument describing the error condition
#pod * a reference to the problematic document or byte-string
#pod * the method in which the error occurred (e.g. C<encode_one> or C<decode_one>)
#pod
#pod Note: for decoding errors, the byte-string is passed as a reference to avoid
#pod copying possibly large strings.
#pod
#pod If not provided, errors messages will be thrown with C<Carp::croak>.
#pod
#pod =cut

has error_callback => (
    is      => 'ro',
    isa     => sub { die "not a code reference" if defined $_[0] && ! ref $_[0] eq 'CODE' },
);

#pod =attr invalid_chars
#pod
#pod A string containing ASCII characters that must not appear in keys.  The default
#pod is the empty string, meaning there are no invalid characters.
#pod
#pod =cut

has invalid_chars => (
    is      => 'ro',
    isa     => sub { die "not a string" if ! defined $_[0] || ref $_[0] },
);

#pod =attr max_length
#pod
#pod This attribute defines the maximum document size. The default is 0, which
#pod disables any maximum.
#pod
#pod If set to a positive number, it applies to both encoding B<and> decoding (the
#pod latter is necessary for prevention of resource consumption attacks).
#pod
#pod =cut

has max_length => (
    is      => 'ro',
    isa     => sub { die "not a non-negative number" unless defined $_[0] && $_[0] >= 0 },
);

#pod =attr op_char
#pod
#pod This is a single character to use for special MongoDB-specific query
#pod operators.  If a key starts with C<op_char>, the C<op_char> character will
#pod be replaced with "$".
#pod
#pod The default is "$", meaning that no replacement is necessary.
#pod
#pod =cut

has op_char => (
    is  => 'ro',
    isa => sub { die "not a single character" if defined $_[0] && length $_[0] > 1 },
);

#pod =attr ordered
#pod
#pod If set to a true value, then decoding will return a reference to a tied
#pod hash that preserves key order. Otherwise, a regular (unordered) hash
#pod reference will be returned.
#pod
#pod B<IMPORTANT CAVEATS>:
#pod
#pod =for :list
#pod * When 'ordered' is true, users must not rely on the return value being any
#pod   particular tied hash implementation.  It may change in the future for
#pod   efficiency.
#pod * Turning this option on entails a significant speed penalty as tied hashes
#pod   are slower than regular Perl hashes.
#pod
#pod The default is false.
#pod
#pod =cut

has ordered => (
    is => 'ro',
);

#pod =attr prefer_numeric
#pod
#pod When false, scalar values will be encoded as a number if they were
#pod originally a number or were ever used in a numeric context.  However, a
#pod string that looks like a number but was never used in a numeric context
#pod (e.g. "42") will be encoded as a string.
#pod
#pod If C<prefer_numeric> is set to true, the encoder will attempt to coerce
#pod strings that look like a number into a numeric value.  If the string
#pod doesn't look like a double or integer, it will be encoded as a string.
#pod
#pod B<IMPORTANT CAVEAT>: the heuristics for determining whether something is a
#pod string or number are less accurate on older Perls.  See L<BSON::Types>
#pod for wrapper classes that specify exact serialization types.
#pod
#pod The default is false.
#pod
#pod =cut

has prefer_numeric => (
    is => 'ro',
);

#pod =attr wrap_dbrefs
#pod
#pod If set to true, during decoding, documents with the fields C<'$id'> and
#pod C<'$ref'> (literal dollar signs, not variables) will be wrapped as
#pod L<BSON::DBRef> objects.  If false, they are decoded into ordinary hash
#pod references (or ordered hashes, if C<ordered> is true).
#pod
#pod The default is true.
#pod
#pod =cut

has wrap_dbrefs  => (
    is => 'ro',
);

#pod =attr wrap_numbers
#pod
#pod If set to true, during decoding, numeric values will be wrapped into
#pod BSON type-wrappers: L<BSON::Double>, L<BSON::Int64> or L<BSON::Int32>.
#pod While very slow, this can help ensure fields can round-trip if unmodified.
#pod
#pod The default is false.
#pod
#pod =cut

has wrap_numbers => (
    is => 'ro',
);

#pod =attr wrap_strings
#pod
#pod If set to true, during decoding, string values will be wrapped into a BSON
#pod type-wrappers, L<BSON::String>.  While very slow, this can help ensure
#pod fields can round-trip if unmodified.
#pod
#pod The default is false.
#pod
#pod =cut

has wrap_strings => (
    is => 'ro',
);

#pod =attr dt_type (Discouraged)
#pod
#pod Sets the type of object which is returned for BSON DateTime fields. The
#pod default is C<undef>, which returns objects of type L<BSON::Time>.  This is
#pod overloaded to be the integer epoch value when used as a number or string,
#pod so is somewhat backwards compatible with C<dt_type> in the L<MongoDB>
#pod driver.
#pod
#pod Other acceptable values are L<BSON::Time> (explicitly), L<DateTime>,
#pod L<Time::Moment>, L<DateTime::Tiny>, L<Mango::BSON::Time>.
#pod
#pod Because BSON::Time objects have methods to convert to DateTime,
#pod Time::Moment or DateTime::Tiny, use of this field is discouraged.  Users
#pod should use these methods on demand.  This option is provided for backwards
#pod compatibility only.
#pod
#pod =cut

has dt_type => (
    is      => 'ro',
    isa     => sub { return if !defined($_[0]); die "not a string" if ref $_[0] },
);

sub BUILD {
    my ($self) = @_;
    $self->{wrap_dbrefs} = 1 unless defined $self->{wrap_dbrefs};
    $self->{invalid_chars} = "" unless defined $self->{invalid_chars};
}

#--------------------------------------------------------------------------#
# public methods
#--------------------------------------------------------------------------#

#pod =method encode_one
#pod
#pod     $byte_string = $codec->encode_one( $doc );
#pod     $byte_string = $codec->encode_one( $doc, \%options );
#pod
#pod Takes a "document", typically a hash reference, an array reference, or a
#pod Tie::IxHash object and returns a byte string with the BSON representation of
#pod the document.
#pod
#pod An optional hash reference of options may be provided.  Valid options include:
#pod
#pod =for :list
#pod * first_key – if C<first_key> is defined, it and C<first_value>
#pod   will be encoded first in the output BSON; any matching key found in the
#pod   document will be ignored.
#pod * first_value - value to assign to C<first_key>; will encode as Null if omitted
#pod * error_callback – overrides codec default
#pod * invalid_chars – overrides codec default
#pod * max_length – overrides codec default
#pod * op_char – overrides codec default
#pod * prefer_numeric – overrides codec default
#pod
#pod =cut

sub encode_one {
    my ( $self, $document, $options ) = @_;
    my $type = ref($document);

    Carp::croak "Can't encode scalars" unless $type;
    # qr// is blessed to 'Regexp';
    if ( $type eq "Regexp"
        || !( blessed($document) || $type eq 'HASH' || $type eq 'ARRAY' ) )
    {
        Carp::croak "Can't encode non-container of type '$type'";
    }

    $document = BSON::Doc->new(@$document)
        if $type eq 'ARRAY';

    my $merged_opts = { %$self, ( $options ? %$options : () ) };

    my $bson = eval { _encode_bson( $document, $merged_opts ) };
    # XXX this is a late max_length check -- it should be checked during
    # encoding after each key
    if ( $@ or ( $merged_opts->{max_length} && length($bson) > $merged_opts->{max_length} ) ) {
        my $msg = $@ || "Document exceeds maximum size $merged_opts->{max_length}";
        if ( $merged_opts->{error_callback} ) {
            $merged_opts->{error_callback}->( $msg, $document, 'encode_one' );
        }
        else {
            Carp::croak("During encode_one, $msg");
        }
    }

    return $bson;
}

#pod =method decode_one
#pod
#pod     $doc = $codec->decode_one( $byte_string );
#pod     $doc = $codec->decode_one( $byte_string, \%options );
#pod
#pod Takes a byte string with a BSON-encoded document and returns a
#pod hash reference representing the decoded document.
#pod
#pod An optional hash reference of options may be provided.  Valid options include:
#pod
#pod =for :list
#pod * dt_type – overrides codec default
#pod * error_callback – overrides codec default
#pod * max_length – overrides codec default
#pod * ordered - overrides codec default
#pod * wrap_dbrefs - overrides codec default
#pod * wrap_numbers - overrides codec default
#pod * wrap_strings - overrides codec default
#pod
#pod =cut

sub decode_one {
    my ( $self, $string, $options ) = @_;

    my $merged_opts = { %$self, ( $options ? %$options : () ) };

    if ( $merged_opts->{max_length} && length($string) > $merged_opts->{max_length} ) {
        my $msg = "Document exceeds maximum size $merged_opts->{max_length}";
        if ( $merged_opts->{error_callback} ) {
            $merged_opts->{error_callback}->( $msg, \$string, 'decode_one' );
        }
        else {
            Carp::croak("During decode_one, $msg");
        }
    }

    my $document = eval { _decode_bson( $string, $merged_opts ) };
    if ( $@ ) {
        if ( $merged_opts->{error_callback} ) {
            $merged_opts->{error_callback}->( $@, \$string, 'decode_one' );
        }
        else {
            Carp::croak("During decode_one, $@");
        }
    }

    return $document;
}

#pod =method clone
#pod
#pod     $copy = $codec->clone( ordered => 1 );
#pod
#pod Constructs a copy of the original codec, but allows changing
#pod attributes in the copy.
#pod
#pod =cut

sub clone {
    my ($self, @args) = @_;
    my $class = ref($self);
    if ( @args == 1 && ref( $args[0] ) eq 'HASH' ) {
        return $class->new( %$self, %{$args[0]} );
    }

    return $class->new( %$self, @args );
}


#--------------------------------------------------------------------------#
# public class methods
#--------------------------------------------------------------------------#

#pod =method create_oid
#pod
#pod     $oid = BSON->create_oid;
#pod
#pod This class method returns a new L<BSON::OID>.  This abstracts OID
#pod generation away from any specific Object ID class and makes it an interface
#pod on a BSON codec.  Alternative BSON codecs should define a similar class
#pod method that returns an Object ID of whatever type is appropriate.
#pod
#pod =cut

sub create_oid { return BSON::OID->new }

#pod =method inflate_extjson (DEPRECATED)
#pod
#pod This legacy method does not follow the L<MongoDB Extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
#pod specification.
#pod
#pod Use L</extjson_to_perl> instead.
#pod
#pod =cut

sub inflate_extjson {
    my ( $self, $hash ) = @_;

    for my $k ( keys %$hash ) {
        my $v = $hash->{$k};
        if ( substr( $k, 0, 1 ) eq '$' ) {
            croak "Dollar-prefixed key '$k' is not legal in top-level hash";
        }
        my $type = ref($v);
        $hash->{$k} =
            $type eq 'HASH'    ? $self->_inflate_hash($v)
          : $type eq 'ARRAY'   ? $self->_inflate_array($v)
          : $type =~ $bools_re ? ( $v ? true : false )
          :                      $v;
    }

    return $hash;
}

#pod =method perl_to_extjson
#pod
#pod     use JSON::MaybeXS;
#pod     my $ext = BSON->perl_to_extjson($data, \%options);
#pod     my $json = encode_json($ext);
#pod
#pod Takes a perl data structure (i.e. hashref) and turns it into an
#pod L<MongoDB Extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
#pod structure. Note that the structure will still have to be serialized.
#pod
#pod Possible options are:
#pod
#pod =for :list
#pod * C<relaxed> A boolean indicating if "relaxed extended JSON" should
#pod be generated. If not set, the default value is taken from the
#pod C<BSON_EXTJSON_RELAXED> environment variable.
#pod
#pod =cut

my $use_win32_specials = ($^O eq 'MSWin32' && $] lt "5.022");

my $is_inf = $use_win32_specials ? qr/^1.\#INF/i : qr/^inf/i;
my $is_ninf = $use_win32_specials ? qr/^-1.\#INF/i : qr/^-inf/i;
my $is_nan = $use_win32_specials ? qr/^-?1.\#(?:IND|QNAN)/i : qr/^-?nan/i;

sub perl_to_extjson {
    my ($class, $data, $options) = @_;

    local $ENV{BSON_EXTJSON} = 1;
    local $ENV{BSON_EXTJSON_RELAXED} = $ENV{BSON_EXTJSON_RELAXED};
    $ENV{BSON_EXTJSON_RELAXED} = $options->{relaxed};

    if (not defined $data) {
        return undef; ## no critic
    }

    if (blessed($data) and $data->can('TO_JSON')) {
        my $json_data = $data->TO_JSON;
        return $json_data;
    }

    if (not ref $data) {

        if (looks_like_number($data)) {
            if ($ENV{BSON_EXTJSON_RELAXED}) {
                return $data;
            }

            if ($data =~ m{\A-?[0-9_]+\z}) {
                if ($data <= $max_int32) {
                    return { '$numberInt' => "$data" };
                }
                else {
                    return { '$numberLong' => "$data" };
                }
            }
            else {
                return { '$numberDouble' => 'Infinity' }
                    if $data =~ $is_inf;
                return { '$numberDouble' => '-Infinity' }
                    if $data =~ $is_ninf;
                return { '$numberDouble' => 'NaN' }
                    if $data =~ $is_nan;
                my $value = "$data";
                $value = $value / 1.0;
                return { '$numberDouble' => "$value" };
            }
        }

        return $data;
    }

    if (boolean::isBoolean($data)) {
        return $data;
    }

    if (ref $data eq 'HASH') {
        for my $key (keys %$data) {
            my $value = $data->{$key};
            $data->{$key} = $class->perl_to_extjson($value, $options);
        }
        return $data;
    }

    if (ref $data eq 'ARRAY') {
        for my $index (0 .. $#$data) {
            my $value = $data->[$index];
            $data->[$index] = $class->perl_to_extjson($value, $options);
        }
        return $data;
    }

    if (blessed($data) and $data->isa('JSON::PP::Boolean')) {
        return $data;
    }

    if (
        blessed($data) and (
            $data->isa('Math::BigInt') or
            $data->isa('Math::BigFloat')
        )
    ) {
        return $data;
    }

    die sprintf "Unsupported ref value (%s)", ref($data);
}

#pod =method extjson_to_perl
#pod
#pod     use JSON::MaybeXS;
#pod     my $ext = decode_json($json);
#pod     my $data = $bson->extjson_to_perl($ext);
#pod
#pod Takes an
#pod L<MongoDB Extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
#pod data structure and inflates it into a Perl data structure. Note that
#pod you have to decode the JSON string manually beforehand.
#pod
#pod Canonically specified numerical values like C<{"$numberInt":"23"}> will
#pod be inflated into their respective C<BSON::*> wrapper types. Plain numeric
#pod values will be left as-is.
#pod
#pod =cut

sub extjson_to_perl {
    my ($class, $data) = @_;
    # top level keys are never extended JSON elements, so we wrap the
    # _extjson_to_perl inflater so it applies only to values, not the
    # original data structure
    for my $key (keys %$data) {
        my $value = $data->{$key};
        $data->{$key} = $class->_extjson_to_perl($value);
    }
    return $data;
}

sub _extjson_to_perl {
    my ($class, $data) = @_;

    if (ref $data eq 'HASH') {

        if ( exists $data->{'$oid'} ) {
            return BSON::OID->new( oid => pack( "H*", $data->{'$oid'} ) );
        }

        if ( exists $data->{'$numberInt'} ) {
            return BSON::Int32->new( value => $data->{'$numberInt'} );
        }

        if ( exists $data->{'$numberLong'} ) {
            if (HAS_INT64) {
                return BSON::Int64->new( value => $data->{'$numberLong'} );
            }
            else {
                return BSON::Int64->new( value => Math::BigInt->new($data->{'$numberLong'}) );
            }
        }

        if ( exists $data->{'$binary'} ) {
            require MIME::Base64;
            if (exists $data->{'$type'}) {
                return BSON::Bytes->new(
                    data    => MIME::Base64::decode_base64($data->{'$binary'}),
                    subtype => hex( $data->{'$type'} || 0 ),
                );
            }
            else {
                my $value = $data->{'$binary'};
                return BSON::Bytes->new(
                    data    => MIME::Base64::decode_base64($value->{base64}),
                    subtype => hex( $value->{subType} || 0 ),
                );
            }
        }

        if ( exists $data->{'$date'} ) {
            my $v = $data->{'$date'};
            $v = ref($v) eq 'HASH' ? $class->_extjson_to_perl($v) : _iso8601_to_epochms($v);
            return BSON::Time->new( value => $v );
        }

        if ( exists $data->{'$minKey'} ) {
            return BSON::MinKey->new;
        }

        if ( exists $data->{'$maxKey'} ) {
            return BSON::MaxKey->new;
        }

        if ( exists $data->{'$timestamp'} ) {
            return BSON::Timestamp->new(
                seconds   => $data->{'$timestamp'}{t},
                increment => $data->{'$timestamp'}{i},
            );
        }

        if ( exists $data->{'$regex'} and not ref $data->{'$regex'}) {
            return BSON::Regex->new(
                pattern => $data->{'$regex'},
                ( exists $data->{'$options'} ? ( flags => $data->{'$options'} ) : () ),
            );
        }

        if ( exists $data->{'$regularExpression'} ) {
            my $value = $data->{'$regularExpression'};
            return BSON::Regex->new(
                pattern => $value->{pattern},
                ( exists $value->{options} ? ( flags => $value->{options} ) : () ),
            );
        }

        if ( exists $data->{'$code'} ) {
            return BSON::Code->new(
                code => $data->{'$code'},
                ( exists $data->{'$scope'}
                    ? ( scope => $class->_extjson_to_perl($data->{'$scope'}) )
                    : ()
                ),
            );
        }

        if ( exists $data->{'$undefined'} ) {
            return undef; ## no critic
        }

        if ( exists $data->{'$dbPointer'} ) {
            my $data = $data->{'$dbPointer'};
            my $id = $data->{'$id'};
            $id = $class->_extjson_to_perl($id) if ref($id) eq 'HASH';
            return BSON::DBPointer->new(
                '$ref' => $data->{'$ref'},
                '$id' => $id,
            );
        }

        if ( exists $data->{'$ref'} ) {
            my $id = delete $data->{'$id'};
            $id = $class->_extjson_to_perl($id) if ref($id) eq 'HASH';
            return BSON::DBRef->new(
                '$ref' => delete $data->{'$ref'},
                '$id' => $id,
                '$db' => delete $data->{'$db'},
                %$data, # extra
            );
        }

        if ( exists $data->{'$numberDecimal'} ) {
            return BSON::Decimal128->new( value => $data->{'$numberDecimal'} );
        }

        # Following extended JSON is non-standard

        if ( exists $data->{'$numberDouble'} ) {
            if ( $data->{'$numberDouble'} eq '-0' && $] lt '5.014' && ! HAS_LD ) {
                $data->{'$numberDouble'} = '-0.0';
            }
            return BSON::Double->new( value => $data->{'$numberDouble'} );
        }

        if ( exists $data->{'$symbol'} ) {
            return BSON::Symbol->new(value => $data->{'$symbol'});
        }

        for my $key (keys %$data) {
            my $value = $data->{$key};
            $data->{$key} = $class->_extjson_to_perl($value);
        }
        return $data;
    }

    if (ref $data eq 'ARRAY') {
        for my $index (0 .. $#$data) {
            my $value = $data->[$index];
            $data->[$index] = ref($value)
                ? $class->_extjson_to_perl($value)
                : $value;
        }
        return $data;
    }

    return $data;
}

#--------------------------------------------------------------------------#
# legacy functional interface
#--------------------------------------------------------------------------#

#pod =func encode
#pod
#pod     my $bson = encode({ bar => 'foo' }, \%options);
#pod
#pod This is the legacy, functional interface and is only exported on demand.
#pod It takes a hashref and returns a BSON string.
#pod It uses an internal codec singleton with default attributes.
#pod
#pod =func decode
#pod
#pod     my $hash = decode( $bson, \%options );
#pod
#pod This is the legacy, functional interface and is only exported on demand.
#pod It takes a BSON string and returns a hashref.
#pod It uses an internal codec singleton with default attributes.
#pod
#pod =cut

{
    my $CODEC;

    sub encode {
        if ( defined $_[0] && ( $_[0] eq 'BSON' || ( blessed($_[0]) && $_[0]->isa('BSON') ) ) ) {
            Carp::croak("Error: 'encode' is a function, not a method");
        }
        my $doc = shift;
        $CODEC = BSON->new unless defined $CODEC;
        if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
            return $CODEC->encode_one( $doc, $_[0] );
        }
        elsif ( @_ % 2 == 0 ) {
            return $CODEC->encode_one( $doc, {@_} );
        }
        else {
            Carp::croak("Options for 'encode' must be a hashref or key-value pairs");
        }
    }

    sub decode {
        if ( defined $_[0] && ( $_[0] eq 'BSON' || ( blessed($_[0]) && $_[0]->isa('BSON') ) ) ) {
            Carp::croak("Error: 'decode' is a function, not a method");
        }
        my $doc = shift;
        $CODEC = BSON->new unless defined $CODEC;
        my $args;
        if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
            $args = shift;
        }
        elsif ( @_ % 2 == 0 ) {
            $args = { @_ };
        }
        else {
            Carp::croak("Options for 'decode' must be a hashref or key-value pairs");
        }
        $args->{ordered} = delete $args->{ixhash}
          if exists $args->{ixhash} && !exists $args->{ordered};
        return $CODEC->decode_one( $doc, $args );
    }
}

#--------------------------------------------------------------------------#
# private functions
#--------------------------------------------------------------------------#

sub _inflate_hash {
    my ( $class, $hash ) = @_;

    if ( exists $hash->{'$oid'} ) {
        return BSON::OID->new( oid => pack( "H*", $hash->{'$oid'} ) );
    }

    if ( exists $hash->{'$numberInt'} ) {
        return BSON::Int32->new( value => $hash->{'$numberInt'} );
    }

    if ( exists $hash->{'$numberLong'} ) {
        if (HAS_INT64) {
            return BSON::Int64->new( value => $hash->{'$numberLong'} );
        }
        else {
            return BSON::Int64->new( value => Math::BigInt->new($hash->{'$numberLong'}) );
        }
    }

    if ( exists $hash->{'$binary'} ) {
        require MIME::Base64;
        return BSON::Bytes->new(
            data    => MIME::Base64::decode_base64($hash->{'$binary'}),
            subtype => hex( $hash->{'$type'} || 0 )
        );
    }

    if ( exists $hash->{'$date'} ) {
        my $v = $hash->{'$date'};
        $v = ref($v) eq 'HASH' ? BSON->_inflate_hash($v) : _iso8601_to_epochms($v);
        return BSON::Time->new( value => $v );
    }

    if ( exists $hash->{'$minKey'} ) {
        return BSON::MinKey->new;
    }

    if ( exists $hash->{'$maxKey'} ) {
        return BSON::MaxKey->new;
    }

    if ( exists $hash->{'$timestamp'} ) {
        return BSON::Timestamp->new(
            seconds   => $hash->{'$timestamp'}{t},
            increment => $hash->{'$timestamp'}{i},
        );
    }

    if ( exists $hash->{'$regex'} ) {
        return BSON::Regex->new(
            pattern => $hash->{'$regex'},
            ( exists $hash->{'$options'} ? ( flags => $hash->{'$options'} ) : () ),
        );
    }

    if ( exists $hash->{'$code'} ) {
        return BSON::Code->new(
            code => $hash->{'$code'},
            ( exists $hash->{'$scope'} ? ( scope => $hash->{'$scope'} ) : () ),
        );
    }

    if ( exists $hash->{'$undefined'} ) {
        return undef; ## no critic
    }

    if ( exists $hash->{'$ref'} ) {
        my $id = $hash->{'$id'};
        $id = BSON->_inflate_hash($id) if ref($id) eq 'HASH';
        return BSON::DBRef->new( '$ref' => $hash->{'$ref'}, '$id' => $id );
    }

    if ( exists $hash->{'$numberDecimal'} ) {
        return BSON::Decimal128->new( value => $hash->{'$numberDecimal'} );
    }

    # Following extended JSON is non-standard

    if ( exists $hash->{'$numberDouble'} ) {
        if ( $hash->{'$numberDouble'} eq '-0' && $] lt '5.014' && ! HAS_LD ) {
            $hash->{'$numberDouble'} = '-0.0';
        }
        return BSON::Double->new( value => $hash->{'$numberDouble'} );
    }

    if ( exists $hash->{'$symbol'} ) {
        return $hash->{'$symbol'};
    }

    return $hash;
}

sub _inflate_array {
    my ($class, $array) = @_;
    if (@$array) {
        for my $i ( 0 .. $#$array ) {
            my $v = $array->[$i];
            $array->[$i] =
                ref($v) eq 'HASH'  ? BSON->_inflate_hash($v)
              : ref($v) eq 'ARRAY' ? _inflate_array($v)
              :                       $v;
        }
    }
    return $array;
}

my $iso8601_re = qr{
    (\d{4}) - (\d{2}) - (\d{2}) T               # date
    (\d{2}) : (\d{2}) : ( \d+ (?:\. \d+ )? )    # time
    (?: Z | ([+-] \d{2} :? (?: \d{2} )? ) )?    # maybe TZ
}x;

sub _iso8601_to_epochms {
    my ($date) = shift;
    require Time::Local;

    my $zone_offset = 0;;
    if ( substr($date,-1,1) eq 'Z' ) {
        chop($date);
    }

    if ( $date =~ /\A$iso8601_re\z/ ) {
        my ($Y,$M,$D,$h,$m,$s,$z) = ($1,$2-1,$3,$4,$5,$6,$7);
        if (defined($z) && length($z))  {
            $z =~ tr[:][];
            $z .= "00" if length($z) < 5;
            my $zd = substr($z,0,1);
            my $zh = substr($z,1,2);
            my $zm = substr($z,3,2);
            $zone_offset = ($zd eq '-' ? -1 : 1 ) * (3600 * $zh + 60 * $zm);
        }
        my $frac = $s - int($s);
        my $epoch = Time::Local::timegm(int($s), $m, $h, $D, $M, $Y) - $zone_offset;
        $epoch = HAS_INT64 ? 1000 * $epoch : Math::BigInt->new($epoch) * 1000;
        $epoch += HAS_INT64 ? $frac * 1000 : Math::BigFloat->new($frac) * 1000;
        return $epoch;
    }
    else {
        Carp::croak("Couldn't parse '\$date' field: $date\n");
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

BSON - BSON serialization and deserialization (EOL)

=head1 VERSION

version v1.12.2

=head1 END OF LIFE NOTICE

Version v1.12.0 was the final feature release of the MongoDB BSON library
and version v1.12.2 is the final patch release.

B<As of August 13, 2020, the MongoDB Perl driver and related libraries have
reached end of life and are no longer supported by MongoDB.> See the
L<August 2019 deprecation
notice|https://www.mongodb.com/blog/post/the-mongodb-perl-driver-is-being-deprecated>
for rationale.

If members of the community wish to continue development, they are welcome
to fork the code under the terms of the Apache 2 license and release it
under a new namespace.  Specifications and test files for MongoDB drivers
and libraries are published in an open repository:
L<mongodb/specifications|https://github.com/mongodb/specifications/tree/master/source>.

=head1 SYNOPSIS

    use BSON;
    use BSON::Types ':all';
    use boolean;

    my $codec = BSON->new;

    my $document = {
        _id             => bson_oid(),
        creation_time   => bson_time(), # now
        zip_code        => bson_string("08544"),
        hidden          => false,
    };

    my $bson = $codec->encode_one( $document );
    my $doc  = $codec->decode_one( $bson     );

=head1 DESCRIPTION

This class implements a BSON encoder/decoder ("codec").  It consumes
"documents" (typically hash references) and emits BSON strings and vice
versa in accordance with the L<BSON Specification|http://bsonspec.org>.

BSON is the primary data representation for L<MongoDB>.  While this module
has several features that support MongoDB-specific needs and conventions,
it can be used as a standalone serialization format.

The codec may be customized through attributes on the codec option as well
as encode/decode specific options on methods:

    my $codec = BSON->new( \%global_attributes );

    my $bson = $codec->encode_one( $document, \%encode_options );
    my $doc  = $codec->decode_one( $bson    , \%decode_options );

Because BSON is strongly-typed and Perl is not, this module supports
a number of "type wrappers" – classes that wrap Perl data to indicate how
they should serialize. The L<BSON::Types> module describes these and
provides associated helper functions.  See L</PERL-BSON TYPE MAPPING>
for more details.

When decoding, type wrappers are used for any data that has no native Perl
representation.  Optionally, all data may be wrapped for precise control of
round-trip encoding.

Please read the configuration attributes carefully to understand more about
how to control encoding and decoding.

At compile time, this module will select an implementation backend.  It
will prefer C<BSON::XS> (released separately) if available, or will fall
back to L<BSON::PP> (bundled with this module).  See L</ENVIRONMENT> for
a way to control the selection of the backend.

=head1 ATTRIBUTES

=head2 error_callback

This attribute specifies a function reference that will be called with
three positional arguments:

=over 4

=item *

an error string argument describing the error condition

=item *

a reference to the problematic document or byte-string

=item *

the method in which the error occurred (e.g. C<encode_one> or C<decode_one>)

=back

Note: for decoding errors, the byte-string is passed as a reference to avoid
copying possibly large strings.

If not provided, errors messages will be thrown with C<Carp::croak>.

=head2 invalid_chars

A string containing ASCII characters that must not appear in keys.  The default
is the empty string, meaning there are no invalid characters.

=head2 max_length

This attribute defines the maximum document size. The default is 0, which
disables any maximum.

If set to a positive number, it applies to both encoding B<and> decoding (the
latter is necessary for prevention of resource consumption attacks).

=head2 op_char

This is a single character to use for special MongoDB-specific query
operators.  If a key starts with C<op_char>, the C<op_char> character will
be replaced with "$".

The default is "$", meaning that no replacement is necessary.

=head2 ordered

If set to a true value, then decoding will return a reference to a tied
hash that preserves key order. Otherwise, a regular (unordered) hash
reference will be returned.

B<IMPORTANT CAVEATS>:

=over 4

=item *

When 'ordered' is true, users must not rely on the return value being any particular tied hash implementation.  It may change in the future for efficiency.

=item *

Turning this option on entails a significant speed penalty as tied hashes are slower than regular Perl hashes.

=back

The default is false.

=head2 prefer_numeric

When false, scalar values will be encoded as a number if they were
originally a number or were ever used in a numeric context.  However, a
string that looks like a number but was never used in a numeric context
(e.g. "42") will be encoded as a string.

If C<prefer_numeric> is set to true, the encoder will attempt to coerce
strings that look like a number into a numeric value.  If the string
doesn't look like a double or integer, it will be encoded as a string.

B<IMPORTANT CAVEAT>: the heuristics for determining whether something is a
string or number are less accurate on older Perls.  See L<BSON::Types>
for wrapper classes that specify exact serialization types.

The default is false.

=head2 wrap_dbrefs

If set to true, during decoding, documents with the fields C<'$id'> and
C<'$ref'> (literal dollar signs, not variables) will be wrapped as
L<BSON::DBRef> objects.  If false, they are decoded into ordinary hash
references (or ordered hashes, if C<ordered> is true).

The default is true.

=head2 wrap_numbers

If set to true, during decoding, numeric values will be wrapped into
BSON type-wrappers: L<BSON::Double>, L<BSON::Int64> or L<BSON::Int32>.
While very slow, this can help ensure fields can round-trip if unmodified.

The default is false.

=head2 wrap_strings

If set to true, during decoding, string values will be wrapped into a BSON
type-wrappers, L<BSON::String>.  While very slow, this can help ensure
fields can round-trip if unmodified.

The default is false.

=head2 dt_type (Discouraged)

Sets the type of object which is returned for BSON DateTime fields. The
default is C<undef>, which returns objects of type L<BSON::Time>.  This is
overloaded to be the integer epoch value when used as a number or string,
so is somewhat backwards compatible with C<dt_type> in the L<MongoDB>
driver.

Other acceptable values are L<BSON::Time> (explicitly), L<DateTime>,
L<Time::Moment>, L<DateTime::Tiny>, L<Mango::BSON::Time>.

Because BSON::Time objects have methods to convert to DateTime,
Time::Moment or DateTime::Tiny, use of this field is discouraged.  Users
should use these methods on demand.  This option is provided for backwards
compatibility only.

=head1 METHODS

=head2 encode_one

    $byte_string = $codec->encode_one( $doc );
    $byte_string = $codec->encode_one( $doc, \%options );

Takes a "document", typically a hash reference, an array reference, or a
Tie::IxHash object and returns a byte string with the BSON representation of
the document.

An optional hash reference of options may be provided.  Valid options include:

=over 4

=item *

first_key – if C<first_key> is defined, it and C<first_value> will be encoded first in the output BSON; any matching key found in the document will be ignored.

=item *

first_value - value to assign to C<first_key>; will encode as Null if omitted

=item *

error_callback – overrides codec default

=item *

invalid_chars – overrides codec default

=item *

max_length – overrides codec default

=item *

op_char – overrides codec default

=item *

prefer_numeric – overrides codec default

=back

=head2 decode_one

    $doc = $codec->decode_one( $byte_string );
    $doc = $codec->decode_one( $byte_string, \%options );

Takes a byte string with a BSON-encoded document and returns a
hash reference representing the decoded document.

An optional hash reference of options may be provided.  Valid options include:

=over 4

=item *

dt_type – overrides codec default

=item *

error_callback – overrides codec default

=item *

max_length – overrides codec default

=item *

ordered - overrides codec default

=item *

wrap_dbrefs - overrides codec default

=item *

wrap_numbers - overrides codec default

=item *

wrap_strings - overrides codec default

=back

=head2 clone

    $copy = $codec->clone( ordered => 1 );

Constructs a copy of the original codec, but allows changing
attributes in the copy.

=head2 create_oid

    $oid = BSON->create_oid;

This class method returns a new L<BSON::OID>.  This abstracts OID
generation away from any specific Object ID class and makes it an interface
on a BSON codec.  Alternative BSON codecs should define a similar class
method that returns an Object ID of whatever type is appropriate.

=head2 inflate_extjson (DEPRECATED)

This legacy method does not follow the L<MongoDB Extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
specification.

Use L</extjson_to_perl> instead.

=head2 perl_to_extjson

    use JSON::MaybeXS;
    my $ext = BSON->perl_to_extjson($data, \%options);
    my $json = encode_json($ext);

Takes a perl data structure (i.e. hashref) and turns it into an
L<MongoDB Extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
structure. Note that the structure will still have to be serialized.

Possible options are:

=over 4

=item *

C<relaxed> A boolean indicating if "relaxed extended JSON" should

be generated. If not set, the default value is taken from the
C<BSON_EXTJSON_RELAXED> environment variable.

=back

=head2 extjson_to_perl

    use JSON::MaybeXS;
    my $ext = decode_json($json);
    my $data = $bson->extjson_to_perl($ext);

Takes an
L<MongoDB Extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
data structure and inflates it into a Perl data structure. Note that
you have to decode the JSON string manually beforehand.

Canonically specified numerical values like C<{"$numberInt":"23"}> will
be inflated into their respective C<BSON::*> wrapper types. Plain numeric
values will be left as-is.

=head1 FUNCTIONS

=head2 encode

    my $bson = encode({ bar => 'foo' }, \%options);

This is the legacy, functional interface and is only exported on demand.
It takes a hashref and returns a BSON string.
It uses an internal codec singleton with default attributes.

=head2 decode

    my $hash = decode( $bson, \%options );

This is the legacy, functional interface and is only exported on demand.
It takes a BSON string and returns a hashref.
It uses an internal codec singleton with default attributes.

=for Pod::Coverage BUILD

=head1 PERL-BSON TYPE MAPPING

BSON has numerous data types and Perl does not.

When B<decoding>, each BSON type should result in a single, predictable
Perl type.  Where no native Perl type is appropriate, BSON decodes to an
object of a particular class (a "type wrapper").

When B<encoding>, for historical reasons, there may be many Perl
representations that should encode to a particular BSON type.  For example,
all the popular "boolean" type modules on CPAN should encode to the BSON
boolean type.  Likewise, as this module is intended to supersede the
type wrappers that have shipped with the L<MongoDB> module, those
type wrapper are supported by this codec.

The table below describes the BSON/Perl mapping for both encoding and
decoding.

On the left are all the Perl types or classes this BSON codec
knows how to serialize to BSON.  The middle column is the BSON type for
each class.  The right-most column is the Perl type or class that the BSON
type deserializes to.  Footnotes indicate variations or special behaviors.

    Perl type/class ->          BSON type        -> Perl type/class
    -------------------------------------------------------------------
    float[1]                    0x01 DOUBLE         float[2]
    BSON::Double
    -------------------------------------------------------------------
    string[3]                   0x02 UTF8           string[2]
    BSON::String
    -------------------------------------------------------------------
    hashref                     0x03 DOCUMENT       hashref[4][5]
    BSON::Doc
    BSON::Raw
    MongoDB::BSON::Raw[d]
    Tie::IxHash
    -------------------------------------------------------------------
    arrayref                    0x04 ARRAY          arrayref
    -------------------------------------------------------------------
    BSON::Bytes                 0x05 BINARY         BSON::Bytes
    scalarref
    BSON::Binary[d]
    MongoDB::BSON::Binary[d]
    -------------------------------------------------------------------
    n/a                         0x06 UNDEFINED[d]   undef
    -------------------------------------------------------------------
    BSON::OID                   0x07 OID            BSON::OID
    BSON::ObjectId[d]
    MongoDB::OID[d]
    -------------------------------------------------------------------
    boolean                     0x08 BOOL           boolean
    BSON::Bool[d]
    JSON::XS::Boolean
    JSON::PP::Boolean
    JSON::Tiny::_Bool
    Mojo::JSON::_Bool
    Cpanel::JSON::XS::Boolean
    Types::Serialiser::Boolean
    -------------------------------------------------------------------
    BSON::Time                  0x09 DATE_TIME      BSON::Time
    DateTime
    DateTime::Tiny
    Time::Moment
    Mango::BSON::Time
    -------------------------------------------------------------------
    undef                       0x0a NULL           undef
    -------------------------------------------------------------------
    BSON::Regex                 0x0b REGEX          BSON::Regex
    qr// reference
    MongoDB::BSON::Regexp[d]
    -------------------------------------------------------------------
    n/a                         0x0c DBPOINTER[d]   BSON::DBRef
    -------------------------------------------------------------------
    BSON::Code[6]               0x0d CODE           BSON::Code
    MongoDB::Code[6]
    -------------------------------------------------------------------
    n/a                         0x0e SYMBOL[d]      string
    -------------------------------------------------------------------
    BSON::Code[6]               0x0f CODEWSCOPE     BSON::Code
    MongoDB::Code[6]
    -------------------------------------------------------------------
    integer[7][8]               0x10 INT32          integer[2]
    BSON::Int32
    -------------------------------------------------------------------
    BSON::Timestamp             0x11 TIMESTAMP      BSON::Timestamp
    MongoDB::Timestamp[d]
    -------------------------------------------------------------------
    integer[7]                  0x12 INT64          integer[2][9]
    BSON::Int64
    Math::BigInt
    Math::Int64
    -------------------------------------------------------------------
    BSON::MaxKey                0x7F MAXKEY         BSON::MaxKey
    MongoDB::MaxKey[d]
    -------------------------------------------------------------------
    BSON::MinKey                0xFF MINKEY         BSON::MinKey
    MongoDB::MinKey[d]

    [d] Deprecated or soon to be deprecated.
    [1] Scalar with "NV" internal representation or a string that looks
        like a float if the 'prefer_numeric' option is true.
    [2] If the 'wrap_numbers' option is true, numeric types will be wrapped
        as BSON::Double, BSON::Int32 or BSON::Int64 as appropriate to ensure
        round-tripping. If the 'wrap_strings' option is true, strings will
        be wrapped as BSON::String, likewise.
    [3] Scalar without "NV" or "IV" representation and not identified as a
        number by notes [1] or [7].
    [4] If 'ordered' option is set, will return a tied hash that preserves
        order (deprecated 'ixhash' option still works).
    [5] If the document appears to contain a DBRef and a 'dbref_callback'
        exists, that callback is executed with the deserialized document.
    [6] Code is serialized as CODE or CODEWSCOPE depending on whether a
        scope hashref exists in BSON::Code/MongoDB::Code.
    [7] Scalar with "IV" internal representation or a string that looks like
        an integer if the 'prefer_numeric' option is true.
    [8] Only if the integer fits in 32 bits.
    [9] On 32-bit platforms, 64-bit integers are deserialized to
        Math::BigInt objects (even if subsequently wrapped into
        BSON::Int64 if 'wrap_scalars' is true).

=head1 THREADS

Threads are never recommended in Perl, but this module is thread safe.

=head1 ENVIRONMENT

=over 4

=item *

PERL_BSON_BACKEND – if set at compile time, this will be treated as a module name.  The module will be loaded and used as the BSON backend implementation.  It must implement the same API as C<BSON::PP>.

=item *

BSON_EXTJSON - if set, serializing BSON type wrappers via C<TO_JSON> will produce Extended JSON v2 output.

=item *

BSON_EXTJSON_RELAXED - if producing Extended JSON output, if this is true, values will use the "Relaxed" form of Extended JSON, which sacrifices type round-tripping for improved human readability.

=back

=head1 SEMANTIC VERSIONING SCHEME

Starting with BSON C<v0.999.0>, this module is using a "tick-tock"
three-part version-tuple numbering scheme: C<vX.Y.Z>

=over 4

=item *

In stable releases, C<X> will be incremented for incompatible API changes.

=item *

Even-value increments of C<Y> indicate stable releases with new functionality.  C<Z> will be incremented for bug fixes.

=item *

Odd-value increments of C<Y> indicate unstable ("development") releases that should not be used in production.  C<Z> increments have no semantic meaning; they indicate only successive development releases.  Development releases may have API-breaking changes, usually indicated by C<Y> equal to "999".

=back

=head1 HISTORY AND ROADMAP

This module was originally written by Stefan G.  In 2014, he graciously
transferred ongoing maintenance to MongoDB, Inc.

The C<bson_xxxx> helper functions in L<BSON::Types> were inspired by similar
work in L<Mango::BSON> by Sebastian Riedel.

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Stefan G. <minimalist@lavabit.com>

=back

=head1 CONTRIBUTORS

=for stopwords Eric Daniels Finn Olivier Duclos Pat Gunn Petr Písař Robert Sedlacek Thomas Bloor Tobias Leich Wallace Reis Yury Zavarin Oleg Kostyuk

=over 4

=item *

Eric Daniels <eric.daniels@mongodb.com>

=item *

Finn <toyou1995@gmail.com>

=item *

Olivier Duclos <odc@cpan.org>

=item *

Pat Gunn <pgunn@mongodb.com>

=item *

Petr Písař <ppisar@redhat.com>

=item *

Robert Sedlacek <rs@474.at>

=item *

Thomas Bloor <tbsliver@shadow.cat>

=item *

Tobias Leich <email@froggs.de>

=item *

Wallace Reis <wallace@reis.me>

=item *

Yury Zavarin <yury.zavarin@gmail.com>

=item *

Oleg Kostyuk <cub@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Stefan G. and MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__


# vim: set ts=4 sts=4 sw=4 et tw=75:
