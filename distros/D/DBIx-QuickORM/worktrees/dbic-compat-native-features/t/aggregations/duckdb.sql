CREATE SEQUENCE orders_id_seq;

CREATE TABLE orders(
    order_id INTEGER     NOT NULL PRIMARY KEY DEFAULT nextval('orders_id_seq'),
    category VARCHAR(32) NOT NULL,
    total    INTEGER     NOT NULL,
    qty      INTEGER     NOT NULL DEFAULT 1
);
