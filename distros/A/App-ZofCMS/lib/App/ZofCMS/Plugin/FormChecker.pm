package App::ZofCMS::Plugin::FormChecker;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

sub new { bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    return
        unless $template->{plug_form_checker}
            or $config->conf->{plug_form_checker};

    my %conf = (
        trigger => 'plug_form_checker',
        ok_key  => 'd',
        no_fill => 0,
        all_errors => 0,
        fill_prefix => 'plug_form_q_',
        %{ delete $template->{plug_form_checker}     || {} },
        %{ delete $config->conf->{plug_form_checker} || {} },
    );

    return
        unless $query->{ $conf{trigger} };

    $self->template( $template );
    $self->query( $query );
    $self->config( $config );
    $self->plug_conf( \%conf );

    if ( ref $conf{rules} eq 'CODE' ) {
        $conf{rules} = $conf{rules}->( $template, $query, $config )
            or return;
    }

    keys %{ $conf{rules} };
    while ( my ( $param, $rule ) = each %{ $conf{rules} } ) {
        if ( not ref $rule ) {
            $rule = { $rule => 1 };
        }
        elsif ( ref $rule eq 'CODE' ) {
            $rule = { code => $rule };
        }
        elsif ( ref $rule eq 'Regexp' ) {
            $rule = { must_match => $rule };
        }
        elsif ( ref $rule eq 'ARRAY' ) {
            $rule = { map +( $_ => 1 ), @$rule };
        }
        elsif ( ref $rule eq 'SCALAR' ) {
            $rule = { param => $$rule };
        }

        $self->_rule_ok( $param, $rule, $query->{ $param }, $query );
    }

    unless ( $conf{no_fill} ) {
        my @rule_params = keys %{ $conf{rules} };
        my @select_params;
        while ( my ( $key, $value ) = each %{ $conf{rules} } ) {
            if ( ref $value eq 'HASH' and $value->{select} ) {
                push @select_params, $key;
            }
        }
        my @template_keys = map "$conf{fill_prefix}$_", @rule_params;
        @{ $template->{t} }{ @template_keys } = @$query{ @rule_params };
        if ( @select_params ) {
            @{ $template->{t} }{
                map "$conf{fill_prefix}${_}_$query->{$_}", @select_params
            } = (1) x @select_params;
        }
    }

    if ( defined(my $error = $self->_error) ) {
        $template->{t}{plug_form_checker_error} = $error;
        if ( exists $conf{fail_code} ) {
            $conf{fail_code}->( $template, $query, $config, $error );
        }
    }
    else {
        $template->{ $conf{ok_key} }{plug_form_checker_ok} = 1;
        if ( exists $conf{ok_code} ) {
            $conf{ok_code}->( $template, $query, $config );
        }
        if ( exists $conf{ok_redirect} ) {
            print $config->cgi->redirect( $conf{ok_redirect} );
            exit;
        }
    }
}

sub _rule_ok {
    my ( $self, $param, $rule, $value, $query ) = @_;

    my $name = defined $rule->{name} ? $rule->{name} : ucfirst $param;

    unless ( defined $value and length $value ) {
        if ( $rule->{optional} ) {
            if ( $rule->{either_or} ) {
                my $which = ref $rule->{either_or}
                          ? $rule->{either_or}
                          : [ $rule->{either_or} ];

                for ( @$which, $param ) {
                    if ( defined $query->{$_} and length $query->{$_} ) {
                        return 1;
                    }
                }

                return $self->_fail( $name, 'either_or_error', $rule );
            }
            return 1;
        }
        else {
            return $self->_fail( $name, 'mandatory_error', $rule );
        }
    }

    if ( $rule->{num} ) {
        return $self->_fail( $name, 'num_error', $rule )
            if $value =~ /\D/;
    }

    return $self->_fail( $name, 'min_error', $rule )
        if defined $rule->{min}
            and length($value) < $rule->{min};

    return $self->_fail( $name, 'max_error', $rule )
        if defined $rule->{max}
            and length($value) > $rule->{max};

    if ( $rule->{must_match} ) {
        return $self->_fail( $name, 'must_match_error', $rule )
            if $value !~ /$rule->{must_match}/;
    }

    if ( $rule->{must_not_match} ) {
        return $self->_fail( $name, 'must_not_match_error', $rule )
            if $value =~ /$rule->{must_not_match}/;
    }

    if ( $rule->{code} ) {
        return $self->_fail( $name, 'code_error', $rule )
            unless $rule->{code}->( $value, map $self->$_, qw/template query config/ );
    }

    if ( my @values = @{ $rule->{valid_values} || [] } ) {
        my %valid;
        @valid{ @values} = (1) x @values;

        return $self->_fail( $name, 'valid_values_error', $rule )
            unless exists $valid{$value};
    }

    if ( $rule->{param} ) {
        my $param_match = $query->{ $rule->{param} };
        defined $param_match
            or $param_match = '';

        return $self->_fail( $name, 'param_error', $rule )
            unless $value eq $param_match;
    }

    return 1;
}

