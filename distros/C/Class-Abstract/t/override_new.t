#!/usr/bin/perl
# t/override_new.t -- enforcement when the abstract class defines its own new().
#
# Verifies the pattern described in the SYNOPSIS: Animal has its own new()
# that calls check_abstract(), Dog inherits it via SUPER::new.

use strict;
use warnings;

BEGIN { unshift @INC, 'lib' }

use Test::Most;
use Scalar::Util qw(blessed);

use Class::Abstract;

# ---------------------------------------------------------------------------
# Fixture packages (mirroring the user's code exactly, plus check_abstract)
# ---------------------------------------------------------------------------

{
    package Animal;
    use parent -norequire, 'Class::Abstract';

    sub new {
        # Enforce: croaks when called as Animal->new, passes for Dog->new
        my $class = shift;
        Class::Abstract::check_abstract($class);
        return bless { 'a' => 'b' }, $class;
    }
}

{
    package Dog;
    use parent -norequire, 'Animal';

    sub new {
        my ($class, %args) = @_;
        my $self = $class->SUPER::new;   # delegates to Animal::new with $class='Dog'
        $self->{name} = $args{name};
        return $self;
    }
    sub speak { 'Woof' }
    sub eat   { 'Nom'  }
}

# ---------------------------------------------------------------------------
# Helper: disable both bypass paths (same as basic.t enforcement_on)
# ---------------------------------------------------------------------------

sub enforcement_on (&) {
    my ($code) = @_;
    local $Class::Abstract::BYPASS                 = 0;
    local $Class::Abstract::config{harness_bypass} = 0;
    local $ENV{HARNESS_ACTIVE}                     = 0;
    return $code->();
}

# ---------------------------------------------------------------------------
# 1. Animal->new must croak (even though Animal defines its own new())
# ---------------------------------------------------------------------------

subtest 'Animal->new croaks -- abstract class with custom new()' => sub {
    plan tests => 1;
    enforcement_on {
        throws_ok { Animal->new }
            qr/Cannot instantiate abstract class Animal directly/,
            'Animal->new croaks';
    };
};

# ---------------------------------------------------------------------------
# 2. Dog->new succeeds and returns a properly populated Dog
# ---------------------------------------------------------------------------

subtest 'Dog->new succeeds -- concrete subclass via SUPER chain through Animal::new' => sub {
    plan tests => 4;
    enforcement_on {
        my $obj;
        lives_ok { $obj = Dog->new(name => 'Rex') }
            'Dog->new lives';

        ok blessed($obj),
            'Dog->new returned a blessed ref';

        is ref($obj), 'Dog',
            'object is blessed into Dog';

        is $obj->{name}, 'Rex',
            'name attribute populated by Dog::new';
    };
};

# ---------------------------------------------------------------------------
# 3. is_abstract returns correct values
# ---------------------------------------------------------------------------

subtest 'Animal->is_abstract = 1, Dog->is_abstract = 0' => sub {
    plan tests => 2;
    is( Animal->is_abstract, 1, 'Animal->is_abstract = 1' );
    is( Dog->is_abstract,    0, 'Dog->is_abstract = 0' );
};

# ---------------------------------------------------------------------------
# 4. check_abstract() directly: croaks for abstract, lives for concrete
# ---------------------------------------------------------------------------

subtest 'check_abstract() enforcement' => sub {
    plan tests => 2;
    enforcement_on {
        throws_ok { Class::Abstract::check_abstract('Animal') }
            qr/Cannot instantiate abstract class Animal directly/,
            'check_abstract(Animal) croaks';

        lives_ok { Class::Abstract::check_abstract('Dog') }
            'check_abstract(Dog) lives';
    };
};

# ---------------------------------------------------------------------------
# 5. is_abstract() three-argument form: Class::Abstract->is_abstract('X')
# ---------------------------------------------------------------------------

subtest 'is_abstract() three-argument form works correctly' => sub {
    plan tests => 2;

    is( Class::Abstract->is_abstract('Animal'), 1,
        'Class::Abstract->is_abstract("Animal") = 1' );

    is( Class::Abstract->is_abstract('Dog'), 0,
        'Class::Abstract->is_abstract("Dog") = 0' );
};

done_testing;
