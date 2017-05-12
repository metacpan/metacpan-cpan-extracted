package DBIx::Class::Factory;

use strict;
use warnings;

use DBIx::Class::Factory::Fields;

=encoding utf8

=head1 NAME

DBIx::Class::Factory - factory-style fixtures for DBIx::Class

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

Create factory:

    package My::UserFactory;
    use base qw(DBIx::Class::Factory);

    __PACKAGE__->resultset(My::Schema->resultset('User'));
    __PACKAGE__->fields({
        name => __PACKAGE__->seq(sub {'User #' . shift}),
        status => 'new',
    });

    package My::SuperUserFactory;
    use base qw(DBIx::Class::Factory);

    __PACKAGE__->base_factory('My::UserFactory');
    __PACKAGE__->field(superuser => 1);

Use factory:

    my $user = My::UserFactory->create();
    my @verified_users = @{ My::UserFactory->create_batch(3, {status => 'verified'}) };

    my $superuser = My::SuperUserFactory->build();
    $superuser->insert();

=head1 DESCRIPTION

Ruby has C<factory_girl>, Python has C<factory_boy>. Now Perl has C<DBIx::Class::Factory>.

Creating big fixture batches may be a pain. This module provides easy way
of creating data in database via L<DBIx::Class>.

To create a factory just derive from L<DBIx::Class::Factory> and apply some settings.
You can also add some data at the moment of creating instance, redefining factory defaults.

Tests for this module contains a bunch of usefull examples.

=head1 METHODS

=head2 Factory settings

=over

=item B<base_factory>

Use this to create one factory derived from another. Don't use direct inheritance.

=cut

sub base_factory {
    my ($class, $base_class) = @_;

    foreach my $data_field (qw(fields exclude)) {
        $class->_class_data->{$data_field} = {
            %{ $base_class->_class_data->{$data_field} || {} },
            %{ $class     ->_class_data->{$data_field} || {} },
        };
    }

    $class->_class_data->{resultset} = $base_class->_class_data->{resultset}
        unless defined $class->_class_data->{resultset};

    no strict 'refs';
    push(@{$class . '::ISA'}, $base_class);

    return;
}

=item B<resultset>

Set resultset this factory is going to work with.

=cut

sub resultset {
    my ($class, $resultset) = @_;

    $class->_class_data->{resultset} = $resultset;

    return;
}

=item B<fields>

Accept hashref as an argument. Add fields to factory. See L</field> for more details.

=cut

sub fields {
    my ($class, $fields) = @_;

    foreach my $key (keys %{$fields}) {
        $class->field($key => $fields->{$key});
    }

    return;
}

=item B<field>

    __PACKAGE__->field($name => $value);

Add field to the factory. C<$name> is directly used in resultset's C<new> method.
C<$value> must be any value or helper result (see L</Helpers>).
C<CODEREF> as a value will be used as callback. However, you must not rely on this,
it can be changed in future releases — use L</callback> helper instead.

=cut

sub field {
    my ($class, $key, $value) = @_;

    $class->_class_data->{fields}->{$key} = $value;

    return;
}

=item B<exclude>

Sometimes you want some fields to be in the factory but not in the created object.

You can use C<exclude> to exclude them. Both arrayref and scalar are accepted.

    {
        package My::UserFactory;

        use base qw(DBIx::Class::Factory);

        __PACKAGE__->resultset(My::Schema->resultset('User'));
        __PACKAGE__->exclude('all_names');
        __PACKAGE__->fields({
            first_name => __PACKAGE__->callback(sub {shift->get('all_names')}),
            last_name => __PACKAGE__->callback(sub {shift->get('all_names')}),
        });
    }

    My::UserFactory->create({all_names => 'Bond'});

=cut

sub exclude {
    my ($class, $list) = @_;

    unless (ref $list eq 'ARRAY') {
        $list = [$list];
    }

    foreach my $exclude_field (@{$list}) {
        $class->_class_data->{exclude}->{$exclude_field} = 1;
    }

    return;
}

=back

=head2 Helpers

Sometimes you want the value of the field to be not just static value but something special.
Helpers are here for that.

=over

=item B<callback>

Sometimes you want field value to be calculated everytime fields for object are created.
Just provide C<callback> as a value in that case.

It will be called with the L<DBIx::Class::Factory::Fields> instance as an argument.

    __PACKAGE__->fields({
        status => __PACKAGE__->callback(sub {
            my ($fields) = @_;
    
            return $fields->get('superuser') ? 3 : 5;
        }),
    });

=cut

sub callback {
    my ($class, $block) = @_;

    return sub {
        $block->(@_);
    }
}

=item B<seq>

