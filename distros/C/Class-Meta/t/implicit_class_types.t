#!/usr/bin/perl -w

##############################################################################
# Set up the tests.
##############################################################################

use strict;
use Test::More tests => 28;

##############################################################################
# Create a simple class.
##############################################################################

package Class::Meta::TestTypes;

BEGIN {
    $SIG{__DIE__} = \&Carp::confess;
    main::use_ok( 'Class::Meta');
    main::use_ok( 'Class::Meta::Type');
}

BEGIN {
    use Test::More;
    ok my $cm = Class::Meta->new(
        package => __PACKAGE__,
        key     => 'types',
        name    => 'Class::Meta::TestTypes Class',
    ), "Create TestTypes CM object";

    ok $cm->add_constructor(name => 'new'), "Create TestTypes constctor";
    ok $cm->build, "Build TestTypes";
}

##############################################################################
# Create another class that implicitly uses the other class as a valid data
# type.
##############################################################################

package Class::Meta::Another;

BEGIN {
    use Test::More;
    ok my $cm = Class::Meta->new(
        package => __PACKAGE__,
        key     => 'another',
        name    => 'Class::Meta::Another Class',
    ), "Create Another CM object";

    ok $cm->add_constructor(name => 'new'), "Create Another constctor";
    ok $cm->add_attribute(
        name    => 'implicit',
        type    => 'types',
        default => sub { Class::Meta::TestTypes->new },
    ), 'Add "types" attribute';

    ok $cm->build, "Build Another";
}

package Class::Meta::YetAnother;
our $ERROR;

BEGIN {
    use Test::More;
    # Replace the validation checker with one of our own.
    ok( Class::Meta::Type->class_validation_generator( sub {
        my ($pkg, $type) = @_;
        return [ sub {
            my ($value, $object, $attr) = @_;
            return if UNIVERSAL::isa($value, $pkg);
            $ERROR = "Value '$value' is not a valid $type";
            die "hooyah!";
        } ];
    }), "Replace class type check generator");

    can_ok 'Class::Meta::Type', 'default_builder';
    ok( Class::Meta::Type->default_builder('affordance'),
        "Make affordance accessors for YetAnother objects" );

    ok my $cm = Class::Meta->new(
        package => __PACKAGE__,
        key     => 'yet_another',
        name    => 'Class::Meta::YetAnother Class',
    ), "Create YetAnother CM object";

    ok $cm->add_constructor(name => 'new'), "Create Another constctor";
    ok $cm->add_attribute(
        name    => 'another_implicit',
        type    => 'another',
        default => sub { Class::Meta::Another->new },
    ), 'Add "another" attribute';

    ok $cm->build, "Build YetAnother";
}

package main;

# Check that the "another" class was added as a data type.
ok my $an = Class::Meta::Another->new, 'Create Another object';
isa_ok $an->implicit, 'Class::Meta::TestTypes';
ok $an->implicit(Class::Meta::TestTypes->new), 'Replace TestTypes object';
isa_ok $an->implicit, 'Class::Meta::TestTypes';
eval { $an->implicit('foo') };
ok my $err = $@, "Catch TestTypes exception";
like $err, qr/Value 'foo' is not a valid Class::Meta::TestTypes/,
  "Check TestTypes exception string";

# Now try with our replaced class check generator.
ok my $yet = Class::Meta::YetAnother->new, 'Create YetAnother object';
isa_ok $yet->get_another_implicit, 'Class::Meta::Another';
is $Class::Meta::YetAnother::ERROR, undef, "Check for undef error";
eval { $yet->set_another_implicit('foo') };
ok $err = $@, "Catch Another exception";
like $err, qr/hooyah\!/,
  "Check Another exception string";
is $Class::Meta::YetAnother::ERROR,
   "Value 'foo' is not a valid Class::Meta::Another",
   "Check for defined error";
