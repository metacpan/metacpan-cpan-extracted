use strict;
use warnings;
use Test::More tests => 31;
use Test::Exception;
BEGIN {
    use_ok( 'Data::FormValidator::Profile' );
}

###############################################################################
# Instantiation; hash
instantiation_via_hash: {
    my %profile = (
        required    => [qw(this that)],
        optional    => [qw(other thing)],
        field_filters => {
            this    => ['trim', 'digit'],
            },
        );
    my $object = Data::FormValidator::Profile->new( %profile );
    isa_ok $object, 'Data::FormValidator::Profile';
    is_deeply $object->profile(), \%profile, 'hash instantiation; profile structure ok';
}

###############################################################################
# Instantiation; hash-ref
instantiation_via_hashref: {
    my %profile = (
        required    => [qw(this that)],
        optional    => [qw(other thing)],
        field_filters => {
            this    => ['trim', 'digit'],
            },
        );
    my $object = Data::FormValidator::Profile->new( \%profile );
    isa_ok $object, 'Data::FormValidator::Profile';
    is_deeply $object->profile(), \%profile, 'hashref instantiation; profile structure ok';
}

###############################################################################
# Reduce to only a given set of fields
reduce_only: {
    my %profile = (
        required    => [qw(this that)],
        optional    => [qw(other thing)],
        field_filters => {
            this    => ['trim', 'digit'],
            },
        );
    my $object = Data::FormValidator::Profile->new( %profile );
    isa_ok $object, 'Data::FormValidator::Profile';

    $object->only( qw(this thing) );
    my %expect = (
        required    => [qw(this)],
        optional    => [qw(thing)],
        field_filters => {
            this    => ['trim', 'digit'],
            },
        );
    is_deeply $object->profile(), \%expect, 'reduced to only certain fields';
}

###############################################################################
# Remove a given set of fields
reduce_remove: {
    my %profile = (
        required    => [qw(this that)],
        optional    => [qw(other thing)],
        field_filters => {
            this    => ['trim', 'digit'],
            },
        );
    my $object = Data::FormValidator::Profile->new( %profile );
    isa_ok $object, 'Data::FormValidator::Profile';

    $object->remove( qw(this) );
    my %expect = (
        required    => [qw(that)],
        optional    => [qw(other thing)],
        field_filters => { },
        );
    is_deeply $object->profile(), \%expect, 'removed "this" field';
}

###############################################################################
# Explicitly set DFV options
explicit_set: {
    my %profile = (
        required    => [qw(this that)],
        );
    my $object = Data::FormValidator::Profile->new( %profile );
    isa_ok $object, 'Data::FormValidator::Profile';

    $object->set(
        filters => [],
        field_filters => { this => 'foo' },
        );
    my %expect = (
        required        => [qw(this that)],
        filters         => [],
        field_filters   => { this => 'foo' },
        );
    is_deeply $object->profile, \%expect, 'explicitly set options';
}

###############################################################################
# Verify interaction with Data::FormValidator; make sure that it'll accept a
# DFV::Profile without choking.
verify_dfv_interaction: {
    my %profile = (
        required    => [qw(this that)],
        optional    => [qw(other thing)],
        );
    my $object = Data::FormValidator::Profile->new( %profile );
    isa_ok $object, 'Data::FormValidator::Profile';

    my $data = {
        'this'  => 'here',
        'that'  => 'there',
        'other' => 'nowhere',
        };
    my $results = $object->check($data);
    isa_ok $results, 'Data::FormValidator::Results';
    ok $results->success(), '... validated successfully';
    is $results->valid('this'), 'here',     '... field: this';
    is $results->valid('that'), 'there',    '... field: that';
    is $results->valid('other'), 'nowhere', '... field: other';
}

###############################################################################
# Call chaining
call_chaining: {
    my %profile = (
        required    => [qw(this that)],
        optional    => [qw(other thing)],
        );
    my $object = Data::FormValidator::Profile->new( %profile );
    isa_ok $object, 'Data::FormValidator::Profile';

    lives_ok {
        $object
            ->only(qw(this that other))
            ->remove(qw(that))
            ->add('foo')
        } '... call chaining';
}

###############################################################################
# Turning required fields into optional ones
make_optional: {
    my %profile = (
        required => [qw( this that )],
        optional => [qw( other thing )],
    );
    my $object = Data::FormValidator::Profile->new( %profile );
    isa_ok $object, 'Data::FormValidator::Profile';

    $object->make_optional(qw( this ));
    my %expect = (
        required => [qw( that )],
        optional => [qw( other thing this )],
    );
    is_deeply $object->profile, \%expect, '... fields made optional';
}

###############################################################################
# Empty list can be accepted when making fields optional
make_optional_empty_list: {
    my %profile = (
        required => [qw( this that )],
    );
    my $object = Data::FormValidator::Profile->new( %profile );
    isa_ok $object, 'Data::FormValidator::Profile';

    $object->make_optional();
    my %expect = (
        required => [qw( this that )],
        optional => [ ],
    );
    is_deeply $object->profile, \%expect, '... no additional fields made optional';
}

###############################################################################
# Turning optional fields into required ones
make_required: {
    my %profile = (
        required => [qw( this that )],
        optional => [qw( other thing )],
    );
    my $object = Data::FormValidator::Profile->new( %profile );
    isa_ok $object, 'Data::FormValidator::Profile';

    $object->make_required(qw( thing ));
    my %expect = (
        required => [qw( this that thing )],
        optional => [qw( other )],
    );
    is_deeply $object->profile, \%expect, '... fields made required';
}

###############################################################################
# Empty list can be accepted when making fields required
make_required_empty_list: {
    my %profile = (
        optional  => [qw( this that )],
    );
    my $object = Data::FormValidator::Profile->new( %profile );
    isa_ok $object, 'Data::FormValidator::Profile';

    $object->make_required();
    my %expect = (
        required => [ ],
        optional => [qw( this that )],
    );
    is_deeply $object->profile, \%expect, '... no additional fields made required';
}

###############################################################################
# List "required" fields.
list_required: {
    my %profile = (
        required => [qw( this that )],
        optional => [qw( other thing )],
    );
    my $object = Data::FormValidator::Profile->new( %profile );
    isa_ok $object, 'Data::FormValidator::Profile';

    my @required = $object->required;
    my @expect   = qw( this that );
    is_deeply \@required, \@expect, '... with correct list of required fields';
}

###############################################################################
# List "optional" fields.
list_optional: {
    my %profile = (
        required => [qw( this that )],
        optional => [qw( other thing )],
    );
    my $object = Data::FormValidator::Profile->new( %profile );
    isa_ok $object, 'Data::FormValidator::Profile';

    my @optional = $object->optional;
    my @expect   = qw( other thing );
    is_deeply \@optional, \@expect, '... with correct list of required fields';
}