sub _make_error {
    my ( $self, $name, $err_name, $rule ) = @_;

    return $rule->{ $err_name }
        if exists $rule->{ $err_name };

    my %errors = (
        mandatory_error   => "You must specify parameter $name",
        num_error         => "Parameter $name must contain digits only",
        min_error         => "Parameter $name must be at least $rule->{min} characters long",
        max_error         => "Parameter $name cannot be longer than $rule->{max} characters",
        code_error        => "Parameter $name contains incorrect data",
        must_match_error  => "Parameter $name contains incorrect data",
        must_not_match_error => "Parameter $name contains incorrect data",
        param_error          => "Parameter $name does not match parameter $rule->{param}",
        either_or_error   => "Parameter $name must contain data if other parameters are not set",
        valid_values_error
            => "Parameter $name must be " . do {
                    my $last = pop @{ $rule->{valid_values} || [''] };
                    join(', ', @{ $rule->{valid_values} || [] } ) . " or $last"
        },
    );

    return $errors{ $err_name };
}

sub _fail {
    my ( $self, $name, $err_name, $rule ) = @_;

    push @{ $self->{FAIL} }, $self->_make_error( $name, $err_name, $rule );
    return;
}

sub _error {
    my $self = shift;
    return
        unless defined $self->{FAIL};

    if ( $self->plug_conf->{all_errors} ) {
        my %errors = map +( $_ => 1 ), @{ $self->{FAIL} || [] };
        return [ map +{ error => $_ }, sort keys %errors ];
    }
    else {
        return shift @{ $self->{FAIL} || [] };
    }
}

sub template {
    my $self = shift;
    @_ and $self->{TEMPLATE} = shift;
    return $self->{TEMPLATE};
}

sub config {
    my $self = shift;
    @_ and $self->{CONFIG} = shift;
    return $self->{CONFIG};
}

sub query {
    my $self = shift;
    @_ and $self->{QUERY} = shift;
    return $self->{QUERY};
}
sub plug_conf {
    my $self = shift;
    @_ and $self->{PLUG_CONF} = shift;
    return $self->{PLUG_CONF};
}
1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::FormChecker - plugin to check HTML form data.

=head1 SYNOPSIS

In ZofCMS template or main config file:

    plugins => [ qw/FormChecker/ ],
    plug_form_checker => {
        trigger     => 'some_param',
        ok_key      => 't',
        ok_code     => sub { die "All ok!" },
        fill_prefix => 'form_checker_',
        rules       => {
            param1 => 'num',
            param2 => qr/foo|bar/,
            param3 => [ qw/optional num/ ],
            param4 => {
                optional        => 1,
                select          => 1,
                must_match      => qr/foo|bar/,
                must_not_match  => qr/foos/,
                must_match_error => 'Param4 must contain either foo or bar but not foos',
                param           => 'param2',
            },
            param5 => {
                valid_values        => [ qw/foo bar baz/ ],
                valid_values_error  => 'Param5 must be foo, bar or baz',
            },
            param6 => sub { time() % 2 }, # return true or false values
        },
    },

