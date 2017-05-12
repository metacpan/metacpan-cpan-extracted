package Anansi::Library;


=head1 NAME

Anansi::Library - A base module definition for object functionality extension.

=head1 SYNOPSIS

    # Note: As 'base' needs a module file, this package must be declared in 'LibraryExample.pm'.
    package LibraryExample;

    use base qw(Anansi::Library);

    sub libraryExample {
        my ($self, %parameters) = @_;
    }

    1;

    # Note: This package should be declared in 'ClassExample.pm'.
    package ClassExample;

    use base qw(Anansi::Class LibraryExample);

    sub classExample {
        my ($self, %parameters) = @_;
        $self->libraryExample();
        $self->LibraryExample::libraryExample();
    }

    1;

=head1 DESCRIPTION

This is a base module definition that manages the functionality extension of
module object instances.

=cut


our $VERSION = '0.03';

my $LIBRARY = {};


=head1 METHODS

=cut


=head2 abstractClosure

    my $CLOSURE = Anansi::Library->abstractClosure(
        'Some::Namespace',
        'someKey' => 'some data',
        'anotherKey' => 'Subroutine::Namespace',
        'yetAnotherKey' => Namespace::someSubroutine,
    );
    $CLOSURE->anotherKey();
    $CLOSURE->yetAnotherKey();

    sub Subroutine::Namespace {
        my ($self, $closure, %parameters) = @_;
        my $abc = ${$closure}{abc} || 'something';
        ${$closure}{def} = 'anything';
    }

=over 4

=item class I<(Blessed Hash B<or> String, Required)>

Either an object of this namespace or this module's namespace.

=item abstract I<(String, Required)>

The namespace to associate with the closure's encapsulating object.

=item parameters I<(Hash, Optional)>

Named parameters where either the key is the name of a variable stored within
the closure and the value is it's data or when the value is a subroutine the key
is the name of a generated method of the closure's encapsulating object that
runs the subroutine and passes it a reference to the closure.

=back

Creates both an anonymous hash to act as a closure variable and a blessed object
as the closure's encapsulating accessor.  Supplied data is either stored within
the closure using the key as the name or in the case of a subroutine, accessed
by an auto-generated method of that name.  Closure is achieved by passing a
reference to the anonymous hash to the supplied subroutines via the
auto-generated methods.

=cut


sub abstractClosure {
    my ($class, $abstract, %parameters) = @_;
    return if(ref($abstract) !~ /^$/);
    return if($abstract !~ /[a-zA-Z]+[a-zA-Z0-9_]*(::[a-zA-Z]+[a-zA-Z0-9_]*)+$/);
    my $ABSTRACT = {
        NAMESPACE => $abstract,
    };
    my $CLOSURE = {
    };
    foreach my $key (keys(%parameters)) {
        next if(ref($key) !~ /^$/);
        next if($key !~ /^[a-zA-Z_]*[a-zA-Z0-9_]+$/);
        next if('NAMESPACE' eq $key);
        if(ref($parameters{$key}) =~ /^CODE$/i) {
            *{$abstract.'::'.$key} = sub {
                my ($self, @PARAMETERS) = @_;
                return &{$parameters{$key}}($self, $CLOSURE, (@PARAMETERS));
            };
        } elsif(ref($parameters{$key}) !~ /^$/i) {
            ${$CLOSURE}{$key} = $parameters{$key};
        } elsif($parameters{$key} =~ /^[a-zA-Z]+[a-zA-Z0-9_]*(::[a-zA-Z]+[a-zA-Z0-9_]*)+$/) {
            if(exists(&{$parameters{$key}})) {
                *{$abstract.'::'.$key} = sub {
                    my ($self, @PARAMETERS) = @_;
                    return &{\&{$parameters{$key}}}($self, $CLOSURE, (@PARAMETERS));
                };
            } else {
                ${$CLOSURE}{$key} = $parameters{$key}
            }
        } else {
            ${$CLOSURE}{$key} = $parameters{$key};
        }
    }
    return bless($ABSTRACT, $abstract);
}