Same as L</callback>, but the callback is called with an additional first argument: the iterating counter.

You can also provide the initial value of the counter (C<0> is default).

    __PACKAGE__->field(id => __PACKAGE__->seq(sub {shift}, 1));

=cut

sub seq {
    my ($class, $block, $init_value) = @_;

    $init_value = 0 unless defined $init_value;

    return sub {
        $block->($init_value++, @_);
    }
}

=item B<related_factory>

This helper just calls another factory's L</get_fields> method.
Thanks to C<DBIx::Class>, the returned data will be used to create a related object.

    package My::UserFactory;

    use base qw(DBIx::Class::Factory);

    __PACKAGE__->resultset(My::Schema->resultset('User'));
    __PACKAGE__->fields({
        # create a new city if it's not specified
        city => __PACKAGE__->related_factory('My::CityFactory'),
    });

=cut

sub related_factory {
    my ($class, $factory_class, $extra_fields) = @_;

    return sub {
        return $factory_class->get_fields($extra_fields);
    };
}

=item B<related_factory_batch>

Same as L</related_factory>, but calls L</get_fields_batch> method.

    __PACKAGE__->fields({
        # Add three accounts to the user
        accounts => __PACKAGE__->related_factory_batch(3, 'My::AccountFactory')
    });

=cut

sub related_factory_batch {
    my ($class, $n, $factory_class, $extra_fields) = @_;

    return sub {
        return $factory_class->get_fields_batch($n, $extra_fields);
    };
}

=back

=head2 Factory actions

=over

=item B<get_fields>

Returns fields that will be used to create object without creating something.

=cut

sub get_fields {
    my ($class, $extra_fields) = @_;

    $extra_fields = {} unless defined $extra_fields;

    my $fields = DBIx::Class::Factory::Fields->new(
        {
            %{$class->_class_data->{fields}},
            %{$extra_fields},
        },
        $class->_class_data->{exclude}
    );

    return $class->after_get_fields($fields->all());
}

=item B<build>

Creates L<DBIx::Class::Row> object without saving it to a database.

=cut

sub build {
    my ($class, $extra_fields) = @_;

    my $resultset = $class->_class_data->{resultset};

    return $class->after_build($resultset->new($class->get_fields($extra_fields)));
}

=item B<create>

Creates L<DBIx::Class::Row> object and saves it to a database.

L<DBIx::Class::Row/discard_changes> is also called on the created object.

=cut

sub create {
    my ($class, $extra_fields) = @_;

    my $row = $class->build($extra_fields)->insert();
    $row->discard_changes;

    return $class->after_create($row);
}

=item B<get_fields_batch>

Runs L</get_fields> C<n> times and returns arrayref of results.

=cut

sub get_fields_batch {
    my ($class, @params) = @_;

    return $class->_batch('get_fields', @params);
}

=item B<build_batch>

Runs L</build> C<n> times and returns arrayref of results.

=cut

sub build_batch {
    my ($class, @params) = @_;

    return $class->_batch('build', @params);
}

=item B<create_batch>

Runs L</create> C<n> times and returns arrayref of results.

=cut

sub create_batch {
    my ($class, @params) = @_;

    return $class->_batch('create', @params);
}

=back

=head2 Hooks

You can define the following methods in your factory to be executed after corresponding methods.

They take result of the corresponding methods as an argument and must return the new one.

=over

=item B<after_get_fields>
=cut

sub after_get_fields {
    my ($class, $fields) = @_;

    return $fields;
}

=item B<after_build>
=cut

sub after_build {
    my ($class, $row) = @_;

    return $row;
}

=item B<after_create>

    sub after_create {
        my ($class, $user_row) = @_;

        $user_row->auth();

        return $user_row;
    }
=cut

sub after_create {
    my ($class, $row) = @_;

    return $row;
}

=back

=cut

# PRIVATE METHODS

sub _batch {
    my ($class, $method, $n, $extra_fields) = @_;

    my @batch = ();
    for (1 .. $n) {
        push(@batch, $class->$method($extra_fields));
    }

    return \@batch;
}

sub _class_data {
    my ($class) = @_;

    no strict 'refs';

    my $var_name = $class . '::_dbix_class_factory_data';

    unless (defined ${$var_name}) {
        ${$var_name} = {fields => {}};
    }

    return ${$var_name};
}

=head1 DEDICATION

This module is lovingly dedicated to my wife Catherine.

=head1 AUTHOR

Vadim Pushtaev, C<pushtaev@cpan.org>

=head1 BUGS AND FEATURES

Bugs are possible, feature requests are welcome. Write me as soon as possible.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Vadim Pushtaev.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