In your L<HTML::Template> template:

    <tmpl_if name="plug_form_checker_error">
        <p class="error"><tmpl_var name="plug_form_checker_error"></p>
    </tmpl_if>

    <form ......

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides nifteh form checking.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and
L<App::ZofCMS::Template>

=head1 ZofCMS TEMPLATE/MAIN CONFIG FILE FIRST LEVEL KEYS

The keys can be set either in ZofCMS template or in Main Config file, if same keys
are set in both, then the one in ZofCMS template takes precedence.

=head2 C<plugins>

    plugins => [ qw/FormChecker/ ],

You obviously would want to include the plugin in the list of plugins to execute.

=head2 C<plug_form_checker>

    # keys are listed for demostrative purposes,
    # some of these don't make sense when used together
    plug_form_checker => {
        trigger     => 'plug_form_checker',
        ok_key      => 'd',
        ok_redirect => '/some-page',
        fail_code   => sub { die "Not ok!" },
        ok_code     => sub { die "All ok!" },
        no_fill     => 1,
        fill_prefix => 'plug_form_q_',
        rules       => {
            param1 => 'num',
            param2 => qr/foo|bar/,
            param3 => [ qw/optional num/ ],
            param4 => {
                optional        => 1,
                select          => 1,
                must_match      => qr/foo|bar/,
                must_not_match  => qr/foos/,
                must_match_error => 'Param4 must contain either foo or bar but not foos',
            },
            param5 => {
                valid_values        => [ qw/foo bar baz/ ],
                valid_values_error  => 'Param5 must be foo, bar or baz',
            },
            param6 => sub { time() % 2 }, # return true or false values
        },
    },

The C<plug_form_checker> first-level key takes a hashref as a value. Only the
C<rules> key is mandatory, the rest are optional. The possible
keys/values of that hashref are as follows.

=head3 C<trigger>

    trigger => 'plug_form_checker',

B<Optional>. Takes a string as a value that must contain the name of the query
parameter that would trigger checking of the form. Generally, it would be some
parameter of the form you are checking (that would always contain true value, in perl's sense
of true) or you could always use
C<< <input type="hidden" name="plug_form_checker" value="1"> >>. B<Defaults to:>
C<plug_form_checker>

=head3 C<ok_key>

    ok_key => 'd',

B<Optional>. If the form passed all the checks plugin will set a B<second level>
key C<plug_form_checker_ok> to a true value. The C<ok_key> parameter specifies the
B<first level> key in ZofCMS template where to put the C<plug_form_checker> key. For example,
you can set C<ok_key> to C<'t'> and then in your L<HTML::Template> template use
C<< <tmpl_if name="plug_form_checker_ok">FORM OK!</tmpl_if> >>... but, beware of using
the C<'t'> key when you are also using
L<App::ZofCMS::Plugin::QueryToTemplate> plugin, as someone
could avoid proper form checking by passing fake query parameter. B<Defaults to:>
C<d> ("data" ZofCMS template special key).

=head3 C<ok_redirect>

    ok_redirect => '/some-page',

B<Optional>. If specified, the plugin will automatically redirect the user to the
URL specified as a value to C<ok_redirect> key. Note that the plugin will C<exit()> right
after printing the redirect header. B<By default> not specified.

=head3 C<ok_code>

    ok_code => sub {
        my ( $template, $query, $config ) = @_;
        $template->{t}{foo} = "Kewl!";
    }

B<Optional>. Takes a subref as a value. When specfied that subref will be executed if the
form passes all the checks. The C<@_> will contain the following (in that order):
hashref of ZofCMS Template, hashref of query parameters and L<App::ZofCMS::Config> object.
B<By default> is not specified. Note: if you specify C<ok_code> B<and> C<ok_redirect> the
code will be executed and only then user will be redirected.

=head3 C<fail_code>

    fail_code => sub {
        my ( $template, $query, $config, $error ) = @_;
        $template->{t}{foo} = "We got an error: $error";
    }

