package Class::Generate;
$Class::Generate::VERSION = '1.18';
use 5.010;
use strict;
use Carp;
use warnings::register;
use Symbol qw(&delete_package);

BEGIN
{
    use vars qw(@ISA @EXPORT_OK);
    use vars
        qw($save $accept_refs $strict $allow_redefine $class_var $instance_var $check_params $check_code $check_default $nfi $warnings);

    require Exporter;
    @ISA       = qw(Exporter);
    @EXPORT_OK = (
        qw(&class &subclass &delete_class),
        qw($save $accept_refs $strict $allow_redefine $class_var $instance_var $check_params $check_code $check_default $nfi $warnings)
    );

    $accept_refs    = 1;
    $strict         = 1;
    $allow_redefine = 0;
    $class_var      = 'class';
    $instance_var   = 'self';
    $check_params   = 1;
    $check_code     = 1;
    $check_default  = 1;
    $nfi            = 0;
    $warnings       = 1;
}

use vars qw(@_initial_values);  # Holds all initial values passed as references.

my ( $class_name, $class );
my (
    $class_vars,       $use_packages, $excluded_methods,
    $param_style_spec, $default_pss
);
my %class_options;

my $cm;                         # These variables are for error messages.
my $sa_needed = 'must be string or array reference';
my $sh_needed = 'must be string or hash reference';

my $allow_redefine_for_class;

my (
    $initialize,                   # These variables all hold
    $parse_any_flags,              # references to package-local
    $set_class_type,               # subs that other packages
    $parse_class_specification,    # shouldn't call.
    $parse_method_specification,
    $parse_member_specification,
    $set_attributes,
    $class_defined,
    $process_class,
    $store_initial_value_reference,
    $check_for_invalid_parameter_names,
    $constructor_parameter_passing_style,
    $verify_class_type,
    $croak_if_duplicate_names,
    $invalid_spec_message
);

my %valid_option =
    map( substr( $_, 0, 1 ) eq '$' ? ( substr( $_, 1 ) => 1 ) : (),
    @EXPORT_OK );
my %class_to_ref_map = (
    'Class::Generate::Array_Class' => 'ARRAY',
    'Class::Generate::Hash_Class'  => 'HASH'
);
my %warnings_keys = map( ( $_ => 1 ), qw(use no register) );

sub class(%)
{    # One of the three interface
    my %params = @_;    # routines to the package.
    if ( defined $params{-parent} )
    {                   # Defines a class or a
        subclass(@_);    # subclass.
        return;
    }
    &$initialize();
    &$parse_any_flags( \%params );
    croak "Missing/extra arguments to class()" if scalar( keys %params ) != 1;
    ( $class_name, undef ) = %params;
    $cm = qq|Class "$class_name"|;
    &$verify_class_type( $params{$class_name} );
    croak "$cm: A package of this name already exists"
        if !$allow_redefine_for_class && &$class_defined($class_name);
    &$set_class_type( $params{$class_name} );
    &$process_class( $params{$class_name} );
}

sub subclass(%)
{    # One of the three interface
    my %params = @_;    # routines to the package.
    &$initialize();     # Defines a subclass.
    my ( $p_spec, $parent );
    if ( defined( $p_spec = $params{-parent} ) )
    {
        delete $params{-parent};
    }
    else
    {
        croak "Missing subclass parent";
    }
    eval { $parent = Class::Generate::Array->new($p_spec) };
    croak qq|Invalid parent specification ($sa_needed)|
        if $@ || scalar( $parent->values ) == 0;
    &$parse_any_flags( \%params );
    croak "Missing/extra arguments to subclass()"
        if scalar( keys %params ) != 1;
    ( $class_name, undef ) = %params;
    $cm = qq|Subclass "$class_name"|;
    &$verify_class_type( $params{$class_name} );
    croak "$cm: A package of this name already exists"
        if !$allow_redefine_for_class && &$class_defined($class_name);
    my $assumed_type =
        UNIVERSAL::isa( $params{$class_name}, 'ARRAY' ) ? 'ARRAY' : 'HASH';
    my $child_type = lc($assumed_type);

    for my $p ( $parent->values )
    {
        my $c = Class::Generate::Class_Holder::get( $p, $assumed_type );
        croak qq|$cm: Parent package "$p" does not exist| if !defined $c;
        my $parent_type = lc( $class_to_ref_map{ ref $c } );
        croak
"$cm: $child_type-based class must have $child_type-based parent ($p is $parent_type-based)"
            if !UNIVERSAL::isa( $params{$class_name},
            $class_to_ref_map{ ref $c } );
        warnings::warn(
qq{$cm: Parent class "$p" was not defined using class() or subclass(); $child_type reference assumed}
        ) if warnings::enabled() && eval "! exists \$" . $p . '::{_cginfo}';
    }
    &$set_class_type( $params{$class_name}, $parent );
    for my $p ( $parent->values )
    {
        $class->add_parents( Class::Generate::Class_Holder::get($p) );
    }
    &$process_class( $params{$class_name} );
}

sub delete_class(@)
{    # One of the three interface routines
    for my $class (@_)
    {    # to the package.  Deletes a class
        next if !eval '%' . $class . '::';    # declared using Class::Generate.
        if ( !eval '%' . $class . '::_cginfo' )
        {
            croak $class, ': Class was not declared using ', __PACKAGE__;
        }
        delete_package($class);
        Class::Generate::Class_Holder::remove($class);
        my $code_checking_package =
            __PACKAGE__ . '::Code_Checker::check::' . $class . '::';
        if ( eval '%' . $code_checking_package )
        {
            delete_package($code_checking_package);
        }
    }
}

$default_pss = Class::Generate::Array->new('key_value');

$initialize = sub {    # Reset certain variables, and set
    undef $class_vars;    # options to their default values.
    undef $use_packages;
    undef $excluded_methods;
    $param_style_spec = $default_pss;
    %class_options    = (
        virtual       => 0,
        strict        => $strict,
        save          => $save,
        accept_refs   => $accept_refs,
        class_var     => $class_var,
        instance_var  => $instance_var,
        check_params  => $check_params,
        check_code    => $check_code,
        check_default => $check_default,
        nfi           => $nfi,
        warnings      => $warnings
    );
    $allow_redefine_for_class = $allow_redefine;
};

$verify_class_type = sub {    # Ensure that the class specification
    my $spec = $_[0];         # is a hash or array reference.
    return
        if UNIVERSAL::isa( $spec, 'HASH' ) || UNIVERSAL::isa( $spec, 'ARRAY' );
    croak qq|$cm: Elements must be in array or hash reference|;
};

$set_class_type = sub {    # Set $class to the type (array or
    my ( $class_spec, $parent ) = @_;    # hash) appropriate to its declaration.
    my @params = ( $class_name, %class_options );
    if ( UNIVERSAL::isa( $class_spec, 'ARRAY' ) )
    {
        if ( defined $parent )
        {
            my ( $parent_name, @other_array_values ) = $parent->values;
            croak
qq|$cm: An array reference based subclass must have exactly one parent|
                if @other_array_values;
            $parent =
                Class::Generate::Class_Holder::get( $parent_name, 'ARRAY' );
            push @params, ( base_index => $parent->last + 1 );
        }
        $class = Class::Generate::Array_Class->new(@params);
    }
    else
    {
        $class = Class::Generate::Hash_Class->new(@params);
    }
};

my $class_name_regexp = '[A-Za-z_]\w*(::[A-Za-z_]\w*)*';

$parse_class_specification = sub {    # Parse the class' specification,
    my %specs = @_;                   # checking for errors and amalgamating
    my %required;                     # class data.

    if ( defined $specs{new} )
    {
        croak qq|$cm: Specification for "new" must be hash reference|
            unless UNIVERSAL::isa( $specs{new}, 'HASH' );
        my %new_spec =
            %{ $specs{new} };         # Modify %new_spec, not parameter passed
        my $required_items;           # to class() or subclass().
        if ( defined $new_spec{required} )
        {
            eval {
                $required_items =
                    Class::Generate::Array->new( $new_spec{required} );
            };
            croak
qq|$cm: Invalid specification for required constructor parameters ($sa_needed)|
                if $@;
            delete $new_spec{required};
        }
        if ( defined $new_spec{style} )
        {
            eval {
                $param_style_spec =
                    Class::Generate::Array->new( $new_spec{style} );
            };
            croak qq|$cm: Invalid parameter-passing style ($sa_needed)| if $@;
            delete $new_spec{style};
        }
        $class->constructor( Class::Generate::Constructor->new(%new_spec) );
        if ( defined $required_items )
        {
            for ( $required_items->values )
            {
                if (/^\w+$/)
                {
                    croak
qq|$cm: Required params list for constructor contains unknown member "$_"|
                        if !defined $specs{$_};
                    $required{$_} = 1;
                }
                else
                {
                    $class->constructor->add_constraints($_);
                }
            }
        }
    }
    else
    {
        $class->constructor( Class::Generate::Constructor->new );
    }

    my $actual_name;
    for my $member_name ( grep $_ ne 'new', keys %specs )
    {
        $actual_name = $member_name;
        $actual_name =~ s/^&//;
        croak qq|$cm: Invalid member/method name "$actual_name"|
            unless $actual_name =~ /^[A-Za-z_]\w*$/;
        croak qq|$cm: "$instance_var" is reserved|
            unless $actual_name ne $class_options{instance_var};
        if ( substr( $member_name, 0, 1 ) eq '&' )
        {
            &$parse_method_specification( $member_name, $actual_name, \%specs );
        }
        else
        {
            &$parse_member_specification( $member_name, \%specs, \%required );
        }
    }
    $class->constructor->style(&$constructor_parameter_passing_style);
};

$parse_method_specification = sub {
    my ( $member_name, $actual_name, $specs ) = @_;
    my ( %spec, $method );

    eval {
        %spec = %{ Class::Generate::Hash->new( $$specs{$member_name} || die,
                'body' ) };
    };
    croak &$invalid_spec_message( 'method', $actual_name, 'body' ) if $@;

    if ( $spec{class_method} )
    {
        croak qq|$cm: Method "$actual_name": A class method cannot be protected|
            if $spec{protected};
        $method =
            Class::Generate::Class_Method->new( $actual_name, $spec{body} );
        if ( $spec{objects} )
        {
            eval {
                $method->add_objects(
                    ( Class::Generate::Array->new( $spec{objects} ) )->values );
            };
            croak
qq|$cm: Invalid specification for objects of "$actual_name" ($sa_needed)|
                if $@;
        }
        delete $spec{objects} if exists $spec{objects};
    }
    else
    {
        $method = Class::Generate::Method->new( $actual_name, $spec{body} );
    }
    delete $spec{class_method} if exists $spec{class_method};
    $class->user_defined_methods( $actual_name, $method );
    &$set_attributes( $actual_name, $method, 'Method', 'body', \%spec );
};

$parse_member_specification = sub {
    my ( $member_name, $specs, $required ) = @_;
    my ( %spec, $member, %member_params );

    eval {
        %spec = %{ Class::Generate::Hash->new( $$specs{$member_name} || die,
                'type' ) };
    };
    croak &$invalid_spec_message( 'member', $member_name, 'type' ) if $@;

    $spec{required} = 1 if $$required{$member_name};
    if ( exists $spec{default} )
    {
        if ( warnings::enabled() && $class_options{check_default} )
        {
            eval {
                Class::Generate::Support::verify_value( $spec{default},
                    $spec{type} );
            };
            warnings::warn(
                qq|$cm: Default value for "$member_name" is not correctly typed|
            ) if $@;
        }
        &$store_initial_value_reference( \$spec{default}, $member_name )
            if ref $spec{default};
        $member_params{default} = $spec{default};
    }
    %member_params = map defined $spec{$_} ? ( $_ => $spec{$_} ) : (),
        qw(post pre assert);
    if ( $spec{type} =~ m/^[\$@%]?($class_name_regexp)$/o )
    {
        $member_params{base} = $1;
    }
    elsif ( $spec{type} !~ m/^[\$\@\%]$/ )
    {
        croak qq|$cm: Member "$member_name": "$spec{type}" is not a valid type|;
    }
    if ( $spec{required} && ( $spec{private} || $spec{protected} ) )
    {
        warnings::warn(
qq|$cm: "required" attribute ignored for private/protected member "$member_name"|
        ) if warnings::enabled();
        delete $spec{required};
    }
    if ( $spec{private} && $spec{protected} )
    {
        warnings::warn(
qq|$cm: Member "$member_name" declared both private and protected (protected assumed)|
        ) if warnings::enabled();
        delete $spec{private};
    }
    delete @member_params{ grep !defined $member_params{$_},
        keys %member_params };
    if ( substr( $spec{type}, 0, 1 ) eq '@' )
    {
        $member =
            Class::Generate::Array_Member->new( $member_name, %member_params );
    }
    elsif ( substr( $spec{type}, 0, 1 ) eq '%' )
    {
        $member =
            Class::Generate::Hash_Member->new( $member_name, %member_params );
    }
    else
    {
        $member =
            Class::Generate::Scalar_Member->new( $member_name, %member_params );
    }
    delete $spec{type};
    $class->members( $member_name, $member );
    &$set_attributes( $member_name, $member, 'Member', undef, \%spec );
};

