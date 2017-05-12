# AnyEvent::ConnPool
Simple asynchronous connection pool, based on anyevent.

## Description

Connection pool designed for asynchronous connections.

## Synopsis

    my $connpool = AnyEvent::ConnPool->new(
        constructor =>  sub {
            create_connection();
        },
        check       =>  {
            cb          =>  sub {
                my $conn = shift;
                if ($conn->ping()) {
                    return 1;
                }
            },
            interval    =>  10,
        },
        size    =>  10,
        init    =>  1,
    );

    # get next connection.
    my $unit = $connpool->get();
    my $conn = $unit->conn();

    # get connection by specified number.
    my $unit_1 = $connpool->get(1);

    # after that, it will be obtained by $connpool->get();
    # you can use it for transact handles.
    $unit_1->lock();

    ...;

    # unlocks connection, after that it will be returned to balance scheme.

    $unit->unlock();