B<Optional>. Takes a subref as a value. When specfied that subref will be executed if the
form fails any of the checks. The C<@_> will contain the following (in that order):
hashref of ZofCMS Template, hashref of query parameters, L<App::ZofCMS::Config> object and
(if the C<all_errors> is set to a false value) the scalar contain the error that would
also go into C<{t}{plug_form_checker_error}> in
ZofCMS template; if C<all_errors> is set to a true value, than C<$error> will be an arrayref
of hashrefs that have only one key - C<error>, value of which is the error message.
B<By default> is not specified.

=head3 C<all_errors>

    all_errors => 1,

B<Optional>. Takes either true or false values. When set to a false value plugin will
stop processing as soon as it finds the first error and will report it to the user. When
set to a true value will find all errors and report all of them; see C<HTML::Template
VARIABLES> section below for samples. B<Defaults to:> C<0>

=head3 C<no_fill>

    no_fill => 1,

B<Optional>. When set to a true value plugin will not fill query values. B<Defaults to:> C<0>.
When C<no_fill> is set to a B<false> value the plugin will fill in
ZofCMS template's C<{t}> special key with query parameter values (only the ones that you
are checking, though, see C<rules> key below). This allows you to fill your form
with values that user already specified in case the form check failed. The names
of the keys inside the C<{t}> key will be formed as follows:
C<< $prefix . $query_param_name >> where C<$prefix> is the value of C<fill_prefix> key
(see below) and C<$query_param_name> is the name of the query parameter.
Of course, this alone wouldn't cut it for radio buttons or C<< <select> >>
elements. For that, you need to set C<< select => 1 >> in the ruleset for that particular
query parameter (see C<rules> key below); when C<select> rule is set to a true value then
the names of the keys inside the C<{t}> key will be formed as follows:
C<< $prefix . $query_param_name . '_' . $value >>. Where the C<$prefix> is the value
of C<fill_prefix> key, C<$query_param_name> is the name of the query parameter; following
is the underscore (C<_>) and then C<$value> that is the value of the query parameter. Consider
the following snippet in ZofCMS template and corresponding L<HTML::Template> HTML code as
an example:

    plug_form_checker => {
        trigger => 'foo',
        fill_prefix => 'plug_form_q_',
        rules => { foo => { select => 1 } },
    }

    <form action="" method="POST">
        <input type="text" name="bar" value="<tmpl_var name="plug_form_q_">">
        <input type="radio" name="foo" value="1"
            <tmpl_if name="plug_form_q_foo_1"> checked </tmpl_if>
        >
        <input type="radio" name="foo" value="2"
            <tmpl_if name="plug_form_q_foo_2"> checked </tmpl_if>
        >
    </form>

=head3 C<fill_prefix>

    fill_prefix => 'plug_form_q_',

B<Optional>. Specifies the prefix to use for keys in C<{t}> ZofCMS template special key
when C<no_fill> is set to a false value. The "filling" is described above in C<no_fill>
description. B<Defaults to:> C<plug_form_q_> (note the underscore at the very end)

=head3 C<rules>

        rules       => {
            param1 => 'num',
            param2 => qr/foo|bar/,
            param3 => [ qw/optional num/ ],
            param4 => {
                optional        => 1,
                select          => 1,
                must_match      => qr/foo|bar/,
                must_not_match  => qr/foos/,
                must_match_error => 'Param4 must contain either foo or bar but not foos',
            },
            param5 => {
                valid_values        => [ qw/foo bar baz/ ],
                valid_values_error  => 'Param5 must be foo, bar or baz',
            },
            param6 => sub { time() % 2 }, # return true or false values
        },

This is the "heart" of the plugin, the place where you specify the rules for checking.
The C<rules> key takes a hashref or a subref as a value. If the value is a subref,
its C<@_> will contain (in that order) ZofCMS Template hashref, query parameters hashref
and L<App::ZofCMS::Config> object. The return value of the subref will be assigned
to C<rules> parameter and therefore must be a hashref; alternatively the sub may
return an C<undef>, in which case the plugin will stop executing.

