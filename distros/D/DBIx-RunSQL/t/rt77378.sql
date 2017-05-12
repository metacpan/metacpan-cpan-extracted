CREATE TABLE user (
 id             INTEGER PRIMARY KEY,
 name           VARCHAR(255)
);
CREATE TABLE emails (
 uid    INTEGER NOT NULL,
 name   VARCHAR(255) UNIQUE NOT NULL,
 FOREIGN KEY (uid) REFERENCES user(id)
);

CREATE TRIGGER user_cleanup
 BEFORE DELETE ON user FOR EACH ROW
 BEGIN
  DELETE FROM email WHERE uid=OLD.id;
 END;