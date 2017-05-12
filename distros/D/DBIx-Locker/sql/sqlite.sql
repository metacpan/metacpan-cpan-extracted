CREATE TABLE locks (
  id INTEGER PRIMARY KEY,
  lockstring varchar(128) UNIQUE,
  created varchar(14) NOT NULL,
  expires varchar(14) NOT NULL,
  locked_by varchar(1024)
);