The keys of C<rules> hashref are the names
of the query parameters that you wish to check. The values of those keys are the
"rulesets". The values can be either a string, regex (C<qr//>), arrayref, subref, scalarref
or a hashref;
If the value is NOT a hashref it will be changed into hashref
as follows (the actual meaning of resulting hashrefs is described below):

=head4 a string

    param => 'num',
    # same as
    param => { num => 1 },

=head4 a regex

    param => qr/foo/,
    # same as
    param => { must_match => qr/foo/ },

=head4 an arrayref

    param => [ qw/optional num/ ],
    # same as
    param => {
        optional => 1,
        num      => 1,
    },

=head4 a subref

    param => sub { time() % 2 },
    # same as
    param => { code => sub { time() % 2 } },

=head4 a scalarref

    param => \'param2',
    # same as
    param => { param => 'param2' },

=head3 C<rules> RULESETS

The rulesets (values of C<rules> hashref) have keys that define the type of the rule and
value defines diffent things or just indicates that the rule should be considered.
Here is the list of all valid ruleset keys:

    rules => {
        param => {
            name            => 'Parameter', # the name of this param to use in error messages
            num             => 1, # value must be numbers-only
            optional        => 1, # parameter is optional
            either_or       => [ qw/foo bar baz/ ], # param or foo or bar or baz must be set
            must_match      => qr/foo/, # value must match given regex
            must_not_match  => qr/bar/, # value must NOT match the given regex
            max             => 20, # value must not exceed 20 characters in length
            min             => 3,  # value must be more than 3 characters in length
            valid_values    => [ qw/foo bar baz/ ], # value must be one from the given list
            code            => sub { time() %2 }, # return from the sub determines pass/fail
            select          => 1, # flag for "filling", see no_fill key above
            param           => 'param1',
            num_error       => 'Numbers only!', # custom error if num rule failed
            mandatory_error => '', # same for if parameter is missing and not optional.
            must_match_error => '', # same for must_match rule
            must_not_match_error => '', # same for must_not_match_rule
            max_error            => '', # same for max rule
            min_error            => '', # same for min rule
            code_error           => '', # same for code rule
            either_or_error      => '', # same for either_or rule
            valid_values_error   => '', # same for valid_values rule
            param_error          => '', # same fore param rule
        },
    }

You can mix and match the rules for perfect tuning.

=head4 C<name>

    name => 'Decent name',

This is not actually a rule but the text to use for the name of the parameter in error
messages. If not specified the actual parameter name - on which C<ucfirst()> will be run -
will be used.

=head4 C<num>

    num => 1,

When set to a true value the query parameter's value must contain digits only.

=head4 C<optional>

    optional => 1,

When set to a true value indicates that the parameter is optional. Note that you can specify
other rules along with this one, e.g.:

    optional => 1,
    num      => 1,

Means, query parameter is optional, B<but if it is given> it must contain only digits.

=head4 C<either_or>

    optional    => 1, # must use this
    either_or   => 'foo',

    optional    => 1, # must use this
    either_or   => [ qw/foo bar baz/ ],

The C<optional> rul B<must be set to a true value> in order for C<either_or> rule to work.
The rule takes either a string or an arrayref as a value. Specifying a string as a value is
the same as specifying a hashref with just that string in it. Each string in an arrayref
represents the name of a query parameter. In order for the rule to succeed B<either> one
of the parameters must be set. It's a bit messy, but you must use the C<optional> rule
as well as list the C<either_or> rule for every parameter that is tested for "either or" rule.

=head4 C<must_match>

    must_match => qr/foo/,

Takes a regex (C<qr//>) as a value. The query parameter's value must match this regex.

=head4 C<must_not_match>

    must_not_match => qr/bar/,

Takes a regex (C<qr//>) as a value. The query parameter's value must B<NOT> match this regex.

=head4 C<max>

    max => 20,

Takes a positive integer as a value. Query parameter's value must not exceed C<max>
characters in length.

=head4 C<min>

    min => 3,

Takes a positive integer as a value. Query parameter's value must be at least C<min>
characters in length.

=head4 C<valid_values>

    valid_values => [ qw/foo bar baz/ ],

Takes an arrayref as a value. Query parameter's value must be one of the items in the arrayref.

=head4 C<code>

    code => sub { time() %2 },

Here you can let your soul dance to your desire. Takes a subref as a value. The C<@_> will
contain the following (in that order): - the value of the parameter that is being tested,
the hashref of ZofCMS Template, hashref of query parameters and the L<App::ZofCMS::Config>
object. If the sub returns a true value - the check will be considered successfull. If the
sub returns a false value, then test fails and form check stops and errors.

=head4 C<param>

    param => 'param2',

Takes a string as an argument; that string will be interpreted as a name of a query parameter.
Values of the parameter that is currently being inspected and the one given as a value must
match in order for the rule to succeed. The example above indicates that query parameter
C<param> C<eq> query parameter C<param2>.

=head4 C<select>

    select => 1,

This one is not actually a "rule". This is a flag for C<{t}> "filling" that is
described in great detail (way) above under the description of C<no_fill> key.

=head3 CUSTOM ERROR MESSAGES IN RULESETS

All C<*_error> keys take strings as values; they can be used to set custom error
messages for each test in the ruleset. In the defaults listed below under each C<*_error>,
the C<$name> represents either the name of the parameter or the value of C<name> key that
you set in the ruleset.

=head4 C<num_error>

    num_error => 'Numbers only!',

This will be the error to be displayed if C<num> test fails.
B<Defaults to> C<Parameter $name must contain digits only>.

=head4 C<mandatory_error>

    mandatory_error => 'Must gimme!',

This is the error when C<optional> is set to a false value, which is the default, and
user did not specify the query parameter. I.e., "error to display for missing mandatory
parameters". B<Defaults to:> C<You must specify parameter $name>

=head4 C<must_match_error>

    must_match_error => 'Must match me!',

This is the error for C<must_match> rule. B<Defaults to:>
C<Parameter $name contains incorrect data>

=head4 C<must_not_match_error>

    must_not_match_error => 'Cannot has me!',

This is the error for C<must_not_match> rule. B<Defaults to:>
C<Parameter $name contains incorrect data>

=head4 C<max_error>

    max_error => 'Too long!',

This is the error for C<max> rule. B<Defaults to:>
C<Parameter $name cannot be longer than $max characters> where C<$max> is the C<max> rule's
value.

=head4 C<min_error>

    min_error => 'Too short :(',

This is the error for C<min> rule. B<Defaults to:>
C<Parameter $name must be at least $rule->{min} characters long>

=head4 C<code_error>

    code_error => 'No likey 0_o',

This is the error for C<code> rule. B<Defaults to:>
C<Parameter $name contains incorrect data>

=head4 C<either_or_error>

    either_or_error => "You must specify either Foo or Bar",

This is the error for C<either_or> rule.
B<Defaults to:> C<Parameter $name must contain data if other parameters are not set>

=head4 C<valid_values_error>

    valid_values_error => 'Pick the correct one!!!',

This is the error for C<valid_values> rule. B<Defaults to:>
C<Parameter $name must be $list_of_values> where C<$list_of_values> is the list of the
values you specified in the arrayref given to C<valid_values> rule joined by commas and
the last element joined by word "or".

=head4 C<param_error>

    param_error => "Two passwords do not match",

This is the error for C<param> rule. You pretty much always would want to set a custom
error message here as it B<defaults to:> C<< Parameter $name does not match parameter
$rule->{param} >> where C<< $rule->{param} >> is the value you set to C<param> rule.

=head1 HTML::Template VARIABLES

    <tmpl_if name="plug_form_checker_error">
        <p class="error"><tmpl_var name="plug_form_checker_error"></p>
    </tmpl_if>

    # or, if 'all_errors' is turned on:
    <tmpl_if name="plug_form_checker_error">
        <tmpl_loop name="plug_form_checker_error">
            <p class="error"><tmpl_var name="error"></p>
        </tmpl_loop>
    </tmpl_if>

If the form values failed any of your checks, the plugin will set C<plug_form_checker_error>
key in C<{t}> special key explaining the error. If C<all_errors> option is turned on, then
the plugin will set C<plug_form_checker_error> to a data structure that you can feed
into C<< <tmpl_loop name=""> >> where the C<< <tmpl_var name="error"> >> will be replaced
with the error message. The sample usage of this is presented above.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut