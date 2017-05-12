package Sakila::Schema;
use DBIx::Skinny::Schema;

install_table actor => schema {
    pk 'actor_id';
    columns qw/actor_id first_name last_name last_update/;
};

install_table address => schema {
    pk 'address_id';
    columns qw/address_id address address2 district city_id postal_code phone last_update/;
};

install_table category => schema {
    pk 'category_id';
    columns qw/category_id name last_update/;
};

install_table city => schema {
    pk 'city_id';
    columns qw/city_id city country_id last_update/;
};

install_table country => schema {
    pk 'country_id';
    columns qw/country_id country last_update/;
};

install_table customer => schema {
    pk 'customer_id';
    columns qw/customer_id store_id first_name last_name email address_id active create_date last_update/;
};

install_table film => schema {
    pk 'film_id';
    columns qw/film_id title description release_year language_id original_language_id rental_duration rental_rate length replacement_cost rating special_features last_update/;
};

install_table film_actor => schema {
    pk '';
    columns qw/actor_id film_id last_update/;
};

install_table film_category => schema {
    pk '';
    columns qw/film_id category_id last_update/;
};

install_table film_text => schema {
    pk 'film_id';
    columns qw/film_id title description/;
};

install_table inventory => schema {
    pk 'inventory_id';
    columns qw/inventory_id film_id store_id last_update/;
};

install_table language => schema {
    pk 'language_id';
    columns qw/language_id name last_update/;
};

install_table payment => schema {
    pk 'payment_id';
    columns qw/payment_id customer_id staff_id rental_id amount payment_date last_update/;
};

install_table rental => schema {
    pk 'rental_id';
    columns qw/rental_id rental_date inventory_id customer_id return_date staff_id last_update/;
};

install_table staff => schema {
    pk 'staff_id';
    columns qw/staff_id first_name last_name address_id picture email store_id active username password last_update/;
};

install_table store => schema {
    pk 'store_id';
    columns qw/store_id manager_staff_id address_id last_update/;
};

1;