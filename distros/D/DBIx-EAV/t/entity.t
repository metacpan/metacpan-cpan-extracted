#!/usr/bin/perl -w
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::DBIx::EAV;

my $dbh = get_test_dbh;

my $eav = DBIx::EAV->new(
    dbh => $dbh,
    tenant_id => 42,
    static_attributes => [qw/ is_deleted:bool::0 is_active:bool::1 is_published:bool::1 /]
);


$eav->schema->deploy( add_drop_table => $eav->schema->db_driver_name eq 'mysql');
$eav->register_types(read_yaml_file("$FindBin::Bin/entities.yml"));


test_common();
test_save();
test_load_attributes();
test_delete();

done_testing;

sub test_common {

    my $bob = $eav->resultset('Artist')->new_entity({ name => 'Bob Marley' });

    isa_ok $bob, 'DBIx::EAV::Entity';
    is $bob->in_storage, '', 'in_storage';
    is $bob->raw->{name}, 'Bob Marley', 'get';
    is exists $bob->raw->{'rating'}, '', 'get (undef)';

    $bob->set('rating', 10);
    is $bob->raw->{rating}, 10, 'set($attr, $val)';

    $bob->set({ name => 'Robert Marley', rating => 100 });
    is $bob->raw, { name => 'Robert Marley', rating => 100 }, 'set(\%attrs)';
}

sub test_save {
    diag 'testing save()';

    my $bob = $eav->resultset('Artist')->new_entity({ name => 'Bob Marley', rating => 10 });
    $bob->save();

    is $bob->in_storage, 1, 'in_storage';

    is $dbh->selectrow_hashref('SELECT * from eav_entities WHERE id = '.$bob->id),
              {
                  id => $bob->id,
                  entity_type_id => $eav->type('Artist')->id,
                  is_published => 1,
                  is_active => 1,
                  is_deleted => 0,
              },
              'entity row';


    is $dbh->selectrow_hashref(sprintf 'SELECT value from eav_value_varchar WHERE entity_id = %d AND attribute_id = %d', $bob->id, $bob->type->attribute('name')->{id}),
            { value => 'Bob Marley' },
            "'name' attribute row";

    is $dbh->selectrow_hashref(sprintf 'SELECT value from eav_value_int WHERE entity_id = %d AND attribute_id = %d', $bob->id, $bob->type->attribute('rating')->{id}),
            { value => 10 },
            "'rating' attribute row";

    # create with static attributes
    diag 'create with static attributes';
    my $peter = $eav->resultset('Artist')->new_entity({ name => 'Peter Tosh', is_published => 0 });
    $peter->save();

    is $dbh->selectrow_hashref('SELECT * from eav_entities WHERE id = '.$peter->id)->{is_published}, 0, 'create with static attrs';

    is $dbh->selectrow_hashref(sprintf 'SELECT value from eav_value_varchar WHERE entity_id = %d AND attribute_id = %d', $peter->id, $peter->type->attribute('name')->{id}),
            { value => 'Peter Tosh' },
            "'name' attribute row";


    # update
    $peter->set('name', 'Peter Machintosh')->save;

    is $dbh->selectrow_hashref(sprintf 'SELECT value from eav_value_varchar WHERE entity_id = %d AND attribute_id = %d', $peter->id, $peter->type->attribute('name')->{id}),
            { value => 'Peter Machintosh' },
            "name updated";



    # update static and dynamic attrs
    $peter->set({ rating => 10, is_published => 1, is_deleted => 1 })->save;

    is $dbh->selectrow_hashref(sprintf 'SELECT value from eav_value_int WHERE entity_id = %d AND attribute_id = %d', $peter->id, $peter->type->attribute('rating')->{id})->{value},
                10, "dynamic attr updated";

    is $dbh->selectrow_hashref(sprintf 'SELECT is_published, is_deleted from eav_entities WHERE id = %d', $peter->id),
              { is_published => 1, is_deleted => 1 },
              "static attrs updated";


    # set attr to undef
    $peter->set({ rating => undef })->save;
    is $dbh->selectrow_hashref(sprintf 'SELECT value from eav_value_int WHERE entity_id = %d AND attribute_id = %d', $peter->id, $peter->type->attribute('rating')->{id}),
                undef, "set attr to undef";

    $peter->set({ rating => 10 })->save;
    is $dbh->selectrow_hashref(sprintf 'SELECT value from eav_value_int WHERE entity_id = %d AND attribute_id = %d', $peter->id, $peter->type->attribute('rating')->{id})->{value},
                10, "set undef back to a value";
}

sub test_load_attributes {
    diag 'testing load_attributes()';

    my $entity = $eav->resultset('Artist')->new_entity({ name => 'Elvis', rating => 10 });
    $entity->save();

    # sabotate
    delete $entity->raw->{name};
    delete $entity->raw->{rating};

    # load
    is $entity->load_attributes, 4, 'load_attributes retval';
    is $entity->get('name'), 'Elvis', 'name is there';
    is $entity->get('rating'), 10, 'rating is there';
}


sub test_delete {

    my $entity = $eav->resultset('Artist')->new_entity({ name => 'Cafe' });
    $entity->save();

    my $id = $entity->id;

    is $entity->delete, 1, 'delete()';

    is $dbh->selectrow_hashref('SELECT * from eav_entities WHERE id = '.$id), undef, 'entity row deleted';

    is $entity->in_storage, '', 'not in_storage after delete';

}
