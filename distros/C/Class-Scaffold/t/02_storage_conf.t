#!/usr/bin/env perl

# test value_person_name_full framework objects in the context of
# Registry-NICAT, which uses a specific character set for that object

use warnings;
use strict;
use Test::More tests => 5;


use parent 'Class::Scaffold::App::Test';


sub app_init {
    my $self = shift;
    $ENV{CF_CONF} = 'local';
    $self->SUPER::app_init(@_);

    our %local_conf = (
        core_storage_name => 'STG_NULL_DBI',
        core_storage_args => {
            dbname     => 'mydb',
            dbuser     => 'myuser',
            dbpass     => 'mypass',
            AutoCommit => 27,
        },
    );

    %Property::Lookup::Local::opt = (
        %Property::Lookup::Local::opt,
        %local_conf,
    );
}


sub app_code {
    my $self = shift;
    $ENV{CF_CONF} = 'local';

    $self->SUPER::app_code(@_);

    my $storage = $self->delegate->core_storage;

    our %local_conf;
    isa_ok($storage, $self->delegate->get_storage_class_name_for(
        $local_conf{core_storage_name}
    ));
    while (my ($key, $value) = each %{ $local_conf{core_storage_args} }) {
        is($storage->$key, $value, "storage [$key] = $value");
    }
}


main->new->run_app;
