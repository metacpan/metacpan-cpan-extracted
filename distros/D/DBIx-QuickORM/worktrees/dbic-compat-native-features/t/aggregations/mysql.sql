CREATE TABLE orders(
    order_id INTEGER     NOT NULL PRIMARY KEY AUTO_INCREMENT,
    category VARCHAR(32) NOT NULL,
    total    INTEGER     NOT NULL,
    qty      INTEGER     NOT NULL DEFAULT 1
);
