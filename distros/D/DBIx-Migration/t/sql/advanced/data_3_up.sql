INSERT INTO Manufacturers (manufacturer_id, name) VALUES
  (901, 'Flattermann AG'),
  (902, 'Dragon.com'),
  (903, 'KiteSports');

INSERT INTO Products (product_id, description, price, stock, manufacturer_id) VALUES
  (201, 'Skyscraper', 99.0, 12, 901),
  (202, 'HimmelsStürmer', 129.0, 4, 901),
  (203, 'Rainbow Hopper', 45.0, 20, 902),
  (204, 'TumbleAround', 21.0, 30, 901),
  (205, '2Hi4U', 129.0, 1, 902),
  (206, 'AirCrusher', 99.0, 3, 904); -- 904 violates the foreign key constraint
