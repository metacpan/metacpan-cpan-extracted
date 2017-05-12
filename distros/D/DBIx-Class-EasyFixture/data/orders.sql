CREATE TABLE people (
    person_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name      VARCHAR(255) NOT NULL,
    email     VARCHAR(255)     NULL UNIQUE,
    birthday  DATETIME     NOT NULL,
    favorite_album_id INTEGER,
    FOREIGN KEY(favorite_album_id) REFERENCES albums(album_id) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE customers (
    customer_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    person_id      INTEGER  NOT NULL UNIQUE,
    first_purchase DATETIME NOT NULL,
    FOREIGN KEY(person_id) REFERENCES people(person_id)
);

CREATE TABLE orders (
    order_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id INTEGER  NOT NULL,
    order_date  DATETIME NOT NULL,
    FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE items (
    item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name    VARCHAR(255) NOT NULL,
    price   REAL         NOT NULL
);

CREATE TABLE order_item (
    order_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id       INTEGER NOT NULL,
    order_id      INTEGER NOT NULL,
    price         REAL    NOT NULL,
    FOREIGN KEY(item_id)  REFERENCES items(item_id),
    FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

CREATE TABLE albums (
    album_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    producer_id INTEGER,
    FOREIGN KEY(producer_id) REFERENCES people(person_id) DEFERRABLE INITIALLY DEFERRED
);