=head2 abstractObject

    my $OBJECT = Anansi::Library->abstractObject(
        'Some::Namespace',
        'someKey' => 'some data',
        'anotherKey' => 'Subroutine::Namespace',
        'yetAnotherKey' => Namespace::someSubroutine,
    );
    $OBJECT->anotherKey();
    $OBJECT->yetAnotherKey();

    sub Subroutine::Namespace {
        my ($self, %parameters) = @_;
        my $abc = $self->{abc} || 'something';
        $self->{def} = 'anything';
    }

=over 4

=item class I<(Blessed Hash B<or> String, Required)>

Either an object of this namespace or this module's namespace.

=item abstract I<(String, Required)>

The namespace to associate with the object.

=item parameters I<(Hash, Required)>

Named parameters where either the key is the name of a variable stored within
the object and the value is it's data or when the value is a subroutine the key
is the name of a namespace method.

=back

Creates a blessed object.  Supplied data is either stored within the object or
in the case of a subroutine as a namespace method of that name.

=cut


sub abstractObject {
    my ($class, $abstract, %parameters) = @_;
    return if(ref($abstract) !~ /^$/);
    return if($abstract !~ /[a-zA-Z]+[a-zA-Z0-9_]*(::[a-zA-Z]+[a-zA-Z0-9_]*)+$/);
    my $ABSTRACT = {
        NAMESPACE => $abstract,
    };
    foreach my $key (keys(%parameters)) {
        next if(ref($key) !~ /^$/);
        next if($key !~ /^[a-zA-Z_]*[a-zA-Z0-9_]+$/);
        next if('NAMESPACE' eq $key);
        if(ref($parameters{$key}) =~ /^CODE$/i) {
            *{$abstract.'::'.$key} = $parameters{$key};
        } elsif(ref($parameters{$key}) !~ /^$/i) {
            $ABSTRACT->{$key} = $parameters{$key};
        } elsif($parameters{$key} =~ /^[a-zA-Z]+[a-zA-Z0-9_]*(::[a-zA-Z]+[a-zA-Z0-9_]*)+$/) {
            if(exists(&{$parameters{$key}})) {
                *{$abstract.'::'.$key} = *{$parameters{$key}};
            } else {
                $ABSTRACT->{$key} = $parameters{$key}
            }
        } else {
            $ABSTRACT->{$key} = $parameters{$key};
        }
    }
    return bless($ABSTRACT, $abstract);
}


=head2 hasAncestor

    my $MODULE_ARRAY = $OBJECT->hasAncestor();
    if(defined($MODULE_ARRAY));

    if(1 == $OBJECT->hasAncestor(
        'Some::Module',
        'Another::Module',
        'Etc'
    ));

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item name I<(Array B<or> String, Optional)>

A namespace or an array of namespaces.

=back

Either returns an array of all the loaded modules that the object inherits from
or whether the object inherits from all of the specified loaded modules with a
B<1> I<(one)> for yes and B<0> I<(zero)> for no.

=cut


sub hasAncestor {
    return if(0 == scalar(@_));
    my $self = shift(@_);
    return if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    my %modules;
    while(my ($name, $value) = each(%INC)) {
        next if($name !~ /\.pm$/);
        $name =~ s/\.pm//;
        $name =~ s/\//::/g if($name =~ /\//);
        next if(!$self->isa($name));
        next if($self eq $name);
        $modules{$name} = 1;
    }
    if(0 == scalar(@_)) {
        return [( keys(%modules) )] if(0 < scalar(keys(%modules)));
        return;
    }
    while(0 < scalar(@_)) {
        my $name = shift(@_);
        return 0 if(ref($name) !~ /^$/);
        return 0 if(!defined($modules{$name}));
    }
    return 1;
}


=head2 hasDescendant

    my $MODULE_ARRAY = $OBJECT->hasDescendant();
    if(defined($MODULE_ARRAY));

    if(1 == $OBJECT->hasDescendant('Some::Module', 'Another::Module', 'Etc'));

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item name I<(Array B<or> String, Optional)>

A namespace or an array of namespaces.

=back

