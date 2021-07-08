CREATE TABLE semaphores (
  id bigint unsigned NOT NULL PRIMARY KEY AUTO_INCREMENT,
  lockstring varchar(128) UNIQUE,
  created datetime NOT NULL,
  expires datetime NOT NULL,
  locked_by text NOT NULL
);
