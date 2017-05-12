use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIx::ObjectMapper::Engine::DBI;
use DBIx::ObjectMapper;
use DBIx::ObjectMapper::Metadata::Query;

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    username => '',
    password => '',
    on_connect_do => [
        q{CREATE TABLE customer (id integer primary key, name text)},
        q{CREATE TABLE email ( customer_id integer primary key, email text)},
        q{CREATE TABLE address( id integer primary key, customer_id integer, address text)},
    ],
});

my $mapper = DBIx::ObjectMapper->new( engine => $engine );
my $meta = $mapper->metadata;
$meta->autoload_all_tables;
ok my $customer = $meta->t('customer');
ok my $email = $meta->t('email');
ok my $address = $meta->t('address');

$customer->insert( name => $_ )->execute for qw(cust1 cust2 cust3);
$email->insert( customer_id => 1, email => 'cust1@example.com' )->execute;
$email->insert( customer_id => 2, email => 'cust2@example.com' )->execute;
$email->insert( customer_id => 3, email => 'cust3@example.com' )->execute;

$address->insert( customer_id => 1, address => 'address' . $_ )->execute for 1 .. 5;

{
    ok my $query = $customer->select
        ->column(@{$customer->columns}, @{$customer->columns})
        ->join([ $email, [ $email->c('customer_id') == $customer->c('id') ] ]);

    dies_ok {
        my $meta_query = DBIx::ObjectMapper::Metadata::Query->new(
            'customer_and_email' => $query,
            {
                engine => $engine,
            },
        );
    };
}


ok my $query = $customer->select->column(@{$customer->columns}, @{$email->columns} )->join([ $email, [ $email->c('customer_id') == $customer->c('id') ] ]);

ok my $meta_query = DBIx::ObjectMapper::Metadata::Query->new(
    'customer_and_email' => $query,
    {
        engine => $engine,
        foreign_key => [
            {
                table => 'email',
                refs => ['customer_id'],
                keys => ['customer_id'],
            }
        ]
    },
);

{
    is $meta_query->table_name, 'customer_and_email';
    is $meta_query, 'customer_and_email';
    is_deeply $meta_query->columns, [
        map { $_->as_alias('customer_and_email') }
            ( @{ $customer->columns }, @{ $email->columns } )
    ];

    is $meta_query->c('id'), 'customer_and_email.id';
    is $meta_query->column('name'), 'customer_and_email.name';
    is $meta_query->c('email'), 'customer_and_email.email';
    is_deeply $meta_query->foreign_key, [
        {
            table => 'email',
            refs => ['customer_id'],
            keys => ['customer_id'],
        }
    ];

    dies_ok { $meta_query->insert };
    dies_ok { $meta_query->delete };
    dies_ok { $meta_query->update };

    ok my $q = $meta_query->select->order_by($meta_query->c('id'));
    is $q->count, 3;
    ok my $it = $q->execute;
    my $loop_cnt = 0;
    while( my $c = $it->next ) {
        $loop_cnt++;
        is $c->{id}, $loop_cnt;
        is $c->{name}, 'cust' . $loop_cnt;
        is $c->{email}, 'cust' . $loop_cnt . '@example.com';
    }
    is $loop_cnt, 3;

    my @res = @$it;
    is $res[0]->{name}, 'cust1';
    is $res[1]->{name}, 'cust2';
    is $res[2]->{name}, 'cust3';

    ok my $clone = $meta_query->clone('customer_and_email2');
    is $clone->table_name, 'customer_and_email2';
};

ok $mapper->maps(
    [
        $query => 'customer_email',
        {
            primary_key => ['id'],
        }
    ] => 'MyTest002::Customer',
    accessors => { auto => 1 },
    constructor => { auto => 1 },
    attributes => {
        properties => {
            rel_email => {
                isa => $mapper->relation( has_one => 'MyTest002::Email' )
            },
            addresses => {
                isa => $mapper->relation(
                    has_many => 'MyTest002::Address',
                ),
            }
        }
    }
);

$mapper->maps(
    $email => 'MyTest002::Email',
    accessors => { auto => 1 },
    constructor => { auto => 1 },
);

$mapper->maps(
    [
        $address->select => 'address2',
        {
            primary_key => ['id'],
            foreign_key => [
                {
                    table => 'customer_email',
                    refs => ['customer_id'],
                    keys => ['customer_id']
                }
            ]
        }
    ] => 'MyTest002::Address',
    accessors => { auto => 1 },
    constructor => { auto => 1 },
);

{ # session
    my $session = $mapper->begin_session;

    ok my $cust1 = $session->get( 'MyTest002::Customer' => 1 );
    is $cust1->name, 'cust1';
    is $cust1->email, 'cust1@example.com';
    is $cust1->id, 1;

    my $attr = $mapper->attribute('MyTest002::Customer');
    ok my $it = $session->search('MyTest002::Customer')->filter(
        $attr->p('id') < 10
    )->execute;

    my $loop_cnt = 0;
    while( my $c = $it->next ) {
        $loop_cnt++;
        is $c->id, $loop_cnt;
        is $c->name, 'cust' . $loop_cnt;
        is $c->email, 'cust' . $loop_cnt . '@example.com';
    }

    is $loop_cnt, 3;
};

{ # relation
    my $session = $mapper->begin_session;
    ok my $cust1 = $session->get( 'MyTest002::Customer' => 1 );
    ok my $email = $cust1->rel_email;
    is $email->customer_id, $cust1->customer_id;
    is $email->email, $cust1->email;

    ok my $address = $cust1->addresses;
    ok @$address == 5;

    my $loop_cnt = 1;
    for my $a ( @$address ) {
        is $a->customer_id, 1;
        is $a->address, 'address' . $loop_cnt++;
    }

};


done_testing;
