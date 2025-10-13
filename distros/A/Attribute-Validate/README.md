# NAME

Attribute::Validate - Validate your subs with attributes

# SYNOPSIS

    use Attribute::Validate;

    use Types::Standard qw/Maybe InstanceOf ArrayRef Str/

    use feature 'signatures';

    sub install_gentoo: Requires(Maybe[ArrayRef[InstanceOf['Linux::Capable::Computer']]], Str) ($maybe_computers, $hostname) {
        # Do something here
    }

    install_gentoo([$computer1, $computer2], 'Tux');

# DESCRIPTION

This module allows you to validate your non-anonymous subs using the powerful attribute syntax of Perl, bringing easy type-checks to
your code, thanks to [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny) you can create your own types to enforce your program using the data you expect it to use.

# INSTANCE METHODS

This module cannot and shouldn't be instanced.

# ATTRIBUTES

## Requires

    sub say_word: Requires(Str) {
        say shift;
    }

    sub say_word_with_spec: Requires(\%spec, Str) {
        say shift;
    }

Receives a list of [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny) types and enforces those types into the arguments, the first argument may be a HashRef containing the
spec of [Type::Params](https://metacpan.org/pod/Type%3A%3AParams) to change the behavior of this module, for example {strictness => 0} as the first argument will allow the user
to have more arguments than the ones declared.

## VoidContext

    sub doesnt_return: VoidContext {
    }
    my $lawless = doesnt_return(); # Dies
    doesnt_return(); # Works

Enforces the caller to use this sub in Void Context and do nothing with the return to avoid programmer errors and incorrect assumptions.

## NoVoidContext

    sub returns: NoVoidContext {
    }
    my $lawful = returns(); # Works
    returns(); # Dies

Enforces the caller to do something with the return of a sub to avoid programmer errors and assumptions.

## ListContext

    sub only_use_in_list_context: ListContext {
        return (0..10);
    }
    my $list = only_use_in_list_context(); # Dies
    only_use_in_list_context(); # Dies
    my @list = only_use_in_list_context(); # Works

Enforces the caller to use the subroutine in List Context to prevent errors and misunderstandings.

## NoListContext

    sub never_use_in_list_context: NoListContext {
        return 'scalar_or_void';
    }
    my $list = never_use_in_list_context(); # Works
    never_use_in_list_context(); # Works
    my @list = never_use_in_list_context(); # Dies

Enforces the caller to never use the subroutine in List Context to prevent errors and misunderstandings.

## ScalarContext

    sub only_use_in_scalar_context: ScalarContext {
        return 'hey';
    }
    my @scalar = only_use_in_scalar_context(); # Dies
    only_use_in_scalar_context(); # Dies
    my $scalar = only_use_in_scalar_context(); # Works

Enforces the caller to use the subroutine in Scalar Context to prevent errors and misunderstandings.

## NoScalarContext

    sub never_scalar_context: NoScalarContext {
        return @array;
    }
    my @list = never_scalar_context(); # Works
    never_scalar_context(); # Works
    my $scalar = never_scalar_context(); # Dies

Enforces the caller to never use the subroutine in Scalar Context to prevent errors and misunderstandings.

# EXPORTABLE SUBROUTINES

## anon\_requires

    my $say_thing = anon_requires(sub($thing) {
        say $thing;
    ), Str);

    my $say_thing = anon_requires(sub($thing) {
        say $thing;
    }, \%spec, Str);

Enforces types into anonymous subroutines since those cannot be enchanted using attributes.

# DEPENDENCIES

The module will pull all the dependencies it needs on install, the minimum supported Perl is v5.16.3, although latest versions are mostly tested for 5.38.2

# CONFIGURATION AND ENVIRONMENT

If your OS Perl is too old perlbrew can be used instead.

# BUGS AND LIMITATIONS

Enchanting anonymous subroutines with attributes won't allow them to be used by this module because of limitations of the language.

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Sergio Iglesias.

This is free software, licensed under:

    The MIT (X11) License

# CREDITS

Thanks to MultiSafePay and the Tech Leader of MultiSafePay for agreeing in creating this CPAN module inspired in a similar feature in their codebase, this code was inspired by code found there, but was
written without the code in front from scratch.

MultiSafePay is searching for Perl Developers for working in their offices on Estepona on Spain next to the beach, if you apply and do not get a reply and you think you are a 
experienced/capable enough Perl Developer drop me a e-mail so I can try to help you get a job [mailto:sergioxz@cpan.org](mailto:sergioxz@cpan.org).

# INCOMPATIBILITIES

None known.

# VERSION

0.0.x

# AUTHOR

Sergio Iglesias
