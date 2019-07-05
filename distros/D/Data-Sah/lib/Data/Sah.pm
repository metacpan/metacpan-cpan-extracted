package Data::Sah;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.896'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any qw($log);

use Mo qw(build default);

our $Log_Validator_Code = $ENV{LOG_SAH_VALIDATOR_CODE} // 0;

use Data::Sah::Normalize qw(
                       $type_re
                       $clause_name_re
                       $clause_re
                       $attr_re
                       $funcset_re
                       $compiler_re
                       );

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(normalize_schema gen_validator);

# store Data::Sah::Compiler::* instances
has compilers    => (is => 'rw', default => sub { {} });

has _var_enumer  => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        require Language::Expr::Interpreter::VarEnumer;
        Language::Expr::Interpreter::VarEnumer->new;
    },
);

sub normalize_clset {
    require Scalar::Util;

    my $self;
    if (Scalar::Util::blessed($_[0])) {
        $self = shift;
    } else {
        $self = __PACKAGE__->new;
    }

    Data::Sah::Normalize::normalize_clset($_[0]);
}

sub normalize_schema {
    require Scalar::Util;

    my $self;
    if (Scalar::Util::blessed($_[0])) {
        $self = shift;
    } else {
        $self = __PACKAGE__->new;
    }
    my ($s) = @_;

    Data::Sah::Normalize::normalize_schema($_[0]);
}

