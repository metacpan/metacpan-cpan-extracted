CREATE TABLE customer(
  cust_id INTEGER PRIMARY KEY,
  cust_name TEXT,
  cust_addr TEXT
);

CREATE VIEW customer_address AS
   SELECT cust_id, cust_addr FROM customer;

CREATE TRIGGER cust_addr_chng
INSTEAD OF UPDATE OF cust_addr ON customer_address
BEGIN
   UPDATE customer SET cust_addr=NEW.cust_addr
   WHERE cust_id=NEW.cust_id;
END;