Either returns an array of all the loaded modules that the object is inherited
from or whether the object is inherited from all of the specified loaded
modules with a B<1> I<(one)> for yes and B<0> I<(zero)> for no.

=cut


sub hasDescendant {
    return if(0 == scalar(@_));
    my $self = shift(@_);
    return if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    my %modules;
    while(my ($name, $value) = each(%INC)) {
        next if($name !~ /\.pm$/);
        $name =~ s/\.pm//;
        $name =~ s/\//::/g if($name =~ /\//);
        next if(!$name->isa($self));
        next if($self eq $name);
        $modules{$name} = 1;
    }
    if(0 == scalar(@_)) {
        return [( keys(%modules) )] if(0 < scalar(keys(%modules)));
        return;
    }
    while(0 < scalar(@_)) {
        my $name = shift(@_);
        return 0 if(ref($name) !~ /^$/);
        return 0 if(!defined($modules{$name}));
    }
    return 1;
}


=head2 hasLoaded

    my $MODULE_ARRAY = $OBJECT->hasLoaded();
    if(defined($MODULE_ARRAY));

    my $MODULE_ARRAY = Anansi::Library->hasLoaded();
    if(defined($MODULE_ARRAY));

    if(1 == $OBJECT->hasLoaded(
        'Some::Module',
        'Another::Module',
        'Etc'
    ));

    if(1 == Anansi::Library->hasLoaded(
        'Some::Module',
        'Another::Module',
        'Etc'
    ));

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item name I<(Array B<or> String, Optional)>

A namespace or an array of namespaces.

=back

Either returns an array of all the loaded modules or whether all of the
specified modules have been loaded with a B<1> I<(one)> for yes and B<0>
I<(zero)> for no.

=cut


sub hasLoaded {
    return if(0 == scalar(@_));
    my $self = shift(@_);
    return if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    my %modules;
    while(my ($name, $value) = each(%INC)) {
        next if($name !~ /\.pm$/);
        $name =~ s/\.pm//;
        $name =~ s/\//::/g if($name =~ /\//);
        $modules{$name} = 1;
    }
    if(0 == scalar(@_)) {
        return [( keys(%modules) )] if(0 < scalar(keys(%modules)));
        return;
    }
    while(0 < scalar(@_)) {
        my $name = shift(@_);
        return 0 if(ref($name) !~ /^$/);
        return 0 if(!defined($modules{$name}));
    }
    return 1;
}


=begin comment

################################################################################

=head2 hasParameter

    my $RESULT = Anansi::Library->hasParameter(
        EXPECTED => [
            {
                SOME_VALUE => {
                    REQUIREMENT => 'OPTIONAL',
                    VALUE => [2,4,6,8,10]
                },
                ANOTHER_VALUE => {
                    VALUE => 24
                },
                ETC => {
                    REQUIREMENT => 'OPTIONAL'
                }
            }
        ],
        SUPPLIED => {
            SOME_VALUE => 3,
            ANOTHER_VALUE => 15
        }
    );
    if(-1 == $RESULT) {
    } elsif(0 == $RESULT || 1 == $RESULT || 2 == $RESULT) {
    }

Determines whether the contents of SUPPLIED matches a pattern set out within
EXPECTED.  EXPECTED is either a HASH or an ARRAY of HASHES with each HASH
containing a number of keys that mirror the keys contained within the SUPPLIED
HASH.

#=cut