sub gen_validator {
    require Scalar::Util;

    my $self;
    if (Scalar::Util::blessed($_[0])) {
        $self = shift;
    } else {
        $self = __PACKAGE__->new;
    }
    my ($schema, $opts) = @_;
    my %args = (schema => $schema, %{$opts // {}});
    my $opt_source = delete $args{source};

    $args{log_result} = 1 if $Log_Validator_Code;

    my $pl = $self->get_compiler("perl");
    my $code = $pl->expr_validator_sub(%args);
    return $code if $opt_source;

    my $res = eval $code;
    die "Can't compile validator: $@" if $@;
    $res;
}

sub get_compiler {
    my ($self, $name) = @_;
    return $self->compilers->{$name} if $self->compilers->{$name};

    die "Invalid compiler name `$name`" unless $name =~ $compiler_re;
    my $module = "Data::Sah::Compiler::$name";
    if (!eval "require $module; 1") {
        die "Can't load compiler module $module".($@ ? ": $@" : "");
    }

    my $obj = $module->new(main => $self);
    $self->compilers->{$name} = $obj;

    return $obj;
}

sub normalize_var {
    my ($self, $var, $curpath) = @_;
    die "Not yet implemented";
}

1;
# ABSTRACT: Fast and featureful data structure validation

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah - Fast and featureful data structure validation

=head1 VERSION

This document describes version 0.896 of Data::Sah (from Perl distribution Data-Sah), released on 2019-07-04.

=head1 SYNOPSIS

Non-OO interface:

 use Data::Sah qw(
     normalize_schema
     gen_validator
 );

 my $v;

 # generate a validator for schema
 $v = gen_validator(["int*", min=>1, max=>10]);

 # validate your data using the generated validator
 say "valid" if $v->(5);     # valid
 say "valid" if $v->(11);    # invalid
 say "valid" if $v->(undef); # invalid
 say "valid" if $v->("x");   # invalid

 # generate validator which reports error message string
 $v = gen_validator(["int*", min=>1, max=>10],
                    {return_type=>'str', lang=>'id_ID'});
 # ditto but the error message will be in Indonesian
 $v = gen_validator(["int*", min=>1, max=>10],
                    {return_type=>'str', lang=>'id_ID'});
 say $v->(5);  # ''
 say $v->(12); # 'Data tidak boleh lebih besar dari 10'
               # (in English: 'Data must not be larger than 10')

 # normalize a schema
 my $nschema = normalize_schema("int*"); # => ["int", {req=>1}, {}]
 normalize_schema(["int*", min=>0]); # => ["int", {min=>0, req=>1}, {}]

OO interface (more advanced usage):

 use Data::Sah;
 my $sah = Data::Sah->new;

 # get perl compiler
 my $pl = $sah->get_compiler("perl");

 # compile schema into Perl code
 my $cd = $pl->compile(schema => ["int*", min=>0]);
 say $cd->{result};

will print something like:

 # req #0
 (defined($data))
 &&
 # check type 'int'
 (Scalar::Util::Numeric::isint($data))
 &&
 (# clause: min
 ($data >= 0))

To see the full validator code (with C<sub {}> and all), you can do something
like:

 % LOG_SAH_VALIDATOR_CODE=1 TRACE=1 perl -MLog::ger::LevelFromEnv -MLog::ger::Output=Screen -MData::Sah=gen_validator -E'gen_validator(["int*", min=>0])'

which will print log message like:

 normalized schema=['int',{min => 0,req => 1},{}]
 validator code:
    1|do {
    2|    require Scalar::Util::Numeric;
    3|    sub {
    4|        my ($data) = @_;
    5|        my $_sahv_res =
     |
    7|            # req #0
    8|            (defined($data))
     |
   10|            &&
     |
   12|            # check type 'int'
   13|            (Scalar::Util::Numeric::isint($data))
     |
   15|            &&
     |
   17|            (# clause: min
   18|            ($data >= 0));
     |
   20|        return($_sahv_res);
   21|    }}

=head1 DESCRIPTION

This distribution, C<Data-Sah>, implements compilers for producing Perl and
JavaScript validators, as well as translatable human description text from
L<Sah> schemas. Compiler approach is used instead of interpreter for faster
speed.

The generated validator code can run without the C<Data::Sah::*> modules.

=head1 STATUS

Some features are not implemented yet:

=over

=item * def/subschema

=item * expression

=item * obj: meths, attrs properties

=item * .prio, .err_msg, .ok_err_msg attributes

=item * .result_var attribute

=item * BaseType: if, prefilters, postfilters, check, prop, check_prop clauses

=item * HasElems: each_index, check_each_elem, check_each_index, exists clauses

=item * HasElems: len, elems, indices properties

=item * hash: check_each_key, check_each_value, allowed_keys_re, forbidden_keys_re clauses

=item * array: uniq clauses

=item * human compiler: markdown output

=back

=head1 VARIABLES

=head2 C<$Log_Validator_Code> (bool, default: 0)

=head1 MODULE ORGANIZATION

B<Data::Sah::Type::*> roles specify Sah types, e.g. C<Data::Sah::Type::bool>
specifies the bool type. It can also be used to name distributions that
introduce new types, e.g. C<Data-Sah-Type-complex> which introduces complex
number type.

B<Data::Sah::FuncSet::*> roles specify bundles of functions, e.g.
<Data::Sah::FuncSet::Core> specifies the core/standard functions.

B<Data::Sah::Compiler::$LANG::> namespace is for compilers. Each compiler might
further contain C<::TH::*> (type handler) and C<::FSH::*> (function handler)
subnamespaces to implement appropriate functionalities, e.g.
L<Data::Sah::Compiler::perl::TH::bool> is the bool type handler for the Perl
compiler, L<Data::Sah::Compiler::perl::FSH::Core> is the Core funcset handler
for Perl compiler.

B<Data::Sah::Coerce::$LANG::$TARGET_TYPE::$SOURCE_TYPE_AND_EXTRA_DESCRIPTION>
contains coercion rules.

B<Data::Sah::TypeX::$TYPENAME::$CLAUSENAME> namespace can be used to name
distributions that extend an existing Sah type by introducing a new clause for
it. See L<Data::Sah::Manual::Extending> for an example.

B<Data::Sah::Lang::$LANGCODE> namespaces are for modules that contain
translations. They are further organized according to the organization of other
Data::Sah modules, e.g. L<Data::Sah::Lang::en_US::Type::int> or
C<Data::Sah::Lang::en_US::TypeX::str::is_palindrome>.

B<Sah::Schema::> namespace is reserved for modules that contain bundles of
schemas. For example, C<Sah::Schema::CPANMeta> contains the schema to validate
CPAN META.yml. L<Sah::Schema::Int> contains various schemas for integers such as
C<pos_int>, C<int8>, C<uint32>. L<Sah::Schema::Sah> contains the schema for Sah
schema itself.

B<Sah::SchemaR::> namespace is reserved to store resolved version of schema. For
example, L<Sah::Schema::unix::local_username> contains the definition for the
schema C<unix::local_username> which is C<unix::username> with some additional
coerce rules. C<unix::username> in turn is defined in
L<Sah::Schema::unix::username> which is base type C<str> with some clauses like
minimum and maximum length as well as regular expression for valid pattern. To
find out the base type of a schema (which might be defined based on another
schema), one has to perform one to several lookups to C<Sah::Schema::*> modules.
A C<Sah::SchemaR::*> module, however, contains the "B<r>esolved" version of the
definition, so by looking at L<Sah::SchemaR::unix::local_username> one can know
that the schema eventually is based on the base type C<str>. See
L<Dist::Zilla::Plugin::Sah::Schemas>.

B<Sah::SchemaV::> namespace is reserved to store generated schema validator
code. See L<Dist::Zilla::Plugin::Rinci::GenValidator>.

=head1 FUNCTIONS

None exported by default.

=head2 normalize_schema($schema) => ARRAY

Normalize C<$schema>.

Can also be used as a method.

=head2 gen_validator($schema, \%opts) => CODE (or STR)

Generate validator code for C<$schema>. Can also be used as a method. Known
options (unknown options will be passed to Perl schema compiler):

=over

=item * accept_ref => BOOL (default: 0)

Normally the generated validator accepts data, as in:

 $res = $vdr->($data);
 $res = $vdr->(42);

If this option is set to true, validator accepts reference to data instead, as
in:

 $res = $vdr->(\$data);

This allows $data to be modified by the validator (mainly, to set default value
specified in schema). For example:

 my $data;
 my $vdr = gen_validator([int => {min=>0, max=>10, default=>5}],
                         {accept_ref=>1});
 my $res = $vdr->(\$data);
 say $res;  # => 1 (success)
 say $data; # => 5

=item * source => BOOL (default: 0)

If set to 1, return source code string instead of compiled subroutine. Usually
only needed for debugging (but see also C<$Log_Validator_Code> and
C<LOG_SAH_VALIDATOR_CODE> if you want to log validator source code).

=back

=head1 ATTRIBUTES

=head2 compilers => HASH

A mapping of compiler name and compiler (C<Data::Sah::Compiler::*>) objects.

=head1 METHODS

=head2 new() => OBJ

Create a new Data::Sah instance.

=head2 $sah->get_compiler($name) => OBJ

Get compiler object. C<Data::Sah::Compiler::$name> will be loaded first and
instantiated if not already so. After that, the compiler object is cached.

Example:

 my $plc = $sah->get_compiler("perl"); # loads Data::Sah::Compiler::perl

=head2 $sah->normalize_schema($schema) => HASH

Normalize a schema, e.g. change C<int*> into C<< [int => {req=>1}] >>, as well
as do some sanity checks on it. Returns the normalized schema if succeeds, or
dies on error.

Can also be used as a function.

Note: this functionality is implemented in L<Data::Sah::Normalize> (distributed
separately in Data-Sah-Normalize). Use that module instead if you just need
normalizing schemas, to reduce dependencies.

=head2 $sah->normalize_clset($clset[, \%opts]) => HASH

Normalize a clause set, e.g. change C<< {"!match"=>"abc"} >> into C<<
{"match"=>"abc", "match.op"=>"not"} >>. Produce a shallow copy of the input
clause set hash.

Can also be used as a function.

=head2 $sah->normalize_var($var) => STR

Normalize a variable name in expression into its fully qualified/absolute form.

Not yet implemented (pending specification).

For example:

 [int => {min => 10, 'max=' => '2*$min'}]

$min in the above expression will be normalized as C<schema:clauses.min>.

=head2 $sah->gen_validator($schema, \%opts) => CODE

Use the Perl compiler to generate validator code. Can also be used as a
function. See the documentation as a function for list of known options.

=head1 FAQ

See also L<Sah::FAQ>.

=head2 Comparison to {JSON::Schema, Data::Rx, Data::FormValidator, ...}?

See L<Sah::FAQ>.

=head2 Why is it so slow?

You probably do not reuse the compiled schema, e.g. you continually destroy and
recreate Data::Sah object, or repeatedly recompile the same schema. To gain the
benefit of compilation, you need to keep the compiled result and use the
generated Perl code repeatedly.

=head2 Can I generate another schema dynamically from within the schema?

For example:

 // if first element is an integer, require the array to contain only integers,
 // otherwise require the array to contain only strings.
 ["array", {"min_len": 1, "of=": "[is_int($_[0]) ? 'int':'str']"}]

Currently no, Data::Sah does not support expression on clauses that contain
other schemas. In other words, dynamically generated schemas are not supported.
To support this, if the generated code needs to run independent of Data::Sah, it
needs to contain the compiler code itself (or an interpreter) to compile or
evaluate the generated schema.

However, an C<eval_schema()> Sah function which uses Data::Sah can be trivially
declared and target the Perl compiler.

=head2 How to display the validator code being generated?

Use the C<< source => 1 >> option in C<gen_validator()>.

If you use the OO interface, e.g.:

 # generate perl code
 my $cd = $plc->compile(schema=>..., ...);

then the generated code is in C<< $cd->{result} >> and you can just print it.

If you generate validator using C<gen_validator()>, you can set environment
LOG_SAH_VALIDATOR_CODE or package variable C<$Log_Validator_Code> to true and
the generated code will be logged at trace level using L<Log::ger>. The log can
be displayed using, e.g., L<Log::ger::Output::Screen>:

 % LOG_SAH_VALIDATOR_CODE=1 TRACE=1 \
   perl -MLog::ger::LevelFromEnv -MLog::ger::Output=Screen \
   -MData::Sah=gen_validator -e '$sub = gen_validator([int => min=>1, max=>10])'

Sample output:

 normalized schema=['int',{max => 10,min => 1},{}]
 schema already normalized, skipped normalization
 validator code:
    1|do {
    2|    require Scalar::Util::Numeric;
    3|    sub {
    4|        my ($data) = @_;
    5|        my $_sahv_res =
     |
    7|            # skip if undef
    8|            (!defined($data) ? 1 :
     |
   10|            (# check type 'int'
   11|            (Scalar::Util::Numeric::isint($data))
     |
   13|            &&
     |
   15|            (# clause: min
   16|            ($data >= 1))
     |
   18|            &&
     |
   20|            (# clause: max
   21|            ($data <= 10))));
     |
   23|        return($_sahv_res);
   24|    }}

Lastly, you can also use L<validate-with-sah> CLI utility from the
L<App::SahUtils> distribution (use the C<--show-code> option).

=head2 How to show the validation error message? The validator only returns true/false!

Pass the C<< return_type=>"str" >> to get an error message string on error, or
C<< return_type=>"full" >> to get a hash of detailed error messages. Note also
that the error messages are translateable (e.g. use C<LANG> or C<< lang=>... >>
option. For example:

 my $v = gen_validator([int => between => [1,10]], {return_type=>"str"});
 say "$_: ", $v->($_) for 1, "x", 12;

will output:

 1:
 "x": Input is not of type integer
 12: Must be between 1 and 10

=head2 How to show all the error and warning messages?

If you pass C<< return_type=>"full" >> then the generated validator code can
return a hashref containing all the errors (in the C<errors> key) and warnings
(in the C<warnings> key) instead of just a boolean (when C<< return_type=>"bool"
>>) or a string containing the first encountered error message (when C<<
return_type=>"str" >>) .

=head2 How to get the data value with the default filled in, or coercion done?

If you use C<< return_type=>"full" >>, the generated validator code will also
return the input data after the default is filled in or coercion is done in the
C<value> key of the result hashref. Or, if you do not need a validator that
checks for all errors/warnings, you can use C<< return_type=>"bool+val" >> or
C<< return_type=>"str+val" >>. For example:

 my $v = gen_validator(["date", {"x.perl.coerce_to"=>"DateTime"}],
                       {return_type=>"str+val"});

 my ($err, $val) = @{ $v->("2016-05-14") };

The validator will return an error message string (or an empty string if
validation succeeds) as well as the final value. In the example above, C<$val>
will contain a L<DateTime> object. This is convenient because the final value is
what is usually used further after validation process.

=head2 What does the C<@...> prefix that is sometimes shown on the error message mean?

It shows the path to data item that fails the validation, e.g.:

 my $v = gen_validator([array => of => [int=>min=>5], {return_type=>"str"});
 say $v->([10, 5, "x"]);

prints:

 @[2]: Input is not of type integer

which means that the third element (subscript 2) of the array fails the
validation. Another example:

 my $v = gen_validator([array => of => [hash=>keys=>{a=>"int"}]]);
 say $v->([{}, {a=>1.1}]);

prints:

 @[1][a]: Input is not of type integer

Note that for validator that returns full result hashref (C<<
return_type=>"full" >>) the error messages in the C<errors> key are also keyed
with data path, albeit in a slightly different format (i.e. slash-separated,
e.g. C<2> and C<1/a>) for easier parsing.

=head2 How to show the process of validation by the compiled code?

If you are generating Perl code from schema, you can pass C<< debug=>1 >> option
so the code contains logging (L<Log::ger>-based) and other debugging
information, which you can display. For example:

 % TRACE=1 perl -MLog::ger::LevelFromEnv -MLog::ger::Output=Screen \
   -MData::Sah=gen_validator -E'
   $v = gen_validator([array => of => [hash => {req_keys=>["a"]}]],
                      {return_type=>"str", debug=>1});
   say "Validation result: ", $v->([{a=>1}, "x"]);'

will output:

 ...
 [spath=[]]skip if undef ...
 [spath=[]]check type 'array' ...
 [spath=['of']]clause: {"of":["hash",{"req_keys":["a"]}]} ...
 [spath=['of']]skip if undef ...
 [spath=['of']]check type 'hash' ...
 [spath=['of','req_keys']]clause: {"req_keys":["a"]} ...
 [spath=['of']]skip if undef ...
 [spath=['of']]check type 'hash' ...
 Validation result: [spath=of]@1: Input is not of type hash

=head2 What else can I do with the compiled code?

Data::Sah offers some options in code generation. Beside compiling the validator
code into a subroutine, there are also some other options. Examples:

=over

=item * L<Dist::Zilla::Plugin::Rinci::Validate>

This plugin inserts the generated code (without the C<sub { ... }> wrapper) to
validate the content of C<%args> right before C<# VALIDATE_ARG> or C<#
VALIDATE_ARGS> like below:

 $SPEC{foo} = {
     args => {
         arg1 => { schema => ..., req=>1 },
         arg2 => { schema => ... },
     },
     ...
 };
 sub foo {
     my %args = @_; # VALIDATE_ARGS
 }

The schemas will be retrieved from the Rinci metadata (C<$SPEC{foo}> above).
This means, subroutines in your built distribution will do argument validation.

=item * L<Perinci::Sub::Wrapper>

This module is part of the L<Perinci> family. What the module does is basically
wrap your subroutine with a wrapper code that can include validation code (among
others). This is a convenient way to add argument validation to an existing
subroutine/code.

=back

=head1 ENVIRONMENT

=head2 LOG_SAH_VALIDATOR_CODE => bool

If set to true, will log (using L<Log::ger>, at the trace level) the validator
code being generated. See L</"SYNOPSIS"> or L</"FAQ"> for example on how to see
this log message.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head3 Other compiled validators

=head3 Other interpreted validators

L<Params::Validate> is very fast, although minimal. L<Data::Rx>, L<Kwalify>,
L<Data::Verifier>, L<Data::Validator>, L<JSON::Schema>, L<Validation::Class>.

For Moo/Mouse/Moose stuffs: L<Moose> type system, L<MooseX::Params::Validate>,
L<Type::Tiny>, among others.

Form-oriented: L<Data::FormValidator>, L<FormValidator::Lite>, among others.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
