-- 1st comment before CREATE TABLE statement
-- 2nd comment before CREATE TABLE statement
CREATE TABLE IF NOT EXISTS Products (
  product_id INT PRIMARY KEY, -- comment next to column definition
  -- comment above column definition
  description VARCHAR(50) NOT NULL,
  price FLOAT NOT NULL,
  stock INT NOT NULL,
  manufacturer_id INT,
  FOREIGN KEY (manufacturer_id) REFERENCES Manufacturers (manufacturer_id)
);
