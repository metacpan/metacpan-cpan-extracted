CREATE TABLE items (
  id INTEGER PRIMARY KEY NOT NULL,
  char_currency VARCHAR(25) NOT NULL,
  format_currency VARCHAR(25) NOT NULL,
  int_currency INTEGER NOT NULL,
  dec_currency DECIMAL(9,2) NOT NULL,
  currency_code VARCHAR(3)
);

CREATE TABLE prices (
  id INTEGER PRIMARY KEY NOT NULL,
  char_currency VARCHAR(25) NOT NULL,
  format_currency VARCHAR(25) NOT NULL,
  int_currency INTEGER NOT NULL,
  dec_currency DECIMAL(9,2) NOT NULL,
  currency_code VARCHAR(3)
);