sub hasParameter {
    my ($self, %parameters) = @_;
    return -1 if(!defined($parameters{EXPECTED}));
    return -1 if(!defined($parameters{SUPPLIED}));
    return -1 if(ref($parameters{SUPPLIED}) !~ /^HASH$/i);
    my @expected;
    if(ref($parameters{EXPECTED}) =~ /^ARRAY$/i) {
        @expected = (@{$parameters{EXPECTED}});
    } elsif(ref($parameters{EXPECTED}) =~ /^HASH$/i) {
        @expected = ($parameters{EXPECTED});
    } else {
        return -1;
    }
    my $valid = -1;
    for(my $index = 0; $index < scalar(@expected); $index++) {
        next if(ref($expected[$index]) !~ /^HASH$/i);
        $match = 1;
        while(my ($suppliedKey, $suppliedValue) = each(%{$parameters{SUPPLIED}})) {
            if(!defined(%{$expected[$index]}->{$suppliedKey})) {
                $match = 0;
                last;
            }
        }
        if($match) {
            $valid = $index;
            last;
        }
        $match = 1;
        while(my ($expectedKey, $expectedValue) = each(%{$expected[$index]})) {
            next if(ref($expectedKey) !~ /^$/);
            next if(ref($expectedValue) !~ /^HASH$/i);
            my $required = 1;
            if(!defined($expectedValue->{REQUIREMENT})) {
            } elsif(ref($expectedValue->{REQUIREMENT}) !~ /^$/) {
            } elsif($expectedValue->{REQUIREMENT} =~ /^OPTIONAL$/i) {
                $required = 0 if(!defined(%{$parameters{SUPPLIED}}->{$expectedKey}));
            }
            if($required) {
                next if(!defined($expectedValue->{VALUE}));
                my @expectedValues;
                if(ref($expectedValue->{VALUE}) =~ /^ARRAY$/i) {
                    @expectedValues = [(@{$expectedValue->{VALUE}})];
                } elsif(ref($expectedValue->{VALUE}) =~ /^HASH$/i) {
                    @expectedValues = [$expectedValue->{VALUE}];
                }
                my $valued;
                if(0 < scalar(@expectedValues)) {
                    $valued = 0;
                    foreach my $value (@expectedValues) {
                        if(ref($value) =~ /^$/) {
                            if($value == %{$parameters{SUPPLIED}}->{$expectedKey}) {
                                $valued = 1;
                                last;
                            }
                        } elsif(ref($value) =~ /^HASH$/i) {
                            if(defined(%{%{$parameters{SUPPLIED}}->{$expectedKey}}->{REFERENCE})) {
                                last if(%{%{$parameters{SUPPLIED}}->{$expectedKey}}->{REFERENCE} ne ref(%{$parameters{SUPPLIED}}->{$expectedKey}));
                            }
                            if(defined(%{%{$parameters{SUPPLIED}}->{$expectedKey}}->{REFERENCE})) {
                            } else {
                                $valued = 1;
                                last;
                            }
                        }
                    }
                } else {
                    $valued = 1;
                }
                if(0 == $valued) {
                    $match = 0;
                    last;
                }
            }
        }
        if($match) {
            $valid = $index;
            last;
        }
    }
    return $valid;
}

################################################################################

=end comment

=cut


=head2 hasSubroutine

    my $SUBROUTINE_ARRAY = $OBJECT->hasSubroutine();
    if(defined($SUBROUTINE_ARRAY));

    if(1 == $OBJECT->hasSubroutine(
        'someSubroutine',
        'anotherSubroutine',
        'etc'
    ));

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item name I<(Array B<or> String, Optional)>

A namespace or an array of namespaces.

=back

Either returns an array of all the subroutines in the loaded module or whether
the loaded module has all of the specified subroutines with a B<1> I<(one)> for
yes and B<0> I<(zero)> for no.

=cut


sub hasSubroutine {
    return if(0 == scalar(@_));
    my $self = shift(@_);
    return if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    no strict 'refs';
    my %subroutines = map { $_ => 1 } grep { exists &{"$self\::$_"} } keys %{"$self\::"};
    if(0 == scalar(@_)) {
        return [( keys(%subroutines) )] if(0 < scalar(keys(%subroutines)));
        return;
    }
    while(0 < scalar(@_)) {
        my $name = shift(@_);
        return 0 if(ref($name) !~ /^$/);
        return 0 if(!defined($subroutines{$name}));
    }
    return 1;
}


=head1 NOTES

This module is designed to make it simple, easy and quite fast to code your
design in perl.  If for any reason you feel that it doesn't achieve these goals
then please let me know.  I am here to help.  All constructive criticisms are
also welcomed.

=cut


INIT {
}


=head1 AUTHOR

Kevin Treleaven <kevin I<AT> treleaven I<DOT> net>

=cut


1;
