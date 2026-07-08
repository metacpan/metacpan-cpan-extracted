CREATE TABLE orders(
    order_id SERIAL      NOT NULL PRIMARY KEY,
    category VARCHAR(32) NOT NULL,
    total    INTEGER     NOT NULL,
    qty      INTEGER     NOT NULL DEFAULT 1
);