$parse_any_flags = sub {
    my $params = $_[0];
    my %flags  = map substr( $_, 0, 1 ) eq '-' ? ( $_ => $$params{$_} ) : (),
        keys %$params;
    return if !%flags;
flag:
    while ( my ( $flag, $value ) = each %flags )
    {
        $flag eq '-use' and do
        {
            eval { $use_packages = Class::Generate::Array->new($value) };
            croak qq|"-use" flag $sa_needed| if $@;
            next flag;
        };
        $flag eq '-class_vars' and do
        {
            eval { $class_vars = Class::Generate::Array->new($value) };
            croak qq|"-class_vars" flag $sa_needed| if $@;
            for my $var_spec ( grep ref($_), $class_vars->values )
            {
                croak 'Each class variable must be scalar or hash reference'
                    unless UNIVERSAL::isa( $var_spec, 'HASH' );
                for my $var ( grep ref( $$var_spec{$_} ), keys %$var_spec )
                {
                    &$store_initial_value_reference( \$$var_spec{$var}, $var );
                }
            }
            next flag;
        };
        $flag eq '-virtual' and do
        {
            $class_options{virtual} = $value;
            next flag;
        };
        $flag eq '-exclude' and do
        {
            eval { $excluded_methods = Class::Generate::Array->new($value) };
            croak qq|"-exclude" flag $sa_needed| if $@;
            next flag;
        };
        $flag eq '-comment' and do
        {
            $class_options{comment} = $value;
            next flag;
        };
        $flag eq '-options' and do
        {
            croak qq|Options must be in hash reference|
                unless UNIVERSAL::isa( $value, 'HASH' );
            if ( exists $$value{allow_redefine} )
            {
                $allow_redefine_for_class = $$value{allow_redefine};
                delete $$value{allow_redefine};
            }
        option:
            while ( my ( $o, $o_value ) = each %$value )
            {
                if ( !$valid_option{$o} )
                {
                    warnings::warn(qq|Unknown option "$o" ignored|)
                        if warnings::enabled();
                    next option;
                }
                $class_options{$o} = $o_value;
            }

            if ( exists $class_options{warnings} )
            {
                my $w = $class_options{warnings};
                if ( ref $w )
                {
                    croak 'Warnings must be scalar value or array reference'
                        unless UNIVERSAL::isa( $w, 'ARRAY' );
                    croak
'Warnings array reference must have even number of elements'
                        unless $#$w % 2 == 1;
                    for ( my $i = 0 ; $i <= $#$w ; $i += 2 )
                    {
                        croak qq|Warnings array: Unknown key "$$w[$i]"|
                            unless exists $warnings_keys{ $$w[$i] };
                    }
                }
            }

            next flag;
        };
        warnings::warn(qq|Unknown flag "$flag" ignored|) if warnings::enabled();
    }
    delete @$params{ keys %flags };
};

# Set the appropriate attributes of
$set_attributes = sub {    # a member or method w.r.t. a class.
    my ( $name, $m, $type, $exclusion, $spec ) = @_;
    for my $attr (
        defined $exclusion
        ? grep( $_ ne $exclusion, keys %$spec )
        : keys %$spec
        )
    {
        if ( $m->can($attr) )
        {
            $m->$attr( $$spec{$attr} );
        }
        elsif ( $class->can($attr) )
        {
            $class->$attr( $name, $$spec{$attr} );
        }
        else
        {
            warnings::warn(qq|$cm: $type "$name": Unknown attribute "$attr"|)
                if warnings::enabled();
        }
    }
};

my $containing_package = __PACKAGE__ . '::';
my $initial_value_form = $containing_package . '_initial_values';

$store_initial_value_reference = sub {    # Store initial values that are
    my ( $default_value, $var_name ) = @_;     # references in an accessible
    push @_initial_values, $$default_value;    # place.
    $$default_value = "\$$initial_value_form" . "[$#_initial_values]";
    warnings::warn(qq|Cannot save reference as initial value for "$var_name"|)
        if $class_options{save} && warnings::enabled();
};

$class_defined = sub {    # Return TRUE if the argument
    my $class_name = $_[0];    # is the name of a Perl package.
    return eval '%' . $class_name . '::';
};

# Do the main work of processing a class.
$process_class = sub {    # Parse its specification, generate a
    my $class_spec = $_[0];    # form, and evaluate that form.
    my ( @warnings, $errors );
    &$croak_if_duplicate_names($class_spec);
    for my $var ( grep defined $class_options{$_}, qw(instance_var class_var) )
    {
        croak
            qq|$cm: Value of $var option must be an identifier (without a "\$")|
            unless $class_options{$var} =~ /^[A-Za-z_]\w*$/;
    }
    &$parse_class_specification(
        UNIVERSAL::isa( $class_spec, 'ARRAY' ) ? @$class_spec : %$class_spec );
    Class::Generate::Member_Names::set_element_regexps();
    $class->add_class_vars( $class_vars->values )     if $class_vars;
    $class->add_use_packages( $use_packages->values ) if $use_packages;
    $class->warnings( $class_options{warnings} ) if $class_options{warnings};
    $class->check_params( $class_options{check_params} )
        if $class_options{check_params};
    $class->excluded_methods_regexp( join '|', map "(?:$_)",
        $excluded_methods->values )
        if $excluded_methods;

    if ( warnings::enabled() && $class_options{check_code} )
    {
        Class::Generate::Code_Checker::check_user_defined_code( $class, $cm,
            \@warnings, \$errors );
        for my $warning (@warnings)
        {
            warnings::warn($warning);
        }
        warnings::warn($errors) if $errors;
    }

    my $form = $class->form;
    if ( $class_options{save} )
    {
        my ( $class_file, $ob, $cb );
        if ( $class_options{save} =~ /\.p[ml]$/ )
        {
            $class_file = $class_options{save};
            open CLASS_FILE, ">>$class_file"
                or croak qq|$cm: Cannot append to "$class_file": $!|;
            $ob = "{\n";    # The form is enclosed in braces to prevent
            $cb = "}\n";    # renaming duplicate "my" variables.
        }
        else
        {
            $class_file = $class_name . '.pm';
            $class_file =~ s|::|/|g;
            open CLASS_FILE, ">$class_file"
                or croak qq|$cm: Cannot save to "$class_file": $!|;
            $ob = $cb = '';
        }
        $form =~
s/^(my [%@\$]\w+) = ([%@]\{)?\$$initial_value_form\[\d+\]\}?;/$1;/mgo;
        print CLASS_FILE $ob, $form, $cb, "\n1;\n";
        close CLASS_FILE;
    }
    croak "$cm: Cannot continue after errors" if $errors;
    {
        local $SIG{__WARN__} = sub { };    # Warnings have been reported during
        eval $form;                        # user-defined code analysis.
        if ($@)
        {
            my @lines = split( "\n", $form );
            my ($l) = ( $@ =~ /(\d+)\.$/ );
            $@ =~ s/\(eval \d+\) //;
            croak "$cm: Evaluation failed (problem in ", __PACKAGE__, "?)\n",
                $@, "\n", join( "\n", @lines[ $l - 1 .. $l + 1 ] ), "\n";
        }
    }
    Class::Generate::Class_Holder::store($class);
};

$constructor_parameter_passing_style =
    sub {    # Establish the parameter-passing style
    my (
        $style,                      # for a class' constructor, meanwhile
        @values,                     # checking for mismatches w.r.t. the
        $parent_with_constructor,    # class' superclass. Return an
        $parent_constructor_package_name
    );                               # appropriate style.
    if ( defined $class->parents )
    {
        $parent_with_constructor =
            Class::Generate::Support::class_containing_method( 'new', $class );
        $parent_constructor_package_name = (
            ref $parent_with_constructor
            ? $parent_with_constructor->name
            : $parent_with_constructor
        );
    }
    ( ( $style, @values ) = $param_style_spec->values )[0] eq 'key_value'
        and do
    {
        if (   defined $parent_with_constructor
            && ref $parent_with_constructor
            && index( ref $parent_with_constructor, $containing_package ) == 0 )
        {
            my $invoked_constructor_style =
                $parent_with_constructor->constructor->style;
            unless (
                $invoked_constructor_style->isa(
                    $containing_package . 'Key_Value'
                )
                || $invoked_constructor_style->isa(
                    $containing_package . 'Own' )
                )
            {
                warnings::warn(
qq{$cm: Probable mismatch calling constructor in superclass "$parent_constructor_package_name"}
                ) if warnings::enabled();
            }
        }
        return Class::Generate::Key_Value->new( 'params',
            $class->public_member_names );
    };
    $style eq 'positional' and do
    {
        &$check_for_invalid_parameter_names(@values);
        my @member_names = $class->public_member_names;
        croak "$cm: Missing/extra members in style"
            unless $#values == $#member_names;

        return Class::Generate::Positional->new(@values);
    };
    $style eq 'mix' and do
    {
        &$check_for_invalid_parameter_names(@values);
        my @member_names = $class->public_member_names;
        croak "$cm: Extra parameters in style specifier"
            unless $#values <= $#member_names;
        my %kv_members = map( ( $_ => 1 ), @member_names );
        delete @kv_members{@values};
        return Class::Generate::Mix->new( 'params', [@values],
            keys %kv_members );
    };
    $style eq 'own' and do
    {
        for ( my $i = 0 ; $i <= $#values ; $i++ )
        {
            &$store_initial_value_reference( \$values[$i],
                $parent_constructor_package_name . '::new' )
                if ref $values[$i];
        }
        return Class::Generate::Own->new( [@values] );
    };
    croak qq|$cm: Invalid parameter passing style "$style"|;
    };

$check_for_invalid_parameter_names = sub {
    my @param_names = @_;
    my $i           = 0;
    for my $param (@param_names)
    {
        croak
qq|$cm: Error in new => { style => '... $param' }: $param is not a member|
            if !defined $class->members($param);
        croak
qq|$cm: Error in new => { style => '... $param' }: $param is not a public member|
            if $class->private($param) || $class->protected($param);
    }
    my %uses;
    for my $param (@param_names)
    {
        $uses{$param}++;
    }
    %uses = map( ( $uses{$_} > 1 ? ( $_ => $uses{$_} ) : () ), keys %uses );
    if (%uses)
    {
        croak "$cm: Error in new => { style => '...' }: ",
            join( '; ', map qq|Name "$_" used $uses{$_} times|, keys %uses );
    }
};

$croak_if_duplicate_names = sub {
    my $class_spec = $_[0];
    my ( @names, %uses );
    if ( UNIVERSAL::isa( $class_spec, 'ARRAY' ) )
    {
        for ( my $i = 0 ; $i <= $#$class_spec ; $i += 2 )
        {
            push @names, $$class_spec[$i];
        }
    }
    else
    {
        @names = keys %$class_spec;
    }
    for (@names)
    {
        $uses{ substr( $_, 0, 1 ) eq '&' ? substr( $_, 1 ) : $_ }++;
    }
    %uses = map( ( $uses{$_} > 1 ? ( $_ => $uses{$_} ) : () ), keys %uses );
    if (%uses)
    {
        croak "$cm: ",
            join( '; ', map qq|Name "$_" used $uses{$_} times|, keys %uses );
    }
};

$invalid_spec_message = sub {
    return
        sprintf
        qq|$cm: Invalid specification of %s "%s" ($sh_needed with "%s" key)|,
        @_;
};

package Class::Generate::Class_Holder;    # This package encapsulates functions
$Class::Generate::Class_Holder::VERSION = '1.18';
use strict;    # related to storing and retrieving
               # information on classes.  It lets classes
               # saved in files be reused transparently.
my %classes;

sub store($)
{    # Given a class, store it so it's
    my $class = $_[0];                    # accessible in future invocations of
    $classes{ $class->name } = $class;    # class() and subclass().
}

# Given a class name, try to return an instance of Class::Generate::Class
# that models the class.  The instance comes from one of 3 places.  We
# first try to get it from wherever store() puts it.  If that fails,
# we check to see if the variable %<class_name>::_cginfo exists (see
# form(), below); if it does, we use the information it contains to
# create an instance of Class::Generate::Class.  If %<class_name>::_cginfo
# doesn't exist, the package wasn't created by Class::Generate.  We try
# to infer some characteristics of the class.
sub get($;$)
{
    my ( $class_name, $default_type ) = @_;
    return $classes{$class_name} if exists $classes{$class_name};

    return undef if !eval '%' . $class_name . '::';    # Package doesn't exist.

    my ( $class, %info );
    if ( !eval "exists \$" . $class_name . '::{_cginfo}' )
    {                                                  # Package exists but is
        return undef if !defined $default_type;        # not a class generated
        if ( $default_type eq 'ARRAY' )
        {                                              # by Class::Generate.
            $class = new Class::Generate::Array_Class $class_name;
        }
        else
        {
            $class = new Class::Generate::Hash_Class $class_name;
        }
        $class->constructor( new Class::Generate::Constructor );
        $class->constructor->style( new Class::Generate::Own );
        $classes{$class_name} = $class;
        return $class;
    }

    eval '%info = %' . $class_name . '::_cginfo';
    if ( $info{base} eq 'ARRAY' )
    {
        $class = Class::Generate::Array_Class->new( $class_name,
            last => $info{last} );
    }
    else
    {
        $class = Class::Generate::Hash_Class->new($class_name);
    }
    if ( exists $info{members} )
    {    # Add members ...
        while ( my ( $name, $mem_info_ref ) = each %{ $info{members} } )
        {
            my ( $member, %mem_info );
            %mem_info = %$mem_info_ref;
        DEFN:
            {
                $mem_info{type} eq "\$" and do
                {
                    $member = Class::Generate::Scalar_Member->new($name);
                    last DEFN;
                };
                $mem_info{type} eq '@' and do
                {
                    $member = Class::Generate::Array_Member->new($name);
                    last DEFN;
                };
                $mem_info{type} eq '%' and do
                {
                    $member = Class::Generate::Hash_Member->new($name);
                    last DEFN;
                };
            }
            $member->base( $mem_info{base} ) if exists $mem_info{base};
            $class->members( $name, $member );
        }
    }
    if ( exists $info{class_methods} )
    {    # Add methods...
        for my $name ( @{ $info{class_methods} } )
        {
            $class->user_defined_methods( $name,
                Class::Generate::Class_Method->new($name) );
        }
    }
    if ( exists $info{instance_methods} )
    {
        for my $name ( @{ $info{instance_methods} } )
        {
            $class->user_defined_methods( $name,
                Class::Generate::Method->new($name) );
        }
    }
    if ( exists $info{protected} )
    {    # Set access ...
        for my $protected_member ( @{ $info{protected} } )
        {
            $class->protected( $protected_member, 1 );
        }
    }
    if ( exists $info{private} )
    {
        for my $private_member ( @{ $info{private} } )
        {
            $class->private( $private_member, 1 );
        }
    }
    $class->excluded_methods_regexp( $info{emr} ) if exists $info{emr};
    $class->constructor( new Class::Generate::Constructor );
CONSTRUCTOR_STYLE:
    {
        exists $info{kv_style} and do
        {
            $class->constructor->style( new Class::Generate::Key_Value 'params',
                @{ $info{kv_style} } );
            last CONSTRUCTOR_STYLE;
        };
        exists $info{pos_style} and do
        {
            $class->constructor->style(
                new Class::Generate::Positional( @{ $info{pos_style} } ) );
            last CONSTRUCTOR_STYLE;
        };
        exists $info{mix_style} and do
        {
            $class->constructor->style(
                new Class::Generate::Mix(
                    'params',
                    [ @{ $info{mix_style}{keyed} } ],
                    @{ $info{mix_style}{pos} }
                )
            );
            last CONSTRUCTOR_STYLE;
        };
        exists $info{own_style} and do
        {
            $class->constructor->style(
                new Class::Generate::Own( @{ $info{own_style} } ) );
            last CONSTRUCTOR_STYLE;
        };
    }

    $classes{$class_name} = $class;
    return $class;
}

sub remove($)
{
    delete $classes{ $_[0] };
}

sub form($)
{
    my $class = $_[0];
    my $form  = qq|use vars qw(\%_cginfo);\n| . '%_cginfo = (';
    if ( $class->isa('Class::Generate::Array_Class') )
    {
        $form .= q|base => 'ARRAY', last => | . $class->last;
    }
    else
    {
        $form .= q|base => 'HASH'|;
    }

    if ( my @members = $class->members_values )
    {
        $form .= ', members => { '
            . join( ', ', map( member($_), @members ) ) . ' }';
    }
    my ( @class_methods, @instance_methods );
    for my $m ( $class->user_defined_methods_values )
    {
        if ( $m->isa('Class::Generate::Class_Method') )
        {
            push @class_methods, $m->name;
        }
        else
        {
            push @instance_methods, $m->name;
        }
    }
    $form .= comma_prefixed_list_of_values( 'class_methods', @class_methods );
    $form .=
        comma_prefixed_list_of_values( 'instance_methods', @instance_methods );
    $form .= comma_prefixed_list_of_values(
        'protected',
        do { my %p = $class->protected; keys %p }
    );
    $form .= comma_prefixed_list_of_values(
        'private',
        do { my %p = $class->private; keys %p }
    );

    if ( my $emr = $class->excluded_methods_regexp )
    {
        $emr =~ s/\'/\\\'/g;
        $form .= ", emr => '$emr'";
    }
    if ( ( my $constructor = $class->constructor ) )
    {
        my $style = $constructor->style;
    STYLE:
        {
            $style->isa('Class::Generate::Key_Value') and do
            {
                my @kpn = $style->keyed_param_names;
                if (@kpn)
                {
                    $form .= comma_prefixed_list_of_values( 'kv_style',
                        $style->keyed_param_names );
                }
                else
                {
                    $form .= ', kv_style => []';
                }
                last STYLE;
            };
            $style->isa('Class::Generate::Positional') and do
            {
                my @members = sort { $style->order($a) <=> $style->order($b) }
                    do { my %m = $style->order; keys %m };
                if (@members)
                {
                    $form .=
                        comma_prefixed_list_of_values( 'pos_style', @members );
                }
                else
                {
                    $form .= ', pos_style => []';
                }
                last STYLE;
            };
            $style->isa('Class::Generate::Mix') and do
            {
                my @keyed_members = $style->keyed_param_names;
                my @pos_members =
                    sort { $style->order($a) <=> $style->order($b) }
                    do { my %m = $style->order; keys %m };
                if ( @keyed_members || @pos_members )
                {
                    my $km_form = list_of_values( 'keyed', @keyed_members );
                    my $pm_form = list_of_values( 'pos',   @pos_members );
                    $form .=
                        ', mix_style => {'
                        . join( ', ',
                        grep( length > 0, ( $km_form, $pm_form ) ) )
                        . '}';
                }
                else
                {
                    $form .= ', mix_style => {}';
                }
                last STYLE;
            };
            $style->isa('Class::Generate::Own') and do
            {
                my @super_values = $style->super_values;
                if (@super_values)
                {
                    for my $sv (@super_values)
                    {
                        $sv =~ s/\'/\\\'/g;
                    }
                    $form .= comma_prefixed_list_of_values( 'own_style',
                        @super_values );
                }
                else
                {
                    $form .= ', own_style => []';
                }
                last STYLE;
            };
        }
    }
    $form .= ');' . "\n";
    return $form;
}

sub member($)
{
    my $member = $_[0];
    my $base;
    my $form = $member->name . ' => {';
    $form .= " type => '"
        . (
          $member->isa('Class::Generate::Scalar_Member') ? "\$"
        : $member->isa('Class::Generate::Array_Member')  ? '@'
        :                                                  '%'
        ) . "'";
    if ( defined( $base = $member->base ) )
    {
        $form .= ", base => '$base'";
    }
    return $form . '}';
}

sub list_of_values($@)
{
    my ( $key, @list ) = @_;
    return '' if !@list;
    return "$key => [" . join( ', ', map( "'$_'", @list ) ) . ']';
}

sub comma_prefixed_list_of_values($@)
{
    return $#_ > 0 ? ', ' . list_of_values( $_[0], @_[ 1 .. $#_ ] ) : '';
}

package Class::Generate::Member_Names;    # This package encapsulates functions
$Class::Generate::Member_Names::VERSION = '1.18';
use strict;                               # to handle name substitution in
                                          # user-defined code.

my (
    $member_regexp,      # Regexp of accessible members.
    $accessor_regexp,    # Regexp of accessible member accessors (x_size, etc.).
    $user_defined_methods_regexp
    ,                    # Regexp of accessible user-defined instance methods.
    $nonpublic_member_regexp
    , # (For class methods) Regexp of accessors for protected and private members.
    $private_class_methods_regexp
);    # (Ditto) Regexp of private class methods.

sub accessible_member_regexps($;$);
sub accessible_members($;$);
sub accessible_accessor_regexps($;$);
sub accessible_user_defined_method_regexps($;$);
sub class_of($$;$);
sub member_index($$);

sub set_element_regexps()
{    # Establish the regexps for
    my @names;    # name substitution.

    # First for members...
    @names = accessible_member_regexps($class);
    if ( !@names )
    {
        undef $member_regexp;
    }
    else
    {
        $member_regexp = '(?:\b(?:my|local)\b[^=;()]+)?('
            . join( '|', sort { length $b <=> length $a } @names ) . ')\b';
    }

    # Next for accessors (e.g., x_size)...
    @names = accessible_accessor_regexps($class);
    if ( !@names )
    {
        undef $accessor_regexp;
    }
    else
    {
        $accessor_regexp = '&('
            . join( '|', sort { length $b <=> length $a } @names )
            . ')\b(?:\s*\()?';
    }

    # Next for user-defined instance methods...
    @names = accessible_user_defined_method_regexps($class);
    if ( !@names )
    {
        undef $user_defined_methods_regexp;
    }
    else
    {
        $user_defined_methods_regexp = '&('
            . join( '|', sort { length $b <=> length $a } @names )
            . ')\b(?:\s*\()?';
    }

# Next for protected and private members, and instance methods in class methods...
    if ( $class->class_methods )
    {
        @names = (
            map( $_->accessor_names( $class, $_->name ),
                grep $class->protected( $_->name )
                    || $class->private( $_->name ),
                $class->members_values ),
            grep( $class->private($_) || $class->protected($_),
                map( $_->name, $class->instance_methods ) )
        );
        if ( !@names )
        {
            undef $nonpublic_member_regexp;
        }
        else
        {
            $nonpublic_member_regexp =
                join( '|', sort { length $b <=> length $a } @names );
        }
    }
    else
    {
        undef $nonpublic_member_regexp;
    }

    # Finally for private class methods invoked from class and instance methods.
    if (
        my @private_class_methods =
        grep $_->isa('Class::Generate::Class_Method')
        && $class->private( $_->name ), $class->user_defined_methods
        )
    {
        $private_class_methods_regexp =
              $class->name
            . '\s*->\s*('
            . join( '|', map $_->name, @private_class_methods ) . ')'
            . '(\s*\((?:\s*\))?)?';
    }
    else
    {
        undef $private_class_methods_regexp;
    }
}

sub substituted($)
{    # Within a code fragment, replace
    my $code = $_[0];    # member names and accessors with the
                         # appropriate forms.
    $code =~ s/$member_regexp/member_invocation($1, $&)/eg
        if defined $member_regexp;
    $code =~ s/$accessor_regexp/accessor_invocation($1, $+, $&)/eg
        if defined $accessor_regexp;
    $code =~ s/$user_defined_methods_regexp/accessor_invocation($1, $1, $&)/eg
        if defined $user_defined_methods_regexp;
    $code =~
s/$private_class_methods_regexp/nonpublic_method_invocation("'" . $class->name . "'", $1, $2)/eg
        if defined $private_class_methods_regexp;
    return $code;
}

# Perform the actual substitution
sub member_invocation($$)
{    # for member references.
    my ( $member_reference, $match ) = @_;
    my ( $name, $type, $form, $index );
    return $member_reference
        if $match =~ /\A(?:my|local)\b[^=;()]+$member_reference$/s;
    $member_reference =~ /^(\W+)(\w+)$/;
    $name = $2;
    return $member_reference
        if !defined( $index = member_index( $class, $name ) );
    $type = $1;
    $form = $class->instance_var . '->' . $index;
    return $type eq '$' ? $form : $type . '{' . $form . '}';
}

# Perform the actual substitution for
sub accessor_invocation($$$)
{    # accessor and user-defined method references.
    my ( $accessor_name, $element_name, $match ) = @_;
    my $prefix = $class->instance_var . '->';
    my $c      = class_of( $element_name, $class );
    if ( !( $c->protected($element_name) || $c->private($element_name) ) )
    {
        return
              $prefix
            . $accessor_name
            . ( substr( $match, -1 ) eq '(' ? '(' : '' );
    }
    if ( $c->private($element_name) || $c->name eq $class->name )
    {
        return "$prefix\$$accessor_name(" if substr( $match, -1 ) eq '(';
        return "$prefix\$$accessor_name()";
    }
    my $form =
          "&{$prefix"
        . $class->protected_members_info_index
        . qq|->{'$accessor_name'}}(|;
    $form .= $class->instance_var . ',';
    return substr( $match, -1 ) eq '(' ? $form : $form . ')';
}

sub substituted_in_class_method
{
    my $method = $_[0];
    my ( @objs, $code, @private_class_methods );
    $code = $method->body;
    if ( defined $nonpublic_member_regexp && ( @objs = $method->objects ) )
    {
        my $nonpublic_member_invocation_regexp = '('
            . join( '|', map( quotemeta($_), @objs ) ) . ')'
            . '\s*->\s*('
            . $nonpublic_member_regexp . ')'
            . '(\s*\((?:\s*\))?)?';
        $code =~
s/$nonpublic_member_invocation_regexp/nonpublic_method_invocation($1, $2, $3)/ge;
    }
    if ( defined $private_class_methods_regexp )
    {
        $code =~
s/$private_class_methods_regexp/nonpublic_method_invocation("'" . $class->name . "'", $1, $2)/ge;
    }
    return $code;
}

sub nonpublic_method_invocation
{    # Perform the actual
    my ( $object, $nonpublic_member, $paren_matter ) = @_;    # substitution for
    my $form = '&$' . $nonpublic_member . '(' . $object;  # nonpublic method and
    if ( defined $paren_matter )
    {                                                     # member references.
        if ( index( $paren_matter, ')' ) != -1 )
        {
            $form .= ')';
        }
        else
        {
            $form .= ', ';
        }
    }
    else
    {
        $form .= ')';
    }
    return $form;
}

sub member_index($$)
{
    my ( $class, $member_name ) = @_;
    return $class->index($member_name) if defined $class->members($member_name);
    for my $parent ( grep ref $_, $class->parents )
    {
        my $index = member_index( $parent, $member_name );
        return $index if defined $index;
    }
    return undef;
}

sub accessible_member_regexps($;$)
{
    my ( $class, $disallow_private_members ) = @_;
    my @members;
    if ($disallow_private_members)
    {
        @members = grep !$class->private( $_->name ), $class->members_values;
    }
    else
    {
        @members = $class->members_values;
    }
    return (
        map( $_->method_regexp($class), @members ),
        map( accessible_member_regexps( $_, 1 ),
            grep( ref $_, $class->parents ) )
    );
}

sub accessible_members($;$)
{
    my ( $class, $disallow_private_members ) = @_;
    my @members;
    if ($disallow_private_members)
    {
        @members = grep !$class->private( $_->name ), $class->members_values;
    }
    else
    {
        @members = $class->members_values;
    }
    return ( @members,
        map( accessible_members( $_, 1 ), grep( ref $_, $class->parents ) ) );
}

sub accessible_accessor_regexps($;$)
{
    my ( $class, $disallow_private_members ) = @_;
    my ( $member_name, @accessor_names );
    for my $member ( $class->members_values )
    {
        next
            if $class->private( $member_name = $member->name )
            && $disallow_private_members;
        for my $accessor_name ( grep $class->include_method($_),
            $member->accessor_names( $class, $member_name ) )
        {
            $accessor_name =~ s/$member_name/($&)/;
            push @accessor_names, $accessor_name;
        }
    }
    return (
        @accessor_names,
        map( accessible_accessor_regexps( $_, 1 ),
            grep( ref $_, $class->parents ) )
    );
}

sub accessible_user_defined_method_regexps($;$)
{
    my ( $class, $disallow_private_methods ) = @_;
    return (
        (
            $disallow_private_methods
            ? grep !$class->private($_),
            $class->user_defined_methods_keys
            : $class->user_defined_methods_keys
        ),
        map( accessible_user_defined_method_regexps( $_, 1 ),
            grep( ref $_, $class->parents ) )
    );
}

# Given element E and class C, return C if E is an
sub class_of($$;$)
{    # element of C; if not, search parents recursively.
    my ( $element_name, $class, $disallow_private_members ) = @_;
    return $class
        if ( defined $class->members($element_name)
        || defined $class->user_defined_methods($element_name) )
        && ( !$disallow_private_members || !$class->private($element_name) );
    for my $parent ( grep ref $_, $class->parents )
    {
        my $c = class_of( $element_name, $parent, 1 );
        return $c if defined $c;
    }
    return undef;
}

package Class::Generate::Code_Checker;    # This package encapsulates
$Class::Generate::Code_Checker::VERSION = '1.18';
use strict;                               # checking for warnings and
use Carp;                                 # errors in user-defined code.

my $package_decl;
my $member_error_message = '%s, member "%s": In "%s" code: %s';
my $method_error_message = '%s, method "%s": %s';

sub create_code_checking_package($);
sub fragment_as_sub($$\@;\@);
sub collect_code_problems($$$$@);

# Check each user-defined code fragment in $class for errors. This includes
# pre, post, and assert code, as well as user-defined methods.  Set
# $errors_found according to whether errors (not warnings) were found.
sub check_user_defined_code($$$$)
{
    my ( $class, $class_name_label, $warnings, $errors ) = @_;
    my ( $code, $instance_var, @valid_variables, @class_vars, $w, $e, @members,
        $problems_in_pre, %seen );
    create_code_checking_package $class;
    @valid_variables = map {
        $seen{ $_->name } ? () : do { $seen{ $_->name } = 1; $_->as_var }
    } (
        ( @members = $class->members_values ),
        Class::Generate::Member_Names::accessible_members($class)
    );
    @class_vars   = $class->class_vars;
    $instance_var = $class->instance_var;
    @$warnings    = ();
    undef $$errors;

    for my $member ( $class->constructor, @members )
    {
        if ( defined( $code = $member->pre ) )
        {
            $code = fragment_as_sub $code, $instance_var, @class_vars,
                @valid_variables;
            collect_code_problems $code,
                $warnings, $errors,
                $member_error_message, $class_name_label, $member->name, 'pre';
            $problems_in_pre = @$warnings || $$errors;
        }

        # Because post shares pre's scope, check post with pre prepended.
        # Strip newlines in pre to preserve line numbers in post.
        if ( defined( $code = $member->post ) )
        {
            my $pre = $member->pre;
            if ( defined $pre && !$problems_in_pre )
            {    # Don't report errors
                $pre =~ s/\n+/ /g;    # in pre again.
                $code = $pre . $code;
            }
            $code = fragment_as_sub $code, $instance_var, @class_vars,
                @valid_variables;
            collect_code_problems $code,
                $warnings, $errors,
                $member_error_message, $class_name_label, $member->name, 'post';
        }
        if ( defined( $code = $member->assert ) )
        {
            $code = fragment_as_sub "unless($code){die}", $instance_var,
                @class_vars, @valid_variables;
            collect_code_problems $code,
                $warnings, $errors,
                $member_error_message, $class_name_label, $member->name,
                'assert';
        }
    }
    for my $method ( $class->user_defined_methods_values )
    {
        if ( $method->isa('Class::Generate::Class_Method') )
        {
            $code = fragment_as_sub $method->body, $class->class_var,
                @class_vars;
        }
        else
        {
            $code = fragment_as_sub $method->body, $instance_var, @class_vars,
                @valid_variables;
        }
        collect_code_problems $code, $warnings, $errors, $method_error_message,
            $class_name_label, $method->name;
    }
}

sub create_code_checking_package($)
{    # Each class with user-defined code gets
    my $class = $_[0];    # its own package in which that code is
                          # evaluated.  Create said package.
    $package_decl = 'package ' . __PACKAGE__ . '::check::' . $class->name . ";";
    $package_decl .= 'use strict;' if $class->strict;
    my $packages = '';
    if ( $class->check_params )
    {
        $packages .= 'use Carp;';
        $packages .= join( ';', $class->warnings_pragmas );
    }
    $packages .= join( '', map( 'use ' . $_ . ';', $class->use_packages ) );
    $packages .= 'use vars qw(@ISA);' if $class->parents;
    eval $package_decl . $packages;
}

# Evaluate a code fragment, passing on
sub collect_code_problems($$$$@)
{    # warnings and errors.
    my ( $code_form, $warnings, $errors, $error_message, @params ) = @_;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    local $SIG{__DIE__};
    eval $package_decl . $code_form;
    push @$warnings,
        map( filtered_message( $error_message, $_, @params ), @warnings );
    $$errors .= filtered_message( $error_message, $@, @params ) if $@;
}

sub filtered_message
{    # Clean up errors and messages
    my ( $message, $error, @params ) = @_;          # a little by removing the
    $error =~ s/\(eval \d+\) //g;                   # "(eval N)" forms that perl
    return sprintf( $message, @params, $error );    # inserts.
}

sub fragment_as_sub($$\@;\@)
{
    my ( $code, $id_var, $class_vars, $valid_vars ) = @_;
    my $form;
    $form = "sub{my $id_var;";
    if ( $#$class_vars >= 0 )
    {
        $form .= 'my('
            . join( ',', map( ( ref $_ ? keys %$_ : $_ ), @$class_vars ) )
            . ');';
    }
    if ( $valid_vars && $#$valid_vars >= 0 )
    {
        $form .= 'my(' . join( ',', @$valid_vars ) . ');';
    }
    $form .= '{' . $code . '}};';
}

package Class::Generate::Array;    # Given a string or an ARRAY, return an
$Class::Generate::Array::VERSION = '1.18';
use strict;                        # object that is either the ARRAY or
use Carp;                          # the string made into an ARRAY by
                                   # splitting the string on white space.

sub new
{
    my $class = shift;
    my $self;
    if ( !ref $_[0] )
    {
        $self = [ split /\s+/, $_[0] ];
    }
    elsif ( UNIVERSAL::isa( $_[0], 'ARRAY' ) )
    {
        $self = $_[0];
    }
    else
    {
        croak 'Expected string or array reference';
    }
    bless $self, $class;
    return $self;
}

sub values
{
    my $self = shift;
    return @$self;
}

package Class::Generate::Hash;    # Given a string or a HASH and a key
$Class::Generate::Hash::VERSION = '1.18';
use strict;                       # name, return an object that is either
use Carp;                         # the HASH or a HASH of the form
                                  # (key => string). Also, if the object

sub new
{    # is a HASH, it *must* contain the key.
    my $class = shift;
    my $self;
    my ( $value, $key ) = @_;
    if ( !ref $value )
    {
        $self = { $key => $value };
    }
    else
    {
        croak 'Expected string or hash reference'
            unless UNIVERSAL::isa( $value, 'HASH' );
        croak qq|Missing "$key"| unless exists $value->{$key};
        $self = $value;
    }
    bless $self, $class;
    return $self;
}

package Class::Generate::Support;    # Miscellaneous support routines.
$Class::Generate::Support::VERSION = '1.18';
no strict;                           # Definitely NOT strict!
                                     # Return the superclass of $class that

sub class_containing_method
{    # contains the method that the form
    my ( $method, $class ) = @_;    # (new $class)->$method would invoke.
    for my $parent ( $class->parents )
    {                               # Return undef if no such class exists.
        local *stab =
            eval( '*' . ( ref $parent ? $parent->name : $parent ) . '::' );
        if (
            exists $stab{$method}
            && do { local *method_entry = $stab{$method}; defined &method_entry }
            )
        {
            return $parent;
        }
        return class_containing_method( $method, $parent );
    }
    return undef;
}

my %map = ( '@' => 'ARRAY', '%' => 'HASH' );

sub verify_value($$)
{    # Die if a given value (ref or string)
    my ( $value, $type ) = @_;    # is not the specified type.
        # The following code is not wrong, but it could be smarter.
    if ( $type =~ /^\w/ )
    {
        $map{$type} = $type;
    }
    else
    {
        $type = substr $type, 0, 1;
    }
    return if $type eq '$';
    local $SIG{__WARN__} = sub { };
    my $result;
    $result = ref $value ? $value : eval $value;
    die "Wrong type" if !UNIVERSAL::isa( $result, $map{$type} );
}

use strict;

sub comment_form
{    # Given arbitrary text, return a form that
    my $comment = $_[0];    # is a valid Perl comment of that text.
    $comment =~ s/^/# /mg;
    $comment .= "\n" if substr( $comment, -1, 1 ) ne "\n";
    return $comment;
}

sub my_decl_form
{    # Given a non-empty set of variable names,
    my @vars = @_;    # return a form declaring them as "my" variables.
    return
        'my '
        . ( $#vars == 0 ? $vars[0] : '(' . join( ', ', @vars ) . ')' ) . ";\n";
}

package Class::Generate::Member;    # A virtual class describing class
$Class::Generate::Member::VERSION = '1.18';
use strict;                         # members.

sub new
{
    my $class = shift;
    my $self  = { name => $_[0], @_[ 1 .. $#_ ] };
    bless $self, $class;
    return $self;
}

sub name
{
    my $self = shift;
    return $self->{'name'};
}

sub default
{
    my $self = shift;
    return $self->{'default'} if $#_ == -1;
    $self->{'default'} = $_[0];
}

sub base
{
    my $self = shift;
    return $self->{'base'} if $#_ == -1;
    $self->{'base'} = $_[0];
}

sub assert
{
    my $self = shift;
    return $self->{'assert'} if $#_ == -1;
    $self->{'assert'} = $_[0];
}

sub post
{
    my $self = shift;
    return $self->{'post'} if $#_ == -1;
    $self->{'post'} = possibly_append_semicolon_to( $_[0] );
}

sub pre
{
    my $self = shift;
    return $self->{'pre'} if $#_ == -1;
    $self->{'pre'} = possibly_append_semicolon_to( $_[0] );
}

sub possibly_append_semicolon_to
{    # If user omits a trailing semicolon
    my $code = $_[0];    # (or doesn't use braces), add one.
    if ( $code !~ /[;\}]\s*\Z/s )
    {
        $code =~ s/\s*\Z/;$&/s;
    }
    return $code;
}

sub comment
{
    my $self = shift;
    return $self->{'comment'};
}

sub key
{
    my $self = shift;
    return $self->{'key'} if $#_ == -1;
    $self->{'key'} = $_[0];
}

sub nocopy
{
    my $self = shift;
    return $self->{'nocopy'} if $#_ == -1;
    $self->{'nocopy'} = $_[0];
}

sub assertion
{    # Return a form that croaks if
    my $self      = shift;               # the member's assertion fails.
    my $class     = $_[0];
    my $assertion = $self->{'assert'};
    return undef if !defined $assertion;
    my $quoted_form = $assertion;
    $quoted_form =~ s/'/\\'/g;
    $assertion = Class::Generate::Member_Names::substituted($assertion);
    return
          qq|unless ( $assertion ) { croak '|
        . $self->name_form($class)
        . qq|Failed assertion: $quoted_form' }|;
}

sub param_message
{    # Encapsulate the messages for
    my $self        = shift;         # incorrect parameters.
    my $class       = $_[0];
    my $name        = $self->name;
    my $prefix_form = q|croak '| . $class->name . '::new' . ': ';
    $class->required($name) && !$self->default and do
    {
        return $prefix_form . qq|Missing or invalid value for $name'|
            if $self->can_be_invalid;
        return $prefix_form . qq|Missing value for required member $name'|;
    };
    $self->can_be_invalid and do
    {
        return $prefix_form . qq|Invalid value for $name'|;
    };
}

sub param_test
{    # Return a form that dies if a constructor
    my $self  = shift;         # parameter is not correctly passed.
    my $class = $_[0];
    my $name  = $self->name;
    my $param = $class->constructor->style->ref($name);
    my $exists =
        $class->constructor->style->existence_test($name) . ' ' . $param;

    my $form = '';
    if ( $class->required($name) && !$self->default )
    {
        $form .= $self->param_message($class) . ' unless ' . $exists;
        $form .= ' && ' . $self->valid_value_form($param)
            if $self->can_be_invalid;
    }
    elsif ( $self->can_be_invalid )
    {
        $form .=
              $self->param_message($class)
            . ' unless ! '
            . $exists . ' || '
            . $self->valid_value_form($param);
    }
    return $form . ';';
}

sub form
{    # Return a form for a member and all
    my $self  = shift;    # its relevant associated accessors.
    my $class = $_[0];
    my ( $element, $exists, $lvalue, $values, $form, $body, $member_name );
    $element = $class->instance_var . '->'
        . $class->index( $member_name = $self->name );
    $exists = $class->existence_test . ' ' . $element;
    $lvalue = $self->lvalue('$_[0]') if $self->can('lvalue');
    $values = $self->values('$_[0]') if $self->can('values');

    $form = '';
    $form .= Class::Generate::Support::comment_form( $self->comment )
        if defined $self->comment;

    if ( $class->include_method($member_name) )
    {
        $body = '';
        for my $param_form ( $self->member_forms($class) )
        {
            $body .= $self->$param_form( $class, $element, $exists, $lvalue,
                $values );
        }
        $body .= '    ' . $self->param_count_error_form($class) . ";\n"
            if $class->check_params;
        $form .= $class->sub_form( $member_name, $member_name, $body );
    }
    for my $a ( grep $_ ne $member_name,
        $self->accessor_names( $class, $member_name ) )
    {
        $a =~ s/^([a-z]+)_$member_name$/$1_form/
            || $a =~ s/^${member_name}_([a-z]+)$/$1_form/;
        $form .= $self->$a( $class, $element, $member_name, $exists );
    }
    return $form;
}

sub invalid_value_assignment_message
{    # Return a form that dies, reporting
    my $self  = shift;    # a parameter that's not of the
    my $class = $_[0];    # correct type for its element.
    return
          'croak \''
        . $self->name_form($class)
        . 'Invalid parameter value (expected '
        . $self->expected_type_form . ')\'';
}

sub valid_value_test_form
{    # Return a form that dies unless
    my $self  = shift;    # a value is of the correct type
    my $class = shift;    # for the member.
    return
          $self->invalid_value_assignment_message($class)
        . ' unless '
        . $self->valid_value_form(@_) . ';';
}

sub param_must_be_checked
{
    my $self  = shift;
    my $class = $_[0];
    return ( $class->required( $self->name ) && !defined $self->default )
        || $self->can_be_invalid;
}

sub maybe_guarded
{    # If parameter checking is enabled, guard a
    my $self = shift;                      # form to check against a parameter
    my ( $form, $param_no, $class ) = @_;  # count. In any case, format the form
    if ( $class->check_params )
    {                                      # a little.
        $form =~ s/^/\t/mg;
        return "    \$#_ == $param_no\tand do {\n$form    };\n";
    }
    else
    {
        $form =~ s/^/    /mg;
        return $form;
    }
}

sub accessor_names
{
    my $self = shift;
    my ( $class, $name ) = @_;
    return !( $class->readonly($name) || $class->required($name) )
        ? ("undef_$name")
        : ();
}

sub undef_form
{    # Return the form to undefine
    my $self = shift;    # a member.
    my ( $class, $element, $member_name ) = @_[ 0 .. 2 ];
    return $class->sub_form(
        $member_name,
        'undef_' . $member_name,
        '    ' . $class->undef_form . " $element;\n"
    );
}

sub param_count_error_form
{    # Return a form that standardizes
    my $self  = shift;    # the message for dieing because
    my $class = $_[0];    # of an incorrect parameter count.
    return
          q|croak '|
        . $self->name_form($class)
        . q|Invalid number of parameters (', ($#_+1), ')'|;
}

sub name_form
{    # Standardize a method name
    my $self  = shift;    # for error messages.
    my $class = $_[0];
    return $class->name . '::' . $self->name . ': ';
}

sub param_assignment_form
{    # Return a form that assigns a parameter
    my $self = shift;    # value to the member.
    my ( $class, $style ) = @_;
    my ( $name, $element, $param, $default, $exists );
    $name    = $self->name;
    $element = $class->instance_var . '->' . $class->index($name);
    $param   = $style->ref($name);
    $default = $self->default;
    $exists  = $style->existence_test($name) . ' ' . $param;
    my $form = "    $element = ";

    if ( defined $default )
    {
        $form .= "$exists ? $param : $default";
    }
    elsif ( $class->check_params && $class->required($name) )
    {
        $form .= $param;
    }
    else
    {
        $form .= "$param if $exists";
    }
    return $form . ";\n";
}

sub default_assignment_form
{    # Return a form that assigns a default value
    my $self  = shift;    # to a member.
    my $class = $_[0];
    my $element;
    $element = $class->instance_var . '->' . $class->index( $self->name );
    return "    $element = " . $self->default . ";\n";
}

package Class::Generate::Scalar_Member;    # A Member subclass for
$Class::Generate::Scalar_Member::VERSION = '1.18';
use strict;                                # scalar class members.
use vars qw(@ISA);                         # accessor accepts 0 or 1 parameters.
@ISA = qw(Class::Generate::Member);

sub member_forms
{
    my $self  = shift;
    my $class = $_[0];
    return $class->readonly( $self->name )
        ? 'no_params'
        : ( 'no_params', 'one_param' );
}

sub no_params
{
    my $self = shift;
    my ( $class, $element ) = @_;
    if ( $class->readonly( $self->name ) && !$class->check_params )
    {
        return "    return $element;\n";
    }
    return "    \$#_ == -1\tand do { return $element };\n";
}

sub one_param
{
    my $self = shift;
    my ( $class, $element ) = @_;
    my $form = '';
    $form .= Class::Generate::Member_Names::substituted( $self->pre )
        if defined $self->pre;
    $form .= $self->valid_value_test_form( $class, '$_[0]' ) . "\n"
        if $class->check_params && defined $self->base;
    $form .= "$element = \$_[0];\n";
    $form .= Class::Generate::Member_Names::substituted( $self->post )
        if defined $self->post;
    $form .= $self->assertion($class) . "\n"
        if defined $class->check_params && defined $self->assert;
    $form .= "return;\n";
    return $self->maybe_guarded( $form, 0, $class );
}

sub valid_value_form
{    # Return a form that tests if
    my $self = shift;       # a ref is of the correct
    my ($param) = @_;       # base type.
    return qq|UNIVERSAL::isa($param, '| . $self->base . qq|')|;
}

sub can_be_invalid
{    # Validity for a scalar member
    my $self = shift;              # is testable only if the member
    return defined $self->base;    # is supposed to be a class.
}

sub as_var
{
    my $self = shift;
    return '$' . $self->name;
}

sub method_regexp
{
    my $self  = shift;
    my $class = $_[0];
    return $class->include_method( $self->name ) ? ( '\$' . $self->name ) : ();
}

sub accessor_names
{
    my $self = shift;
    my ( $class, $name ) = @_;
    return grep $class->include_method($_),
        ( $name, $self->SUPER::accessor_names( $class, $name ) );
}

sub expected_type_form
{
    my $self = shift;
    return $self->base;
}

sub copy_form
{
    my $self = shift;
    my ( $from, $to ) = @_;
    my $form = "    $to = $from";
    if ( !$self->nocopy )
    {
        $form .= '->copy' if $self->base;
    }
    $form .= " if defined $from;\n";
    return $form;
}

sub equals
{
    my $self = shift;
    my ( $index, $existence_test ) = @_;
    my ( $sr,    $or )             = ( '$self->' . $index, '$o->' . $index );
    my $form =
          "    return undef if $existence_test $sr ^ $existence_test $or;\n"
        . "    if ( $existence_test $sr ) { return undef unless $sr";
    if ( $self->base )
    {
        $form .= "->equals($or)";
    }
    else
    {
        $form .= " eq $or";
    }
    return $form . " }\n";
}

package Class::Generate::List_Member;    # A Member subclass for list
$Class::Generate::List_Member::VERSION = '1.18';
use strict;                              # (array and hash) members.
use vars qw(@ISA);                       # accessor accepts 0-2 parameters.
@ISA = qw(Class::Generate::Member);

sub member_forms
{
    my $self  = shift;
    my $class = $_[0];
    return $class->readonly( $self->name )
        ? ( 'no_params', 'one_param' )
        : ( 'no_params', 'one_param', 'two_params' );
}

sub no_params
{
    my $self = shift;
    my ( $class, $element, $exists, $lvalue, $values ) = @_;
    return
          "    \$#_ == -1\tand do { return $exists ? "
        . $self->whole_lvalue($element)
        . " : () };\n";
}

sub one_param
{
    my $self = shift;
    my ( $class, $element, $exists, $lvalue, $values ) = @_;
    my $form;
    if ( $class->accept_refs )
    {
        $form = "    \$#_ == 0\tand do {\n" . "\t"
            . "return ($exists ? ${element}->$lvalue : undef)	if ! ref \$_[0];\n";
        if ( $class->check_params && $class->readonly( $self->name ) )
        {
            $form .=
                  "croak '"
                . $self->name_form($class)
                . "Member is read-only';\n";
        }
        else
        {
            $form .=
                "\t" . Class::Generate::Member_Names::substituted( $self->pre )
                if defined $self->pre;
            $form .=
                "\t" . $self->valid_value_test_form( $class, '$_[0]' ) . "\n"
                if $class->check_params;
            $form .= "\t"
                . $self->whole_lvalue($element) . ' = '
                . $self->whole_lvalue('$_[0]') . ";\n";
            $form .=
                "\t" . Class::Generate::Member_Names::substituted( $self->post )
                if defined $self->post;
            $form .= "\t" . $self->assertion($class) . "\n"
                if defined $class->check_params && defined $self->assert;
            $form .= "\t" . "return;\n";
        }
        $form .= "    };\n";
    }
    else
    {
        $form =
"    \$#_ == 0\tand do { return $exists ? ${element}->$lvalue : undef };\n";
    }
    return $form;
}

sub two_params
{
    my $self = shift;
    my ( $class, $element, $exists, $lvalue, $values ) = @_;
    my $form = '';
    $form .= Class::Generate::Member_Names::substituted( $self->pre )
        if defined $self->pre;
    $form .= $self->valid_element_test( $class, '$_[1]' ) . "\n"
        if $class->check_params && defined $self->base;
    $form .= "${element}->$lvalue = \$_[1];\n";
    $form .= Class::Generate::Member_Names::substituted( $self->post )
        if defined $self->post;
    $form .= "return;\n";
    return $self->maybe_guarded( $form, 1, $class );
}

sub valid_value_form
{    # Return a form that tests if a
    my $self  = shift;          # parameter is a correct list reference
    my $param = $_[0];          # and (if relevant) if all of its
    my $base  = $self->base;    # elements have the correct base type.
    ref($self) =~ /::(\w+)_Member$/;
    my $form = "UNIVERSAL::isa($param, '" . uc($1) . "')";
    if ( defined $base )
    {
        $form .=
            qq| && ! grep ! (defined \$_ && UNIVERSAL::isa(\$_, '$base')), |
            . $self->values($param);
    }
    return $form;
}

sub valid_element_test
{    # Return a form that dies unless an
    my $self = shift;    # element has the correct base type.
    my ( $class, $param ) = @_;
    return
          $self->invalid_value_assignment_message($class)
        . qq| unless UNIVERSAL::isa($param, '|
        . $self->base . q|');|;
}

sub valid_elements_test
{    # Return a form that dies unless all
    my $self = shift;    # elements of a list are validly typed.
    my ( $class, $values ) = @_;
    my $base = $self->base;
    return
          $self->invalid_value_assignment_message($class)
        . q| unless ! grep ! UNIVERSAL::isa($_, '|
        . $self->base
        . qq|'), $values;|;
}

sub can_be_invalid
{    # A value for a list member can
    return 1;    # always be invalid: the wrong
}    # type of list can be given.

package Class::Generate::Array_Member;    # A List subclass for array
$Class::Generate::Array_Member::VERSION = '1.18';
use strict;                               # members.  Provides the
use vars qw(@ISA);                        # of accessing array members.
@ISA = qw(Class::Generate::List_Member);

sub lvalue
{
    my $self = shift;
    return '[' . $_[0] . ']';
}

sub whole_lvalue
{
    my $self = shift;
    return '@{' . $_[0] . '}';
}

sub values
{
    my $self = shift;
    return '@{' . $_[0] . '}';
}

sub size_form
{
    my $self = shift;
    my ( $class, $element, $member_name, $exists ) = @_;
    return $class->sub_form(
        $member_name,
        $member_name . '_size',
        "    return $exists ? \$#{$element} : -1;\n"
    );
}

sub last_form
{
    my $self = shift;
    my ( $class, $element, $member_name, $exists ) = @_;
    return $class->sub_form(
        $member_name,
        'last_' . $member_name,
        "    return $exists ? $element" . "[\$#{$element}] : undef;\n"
    );
}

sub add_form
{
    my $self = shift;
    my ( $class, $element, $member_name, $exists ) = @_;
    my $body = '';
    $body .= '    ' . $self->valid_elements_test( $class, '@_' ) . "\n"
        if $class->check_params && defined $self->base;
    $body .= Class::Generate::Member_Names::substituted( $self->pre )
        if defined $self->pre;
    $body .= '    push @{' . $element . '}, @_;' . "\n";
    $body .= Class::Generate::Member_Names::substituted( $self->post )
        if defined $self->post;
    $body .= '    ' . $self->assertion($class) . "\n"
        if defined $class->check_params && defined $self->assert;
    return $class->sub_form( $member_name, 'add_' . $member_name, $body );
}

sub as_var
{
    my $self = shift;
    return '@' . $self->name;
}

sub method_regexp
{
    my $self  = shift;
    my $class = $_[0];
    return $class->include_method( $self->name )
        ? ( '@' . $self->name, '\$#?' . $self->name )
        : ();
}

sub accessor_names
{
    my $self = shift;
    my ( $class, $name ) = @_;
    my @names = (
        $name, "${name}_size", "last_$name",
        $self->SUPER::accessor_names( $class, $name )
    );
    push @names, "add_$name" if !$class->readonly($name);
    return grep $class->include_method($_), @names;
}

sub expected_type_form
{
    my $self = shift;
    if ( defined $self->base )
    {
        return 'reference to array of ' . $self->base;
    }
    else
    {
        return 'array reference';
    }
}

sub copy_form
{
    my $self = shift;
    my ( $from, $to ) = @_;
    my $form = "    $to = ";
    if ( !$self->nocopy )
    {
        $form .= '[ ';
        $form .= 'map defined $_ ? $_->copy : undef, ' if $self->base;
        $form .= "\@{$from} ]";
    }
    else
    {
        $form .= $from;
    }
    $form .= " if defined $from;\n";
    return $form;
}

sub equals
{
    my $self = shift;
    my ( $index, $existence_test ) = @_;
    my ( $sr,    $or )             = ( '$self->' . $index, '$o->' . $index );
    my $form =
          "    return undef if $existence_test($sr) ^ $existence_test($or);\n"
        . "    if ( $existence_test $sr ) {\n"
        . "	return undef unless (\$ub = \$#{$sr}) == \$#{$or};\n"
        . "	for ( my \$i = 0; \$i <= \$ub; \$i++ ) {\n"
        . "	    return undef unless $sr" . '[$i]';
    if ( $self->base )
    {
        $form .= '->equals(' . $or . '[$i])';
    }
    else
    {
        $form .= ' eq ' . $or . '[$i]';
    }
    return $form . ";\n\t}\n    }\n";
}

package Class::Generate::Hash_Member;    # A List subclass for Hash
$Class::Generate::Hash_Member::VERSION = '1.18';
use strict;                              # members.  Provides the n_keys
use vars qw(@ISA);                       # specifics of accessing
@ISA = qw(Class::Generate::List_Member); # hash members.

sub lvalue
{
    my $self = shift;
    return '{' . $_[0] . '}';
}

sub whole_lvalue
{
    my $self = shift;
    return '%{' . $_[0] . '}';
}

sub values
{
    my $self = shift;
    return 'values %{' . $_[0] . '}';
}

sub delete_form
{
    my $self = shift;
    my ( $class, $element, $member_name, $exists ) = @_;
    return $class->sub_form(
        $member_name,
        'delete_' . $member_name,
        "    delete \@{$element}{\@_} if $exists;\n"
    );
}

sub keys_form
{
    my $self = shift;
    my ( $class, $element, $member_name, $exists ) = @_;
    return $class->sub_form(
        $member_name,
        $member_name . '_keys',
        "    return $exists ? keys \%{$element} : ();\n"
    );
}

sub values_form
{
    my $self = shift;
    my ( $class, $element, $member_name, $exists ) = @_;
    return $class->sub_form(
        $member_name,
        $member_name . '_values',
        "    return $exists ? values \%{$element} : ();\n"
    );
}

sub as_var
{
    my $self = shift;
    return '%' . $self->name;
}

sub method_regexp
{
    my $self  = shift;
    my $class = $_[0];
    return $class->include_method( $self->name )
        ? ( '[%$]' . $self->name )
        : ();
}

sub accessor_names
{
    my $self = shift;
    my ( $class, $name ) = @_;
    my @names = (
        $name, "${name}_keys", "${name}_values",
        $self->SUPER::accessor_names( $class, $name )
    );
    push @names, "delete_$name" if !$class->readonly($name);
    return grep $class->include_method($_), @names;
}

sub expected_type_form
{
    my $self = shift;
    if ( defined $self->base )
    {
        return 'reference to hash of ' . $self->base;
    }
    else
    {
        return 'hash reference';
    }
}

sub copy_form
{
    my $self = shift;
    my ( $from, $to ) = @_;
    if ( !$self->nocopy )
    {
        if ( $self->base )
        {
            return
                  "    if ( defined $from ) {\n"
                . "\t$to = {};\n"
                . "\twhile ( my (\$key, \$value) = each \%{$from} ) {\n"
                . "\t    $to"
                . '->{$key} = defined $value ? $value->copy : undef;' . "\n"
                . "\t}\n"
                . "    }\n";
        }
        else
        {
            return "    $to = { \%{$from} } if defined $from;\n";
        }
    }
    else
    {
        return "    $to = $from if defined $from;\n";
    }
}

sub equals
{
    my $self = shift;
    my ( $index, $existence_test ) = @_;
    my ( $sr,    $or )             = ( '$self->' . $index, '$o->' . $index );
    my $form =
          "    return undef if $existence_test $sr ^ $existence_test $or;\n"
        . "    if ( $existence_test $sr ) {\n"
        . '	@self_keys = keys %{'
        . $sr . '};' . "\n"
        . '	return undef unless $#self_keys == scalar(keys %{'
        . $or
        . '}) - 1;' . "\n"
        . '	for my $k ( @self_keys ) {' . "\n"
        . "	    return undef unless exists $or" . '{$k};' . "\n"
        . '	    return undef if ($self_value_defined = defined '
        . $sr
        . '{$k}) ^ defined '
        . $or . '{$k};' . "\n"
        . '	    if ( $self_value_defined ) { return undef unless ';
    if ( $self->base )
    {
        $form .= $sr . '{$k}->equals(' . $or . '{$k})';
    }
    else
    {
        $form .= $sr . '{$k} eq ' . $or . '{$k}';
    }
    $form .= " }\n\t}\n    }\n";
    return $form;
}

package Class::Generate::Constructor;    # The constructor is treated as a
$Class::Generate::Constructor::VERSION = '1.18';
use strict;                              # special type of member.  It includes
use vars qw(@ISA);                       # constraints on required members.
@ISA = qw(Class::Generate::Member);

sub new
{
    my $class = shift;
    my $self  = $class->SUPER::new( 'new', @_ );
    return $self;
}

sub style
{
    my $self = shift;
    return $self->{'style'} if $#_ == -1;
    $self->{'style'} = $_[0];
}

sub constraints
{
    my $self = shift;
    return exists $self->{'constraints'} ? @{ $self->{'constraints'} } : ()
        if $#_ == -1;
    return exists $self->{'constraints'}
        ? $self->{'constraints'}->[ $_[0] ]
        : undef
        if $#_ == 0;
    $self->{'constraints'}->[ $_[0] ] = $_[1];
}

sub add_constraints
{
    my $self = shift;
    push @{ $self->{'constraints'} }, @_;
}

sub constraints_size
{
    my $self = shift;
    return exists $self->{'constraints'} ? $#{ $self->{'constraints'} } : -1;
}

sub constraint_form
{
    my $self = shift;
    my ( $class, $style, $constraint ) = @_;
    my $param_given = $constraint;
    $param_given =~ s/\w+/$style->existence_test($&) . ' ' . $style->ref($&)/eg;
    $constraint  =~ s/'/\\'/g;
    return
          q|croak '|
        . $self->name_form($class)
        . qq|Parameter constraint "$constraint" failed' unless $param_given;|;
}

sub param_tests_form
{
    my $self = shift;
    my ( $class, $style ) = @_;
    my $form = '';
    if ( !$class->parents && $style->can('params_check_form') )
    {
        $form .= $style->params_check_form( $class, $self );
    }
    if ( !$style->isa('Class::Generate::Own') )
    {
        my @public_members = map $class->members($_),
            $class->public_member_names;
        for my $param_test (
            map $_->param_must_be_checked($class) ? $_->param_test($class) : (),
            @public_members
            )
        {
            $form .= '    ' . $param_test . "\n";
        }
        for my $constraint ( $self->constraints )
        {
            $form .= '    '
                . $self->constraint_form( $class, $style, $constraint ) . "\n";
        }
    }
    return $form;
}

sub assertions_form
{
    my $self  = shift;
    my $class = $_[0];
    my $form  = '';
    $form .= '    ' . $self->assertion($class) . "\n"
        if defined $class->check_params && defined $self->assert;
    for my $member ( grep defined $_->assert, $class->members_values )
    {
        $form .= '    ' . $member->assertion($class) . "\n";
    }
    return $form;
}

sub form
{
    my $self  = shift;
    my $class = $_[0];
    my $style = $self->style;
    my ( $iv, $cv ) = ( $class->instance_var, $class->class_var );
    my $form;
    $form =
          "sub new {\n"
        . "    my $cv = "
        . (
        $class->nfi
        ? 'do { my $proto = shift; ref $proto || $proto }'
        : 'shift'
        ) . ";\n";
    if ( $class->check_params && $class->virtual )
    {
        $form .=
              q|    croak '|
            . $self->name_form($class)
            . q|Virtual class' unless $class ne '|
            . $class->name
            . qq|';\n|;
    }
    $form .= $style->init_form( $class, $self )
        if !$class->can_assign_all_params
        && $style->can('init_form');
    $form .= $self->param_tests_form( $class, $style ) if $class->check_params;
    if ( defined $class->parents )
    {
        $form .= $style->self_from_super_form($class);
    }
    else
    {
        $form .=
              '    my '
            . $iv . ' = '
            . $class->base . ";\n"
            . '    bless '
            . $iv . ', '
            . $cv . ";\n";
    }
    if ( !$class->can_assign_all_params )
    {
        $form .= $class->size_establishment($iv)
            if $class->can('size_establishment');
        if ( !$style->isa('Class::Generate::Own') )
        {
            for my $name ( $class->public_member_names )
            {
                $form .= $class->members($name)
                    ->param_assignment_form( $class, $style );
            }
        }
    }
    $form .= $class->protected_members_info_form;
    for my $member (
        grep( (
                       $style->isa('Class::Generate::Own')
                    || $class->protected( $_->name )
                    || $class->private( $_->name )
            )
                && defined $_->default,
            $class->members_values )
        )
    {
        $form .= $member->default_assignment_form($class);
    }
    $form .= Class::Generate::Member_Names::substituted( $self->post )
        if defined $self->post;
    $form .= $self->assertions_form($class) if $class->check_params;
    $form .= '    return ' . $iv . ";\n" . "}\n";
    return $form;
}

package Class::Generate::Method;    # A user-defined method,
$Class::Generate::Method::VERSION = '1.18';
# with a name and body.
sub new
{
    my $class = shift;
    my $self  = { name => $_[0], body => $_[1] };
    bless $self, $class;
    return $self;
}

sub name
{
    my $self = shift;
    return $self->{'name'};
}

sub body
{
    my $self = shift;
    return $self->{'body'};
}

sub comment
{
    my $self = shift;
    return $self->{'comment'} if $#_ == -1;
    $self->{'comment'} = $_[0];
}

sub form
{
    my $self  = shift;
    my $class = $_[0];
    my $form  = '';
    $form .= Class::Generate::Support::comment_form( $self->comment )
        if defined $self->comment;
    $form .= $class->sub_form( $self->name, $self->name,
        Class::Generate::Member_Names::substituted( $self->body ) );
    return $form;
}

package Class::Generate::Class_Method;    # A user-defined class method,
$Class::Generate::Class_Method::VERSION = '1.18';
use strict;                               # which may specify objects
use vars qw(@ISA);                        # of the class used within its
@ISA = qw(Class::Generate::Method);       # body.

sub objects
{
    my $self = shift;
    return exists $self->{'objects'} ? @{ $self->{'objects'} } : ()
        if $#_ == -1;
    return exists $self->{'objects'} ? $self->{'objects'}->[ $_[0] ] : undef
        if $#_ == 0;
    $self->{'objects'}->[ $_[0] ] = $_[1];
}

sub add_objects
{
    my $self = shift;
    push @{ $self->{'objects'} }, @_;
}

sub form
{
    my $self  = shift;
    my $class = $_[0];
    return $class->class_sub_form( $self->name,
        Class::Generate::Member_Names::substituted_in_class_method($self) );
}

package Class::Generate::Class;    # A virtual class describing
$Class::Generate::Class::VERSION = '1.18';
use strict;                        # a user-specified class.

sub new
{
    my $class = shift;
    my $self  = { name => shift, @_ };
    bless $self, $class;
    return $self;
}

sub name
{
    my $self = shift;
    return $self->{'name'};
}

sub parents
{
    my $self = shift;
    return exists $self->{'parents'} ? @{ $self->{'parents'} } : ()
        if $#_ == -1;
    return exists $self->{'parents'} ? $self->{'parents'}->[ $_[0] ] : undef
        if $#_ == 0;
    $self->{'parents'}->[ $_[0] ] = $_[1];
}

sub add_parents
{
    my $self = shift;
    push @{ $self->{'parents'} }, @_;
}

sub members
{
    my $self = shift;
    return exists $self->{'members'} ? %{ $self->{'members'} } : ()
        if $#_ == -1;
    return exists $self->{'members'} ? $self->{'members'}->{ $_[0] } : undef
        if $#_ == 0;
    $self->{'members'}->{ $_[0] } = $_[1];
}

sub members_keys
{
    my $self = shift;
    return exists $self->{'members'} ? keys %{ $self->{'members'} } : ();
}

sub members_values
{
    my $self = shift;
    return exists $self->{'members'} ? values %{ $self->{'members'} } : ();
}

sub user_defined_methods
{
    my $self = shift;
    return exists $self->{'udm'} ? %{ $self->{'udm'} }       : () if $#_ == -1;
    return exists $self->{'udm'} ? $self->{'udm'}->{ $_[0] } : undef
        if $#_ == 0;
    $self->{'udm'}->{ $_[0] } = $_[1];
}

sub user_defined_methods_keys
{
    my $self = shift;
    return exists $self->{'udm'} ? keys %{ $self->{'udm'} } : ();
}

sub user_defined_methods_values
{
    my $self = shift;
    return exists $self->{'udm'} ? values %{ $self->{'udm'} } : ();
}

sub class_vars
{
    my $self = shift;
    return exists $self->{'class_vars'} ? @{ $self->{'class_vars'} } : ()
        if $#_ == -1;
    return
        exists $self->{'class_vars'} ? $self->{'class_vars'}->[ $_[0] ] : undef
        if $#_ == 0;
    $self->{'class_vars'}->[ $_[0] ] = $_[1];
}

sub add_class_vars
{
    my $self = shift;
    push @{ $self->{'class_vars'} }, @_;
}

sub use_packages
{
    my $self = shift;
    return exists $self->{'use_packages'} ? @{ $self->{'use_packages'} } : ()
        if $#_ == -1;
    return exists $self->{'use_packages'}
        ? $self->{'use_packages'}->[ $_[0] ]
        : undef
        if $#_ == 0;
    $self->{'use_packages'}->[ $_[0] ] = $_[1];
}

sub add_use_packages
{
    my $self = shift;
    push @{ $self->{'use_packages'} }, @_;
}

sub excluded_methods_regexp
{
    my $self = shift;
    return $self->{'em'} if $#_ == -1;
    $self->{'em'} = $_[0];
}

sub private
{
    my $self = shift;
    return exists $self->{'private'} ? %{ $self->{'private'} } : ()
        if $#_ == -1;
    return exists $self->{'private'} ? $self->{'private'}->{ $_[0] } : undef
        if $#_ == 0;
    $self->{'private'}->{ $_[0] } = $_[1];
}

sub protected
{
    my $self = shift;
    return exists $self->{'protected'} ? %{ $self->{'protected'} } : ()
        if $#_ == -1;
    return
        exists $self->{'protected'} ? $self->{'protected'}->{ $_[0] } : undef
        if $#_ == 0;
    $self->{'protected'}->{ $_[0] } = $_[1];
}

sub required
{
    my $self = shift;
    return exists $self->{'required'} ? %{ $self->{'required'} } : ()
        if $#_ == -1;
    return exists $self->{'required'} ? $self->{'required'}->{ $_[0] } : undef
        if $#_ == 0;
    $self->{'required'}->{ $_[0] } = $_[1];
}

sub readonly
{
    my $self = shift;
    return exists $self->{'readonly'} ? %{ $self->{'readonly'} } : ()
        if $#_ == -1;
    return exists $self->{'readonly'} ? $self->{'readonly'}->{ $_[0] } : undef
        if $#_ == 0;
    $self->{'readonly'}->{ $_[0] } = $_[1];
}

sub constructor
{
    my $self = shift;
    return $self->{'constructor'} if $#_ == -1;
    $self->{'constructor'} = $_[0];
}

sub virtual
{
    my $self = shift;
    return $self->{'virtual'} if $#_ == -1;
    $self->{'virtual'} = $_[0];
}

sub comment
{
    my $self = shift;
    return $self->{'comment'} if $#_ == -1;
    $self->{'comment'} = $_[0];
}

sub accept_refs
{
    my $self = shift;
    return $self->{'accept_refs'};
}

sub strict
{
    my $self = shift;
    return $self->{'strict'};
}

sub nfi
{
    my $self = shift;
    return $self->{'nfi'};
}

sub warnings
{
    my $self = shift;
    return $self->{'warnings'} if $#_ == -1;
    $self->{'warnings'} = $_[0];
}

sub check_params
{
    my $self = shift;
    return $self->{'check_params'} if $#_ == -1;
    $self->{'check_params'} = $_[0];
}

sub instance_methods
{
    my $self = shift;
    return grep !$_->isa('Class::Generate::Class_Method'),
        $self->user_defined_methods_values;
}

sub class_methods
{
    my $self = shift;
    return grep $_->isa('Class::Generate::Class_Method'),
        $self->user_defined_methods_values;
}

sub include_method
{
    my $self        = shift;
    my $method_name = $_[0];
    my $r           = $self->excluded_methods_regexp;
    return !defined $r || $method_name !~ m/$r/;
}

sub member_methods_form
{    # Return a form containing methods for all
    my $self = shift;    # non-private members in the class, plus
    my $form = '';       # private members used in class methods.
    for my $element (
        $self->public_member_names,
        $self->protected_member_names,
        $self->private_members_used_in_user_defined_code
        )
    {
        $form .= $self->members($element)->form($self);
    }
    $form .= "\n" if $form ne '';
    return $form;
}

sub user_defined_methods_form
{    # Return a form containing all
    my $self = shift;    # user-defined methods.
    my $form =
        join( '', map( $_->form($self), $self->user_defined_methods_values ) );
    return length $form > 0 ? $form . "\n" : '';
}

sub warnings_pragmas
{    # Return an array containing the
    my $self = shift;                 # warnings pragmas for the class.
    my $w    = $self->{'warnings'};
    return ()                   if !defined $w;
    return ('no warnings;')     if !$w;
    return ('use warnings;')    if $w =~ /^\d+$/;
    return ("use warnings $w;") if !ref $w;

    my @pragmas;
    for ( my $i = 0 ; $i <= $#$w ; $i += 2 )
    {
        my ( $key, $value ) = ( $$w[$i], $$w[ $i + 1 ] );
        if ( $key eq 'register' )
        {
            push @pragmas, 'use warnings::register;' if $value;
        }
        elsif ( defined $value && $value )
        {
            if ( $value =~ /^\d+$/ )
            {
                push @pragmas, $key . ' warnings;';
            }
            else
            {
                push @pragmas, $key . ' warnings ' . $value . ';';
            }
        }
    }
    return @pragmas;
}

sub warnings_form
{    # Return a form representing the
    my $self = shift;    # warnings pragmas for a class.
    my @warnings_pragmas = $self->warnings_pragmas;
    return @warnings_pragmas ? join( "\n", @warnings_pragmas ) . "\n" : '';
}

sub form
{    # Return a form representing
    my $self = shift;    # a class.
    my $form;
    $form = 'package ' . $self->name . ";\n";
    $form .= "use strict;\n" if $self->strict;
    $form .= join( "\n", map( "use $_;", $self->use_packages ) ) . "\n"
        if $self->use_packages;
    $form .= "use Carp;\n" if defined $self->{'check_params'};
    $form .= $self->warnings_form;
    $form .= Class::Generate::Class_Holder::form($self);
    $form .= "\n";
    $form .= Class::Generate::Support::comment_form( $self->comment )
        if defined $self->comment;
    $form .= $self->isa_decl_form if $self->parents;
    $form .= $self->private_methods_decl_form
        if grep $self->private($_), $self->user_defined_methods_keys;
    $form .= $self->private_members_decl_form
        if $self->private_members_used_in_user_defined_code;
    $form .= $self->protected_methods_decl_form
        if grep $self->protected($_), $self->user_defined_methods_keys;
    $form .= $self->protected_members_decl_form
        if grep $self->protected($_), $self->members_keys;
    $form .= join( "\n", map( class_var_form($_), $self->class_vars ) ) . "\n\n"
        if $self->class_vars;
    $form .= $self->constructor->form($self) if $self->needs_constructor;
    $form .= $self->member_methods_form;
    $form .= $self->user_defined_methods_form;
    my $emr = $self->excluded_methods_regexp;
    $form .= $self->copy_form if !defined $emr || 'copy' !~ m/$emr/;
    $form .= $self->equals_form
        if ( !defined $emr || 'equals' !~ m/$emr/ )
        && !defined $self->user_defined_methods('equals');
    return $form;
}

sub class_var_form
{    # Return a form for declaring a class
    my $var_spec = $_[0];    # variable.  Account for an initial value.
    return "my $var_spec;" if !ref $var_spec;
    return map {
        my $value = $$var_spec{$_};
        "my $_ = "
            . ( ref $value ? substr( $_, 0, 1 ) . "{$value}" : $value ) . ';'
    } keys %$var_spec;
}

sub isa_decl_form
{
    my $self = shift;
    my @parent_names = map !ref $_ ? $_ : $_->name, $self->parents;
    return
          "use vars qw(\@ISA);\n"
        . '@ISA = qw('
        . join( ' ', @parent_names ) . ");\n";
}

sub sub_form
{    # Return a declaration for a sub, as an
    my $self = shift;    # assignment to a variable if not public.
    my ( $element_name, $sub_name, $body ) = @_;
    my ( $form, $not_public );
    $not_public =
        $self->private($element_name) || $self->protected($element_name);
    $form =
          ( $not_public ? "\$$sub_name = sub" : "sub $sub_name" ) . " {\n"
        . '    my '
        . $self->instance_var
        . " = shift;\n"
        . $body . '}';
    $form .= ';' if $not_public;
    return $form . "\n";
}

sub class_sub_form
{    # Ditto, but for a class method.
    my $self = shift;
    my ( $method_name, $body ) = @_;
    my ( $form, $not_public );
    $not_public =
        $self->private($method_name) || $self->protected($method_name);
    $form =
          ( $not_public ? "\$$method_name = sub" : "sub $method_name" ) . " {\n"
        . '    my '
        . $self->class_var
        . " = shift;\n"
        . $body . '}';
    $form .= ';' if $not_public;
    return $form . "\n";
}

sub private_methods_decl_form
{    # Private methods are implemented as CODE refs.
    my $self = shift;    # Return a form declaring the variables to hold them.
    my @private_methods = grep $self->private($_),
        $self->user_defined_methods_keys;
    return Class::Generate::Support::my_decl_form( map "\$$_",
        @private_methods );
}

sub private_members_used_in_user_defined_code
{    # Return the names of all private
    my $self = shift;    # members that appear in user-defined code.
    my @private_members = grep $self->private($_), $self->members_keys;
    return () if !@private_members;
    my $member_regexp = join '|', @private_members;
    my %private_members;
    for my $code (
        map( $_->body, $self->user_defined_methods_values ),
        grep( defined $_,
            (
                map( ( $_->pre, $_->post, $_->assert ), $self->members_values ),
                map( ( $_->post, $_->assert ), $self->constructor )
            ) )
        )
    {
        while ( $code =~ /($member_regexp)/g )
        {
            $private_members{$1}++;
        }
    }
    return keys %private_members;
}

sub nonpublic_members_decl_form
{
    my $self           = shift;
    my @members        = @_;
    my @accessor_names = map( $_->accessor_names( $self, $_->name ), @members );
    return Class::Generate::Support::my_decl_form( map "\$$_",
        @accessor_names );
}

sub private_members_decl_form
{
    my $self = shift;
    return $self->nonpublic_members_decl_form( map $self->members($_),
        $self->private_members_used_in_user_defined_code );
}

sub protected_methods_decl_form
{
    my $self = shift;
    return Class::Generate::Support::my_decl_form(
        map $self->protected($_) ? "\$$_" : (),
        $self->user_defined_methods_keys
    );
}

sub protected_members_decl_form
{
    my $self = shift;
    return $self->nonpublic_members_decl_form(
        grep $self->protected( $_->name ),
        $self->members_values );
}

sub protected_members_info_form
{
    my $self              = shift;
    my @protected_members = grep $self->protected( $_->name ),
        $self->members_values;
    my @protected_methods = grep $self->protected( $_->name ),
        $self->user_defined_methods_values;
    return '' if !( @protected_members || @protected_methods );
    my $info_index_lvalue =
        $self->instance_var . '->' . $self->protected_members_info_index;
    my @protected_element_names = (
        map( $_->accessor_names( $class, $_->name ), @protected_members ),
        map( $_->name,                               @protected_methods )
    );
    if ( $self->parents )
    {
        my $form = '';
        for my $element_name (@protected_element_names)
        {
            $form .=
"    ${info_index_lvalue}->{'$element_name'} = \$$element_name;\n";
        }
        return $form;
    }
    else
    {
        return
              "    $info_index_lvalue = { "
            . join( ', ', map "$_ => \$$_", @protected_element_names )
            . " };\n";
    }
}

sub copy_form
{
    my $self = shift;
    my ( $form, @members, $has_parents );
    @members     = $self->members_values;
    $has_parents = defined $self->parents;
    $form = "sub copy {\n" . "    my \$self = shift;\n" . "    my \$copy;\n";
    if (
        !(
            do
            {
                my $has_complex_mems;
                for my $m (@members)
                {
                    if ( $m->isa('Class::Generate::List_Member')
                        || defined $m->base )
                    {
                        $has_complex_mems = 1;
                        last;
                    }
                }
                $has_complex_mems;
            }
            || $has_parents
        )
        )
    {
        $form .= '    $copy = ' . $self->wholesale_copy . ";\n";
    }
    else
    {
        $form .=
              '    $copy = '
            . ( $has_parents ? '$self->SUPER::copy' : $self->empty_form )
            . ";\n";
        $form .= $self->size_establishment('$copy')
            if $self->can('size_establishment');
        for my $m (@members)
        {
            my $index = $self->index( $m->name );
            $form .= $m->copy_form( '$self->' . $index, '$copy->' . $index );
        }
    }
    $form .= "    bless \$copy, ref \$self;\n" . "    return \$copy;\n" . "}\n";
    return $form;
}

sub equals_form
{
    my $self = shift;
    my ( $form, @parents, @members, $existence_test, @local_vars,
        @key_members );
    @parents = $self->parents;
    @members = $self->members_values;
    if ( @key_members = grep $_->key, @members )
    {
        @members = @key_members;
    }
    $existence_test = $self->existence_test;
    $form =
          "sub equals {\n"
        . "    my \$self = shift;\n"
        . "    my \$o = \$_[0];\n";
    for my $m (@members)
    {
        if ( $m->isa('Class::Generate::Hash_Member'), @members )
        {
            push @local_vars, qw($self_value_defined @self_keys);
            last;
        }
    }
    for my $m (@members)
    {
        if ( $m->isa('Class::Generate::Array_Member'), @members )
        {
            push @local_vars, qw($ub);
            last;
        }
    }
    if (@local_vars)
    {
        $form .= '    my (' . join( ', ', @local_vars ) . ");\n";
    }
    if (@parents)
    {
        $form .= "    return undef unless \$self->SUPER::equals(\$o);\n";
    }
    $form .= join( "\n",
        map $_->equals( $self->index( $_->name ), $existence_test ), @members )
        . "    return 1;\n" . "}\n";
    return $form;
}

sub all_members_required
{
    my $self = shift;
    for my $m ( $self->members_keys )
    {
        return 0 if !( $self->private($m) || $self->required($m) );
    }
    return 1;
}

sub private_member_names
{
    my $self = shift;
    return grep $self->private($_), $self->members_keys;
}

sub protected_member_names
{
    my $self = shift;
    return grep $self->protected($_), $self->members_keys;
}

sub public_member_names
{
    my $self = shift;
    return grep !( $self->private($_) || $self->protected($_) ),
        $self->members_keys;
}

sub class_var
{
    my $self = shift;
    return '$' . $self->{'class_var'};
}

sub instance_var
{
    my $self = shift;
    return '$' . $self->{'instance_var'};
}

sub needs_constructor
{
    my $self = shift;
    return (
               defined $self->members
            || ( $self->virtual && $self->check_params )
            || !$self->parents
            || do
        {
            my $c = $self->constructor;
            (          defined $c->post
                    || defined $c->assert
                    || $c->style->isa('Class::Generate::Own') );
        }
    );
}

package Class::Generate::Array_Class;    # A subclass of Class defining
$Class::Generate::Array_Class::VERSION = '1.18';
use strict;                              # array-based classes.
use vars qw(@ISA);
@ISA = qw(Class::Generate::Class);

sub new
{
    my $class        = shift;
    my $name         = shift;
    my %params       = @_;
    my %super_params = %params;
    delete @super_params{qw(base_index member_index)};
    my $self = $class->SUPER::new( $name, %super_params );
    $self->{'base_index'} =
        defined $params{'base_index'} ? $params{'base_index'} : 1;
    $self->{'next_index'} = $self->base_index - 1;
    return $self;
}

sub base_index
{
    my $self = shift;
    return $self->{'base_index'};
}

sub base
{
    my $self = shift;
    return '[]' if !$self->can_assign_all_params;
    my @sorted_members =
        sort { $$self{member_index}{$a} <=> $$self{member_index}{$b} }
        $self->members_keys;
    my %param_indices = map( ( $_, $self->constructor->style->order($_) ),
        $self->members_keys );
    for ( my $i = 0 ; $i <= $#sorted_members ; $i++ )
    {
        next if $param_indices{ $sorted_members[$i] } == $i;
        return '[ undef, '
            . join( ', ',
            map { '$_[' . $param_indices{$_} . ']' } @sorted_members )
            . ' ]';
    }
    return '[ undef, @_ ]';
}

sub base_type
{
    return 'ARRAY';
}

sub members
{
    my $self = shift;
    return $self->SUPER::members(@_) if $#_ != 1;
    $self->SUPER::members(@_);
    my $overridden_class;
    if (
        defined(
            $overridden_class =
                Class::Generate::Support::class_containing_method(
                $_[0], $self
                )
        )
        )
    {
        $self->{'member_index'}{ $_[0] } =
            $overridden_class->{'member_index'}->{ $_[0] };
    }
    else
    {
        $self->{'member_index'}{ $_[0] } = ++$self->{'next_index'};
    }
}

sub index
{
    my $self = shift;
    return '[' . $self->{'member_index'}{ $_[0] } . ']';
}

sub last
{
    my $self = shift;
    return $self->{'next_index'};
}

sub existence_test
{
    my $self = shift;
    return 'defined';
}

sub size_establishment
{
    my $self         = shift;
    my $instance_var = $_[0];
    return '    $#' . $instance_var . ' = ' . $self->last . ";\n";
}

sub can_assign_all_params
{
    my $self = shift;
    return
          !$self->check_params
        && $self->all_members_required
        && $self->constructor->style->isa('Class::Generate::Positional')
        && !defined $self->parents;
}

sub undef_form
{
    return 'undef';
}

sub wholesale_copy
{
    return '[ @$self ]';
}

sub empty_form
{
    return '[]';
}

sub protected_members_info_index
{
    return q|[0]|;
}

package Class::Generate::Hash_Class;    # A subclass of Class defining
$Class::Generate::Hash_Class::VERSION = '1.18';
use vars qw(@ISA);                      # hash-based classes.
@ISA = qw(Class::Generate::Class);

sub index
{
    my $self = shift;
    return
          "{'"
        . ( $self->private( $_[0] ) ? '*' . $self->name . '_' . $_[0] : $_[0] )
        . "'}";
}

sub base
{
    my $self = shift;
    return '{}' if !$self->can_assign_all_params;
    my $style = $self->constructor->style;
    return '{ @_ }' if $style->isa('Class::Generate::Key_Value');
    my %order = $style->order;
    my $form = '{ ' . join( ', ', map( "$_ => \$_[$order{$_}]", keys %order ) );
    if ( $style->isa('Class::Generate::Mix') )
    {
        $form .= ', @_[' . $style->pcount . '..$#_]';
    }
    return $form . ' }';
}

sub base_type
{
    return 'HASH';
}

sub existence_test
{
    return 'exists';
}

sub can_assign_all_params
{
    my $self = shift;
    return
          !$self->check_params
        && $self->all_members_required
        && !$self->constructor->style->isa('Class::Generate::Own')
        && !defined $self->parents;
}

sub undef_form
{
    return 'delete';
}

sub wholesale_copy
{
    return '{ %$self }';
}

sub empty_form
{
    return '{}';
}

sub protected_members_info_index
{
    return q|{'*protected*'}|;
}

package Class::Generate::Param_Style;    # A virtual class encompassing
$Class::Generate::Param_Style::VERSION = '1.18';
use strict;                              # parameter-passing styles for

sub new
{
    my $class = shift;
    return bless {}, $class;
}

sub keyed_param_names
{
    return ();
}

sub delete_self_members_form
{
    shift;
    my @self_members = @_;
    if ( $#self_members == 0 )
    {
        return q|delete $super_params{'| . $self_members[0] . q|'};|;
    }
    elsif ( $#self_members > 0 )
    {
        return
            q|delete @super_params{qw(| . join( ' ', @self_members ) . q|)};|;
    }
}

sub odd_params_check_form
{
    my $self = shift;
    my ( $class, $constructor ) = @_;
    return
          q|    croak '|
        . $constructor->name_form($class)
        . q|Odd number of parameters' if |
        . $self->odd_params_test($class) . ";\n";
}

sub my_decl_form
{
    my $self  = shift;
    my $class = $_[0];
    return
          '    my '
        . $class->instance_var . ' = '
        . $class->class_var
        . '->SUPER::new';
}

package Class::Generate::Key_Value;    # The key/value parameter-
$Class::Generate::Key_Value::VERSION = '1.18';
use strict;                                 # passing style.  It adds
use vars qw(@ISA);                          # the name of the variable
@ISA = qw(Class::Generate::Param_Style);    # that holds the parameters.

sub new
{
    my $class = shift;
    my $self  = $class->SUPER::new;
    $self->{'holder'}            = $_[0];
    $self->{'keyed_param_names'} = [ @_[ 1 .. $#_ ] ];
    return $self;
}

sub holder
{
    my $self = shift;
    return $self->{'holder'};
}

sub ref
{
    my $self = shift;
    return '$' . $self->holder . "{'" . $_[0] . "'}";
}

sub keyed_param_names
{
    my $self = shift;
    return @{ $self->{'keyed_param_names'} };
}

sub existence_test
{
    return 'exists';
}

sub init_form
{
    my $self = shift;
    my ( $class, $constructor ) = @_;
    my ( $form, $cn );
    $form = '';
    $form .= $self->odd_params_check_form( $class, $constructor )
        if $class->check_params;
    $form .= "    my \%params = \@_;\n";
    return $form;
}

sub odd_params_test
{
    return '$#_%2 == 0';
}

sub self_from_super_form
{
    my $self  = shift;
    my $class = $_[0];
    return
          '    my %super_params = %params;' . "\n" . '    '
        . $self->delete_self_members_form( $class->public_member_names ) . "\n"
        . $self->my_decl_form($class)
        . "(\%super_params);\n";
}

sub params_check_form
{
    my $self = shift;
    my ( $class, $constructor ) = @_;
    my ( $cn, @valid_names, $form );
    @valid_names = $self->keyed_param_names;
    $cn          = $constructor->name_form($class);
    if ( !@valid_names )
    {
        $form =
"    croak '$cn', join(', ', keys %params), ': Not a member' if keys \%params;\n";
    }
    else
    {
        $form = "    {\n";
        if ( $#valid_names == 0 )
        {
            $form .=
"\tmy \@unknown_params = grep \$_ ne '$valid_names[0]', keys \%params;\n";
        }
        else
        {
            $form .=
                  "\tmy %valid_param = ("
                . join( ', ', map( "'$_' => 1", @valid_names ) ) . ");\n"
                . "\tmy \@unknown_params = grep ! defined \$valid_param{\$_}, keys \%params;\n";
        }
        $form .=
"\tcroak '$cn', join(', ', \@unknown_params), ': Not a member' if \@unknown_params;\n"
            . "    }\n";
    }
    return $form;
}

package Class::Generate::Positional;    # The positional parameter-
$Class::Generate::Positional::VERSION = '1.18';
use strict;                             # passing style.  It adds
use vars qw(@ISA);                      # an ordering of parameters.
@ISA = qw(Class::Generate::Param_Style);

sub new
{
    my $class = shift;
    my $self  = $class->SUPER::new;
    for ( my $i = 0 ; $i <= $#_ ; $i++ )
    {
        $self->{'order'}->{ $_[$i] } = $i;
    }
    return $self;
}

sub order
{
    my $self = shift;
    return exists $self->{'order'} ? %{ $self->{'order'} } : () if $#_ == -1;
    return exists $self->{'order'} ? $self->{'order'}->{ $_[0] } : undef
        if $#_ == 0;
    $self->{'order'}->{ $_[0] } = $_[1];
}

sub ref
{
    my $self = shift;
    return '$_[' . $self->{'order'}->{ $_[0] } . ']';
}

sub existence_test
{
    return 'defined';
}

sub self_from_super_form
{
    my $self  = shift;
    my $class = $_[0];
    my $lb    = scalar( $class->public_member_names ) || 0;
    return
          '    my @super_params = @_['
        . $lb
        . '..$#_];' . "\n"
        . $self->my_decl_form($class)
        . "(\@super_params);\n";
}

sub params_check_form
{
    my $self = shift;
    my ( $class, $constructor ) = @_;
    my $cn         = $constructor->name_form($class);
    my $max_params = scalar( $class->public_member_names ) || 0;
    return
          qq|    croak '$cn|
        . qq|Only $max_params parameter(s) allowed (', \$#_+1, ' given)'|
        . " unless \$#_ < $max_params;\n";
}

package Class::Generate::Mix;    # The mix parameter-passing
$Class::Generate::Mix::VERSION = '1.18';
use strict;                      # style.  It combines key/value
use vars qw(@ISA);               # and positional.
@ISA = qw(Class::Generate::Param_Style);

sub new
{
    my $class = shift;
    my $self  = $class->SUPER::new;
    $self->{'pp'} = Class::Generate::Positional->new( @{ $_[1] } );
    $self->{'kv'} = Class::Generate::Key_Value->new( $_[0], @_[ 2 .. $#_ ] );
    $self->{'pnames'} = { map( ( $_ => 1 ), @{ $_[1] } ) };
    return $self;
}

sub keyed_param_names
{
    my $self = shift;
    return $self->{'kv'}->keyed_param_names;
}

sub order
{
    my $self = shift;
    return $self->{'pp'}->order(@_) if $#_ <= 0;
    $self->{'pp'}->order(@_);
    $self->{'pnames'}{ $_[0] } = 1;
}

sub ref
{
    my $self = shift;
    return $self->{'pnames'}->{ $_[0] }
        ? $self->{'pp'}->ref( $_[0] )
        : $self->{'kv'}->ref( $_[0] );
}

sub existence_test
{
    my $self = shift;
    return $self->{'pnames'}->{ $_[0] }
        ? $self->{'pp'}->existence_test
        : $self->{'kv'}->existence_test;
}

sub pcount
{
    my $self = shift;
    return exists $self->{'pnames'} ? scalar( keys %{ $self->{'pnames'} } ) : 0;
}

sub init_form
{
    my $self = shift;
    my ( $class, $constructor ) = @_;
    my ( $form,  $m )           = ( '', $self->max_possible_params($class) );
    $form .=
        $self->odd_params_check_form( $class, $constructor, $self->pcount, $m )
        if $class->check_params;
    $form .= '    my %params = ' . $self->kv_params_form($m) . ";\n";
    return $form;
}

sub odd_params_test
{
    my $self  = shift;
    my $class = $_[0];
    my ( $p, $test );
    $p    = $self->pcount;
    $test = '$#_>=' . $p;
    $test .= ' && $#_<=' . $self->max_possible_params($class)
        if $class->parents;
    $test .= ' && $#_%2 == ' . ( $p % 2 == 0 ? '0' : '1' );
    return $test;
}

sub self_from_super_form
{
    my $self               = shift;
    my $class              = $_[0];
    my @positional_members = keys %{ $self->{'pnames'} };
    my %self_members       = map { ( $_ => 1 ) } $class->public_member_names;
    delete @self_members{@positional_members};
    my $m = $self->max_possible_params($class);
    return
          $self->my_decl_form($class) . '(@_['
        . ( $m + 1 )
        . '..$#_]);' . "\n";
}

sub max_possible_params
{
    my $self  = shift;
    my $class = $_[0];
    my $p     = $self->pcount;
    return $p + 2 * ( scalar( $class->public_member_names ) - $p ) - 1;
}

sub params_check_form
{
    my $self = shift;
    my ( $class, $constructor ) = @_;
    my ( $form, $cn );
    $cn   = $constructor->name_form($class);
    $form = $self->{'kv'}->params_check_form(@_);
    my $max_params = $self->max_possible_params($class) + 1;
    $form .=
          qq|    croak '$cn|
        . qq|Only $max_params parameter(s) allowed (', \$#_+1, ' given)'|
        . " unless \$#_ < $max_params;\n";
    return $form;
}

sub kv_params_form
{
    my $self       = shift;
    my $max_params = $_[0];
    return
          '@_['
        . $self->pcount
        . "..(\$#_ < $max_params ? \$#_ : $max_params)]";
}

package Class::Generate::Own;    # The "own" parameter-passing
$Class::Generate::Own::VERSION = '1.18';
use strict;                      # style.
use vars qw(@ISA);
@ISA = qw(Class::Generate::Param_Style);

sub new
{
    my $class = shift;
    my $self  = $class->SUPER::new;
    $self->{'super_values'} = $_[0] if defined $_[0];
    return $self;
}

sub super_values
{
    my $self = shift;
    return defined $self->{'super_values'} ? @{ $self->{'super_values'} } : ();
}

sub can_assign_all_params
{
    return 0;
}

sub self_from_super_form
{
    my $self  = shift;
    my $class = $_[0];
    my ( $form, @sv );
    $form = $self->my_decl_form($class);
    if ( @sv = $self->super_values )
    {
        $form .= '(' . join( ',', @sv ) . ')';
    }
    $form .= ";\n";
    return $form;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Class::Generate - Generate Perl class hierarchies

=head1 VERSION

version 1.18

=head1 SYNOPSIS

 use Class::Generate qw(class subclass delete_class);

 # Declare class Class_Name, with the following types of members:
 class
     Class_Name => [
         s => '$',			# scalar
	 a => '@',			# array
	 h => '%',			# hash
	 c => 'Class',			# Class
	 c_a => '@Class',		# array of Class
	 c_h => '%Class',		# hash of Class
         '&m' => 'body',		# method
     ];

 # Allocate an instance of class_name, with members initialized to the
 # given values (pass arrays and hashes using references).
 $obj = Class_Name->new ( s => scalar,
			  a => [ values ],
			  h => { key1 => v1, ... },
			  c => Class->new,
			  c_a => [ Class->new, ... ],
			  c_h => [ key1 => Class->new, ... ] );

		# Scalar type accessor:
 $obj->s($value);			# Assign $value to member s.
 $member_value = $obj->s;		# Access member's value.

		# (Class) Array type accessor:
 $obj->a([value1, value2, ...]);	# Assign whole array to member.
 $obj->a(2, $value);			# Assign $value to array member 2.
 $obj->add_a($value);			# Append $value to end of array.
 @a = $obj->a;				# Access whole array.
 $ary_member_value = $obj->a(2);	# Access array member 2.
 $s = $obj->a_size;			# Return size of array.
 $value = $obj->last_a;			# Return last element of array.

		# (Class) Hash type accessor:
 $obj->h({ k_1=>v1, ..., k_n=>v_n })	# Assign whole hash to member.
 $obj->h($key, $value);			# Assign $value to hash member $key.
 %hash = $obj->h;			# Access whole hash.
 $hash_member_value = $obj->h($key);	# Access hash member value $key.
 $obj->delete_h($key);			# Delete slot occupied by $key.
 @keys = $obj->h_keys;			# Access keys of member h.
 @values = $obj->h_values;		# Access values of member h.

 $another = $obj->copy;			# Copy an object.
 if ( $obj->equals($another) ) { ... }	# Test equality.

 subclass s  => [ <more members> ], -parent => 'class_name';

=head1 DESCRIPTION

The C<Class::Generate> package exports functions that take as arguments
a class specification and create from these specifications a Perl 5 class.
The specification language allows many object-oriented constructs:
typed members, inheritance, private members, required members,
default values, object methods, class methods, class variables, and more.

CPAN contains similar packages.
Why another?
Because object-oriented programming,
especially in a dynamic language like Perl,
is a complicated endeavor.
I wanted a package that would work very hard to catch the errors you
(well, I anyway) commonly make.
I wanted a package that could help me
enforce the contract of object-oriented programming.
I also wanted it to get out of my way when I asked.

=head1 THE CLASS FUNCTION

You create classes by invoking the C<class> function.
The C<class> function has two forms:

    class Class_Name => [ specification ];	# Objects are array-based.
    class Class_Name => { specification };	# Objects are hash-based.

The result is a Perl 5 class, in a package C<Class_Name>.
This package must not exist when C<class> is invoked.

An array-based object is faster and smaller.
A hash-based object is more flexible.
Subsequent sections explain where and why flexibility matters.

The specification consists of zero or more name/value pairs.
Each pair declares one member of the class,
with the given name, and with attributes specified by the given value.

=head1 MEMBER TYPES

In the simplest name/value form,
the value you give is a string that defines the member's type.
A C<'$'> denotes a scalar member type.
A C<'@'> denotes an array type.
A C<'%'> denotes a hash type.
Thus:

    class Person => [ name => '$', age => '$' ];

creates a class named C<Person> with two scalar members,
C<name> and C<age>.

If the type is followed by an identifier,
the identifier is assumed to be a class name,
and the member is restricted to a blessed reference of the class
(or one of its subclasses),
an array whose elements are blessed references of the class,
or a hash whose keys are strings
and whose values are blessed references of the class.
For scalars, the C<$> may be omitted;
i.e., C<Class_Name> and C<$Class_Name> are equivalent.
The class need not be declared using the C<Class::Generate> package.

=head1 CREATING INSTANCES

Each class that you generate has a constructor named C<new>.
Invoking the constructor creates an instance of the class.
You may provide C<new> with parameters to set the values of members:

    class Person => [ name => '$', age => '$' ];
    $p = Person->new;			# Neither name nor age is defined.
    $q = Person->new( name => 'Jim' );	# Only name is defined.
    $r = Person->new( age => 32 );	# Only age is defined.

=head1 ACCESSOR METHODS

A class has a standard set of accessor methods for each member you specify.
The accessor methods depend on a member's type.

=head2 Scalar (name => '$', name => 'Class_Name', or name => '$Class_Name')

The member is a scalar.
The member has a single method C<name>.
If called with no arguments, it returns the member's current value.
If called with arguments, it sets the member to the first value:

    $p = Person->new;
    $p->age(32);		# Sets age member to 32.
    print $p->age;		# Prints 32.

If the C<Class_Name> form is used, the member must be a reference blessed
to the named class or to one of its subclasses.
The method will C<croak> (see L<Carp>) if the argument is not
a blessed reference to an instance of C<Class_Name> or one of its subclasses.

    class Person => [
	name => '$',
	spouse => 'Person'	# Works, even though Person
    ];				# isn't yet defined.
    $p = Person->new(name => 'Simon Bar-Sinister');
    $q = Person->new(name => 'Polly Purebred');
    $r = Person->new(name => 'Underdog');
    $r->spouse($q);				# Underdog marries Polly.
    print $r->spouse->name;			# Prints 'Polly Purebred'.
    print "He's married" if defined $p->spouse;	# Prints nothing.
    $p->spouse('Natasha Fatale');		# Croaks.

=head2 Array (name => '@' or name => '@Class')

The member is an array.
If the C<@Class> form is used, all members of the array must be
a blessed reference to C<Class> or one of its subclasses.
An array member has four associated methods:

=over 4

=item C<name>

With no argument, C<name> returns the member's whole array.

With one argument, C<name>'s behavior depends on
whether the argument is an array reference.
If it is not, then the argument must be an integer I<i>,
and C<name> returns element I<i> of the member.
If no such element exists, C<name> returns C<undef>.
If the argument is an array reference,
it is cast into an array and assigned to the member.

With two arguments, the first argument must be an integer I<i>.
The second argument is assigned to element I<i> of the member.

=item C<add_name>

This method appends its arguments to the member's array.

=item C<name_size>

This method returns the index of the last element in the array.

=item C<last_name>

This method returns the last element of C<name>,
or C<undef> if C<name> has no elements.
It's a shorthand for C<$o-E<gt>array_mem($o-E<gt>array_mem_size)>.

=back

For example:

    class Person => [ name => '$', kids => '@Person' ];
    $p = Person->new;
    $p->add_kids(Person->new(name => 'Heckle'),
		 Person->new(name => 'Jeckle'));
    print $p->kids_size;	# Prints 1.
    $p->kids([Person->new(name => 'Bugs Bunny'),
	      Person->new(name => 'Daffy Duck')]);
    $p->add_kids(Person->new(name => 'Yosemite Sam'),
		 Person->new(name => 'Porky Pig'));
    print $p->kids_size;	# Prints 3.
    $p->kids(2, Person->new(name => 'Elmer Fudd'));
    print $p->kids(2)->name;	# Prints 'Elmer Fudd'.
    @kids = $p->kids;		# Get all the kids.
    print $p->kids($p->kids_size)->name; # Prints 'Porky Pig'.
    print $p->last_kids->name;	   # So does this.

=head2 Hash (name => '%' or name => '%Class')

The member is a hash.
If the C<%Class> form is used, all values in the hash
must be a blessed reference to C<Class> or one of its subclasses.
A hash member has four associated methods:

=over 4

=item C<name>

With no arguments, C<name> returns the member's whole hash.

With one argument that is a hash reference,
the member's value becomes the key/value pairs in that reference.
With one argument that is a string,
the element of the hash keyed by that string is returned.
If no such element exists, C<name> returns C<undef>.

With two arguments, the second argument is assigned to the hash,
keyed by the string representation of the first argument.

=item C<name_keys>

The C<name_keys> method returns all keys associated with the member.

=item C<name_values>

The C<name_values> method returns all values associated with the member.

=item C<delete_name>

The C<delete_name> method takes one or more arguments.
It deletes from C<name>'s hash all elements matching the arguments.

=back

For example:

    class Person => [ name => '$', kids => '%Kid_Info' ];
    class Kid_Info => [
	grade  => '$',
	skills => '@'
    ];
    $f = new Person(
	name => 'Fred Flintstone',
	kids => { Pebbles => new Kid_Info(grade => 1,
				          skills => ['Programs VCR']) }
    );
    print $f->kids('Pebbles')->grade;	# Prints 1.
    $b = new Kid_Info;
    $b->grade('Kindergarten');
    $b->skills(['Knows Perl', 'Phreaks']);
    $f->kids('BamBam', $b);
    print join ', ', $f->kids_keys;	# Prints "Pebbles, BamBam",
					# though maybe not in that order.

=head1 COMMON METHODS

All members also have a method C<undef_m>.
This method undefines a member C<m>.

=head1 OBJECT INSTANCE METHODS

C<Class::Generate> also generates methods
that you can invoke on an object instance.
These are as follows:

=head2 Copy

Use the C<copy> method to copy the value of an object.
The expression:

    $p = $o->copy;

assigns to C<$p> a copy of C<$o>.
Members of C<$o> that are classes (or arrays or hashes of classes)
are copied using their own C<copy> method.

=head2 Equals

Use the C<equals> method to test the equality of two object instances:

    if ( $o1->equals($o2) ) { ... }

The two object instances are equal if
members that have values in C<$o1> have equal values in C<$o2>, and vice versa.
Equality is tested as you would expect:
two scalar members are equal if they have the same value;
two array members are equal if they have the same elements;
two hash members are equal if they have the same key/value pairs.

If a member's value is restricted to a class,
then equality is tested using that class' C<equals> method.
Otherwise, it is tested using the C<eq> operator.

By default, all members participate in the equality test.
If one or more members possess true values for the C<key> attribute,
then only those members participate in the equality test.

You can override this definition of equality.
See L<ADDING METHODS>.

=head1 ADVANCED MEMBER SPECIFICATIONS

As shown, you specify each member as a C<name=E<gt>value> pair.
If the C<value> is a string, it specifies the member's type.
The value may also be a hash reference.
You use hash references to specify additional member attributes.
The following is a complete list of the attributes you may specify for a member:

=over 4

=item type=>string

If you use a hash reference for a member's value,
you I<must> use the C<type> attribute to specify its type:

    scalar_member => { type => '$' }

=item required=>boolean

If the C<required> attribute is true,
the member must be passed each time the class' constructor is invoked:

    class Person => [ name => { type => '$', required => 1 } ];
    Person->new ( name => 'Wilma' );	# Valid
    Person->new;			# Invalid

Also, you may not call C<undef_name> for the member.

=item default=>value

The C<default> attribute provides a default value for a member
if none is passed to the constructor:

    class Person => [ name => '$',
		      job => { type => '$',
			       default => "'Perl programmer'" } ];
    $p = Person->new(name => 'Larry');
    print $p->job;		# Prints 'Perl programmer'.
    $q = Person->new(name => 'Bjourne', job => 'C++ programmer');
    print $q->job;		# Unprintable.

The value is treated as a string that is evaluated
when the constructor is invoked.

For array members, use a string that looks like a Perl expression
that evaluates to an array reference:

    class Person => {
	name => '$',
	lucky_numbers => { type => '@', default => '[42, 17]' }
    };
    class Silly => {
	UIDs => {		# Default value is all UIDs
	    type => '@',	# currently in /etc/passwd.
	    default => 'do {
		local $/ = undef;
		open PASSWD, "/etc/passwd";
		[ map {(split(/:/))[2]} split /\n/, <PASSWD> ]
	    }'
	}
    };

Specify hash members analogously.

The value is evaluated each time the constructor is invoked.
In C<Silly>, the default value for C<UIDs> can change between invocations.
If the default value is a reference rather than a string,
it is not re-evaluated.
In the following, default values for C<e1> and C<e2>
are based on the members of C<@default_value>
each time C<Example-E<gt>new> is invoked,
whereas C<e3>'s default value is set when the C<class> function is invoked
to define C<Example>:

    @default_value = (1, 2, 3);
    $var_name = '@' . __PACKAGE__ . '::default_value';
    class Example => {
        e1 => { type => '@', default => "[$var_name]" },
	e2 => { type => '@', default => \@default_value },
	e3 => { type => '@', default => [ @default_value ] }
    };
    Example->new;	# e1, e2, and e3 are all identical.
    @default_value = (10, 20, 30);
    Example->new;	# Now only e3 is (1, 2, 3).

There are two more things to know about default values that are strings.
First, if a member is typed,
the C<class> function evaluates its (string-based)
default value to ensure that it
is of the correct type for the member.
Be aware of this if your default value has side effects
(and see L<Checking Default Value Types>).

Second, the context of the default value is the C<new()> method
of the package generated to implement your class.
That's why C<e1> in C<Example>, above,
needs the name of the current package in its default value.

=item post=>code

The value of this attribute is a string of Perl code.
It is executed immediately after the member's value is modified through its accessor.
Within C<post> code, you can refer to members as if they were Perl identifiers.
For instance:

    class Person => [ age => { type => '$',
			       post => '$age *= 2;' } ];
    $p = Person->new(age => 30);
    print $p->age;	# Prints 30.
    $p->age(15);
    print $p->age;	# Prints 30 again.

The trailing semicolon used to be required, but everyone forgot it.
As of version 1.06 it's optional:
C<'$age*=2'> is accepted and equivalent to C<'$age*=2;'>
(but see L<"BUGS">).

You reference array and hash members as usual
(except for testing for definition; see L<"BUGS">).
You can reference individual elements, or the whole list:

    class Foo => [
	m1 => { type => '@', post => '$m1[$#m1/2] = $m2{xxx};' },
	m2 => { type => '%', post => '@m1 = keys %m2;' }
    ];

You can also invoke accessors.
Prefix them with a C<&>:

    class Bar => [
	m1 => { type => '@', post => '&undef_m1;' },
	m2 => { type => '%', post => '@m1 = &m2_keys;' }
    ];
    $o = new Bar;
    $o->m1([1, 2, 3]);		# m1 is still undefined.
    $o->m2({a => 1, b => 2});	# Now m1 is qw(a b).

=item pre=>code

The C<pre> key is similar to the C<post> key,
but it is executed just before an member is changed.
It is I<not> executed if the member is only accessed.
The C<pre> and C<post> code have the same scope,
which lets you share variables.
For instance:

    class Foo => [
	mem => { type => '$', pre => 'my $v = $mem;', post => 'return $v;' }
    ];
    $o = new Foo;
    $p = $o->mem(1);	# Sets $p to undef.
    $q = $o->mem(2);	# Sets $q to 1.

is a way to return the previous value of C<mem> any time it's modified
(but see L<"NOTES">).

=item assert=>expression

The value of this key should be a Perl expression
that evaluates to true or false.
Use member names in the expression, as with C<post>.
The expression will be tested any time
the member is modified through its accessors.
Your code will C<croak> if the expression evaluates to false.
For instance,

    class Person => [
	name => '$',
	age => { type => '$',
		 assert => '$age =~ /^\d+$/ && $age < 200' } ];

ensures the age is reasonable.

The assertion is executed after any C<post> code associated with the member.

=item private=>boolean

If the C<private> attribute is true,
the member cannot be accessed outside the class;
that is, it has no accessor functions that can be called
outside the scope of the package defined by C<class>.
A private member can, however, be accessed in C<post>, C<pre>, and C<assert>
code of other members of the class.

=item protected=>boolean

If the C<protected> attribute is true,
the member cannot be accessed outside the class or any of its subclasses.
A protected member can, however, be accessed in C<post>, C<pre>, and C<assert>
code of other members of the class or its subclasses.

=item readonly=>boolean

If this attribute is true, then the member cannot be modified
through its accessors.
Users can set the member only by using the class constructor.
The member's accessor that is its name can retrieve but not set the member.
The C<undef_>I<name> accessor is not defined for the member,
nor are other accessors that might modify the member.
(Code in C<post> can set it, however.)

=item key=>boolean

If this attribute is true, then the member participates in equality tests.
See L<"Equals">.

=item nocopy=>value

The C<nocopy> attribute gives you some per-member control
over how the C<copy> method.
If C<nocopy> is false (the default),
the original's value is copied as described in L<"Copy">.
If C<nocopy> is true,
the original's value is assigned rather than copied;
in other words, the copy and the original will have the same value
if the original's value is a reference.

=back

=head1 AFFECTING THE CONSTRUCTOR

You may include a C<new> attribute in the specification to affect the constructor.
Its value must be a hash reference.
Its attributes are:

=over 4

=item required=>list of constraints

This is another (and more general) way to require that
parameters be passed to the constructor.
Its value is a reference to an array of constraints.
Each constraint is a string that must be an expression
composed of Perl logical operators and member names.
For example:

    class Person => {
	name   => '$',
        age    => '$',
	height => '$',
	weight => '$',
	new => { required => ['name', 'height^weight'] }
    };

requires member C<name>, and exactly one of C<height> or C<weight>.
Note that the names are I<not> prefixed with C<$>, C<@>, or C<%>.

Specifying a list of constraints as an array reference can be clunky.
The C<class> function also lets you specify the list as a string,
with individual constraints separated by spaces.
The following two strings are equivalent to the above C<required> attribute:

    'name height^weight'
    'name&(height^weight)'

However, C<'name & (height ^ weight)'> would not work.
The C<class> function interprets it as a five-member list,
four members of which are not valid expressions.

This equivalence between a reference to array of strings
and a string of space-separated items is used throughout C<Class::Generate>.
Use whichever form works best for you.

=item post=>string of code

The C<post> key is similar to the C<post> key for members.
Its value is code that is inserted into the constructor
after parameter values have been assigned to members.
The C<class> function performs variable substitution.

The C<pre> key is I<not> recognized in C<new>.

=item assert=>expression

The C<assert> key's value is inserted
just after the C<post> key's value (if any).
Assertions for members are inserted after the constructor's assertion.

=item comment=>string

This attribute's value can be any string.
If you save the class to a file
(see L<Saving the Classes>),
the string is included as a comment just before
the member's methods.

=item style=>style definition

The C<style> attribute controls how parameters
are passed to the class' constructor.
See L<PARAMETER PASSING STYLES>.

=back

=head1 ADDING METHODS

Accessors often do not provide a class with enough functionality.
They also do not encapsulate your algorithms.
For these reasons, the C<class> function lets you add methods.
Both object methods and class methods are allowed.

Add methods using an member of the form C<'&name'=E<gt>body>,
where C<body> is a string containing valid Perl code.
This yields a method C<name> with the specified C<body>.
For object methods, the C<class> function performs variable substitution
as described in L<ADVANCED MEMBER SPECIFICATIONS>.
For example,

    class Person => [ first_name => '$',
		      last_name  => '$',
		      '&name'    => q{return "$first_name $last_name";}
    ];
    $p = Person->new(first_name => 'Barney', last_name => 'Rubble');
    print $p->name;	# Prints "Barney Rubble".

    class Stack => [	# Venerable example.
	top_e	 => { type => '$', private => 1, default => -1 },
	elements => { type => '@', private => 1, default => '[]' },
	'&push' => '$elements[++$top_e] = $_[0];',
	'&pop'  => '$top_e--;',
	'&top'  => 'return $elements[$top_e];'
    ];

A method has the following attributes which,
like members, are specified as a hash reference:

=over 4

=item body=>code

This attribute specifies the method's body.
It is required if other attributes are given.

=item private=>boolean

The method cannot be accessed outside the class.

    class Example => [
	m1 => '$',
	m2 => '$',
	'&public_interface' => q{return &internal_algorithm;},
	'&internal_algorithm' => { private => 1,
				   body => q{return $m1 + 4*$m2;} }
    ];
    $e = Example->new(m1 => 2, m2 => 4);
    print $e->public_interface;		# Prints 18.
    print $e->internal_algorithm;	# Run-time error.

=item protected=>boolean

If true, the method cannot be accessed outside the class or any of its subclasses.

=item class_method=>boolean

If true, the method applies to classes rather than objects.
Member name substitution is I<not> performed within a class method.
You can, however, use accessors, as usual:

    class Foo => [
	m1 => '$', m2 => '@',
	'&to_string' => {
	    class_method => 1,
	    body => 'my $o = $_[0];
		     return $o->m1 . "[" . join(",", $o->m2) . "]"';
	}
    ];
    $f = Foo->new(m1 => 1, m2 => [2, 3]);
    print Foo->to_string($f);	# Prints "1[2,3]"

You can also call class methods from within instance and class methods.
Use the C<Class-E<gt>method> syntax.

Currently, a class method may be public or private, but not protected.

=item objects=>list of object instance expressions

This attribute is only used for class methods.
It is needed when the method refers to a private or protected member or method.
Its argument is a list,
each element of which is a Perl expression that occurs in the body
of the class method.
The expression must evaluate to an instance of the class.
It will be replaced by an appropriate reference to the private member or method.
For example:

    class Bar => [
	mem1 => '$',
	mem2 => { type => '@', private => 1 },
	'&meth1' => 'return $mem1 + $#mem2;',
	'&meth2' => { private => 1,
		      body    => 'return eval join "+", @mem2;' },
	'&cm1' => { class_method => 1,
		    objects => '$o',
		    body => 'my $o = Bar->new(m1 => 8);
			     $o->mem2([4, 5, 6]);
			     return $o->meth2;' },
	'&cm2' => { class_method => 1,
		    objects => ['$o', 'Bar->new(m1 => 3)'],
		    body => 'my $o => Bar->new(m1 => 8);
			     $o->mem2(0, Bar->new(m1 => 3)->meth2);
			     return $o;' }
    ];

The C<objects> attribute for C<cm1> tells C<class>
to treat all occurrences of the string C<$o> as an instance of class C<Bar>,
giving the expression access to private members and methods of C<Bar>.
The string can be an arbitrary expression, as long as it's valid Perl
and evaluates to an instance of the class;
hence the use of C<Bar-E<gt>new(m1 =E<gt> 3)> in C<cm2>.
The string must match exactly,
so C<Bar-E<gt>new(m1 =E<gt> 8)> is not replaced.

=back

You can add a method named C<&equals>
to provide your own definition of equality.
An example:

    $epsilon = 0.1e-20;
    class Imaginary_No => {			# Treat floating-point
	real => '$',				# values as equal if their
	imag => '$',				# difference is less than
	'&equals' => qq|my \$o = \$_[0];	# some epsilon.
		        return abs(\$real - \$o->real) < $epsilon &&
			       abs(\$imag - \$o->imag) < $epsilon;|
    };

If you declare C<&equals> to be private, you create a class
whose instances cannot be tested for equality except within the class.

=head1 THE SUBCLASS FUNCTION

The C<subclass()> function declares classes
that are subclasses of another class.
The statement:

    subclass S => [ specification ], -parent => P

declares a package C<s>, and a constructor function C<new>, just like C<class>;
but C<s-E<gt>new> yields a blessed reference that inherits from C<P>.
You can use all the attributes discussed above in the specification
of a subclass.
(Prior to version 1.02 you specified the parent using C<parent=E<gt>P>,
but this is deprecated in favor of C<-parent=E<gt>P>.)

As of version 1.05, the C<class> function also accepts C<-parent>.
In other words,

    class S => [ specification ], -parent => P
    subclass S => [ specification ], -parent => P

are equivalent.

Class C<P> need not have been defined
using the C<class> or C<subclass> function.
It must have a constructor named C<new>, however,
or at least be an ancestor of a class that does.

A subclass may be either an array or hash reference.
Its parent must be the same type of reference.

You can inherit from multiple classes, providing all are hash-based
(C<Class::Generate> does not support multiple inheritance
for array-based classes).
Just list more than one class as the value of C<parent>:

    subclass S => { specification }, -parent => 'P1 P2 P3';

Elements of the C<@ISA> array for package C<S>
appear in the order you list them.
This guarantee should let you determine the order in which methods are invoked.

The subclass constructor automatically calls its parent constructor.
It passes to the parent constructor any parameters
that aren't members of the subclass.

Subclass members with the same name as that of their parent
override their parent methods.

You can access a (non-private) member or method of a parent within
user-defined code in the same way you access members or methods of the class:

    class Person => [
	name => '$',
	age => '$',
	'&report' => q{return "$name is $age years old"}
    ];
    subclass Employee => [
	job_title => '$',
	'&report' => q{return "$name is $age years old and is a $job_title";}
    ], -parent => 'Person';
    subclass Manager => [
	workers => '@Employee',
	'&report' => q{return "$name is $age years old, is a $job_title, " .
			      "and manages " . (&workers_size + 1) . " people";}
    ], -parent => 'Employee';

If a class has multiple parents,
and these parents have members whose names conflict,
the name used is determined by a depth-first search of the parents.

The previous example shows that a subclass may declare a member or method
whose name is already declared in one of its ancestors.
The subclass declaration overrides any ancestor declarations:
the C<report> method behaves differently depending on the class of the
instance that invokes it.

Sometimes you override an ancestor's method to add some extra functionality.
In that situation,
you want the overriding method to invoke the ancestor's method.
All user-defined code in C<Class::Generate> has access to a variable C<$self>,
which is a blessed reference.
You therefore can use Perl's C<SUPER::> construct to get at ancestor methods:

    class Person => [
	name => '$',
	age => '$',
	'&report' => q{return &name . ": $age years old"}
    ];
    subclass Employee => [
	job_title => '$',
	'&report' => q{return $self->SUPER::report . "; job: $job_title";}
    ], -parent => 'Person';
    subclass Manager => [
	workers => '@Employee',
	'&report' => q{return $self->SUPER::report . "; manages: " .
			      (&workers_size + 1) . " people";}
    ], -parent => 'Employee';

Currently, you cannot access a protected method of an ancestor this way.
The following code will generate a run-time error:

    class Foo => [
	'&method' => { protected => 1, body => '...' },
    ];
    subclass Bar => [
	'&method' => { protected => 1, body => '$self->SUPER::method;' }
    ], -parent => 'Foo';

=head1 THE DELETE_CLASS FUNCTION

=head2 delete_class

You can delete classes you declare using C<Class::Generate>,
after which you can declare another class with the same name.
Use the C<delete_class> function,
which accepts as arguments one or more class names:

    class Person => [ name => '$' ];
    delete_class 'Person';			 # Nah...
    class Name => [ last => '$', first => '$' ]; # ... let's really encapsulate.
    class Person => [ name = 'Name' ];		 # That's better.

This function silently ignores classes that don't exist,
but it croaks if you try to delete a package that wasn't declared
using C<Class::Generate>.

=head1 FLAGS

You can affect the specification of a class using certain flags.
A flag is a key/value pair passed as an argument to C<class> (or C<subclass>).
The first character of the key is always a hyphen.
The following is a list of recognized flags:

=over 4

=item -use=>list

Your C<pre> or C<post> code, or your methods,
may want to use functions declared in other packages.
List these packages as the value of the C<-use> flag.
For example, suppose you are creating a class that does date handling,
and you want to use functions in the C<Time::Local>
and C<Time::localtime> packages.
Write the class as follows:

    class Date_User => [ ... ],
	-use => 'Time::Local Time::localtime';

Any code you add to C<Date_User> can now access the
time functions declared in these two packages.

To import functions, you need to use the array reference form:

    class Foo => [ ... ],
	-use => ["FileHandle 'autoflush'"];

Otherwise, the C<class> function would assume you want to use two packages,
C<Filehandle> and C<'autoflush'>.

=item -class_vars=>list

A class can have class variables,
i.e., variables accessible to all instances of the class
as well as to class methods.
Specify class variables using the C<-class_vars> flag.
For example, suppose you want the average age of all Persons:

    $compute_average_age = '$n++; $total += $age; $average = $total/$n;';
    class Person => [
	name => '$',
	age  => { type => '$', required => 1, readonly => 1 },
	new  => { post => $compute_average_age }
    ],
        -class_vars => '$n $total $average';
    $p = Person->new(age => 24);		# Average age is now 24.
    $q = Person->new(age => 30);		# Average age is now 27.

You can also provide an initial value for class variables.
Specify the value of C<-class_vars> as an array reference.
If any member of this array is a hash reference,
its members are taken to be variable name/initial value pairs.
For example:

    class Person => [ name => '$',
		      age => { type => '$', required => 1, readonly => 1 },
		      new => { post => $compute_average_age }
    ],
	  -class_vars => [ { '$n' => 0 },
			   { '$total' => 0 },
			   '$average' ];

C<Class::Generate> evaluates the initial value
as part of evaluating your class.
This means you must quote any strings:

    class Room => [
    ],
	  -class_vars => [ { '$board' => "'white'" } ];

=item -virtual=>boolean

A virtual class is a class that cannot be instantiated,
although its descendents can.
Virtual classes are useful as modeling aids and debugging tools.
Specify them using the C<-virtual> flag:

    class Parent =>   [ e => '$' ], -virtual => 1;
    subclass Child => [ d => '$' ], -parent => 'Parent';
    Child->new;		# This is okay.
    Parent->new;	# This croaks.

There is no built-in way to specify a virtual method,
but the following achieves the desired effect:

    class Foo => [ '&m' => 'die "m is a virtual method";' ];

=item -comment=>string

The string serves as a comment for the class.

=item -options=>{ options }

This flag lets you specify options
that alter the behavior of C<Class::Generate>.
See L<"OPTIONS">.

=item -exclude=>string

Sometimes it isn't appropriate for a user to be able to copy an object.
And sometimes testing the equality of two object instances makes no sense.
For these and other situations,
you have some control over the automatically generated methods for each class.

You control method generation using the C<-exclude> flag.
Its value is a string of space-separated regular expressions.
A method is included if it does I<not> match any of the regular expressions.
For example, a person has a unique social security number,
so you might want a class where a person can't be copied:

    class Person => [
	name => '$',
	ssn  => { type => '$', readonly => 1 }
    ], -exclude => '^copy$';
    $o = Person->new name => 'Forrest Gump', ssn => '000-00-0000';
    $p = $o->copy;	# Run-time error.

The C<-exclude> flag can describe a whole range of esoteric restrictions:

    class More_Examples => [
	mem1 => { type => '$', required => 1 },
	mem2 => { type => '@', required => 1 },
	mem3 => '%',
	new => { post => '%mem3 = map { $_ => $mem1 } @mem2' }
    ], -exclude => 'undef_ mem2_size mem3';
    $o = More_Examples->new mem1 => 1, mem2 => [2, 3, 4];
    @keys = $o->mem3_keys;	# Run-time error.
    $o->undef_mem1;		# Ditto.
    print $o->last_mem2;	# This works as expected.
    print $o->mem2_size;	# But this blows up.

In C<More_Examples>, it isn't possible to undefine a member.
The size of C<mem2> can't be determined.
And C<mem3> is effectively private
(it can't even be accessed from class methods).

=back

=head1 PARAMETER PASSING STYLES

By default, parameters to the constructor are passed
using a C<name=E<gt>value> form.
You have some control over this using the C<style> key
in a constructor's C<new> specifier.
It lets you pass parameters to constructors using one of the following styles:

=over 4

=item Key/Value

This is the default.
Parameters are passed using the C<name=E<gt>value> form,
as shown in previous examples.
Specify it as C<style=E<gt>'key_value'> if you want to be explicit.

=item Positional

Parameters are passed based on a positional order you specify.
For example:

    class Foo => [ e1 => '$', e2 => '@', e3 => '%',
	           new => { style => 'positional e1 e2 e3' } ];
    $obj = Foo->new(1);			# Sets e1 to 1.
    $obj = Foo->new(1, [2,3]);		# Ditto, and sets e2 to (2,3).
    my %hash = (foo => 'bar');
    $obj = Foo->new(1,			# Ditto,
		    [2, 3],		# ditto,
		    {%hash});		# and sets e3 to %hash.

You must list all non-private members,
although you do not have to include all of them in
every invocation of C<new>.
Also, if you want to set C<e1> and C<e3> but not C<e2>,
you can give C<undef> as C<e2>'s value:

    $obj = Foo->new(1, undef, { e3_value => 'see what I mean?' });

=item Mixed Styles

Parameters are passed mixing the positional and key/value styles.
The values following C<mix> are the names of the positional parameters,
in the order in which they will be passed.
This style is useful when certain parameters are "obvious".
For example:

    class Person => [
	first_name => { type => '$', required => 1 },
	last_name  => { type => '$', required => 1 },
	favorite_language => '$',
	favorite_os	  => '$',
	new => { style => 'mix first_name last_name' }
    ];
    $obj = Person->new('Joe',  'Programmer', favorite_language => 'Perl');
    $obj = Person->new('Sally', 'Codesmith', favorite_os       => 'Linux');

The positional parameters need not be required,
but they must all be given if you want to set any members passed as
key/value parameters.

=item Your Own Parameter Handling

Finally, sometimes you want a constructor whose parameters aren't the members.
Specify such classes using C<own>.
Access the parameters through C<@_>, as usual in Perl:

    class Person => [
	first => { type => '$', private => 1 },
	last  => { type => '$', private => 1 },
	new   => { style => 'own',
		   post => '($first, $last) = split /\s+/, $_[0];' },
	'&name' => q|return $last . ', ' . $first;|
    ];
    $p = Person->new('Fred Flintstone');
    print $p->name;			# Prints 'Flintstone, Fred'.

If C<own> is followed by a space, and the class has a parent,
everything after the space is treated as
a space-separated list of Perl expressions,
and these expressions are passed to the superclass constructor.
The expressions are passed in the order given.
Thus:

    subclass Child => [
	grade => '$',
	new   => { style => 'own $_[0]', post => '$grade = $_[1];' }
    ], -parent => 'Person';

Now you can create a C<Child> by passing the grade as the second parameter,
and the name as the first:

    $c = Child->new('Penny Robinson', 5);

The C<own> style causes the C<type>, C<required>, and C<default> member
specifications to be ignored.

=back

If you use styles other than C<key_value>,
you must be aware of how a subclass constructor passes parameter
to its superclass constructor.
C<Class::Generate> has some understanding of styles,
but not all combinations make sense,
and for those that do, you have to follow certain conventions.
Here are the rules for a subclass C<S> with parent C<P>:

=over 4

=item 1.

If C<S>'s constructor uses the C<key_value> style,
C<P>'s constructor must use the C<key_value> or C<own> style.
The parameters are treated as a hash;
C<P>'s constructor receives a hash with
all elements indexed by nonprivate members of C<S> deleted.
C<P>'s constructor must not expect
the hash elements to be passed in a prespecified order.

=item 2.

If C<S>'s constructor uses the C<positional> style,
C<P>'s constructor may use any style.
If C<S> has C<n> nonprivate members,
then parameters 0..I<n>-1 are used to assign members of C<S>.
Remaining parameters are passed to C<P::new>,
in the same order they were passed to C<S::new>.

=item 3.

If C<S>'s constructor uses the C<mix> style,
C<P>'s constructor may use any style.
If C<S> has I<n> nonprivate members,
of which I<p> are passed by position,
then parameters 0..(I<p>-1)+2*(I<n>-I<p>) are used to assign members of C<S>.
Remaining parameters are passed to C<P::new>,
in the same order they were passed to C<S::new>.

=item 4.

If C<S>'s constructor uses the C<own> style,
you are responsible for ensuring that it passes parameters to
C<P>'s constructor in the correct style.

=back

=head1 OPTIONS

The C<Class::Generate> package provides what its author believes is
reasonable default style and behavior.
But if you disagree,
there are certain defaults you can control on a class-by-class basis,
or for all classes you generate.
These defaults are specified as options.
An option is given in one of two ways:

=over 4

=item 1.

Via the C<-options> flag,
the value of which is a hash reference containing the individual options.
This affects an individual class.

=item 2.

By setting a variable declared in C<Class::Generate>.
The variable has the same name as the option.
This affects all subsequently generated classes
except those where the option is explicitly overridden
via the C<-options> flag.
You may export these variables, although they are not exported by default.

=back

The following sections list the options
that C<class> and C<subclass> recognize.

=head2 Saving the Classes

If the C<save> option is true for class C<c>,
the code implementing it will be saved to file C<c.pm>.
This is useful in several situations:

=over 4

=item 1.

You may need functionality that C<class> and C<subclass> cannot provide.

=item 2.

Errors in your methods, or in C<pre> and C<post> code,
can result in obscure diagnostics.
Debugging classes is easier if they are saved in files.
This is especially true if you use Emacs for debugging,
as Emacs does not handle evaluated expressions very well.

=item 3.

If you have many classes,
there is overhead in regenerating them each time you execute your program.
Accessing them in files may be faster.

=back

If the value of C<save> looks like a Perl file name
(i.e., if it ends in C<.pl> or C<.pm>),
the class is appended to that file.
This feature lets your program avoid the overhead
of opening and closing multiple files.
It also saves you from the burden of maintaining multiple files.

All comments specified using C<comment> attributes
and the C<-comment> flag are saved along with your code.

=head2 Passing References

Sometimes you want to be able to assign a whole array to an array member
(or a whole hash to a hash member):

    class Person => [
	name	=> '$',
	parents => '@Person',
	new	=> { style => 'positional name parents' }
    ];
    $p = Person->new('Will Robinson');
    $p->parents( [ Person->new('John Robinson'),
		   Person->new('Maureen Robinson') ] );

But sometimes you don't.
Often you only have one member value available at any time,
and you only want to add values:

    class Person => [
	name	=> '$',
	parents => '@Person',
	new	=> { style => 'positional name parents' }
    ],
	-options => { accept_refs => 0 };
    $p = Person->new('Will Robinson');
    $p->add_parents( Person->new('Maureen Robinson'),
		     Person->new('John Robinson') );

Passing references is a matter of taste and situation.
If you don't think you will need or want to do it,
set the C<accept_refs> option to false.
An added benefit is that the classes will catch more parameter-passing errors,
because with references there are two meanings
for passing a single parameter to the method.

=head2 Strictness

By default, the classes include a C<use strict> directive.
You can change this (if you must) using a false value for the C<strict> option.

=head2 Warnings

You can use Perl's lexical warnings through C<Class::Generate>.
Any class you generate can have C<use warnings> or not, as you see fit.
This is controlled by the C<warnings> option,
the value of which may be:

=over 4

=item *

A scalar, in which case your class will be generated with
C<use warnings> or C<no warnings>,
depending on whether the scalar evaluates to true or false, respectively.
If the scalar is C<undef>,
your class won't even contain C<no warnings>.
If the scalar looks like a positive integer,
your class will contain the single line:

    use warnings;

If the scalar doesn't look like a positive integer,
its value is appended after C<warnings>.
Thus:

    -options => { warnings => 'FATAL => qw(void)' }

yields:

    use warnings FATAL => qw(void);

=item *

An array reference containing a list of key/value pairs.
Valid keys are C<register>, C<use>, and C<no>.
If the key is C<register> and the value evaluates to true,
your class will contain a C<use warnings::register> line.
If the key is C<use> or C<no>, your class will enable or
disable warnings, respectively,
according to the value that follows.
If the value looks like a positive integer,
your class will contain a C<use>/C<no warnings> line.
If it looks like anything else that evaluates to true,
your class will contain a C<use>/C<no warnings> line
followed by the value's string representation.

Warnings are enabled and disabled in the order they appear in the array.
For example:

    -options => { warnings => [use => 1, no => 'qw(io)', register => 1] }

yields:

    use warnings;
    no warnings qw(io);
    use warnings::register;

Perl won't let you specify a warnings category until you import a module,
so the following won't work:

    class Too_Soon => { ... }, -options => { warnings => { register => 1 } };
    use warnings 'Too_Soon';

because the C<use warnings> statement is processed at compile time.
In fact, you probably don't want to use the C<register> key except for
classes you save.
See L<"Saving the Classes">.

=back

The default value of the C<warnings> option is 1,
meaning your class will contain a C<use warnings> pragma.

=head2 Redefining an Existing Package

C<Class::Generate> is intended for generating classes,
not packages containing classes.
For that reason, C<class> and C<subclass> croak if you try to define
a class whose name is a package that already exists.
Setting the C<allow_redefine> option to true changes this behavior.
It also opens up a minefield of potential errors, so be careful.

=head2 Instance Variable Name

By default, the reference to an object instance is stored
in a variable named C<$self>.
If you prefer another name (e.g., C<$this>),
you can specify it using the C<instance_var> option:

    class Foo => {
	array => '@'
    };
    subclass Bar => {
	bar_mem => {
	    type => '$',
	    pre => 'print "array_size is ", $this->array_size;'
	}
    }, -parent => 'Foo',
       -options => { instance_var => 'this' };

=head2 Class Variable Name

By default, the reference to a class variable is stored
in a variable named C<$class>.
If you prefer another name,
you can specify it using the C<class_var> option.

=head2 Checking User-Defined Code

The C<class> and C<subclass> functions check that
any C<pre>, C<post>, or C<assert> code is valid Perl.
They do so by creating and evaluating a subroutine that contains the code,
along with declarations that mimic the context in which the code would execute.
The alternative would be to wait until the entire class has been defined,
but that would yield error messages with line numbers that don't correspond
to your code.
Never underestimate the value of meaningful error messages.

However, this approach results in code being evaluated twice:
once to check its syntax and semantics,
and again when the package is created.
To avoid this overhead,
set the C<check_code> option to false.

=head2 Checking Default Value Types

A default value for a member is checked against the type of the member.
If a member is an array, for instance,
you will get a warning if C<class> detects that its default value
is anything other than an array reference.

If you specify a default value as a string,
C<class> and C<subclass> have to evaluate the string
to see if it yields a value of the correct type.
This may cause unwanted behavior
if the string is an expression with side effects.
Furthermore, your program will behave differently depending on
whether warnings are in effect.

If you set the C<check_default> option to false,
C<class> and C<subclass> will not check the types of default values.
It's common to do so after you have debugged a class.

=head2 Creating New Objects From Instances

By default, C<Class::Generate> lets you create a new object instance only
from a class name, i.e., C<Class-E<gt>new>.
However, some Perl programmers prefer another style,
wherein you can create an object from either a class or an instance
(see L<perlobj>).
The C<nfi> (I<n>ew I<f>rom I<i>nstance) option controls whether
you can use both:

    class C => { ... };
    $o = C->new;	# Always works.
    $p = $o->new;	# Works if nfi option is true.

=head2 Checking Parameter Values

Several sections have mentioned errors
that will cause your classes to croak if used incorrectly.
Examples include constructor invocation that omits a required member's value
and passing a scalar where a reference is expected.
These checks are useful, especially during debugging,
but they can slow your code.
If you set the C<check_params> option to a false value,
C<Class::Generate> will omit these checks.
Furthermore, if you set C<check_params> to C<undef>,
C<Class::Generate> will omit assertions too.

A class that checks parameters automatically includes the
L<Carp> package.
C<Class::Generate> generates code that uses methods in this package,
especially C<croak>, to report errors.

The downside of changing the default C<check_params> value should be
obvious to any experienced programmer.

=head1 DIAGNOSTICS

The following is a list of the diagnostics the C<class> and C<subclass>
functions can produce.
Each diagnostic is prefixed with "(F)" or "(W)",
indicating that it is fatal or a warning, respectively.
Warning messages are only emitted if you use the C<warnings> pragma.

Classes that contain user defined code can yield Perl errors and warnings.
These messages are prefixed by one of the following phrases:

    Class class_name, member "name": In "<x>" code:
    Class class_name, method "name":

where C<E<lt>xE<gt>> is one of C<pre>, C<post>, or C<assert>.
See L<perldiag> for an explanation of such messages.
The message will include a line number that is relative to the
lines in the erroneous code fragment,
as well as the line number on which the class begins.
For instance, suppose the file C<stacks.pl> contains the following code:

    #! /bin/perl
    use warnings;
    use Class::Generate 'class';
    class Stack => [
	top_e	 => { type => '$', private => 1, default => -1 },
	elements => { type => '@', private => 1, default => '[]' },
	'&push' => '$elements[++$top_e] = $_[0];',
	'&pop'  => '$top_e--;',
	'&top'  => 'return $elements[$top_e];'
    ];
    class Integer_Stack => [
	'&push' => q{die 'Not an integer' if $_[0] !~ /^-?\d+$/;
		     $self->SUPER:push($_[0]);}	# Meant "::", not ":".
    ], -parent => 'Stack';

Executing this file yields:

    Subclass "Integer_Stack", method "push": syntax error at line 2,
     near "->SUPER:"
     at stacks.pl line 11

meaning the error occurs in the second line of the C<push> method.

=head2 Compile-Time Diagnostics

The C<class> and C<subclass> functions emit the following diagnostics:

=over 4

=item "-class_vars" flag must be string or array reference

(F) The value of the C<-class_vars> flag must be a string
containing a space-separated list of class variables,
or a reference to an array of strings,
each of which specifies one or more class variables.

=item "-exclude" flag must be string or array reference

(F) The value of the C<-exclude> flag must be a string
containing a space-separated list of regular expressions,
or a reference to an array of strings,
each of which specifies one or more regular expressions.

=item "-pod" flag must be scalar value or hash reference

(F) The value of the C<-pod> flag must be either a scalar
that evaluates to a boolean value or a hash reference
whose elements denote sections of POD documentation.

=item "-use" flag must be string or array reference

(F) The value of the C<-use> flag must be a string
containing a space-separated list of packages to use,
or a reference to an array of strings,
each of which is a package to use.

=item %s: "%s" is reserved

(F) The member name conflicts with the instance variable name for the class.
Change the member name,
or change the instance variable name using the C<instance_var> option.

=item %s: "-pod" flag must be scalar value or hash reference

(F) You gave a value of the C<-pod> flag for the <class> or <subclass>
function that isn't a scalar value or a hash reference.

=item %s: "required" attribute ignored for private/protected member "%s"

(W) If member is private or protected, it cannot be a constructor parameter.

=item %s: %s-based class must have %s-based parent (%s is %s-based)

(F) If the class specified using C<subclass> is specified as an array reference,
its parent must also be specified as array references.
If it is specified as a hash reference,
its parent(s) must be specified as hash references.

=item %s: A package of this name already exists

(F) The name passed to C<class> or C<subclass> must not be
the name of an existing package,
unless the C<allow_redefine> option is true.

=item %s: An array reference based subclass must have exactly one parent

(F) Multiple inheritance is only permitted for class hierarchies
specified as hash references.

=item %s: Cannot append to "%s": %s

(F) The C<save> option was true,
but a class definition cannot be appended to the named file for the
specified operating system-specific reason.

=item %s: Cannot save to "%s": %s

(F) The C<save> option was true,
but the class cannot be saved to the named file for the
specified operating system-specific reason.

=item %s: Cannot continue after errors

(F) The class specification includes user defined code
that is not valid Perl.

=item %s: Class was not declared using Class::Generate

(F) An argument of C<delete_class> is the name of a package
that wasn't declared using C<class> or C<subclass>.

=item %s: Default value for "%s" is not correctly typed

(W) The value of the C<default> attribute
specified for the named member is either a reference
that is does not match the type required for the member,
or a string that, when evaluated, does not match the member's type.

=item %s: Elements must be in array or hash reference

(F) A class specification must be an array or hash reference.
Scalars, lists, and other references are not allowed.

=item %s: Error in new => { style => '... %s' }: %s is not a member

(F) A class' constructor specifies a style that requires listing members,
and the list includes a value that is not a member.

=item %s: Error in new => { style => '... %s' }: %s is not a public member

(F) A class' constructor specifies a style that requires listing members,
and the list includes the name of a private or protected member.
Only public members can be passed as a constructor parameter.

=item %s: Error in new => { style => '... %s' }: Name "%s" used %d times

(F) A class' constructor specifies a style that requires listing members,
and the list contains the same member name more than once.

=item %s: Evaluation failed (problem in Class::Generate?)

(F) You have done something the creator of C<Class::Generate> did
not anticipate, you've found a bug (or both),
or you've got a trailing comment in user-defined code (see L<"BUGS">).
Please report either of the first two cases.
(This message is accompanied by some contextual information that can help
you identify the error.
Please include that information too.)

=item %s: Extra parameters in style specifier

(F) A class' constructor was specified to use the C<mix> style,
but more values were listed than exist non-private members.

=item %s: Invalid member/method name "%s"

(F) The names of members and methods must be valid Perl identifiers,
starting with a letter or underscore and containing
only letters, underscores, or digits.

=item %s: Invalid parameter-passing style (must be string or array reference)

(F) Within the C<new> attribute of a class,
the C<style> attribute's value  must be given as a string
or a reference to an array of strings.

=item %s: Invalid parameter-passing style type "%s"

(F) Within the C<new> attribute of a class,
the C<style> attribute's value must begin with one of
the words C<key_value>, C<mix>, C<positional>, or C<own>.

=item %s: Invalid specification for objects of "%s" (must be string or array reference)

(F) For the named class method,
the expressions to be recognized as objects must be passed
as a string or a reference to a list of strings.

=item %s: Invalid specification for required constructor parameters (must be string or array reference)

(F) Within the C<new> attribute of a class,
the C<required> attribute's value must be given as a string
or a reference to an array of strings.

=item %s: Invalid specification of member "%s" (must be string or hash reference with "type" key)

(F) A member's specification must be given as either
a string (describing its type)
or a hash reference (which must contain the C<type> key).

=item %s: Invalid specification of method "%s" (must be string or hash reference with "body" key)

(F) The value of a method name must be a string
(specifying the method's body)
or a hash reference, one of whose elements is keyed by C<body>.

=item %s: Member "%s": "%s" is not a valid type

(F) The type of a member must be C<$>, C<@>, C<%>,
one of these three types followed by an identifier,
or an identifier.

=item %s: Member "%s": Unknown attribute "%s"

(W) One of the attributes given in the hash reference specifying the named
member is not a recognized attribute.

=item %s: Member "%s": Value of pod must be a hash reference

(F) The value of the C<pod> attribute given in the hash reference
specifying the name member is not a hash reference.

=item "%s: Member "%s" declared both private and protected (protected assumed)

(W) The member's specification has C<TRUE> values for both the C<protected>
and C<private> attributes.
The more general attribute, C<protected>, will be used.

=item %s: Method "%s": A class method cannot be protected

(F) In the current implementation, a class method must be public or private.

=item %s: Method "%s": Unknown attribute "%s"

(W) One of the attributes given in the hash reference specifying the named
method is not a recognized attribute.

=item %s: Missing/extra members in style

(F) A class' constructor was specified to use the C<positional> style,
but not all non-private members (or too many members) were listed.

=item %s: Name "%s" used %d times

(F) The set of member and method names cannot contain duplicates.
Member and method names share the same namespace.

=item %s: Parent class "%s" was not defined using class() or subclass(); %s reference assumed

(W) The C<subclass> function permits parents to be any package,
not just those defined using C<class> and C<subclass>.
However, because certain capabilities are lost (e.g., base type checking),
it emits warnings when it detects such subclasses.
Also, the C<subclass> function assumes that invoking C<parent-E<gt>new> returns
a blessed reference to whatever the child expects.
If it's wrong, you'll get a run-time error when your program invokes one of
the parent's or child's accessors.

=item %s: Parent package "%s" does not exist

(F) The C<subclass> function requires all parent classes
to exist (meaning each is a package) before it is invoked.

=item %s: Probable mismatch calling constructor in superclass "%s"

(W) The C<subclass> function's constructor specifies
a parameter passing style that is likely to conflict
with the style of its parent's.

=item %s: Required params list for constructor contains unknown member "%s"

(F) Within the C<new> attribute of a class,
the C<required> attribute's value contains a name that
is not given as class member.

=item %s: Specification for "new" must be hash reference

(F) The C<new> attribute of a class must be given as a hash reference.

=item %s: Value of %s option must be an identifier (without a "$")

(F) The value passed to the C<class_var> or C<instance_var> option
must, when prefixed with a C<$>, be a valid Perl scalar identifier.
Note that you do not prefix it with a C<$>.
Use:

    -options => { class_var => 'x' }

and not

    -options => { class_var => '$x' }

=item Cannot save reference as initial value for "%s"

(W) References are legal default or initial values.
However, they cannot be saved using the C<save> option.

=item Each class variable must be scalar or hash reference

(F) The specification of a class variable must be either a string
containing a valid Perl variable name, or a hash reference;
for each key/value pair of the reference
the key must be a valid Perl variable name,
and the value must be a Perl expression
to be used as the variable's default value.

=item Expected string or array reference

(F) The value of an attribute's key/value pair should have been
a string or an array reference, but was not.

=item Expected string or hash reference

(F) The value of an attribute's key/value pair should have been
a string or a hash reference, but was not.

=item Invalid parent specification (must be string or array reference)

(F) The C<subclass> function requires the class' parent(s) to be specified
as either a string, or a list of strings passed as an array reference.

=item Missing subclass parent

(F) The C<subclass> function requires the class' parent(s) to be specified,
using the C<parent=E<gt>list> form.

=item Missing/extra arguments to class()

(F) The C<class> function requires at least two arguments:
the class' name and specification.
Its other arguments must be flags.

=item Missing/extra arguments to subclass()

(F) The C<subclass> function requires at least four arguments:
the class' name, the class' specification,
and the class' parent as a key/value pair.
Other arguments to C<subclass> must be flags.

=item Options must be in hash reference

(F) The value of the C<-options> flag must be a hash reference.

=item Unknown flag "%s" ignored

(W) One of the arguments to C<class> or C<subclass> begins with C<->,
but is not a recognized flag.

=item Unknown option "%s" ignored

(W) The C<-options> flag includes a key/value pair
where the key is not a recognized option.

=item Warnings array reference must have even number of elements

(F) Your array reference to the C<warnings> option isn't valid.
It must be a list of key/value pairs.
See L<Warnings>.

=item Warnings array: Unknown key "%s"

(F) A key in the array used as the value of the C<warnings> option must be
C<register>, C<use>, or C<no>.

=item Warnings must be scalar value or array reference

(F) You specified a value for the C<warnings> option that isn't
a scalar or a array reference.  See L<Warnings>.

=back

=head2 Run-Time Diagnostics

Unless you change the default values of
C<Class::Generate>'s diagnostic options,
your classes will contain code that
can cause the following diagnostics to be emitted:

=over 4

=item %s: Failed assertion: %s

(F) The specified assertion did not evaluate to true.

=item %s: Invalid number of parameters

(F) One of the class' accessors was invoked with
too many or too few parameters.

=item %s: Invalid parameter value (expected %s)

(F) One of the class' accessors was invoked with a parameter
of the wrong type.

=item %s: Member is read-only

(F) Member C<m> was specified read-only,
but C<$o-E<gt>m> was invoked with parameters that looked like
an attempt to set C<m>.

=item %s: Parameter constraint "%s" failed

(F) The constraint for the constructor,
which involves operators,
has failed.

=item %s: Virtual class

(F) The constructor of a virtual class has been directly invoked.

=item %s::new: %s: Not a member

(F) The named class uses the key/value parameter passing style.
Its constructor was invoked with one or more key/value pairs whose keys
don't name a member of the class.
This message often occurs when you forget that keys are needed.

=item %s::new: Invalid value for %s

(F) The class' constructor was given an improper value for a member.
If the member is a list, the value passed is the wrong kind of list
(or not a list).
If the member is typed, the value passed isn't of that type.

=item %s::new: Missing or invalid value for %s

(F) The class' constructor was invoked without a value for a required member,
or the value was not of the correct type
(e.g., hash reference where an array reference is needed,
not a blessed reference to the necessary class).

=item %s::new: Missing value for required member %s

(F) The class' constructor was invoked without a required parameter.

=item %s::new: Odd number of parameters

(F) The named class uses the key/value or mix parameter passing style.
Its constructor was invoked with too many or too few
(not just right) parameters,
i.e., something that didn't look like a list of key/value pairs
(accounting for any positional parameters in the mix style).

=item %s::new: Only %d parameter(s) allowed (%d given)

(F) The named class uses the positional parameter passing style.
Its constructor was invoked with more parameters
than the class has members.

=back

=head1 SEE ALSO

PERLDIAG(1),
PERLLEXWARN(1),
PERLOBJ(1),
Carp(3),
Class::Struct(3)

=head1 COPYRIGHT

Copyright (c) 1999, 2000, 2006 Steven Wartik.
All rights reserved.
This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 BUGS

It would be nice to have more selective control of what errors are checked.

That C<pre> and C<post> code share the same name space
can cause problems if the C<check_code> option is true.
The reason is that the C<post> code is evaluated with a prepended copy
of C<pre> in which all newlines are replaced by spaces.
This replacement ensures that an error message about C<post>
refers to the appropriate line number within C<post>.
However, if the C<pre> code contains the C<E<lt>E<lt>> quotation form,
Perl will probably complain about a syntax error;
and if it contains a comment,
Perl will ignore the first line of the C<post> code.
Note that this only affects code checking,
not the package that's generated.

In the current implementation, if member C<m> is an array,
then within user-defined code,
the test C<if ( @m ) { ... }> does not work in hash-based classes
unless C<@m> is initialized.
Use C<$#m != -1> instead.
Or specify C<m> as explicitly empty:

    m => { type => '@', default => '[]' }

Hash members have an analogous bug.
Use C<scalar(&m_keys) != 0> to test if a hash member is empty
in user-defined code.

The C<&equals> and C<&copy> functions do not understand multiple inheritance.

Member and method name substitution in code
can be fooled if a member name is also declared as a variable.
Unfortunately the C<class> function doesn't detect this error.
In the following class, the C<$f> of C<$f[0]> is mistaken for
scalar member C<f>, not array variable C<@f>:

    class Foo => {
	f => {
	    type => '$',
	    post => 'my @f;
	     	     $f[0] = $f;    # This causes an error.
		     ${f}[0] = $f;' # However, this works.
	}
    };

If a class declares a protected method C<m>,
and one of its subclasses also declares C<m>,
the subclass can't access the parent's version.

A subclass can declare a member C<m> that overrides a parent's
declaration of C<m>,
but it can cause some logical inconsistencies and isn't recommended.
Tne entire model of member overriding may change in some future version.

The C<subclass> function doesn't test for circularity
in inheritance hierarchies.

The C<-allow_redefine> option is intended to let you add functionality to
packages I<not> declared using C<Class::Generate>.
This rule isn't strictly enforced, but probably should be.
If you redefine a class, you change the constructor,
as well as the C<copy> and C<equals> methods.
Consider the following:

    class Foo => [ mem1 => '$' ];
    class Foo => [ mem2 => '@' ], # Intends to add a member to Foo.
	-options => { allow_redefine => 1 };
    $o = new Foo;
    $o->mem1('this works');
    $o->mem2([qw(so does this)]);
    $p = $o->copy;		  # But this doesn't copy mem1.
    $p = new Foo mem1 => 'x';	  # And this fails.

Use inheritance instead.

The algorithm that adds a trailing semicolon to C<pre> and C<post> code
uses a simple regular expression to test for a semicolon's presence.
Please don't strain it by doing odd things like embedding comments:

    post => 'print "foo"  # This will fail, with an obscure error message.',
    post => 'print "foo"' # Use this form instead.

=head1 NOTES

Default values that are references cannot be saved to a file.

In C<pre> and C<post> code,
you can access method parameters via C<@_>.
You probably should not do so except for scalar members, though.
For array members, the same code is inserted into I<m> and C<add_>I<m>,
and the code can't tell which method it's in.
Even within method I<m>, the code can't tell if it's looking at a reference
or a value if C<$accept_refs> is true.

The C<UNIVERSAL::isa> function is used to determine if
something is an array or hash reference.
This presents possibilities for metaspecification functions.

The name C<_cginfo> is reserved in all packages
generated by C<Class::Generate>.

Emacs users will quickly discover that the form:

    class Foo => [ member_name => '$' ];

causes subsequent lines to be incorrectly indented.
The reason is that perl-mode is confused by C<'$'>.
Use instead:

    class Foo => [ member_name => "\$" ];

This package clearly owes much to C<Class::Struct>.
I thank its creators for their insights.

Speaking of which, unlike C<Class::Struct>,
the C<m> accessor for member C<m> does not return a value when it is set.
This is a deliberate design decision.
If you would like that feature,
you can simulate it for (scalar) member C<m>
by including C<return $m;> as C<post> code.
However, you then short-circuit any assertion for member C<m>.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Class-Generate>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Class-Generate>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Class-Generate>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/Class-Generate>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Class-Generate>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Class::Generate>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-class-generate at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Class-Generate>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-Class-Generate>

  git clone https://github.com/shlomif/perl-Class-Generate

=head1 AUTHOR

unknown

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-Class-Generate/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by unknown.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# Copyright (c) 1999-2007 Steven Wartik. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms as
# Perl itself.
