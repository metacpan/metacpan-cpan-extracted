package DBIx::DataFactory::Type;

use strict;
use warnings;
use Carp;

sub type_name {
    croak 'must be implemented in sub class';
}

sub make_value {
    croak 'must be implemented in sub class';
}

1;

__END__

=head1 NAME

DBIx::DataFactory::Type - the class for defining the rule of inserting data.

=head1 SYNOPSIS

    package DBIx::DataFactory::Type::Test;

    use strict;
    use warnings;
    use Carp;

    sub type_name {
        return 'Test';
    }

    sub make_value {
        my ($class, %args) = @_;
        return 'test';
    }

    1;

=head1 DESCRIPTION

you can define the rule of inserting data as class.  you must define the method named type_name and make_value.

type_name is used to identify the class of type when create_factory_method is called.  in following example, factory method insert data, defined by DBIx::DataFactory::Type::Test(see synopsis) make_value method, into 'test' column automatically.

    $factory_maker->create_factory_method(
        method   => 'create_factory_data',
        table    => 'test_factory',
        auto_inserted_columns => {
            test => {
                type => 'Test',
            },
        },
    );

make_value is used to define data for inserting.  hash specified in auto_inserted_columns except type is passed to make_value.

    $factory_maker->create_factory_method(
        method   => 'create_factory_data',
        table    => 'test_factory',
        auto_inserted_columns => {
            test => {
                type   => 'Test',
                size   => 10,
                regexp => '[a-z]{10}',
            },
        },
    );

when the above case, make_value will be called in create_factory_data method as following.

    DBIx::DataFactory::Type::Test->make_value(
        size   => 10,
        regexp => '[a-z]{10}',
    );

=head1 DEFINED TYPE

the following type is already defined in this module.

=head2 DBIx::DataFactory::Type::Int

random int maker.  you can pass size parameter.

    $factory_maker->create_factory_method(
        method   => 'create_factory_data',
        table    => 'test_factory',
        auto_inserted_columns => {
            int => {
                type => 'Int',
                size => 8,
            },
        },
    );

=head2 DBIx::DataFactory::Type::Num

random number maker.  you can pass size parameter.  size means integer part size.

    $factory_maker->create_factory_method(
        method   => 'create_factory_data',
        table    => 'test_factory',
        auto_inserted_columns => {
            num => {
                type => 'Num',
                size => 8,
            },
        },
    );

=head2 DBIx::DataFactory::Type::Str

random string maker.  you can pass size or regexp parameter.

if size parameter is passed, this maker produce strings like [a-zA-Z0-9]{$size}.

if regexp parameter is passed, this maker produce strings according to passed regular regexp.

    $factory_maker->create_factory_method(
        method   => 'create_factory_data',
        table    => 'test_factory',
        auto_inserted_columns => {
            str => {
                type   => 'Str',
                regexp => '[a-z]{20}',
            },
        },
    );

=head2 DBIx::DataFactory::Type::Str

returning one of specified set in a random manner.

    $factory_maker->create_factory_method(
        method   => 'create_factory_data',
        table    => 'test_factory',
        auto_inserted_columns => {
            set => {
                type => 'Set',
                set  => ['test1', 'test2'],
            },
        },
    );
