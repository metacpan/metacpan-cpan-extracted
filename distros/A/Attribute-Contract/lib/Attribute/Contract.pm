package Attribute::Contract;

use strict;
use warnings;

use 5.012;
use attributes;

our $VERSION = '0.05';

use constant NO_ATTRIBUTE_CONTRACT => $ENV{NO_ATTRIBUTE_CONTRACT};

use Scalar::Util qw(refaddr);

use Attribute::Contract::Modifier::Requires;
use Attribute::Contract::Modifier::Ensures;

BEGIN {
    use Exporter ();
    our (@ISA, @EXPORT);

    @ISA    = qw(Exporter);
    @EXPORT = qw(&MODIFY_CODE_ATTRIBUTES &FETCH_CODE_ATTRIBUTES);
}

our $CONTRACT_REQUIRES_ATTR_ALIAS = 'ContractRequires';
our $CONTRACT_ENSURES_ATTR_ALIAS  = 'ContractEnsures';

my %attrs;
my %modifiers;
my %symcache;
my %todo;
my %import;

sub contract_requires_name {
    $import{-names}->{requires} || $CONTRACT_REQUIRES_ATTR_ALIAS;
}

sub contract_ensures_name {
    $import{-names}->{ensures} || $CONTRACT_ENSURES_ATTR_ALIAS;
}

sub contract_attr_re {
    my $requires_name = contract_requires_name();
    my $ensures_name = contract_ensures_name();

    return qr/
        ^
        ($requires_name|$ensures_name)
        (?:\((.*?)\))?
        $
    /x;
}

sub import {
    return if NO_ATTRIBUTE_CONTRACT;

    my ($package) = caller;
    $todo{$package}++;

    shift;
    %import = @_;

    __PACKAGE__->export_to_level(1);
}

sub CHECK {
    return if NO_ATTRIBUTE_CONTRACT;

    foreach my $package (keys %todo) {
        foreach my $key (keys %modifiers) {
            my ($class, $method) = split /::/, $key;
            next unless $package->isa($class);

            next unless my $code_ref = $package->can($method);

            my $attrs = $modifiers{$key};

            foreach my $attr (@$attrs) {
                next unless $attr =~ contract_attr_re();

                attributes::->import($package, $code_ref, $attr);
            }
        }
    }
}

sub FETCH_CODE_ATTRIBUTES {
    my ($package, $subref) = @_;

    my $attrs = $attrs{refaddr $subref };

    return @$attrs;
}

sub MODIFY_CODE_ATTRIBUTES {
    my ($package, $code_ref, @attr) = @_;

    my $sym = findsym($package, $code_ref);
    my $name = *{$sym}{NAME};

    return if exists $attrs{refaddr $code_ref };
    return if exists $modifiers{"$package\::$name"};

    $attrs{refaddr $code_ref } = \@attr;
    $modifiers{"$package\::$name"} = \@attr;

    if (@attr) {
        no strict;
        my @isa = @{"$package\::ISA"};
        use strict;
        foreach my $isa (@isa) {
            my $key = "$isa\::$name";
            if (exists $modifiers{$key}) {

                my $base_contract = $modifiers{$key};
                my $contract = $modifiers{"$package\::$name"};

                if (@$base_contract == @$contract) {
                    next
                      if join(',', sort @$base_contract) eq
                          join(',', sort @$contract);
                }

                Carp::croak(qq{Changing contract of method '$name'}
                      . qq{ in $package is not allowed});
            }
        }
    }

    no warnings 'redefine';
    foreach my $attr (@attr) {
        next unless $attr =~ contract_attr_re();

        my $type      = $1;
        my $arguments = $2;

        my $modifier = $type eq contract_requires_name() ? 'Requires' : 'Ensures';

        my $class = __PACKAGE__ . '::Modifier::' . $modifier;

        *{$sym} = $class->modify($package, $name, $code_ref, \%import, $arguments);
    }

    return ();
}

# From Attribute::Handlers
sub findsym {
    my ($package, $ref) = @_;

    return $symcache{$package, $ref} if $symcache{$package, $ref};

    my $type = ref($ref);

    no strict 'refs';
    foreach my $sym (values %{$package . "::"}) {
        use strict;
        next unless ref(\$sym) eq 'GLOB';

        return $symcache{$package, $ref} = \$sym
          if *{$sym}{$type} && *{$sym}{$type} == $ref;
    }

    return;
}

1;
__END__

=head1 NAME

Attribute::Contract - Design by contract via Perl attributes

=head1 SYNOPSIS

    package Interface;
    use Attribute::Contract -types => [qw/Str slurpy ArrayRef/];

    sub do_smth :ContractRequires(Str, slurpy ArrayRef[Str]) :ContractEnsures(Str) {
        my $self = shift;
        my ($input_string, $array_ref_of_strings) = @_;

        return '...';
    }

    package Implementation;
    use base 'Interface';
    use Attribute::Contract;

    sub do_smth {
        my $self = shift;
        my ($input_string, $array_ref_of_strings) = @_;

        return 'ok';
    }

    Implementation->do_smth('hi', 'there'); # works

    Implementation->do_smth();              # croaks!
    Implementation->do_smth(sub {});        # croaks!

=head1 DESCRIPTION

L<Attribute::Contract> by using Perl attributes allows you to specify contract
(L<Design by Contract|http://en.wikipedia.org/wiki/Design_by_contract>) for
every method in your class. You can check incoming and outgoing values by
specifying C<ContractRequires> and C<ContractEnsures> attributes.

It's the most useful for interfaces or abstract classes when you want to control
whether your implementation follows the same interface and respects the Liskov
substitution principle.

This module uses L<Type::Tiny> underneath so all the checks is done via that
module. Check it out for more documention on type validation.

Why attributes? They feel and look natural and are applied during compile time.

=head2 IMPORTING

When using L<Attribute::Contract> one may want to import various types in order
to check them in attributes. Types themselves are not imported into the current
module but rather used when compiling attributes.

=head3 Types

    package MyClass;
    use Attribute::Contract -types => [qw/ClassName Str/];

    sub static_method : ContractRequires(ClassName, Str) {
    };

    ...

    MyClass->static_method('string');

=head3 Type libraries

When types are complex or the description is too long attributes might get not
very readable. In this case one can use type libraries (implemented again via
L<Type::Tiny>):

    package MyTypes;
    use Type::Library -base, -declare => qw(MyInt);
    use Type::Utils;
    use Types::Standard qw(Int);

    declare MyInt, as Int, where => {$_ > 0};

    package MyClass;
    use Attribute::Contract -library => 'MyTypes';

    sub static_method : ContractRequires(ClassName, MyInt) {
    }

    ...

    MyClass->static_method(5);

=head3 Aliasing

If you don't like C<ContractRequires> and C<ContractEnsures> you can set your
own names:

    use Attribute::Contract -names => {requires => 'In', ensures => 'Out'}

    sub method : In(ClassName, Str) Out(Str) {
    }

=head2 IMPLEMENTATION

=head3 Inheritance

By default all the contracts are inherited. Just don't forget to C<use>
L<Attribute::Contract> in the derived class. But if no methods are overriden
then even C<using> this module is not needed.

=head3 Caching

During the compile time for every contract a Perl subroutine is built and
evaled. If the methods share the same contract they use the same checking code
reference. This speeds up the checking and saves some memory.

=head3 Error reporting

Errors are as specific as possible. On error you will get a meaningful message
and a stack trace.

=head2 SWITCHING OFF

You can switch off contract checking by specifying an environment variable
C<NO_ATTRIBUTE_CONTRACT>.

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/attribute-contract

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
