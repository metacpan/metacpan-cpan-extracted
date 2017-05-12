BEGIN TRANSACTION;

CREATE TABLE User (
	user_seq INTEGER PRIMARY KEY,
	user_id TEXT,
	password_digest TEXT,
	created_on DATETIME DEFAULT current_date,
	updated_on DATETIME DEFAULT current_date
);

CREATE TABLE Profile (
	user_seq INTEGER PRIMARY KEY CONSTRAINT fk_user_seq REFERENCES User(user_seq),
	name TEXT,
	nickname TEXT,
	created_on DATETIME DEFAULT current_date,
	updated_on DATETIME DEFAULT current_date
);

CREATE TABLE Diary (
    diary_seq INTEGER PRIMARY KEY,
    user_seq INTEGER CONSTRAINT fk_user_seq REFERENCES User(user_seq),
	title TEXT,
	content TEXT,
	created_on DATETIME DEFAULT current_date,
	updated_on DATETIME DEFAULT current_date
);

-- Foreign Key Preventing insert
CREATE TRIGGER fki_Profile_user_seq_User_user_seq
BEFORE INSERT ON [Profile]
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'insert on table "Profile" violates foreign key constraint "fki_Profile_user_seq_User_user_seq"')
  WHERE NEW.user_seq IS NOT NULL AND (SELECT user_seq FROM User WHERE user_seq = NEW.user_seq) IS NULL;
END;

-- Foreign key preventing update
CREATE TRIGGER fku_Profile_user_seq_User_user_seq
BEFORE UPDATE ON [Profile]
FOR EACH ROW BEGIN
    SELECT RAISE(ROLLBACK, 'update on table "Profile" violates foreign key constraint "fku_Profile_user_seq_User_user_seq"')
      WHERE NEW.user_seq IS NOT NULL AND (SELECT user_seq FROM User WHERE user_seq = NEW.user_seq) IS NULL;
END;

-- Foreign key preventing delete
CREATE TRIGGER fkd_Profile_user_seq_User_user_seq
BEFORE DELETE ON User
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'delete on table "User" violates foreign key constraint "fkd_Profile_user_seq_User_user_seq"')
  WHERE (SELECT user_seq FROM Profile WHERE user_seq = OLD.user_seq) IS NOT NULL;
END;

-- Foreign Key Preventing insert
CREATE TRIGGER fki_Diary_user_seq_User_user_seq
BEFORE INSERT ON [Diary]
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'insert on table "Diary" violates foreign key constraint "fki_Diary_user_seq_User_user_seq"')
  WHERE NEW.user_seq IS NOT NULL AND (SELECT user_seq FROM User WHERE user_seq = NEW.user_seq) IS NULL;
END;

-- Foreign key preventing update
CREATE TRIGGER fku_Diary_user_seq_User_user_seq
BEFORE UPDATE ON [Diary]
FOR EACH ROW BEGIN
    SELECT RAISE(ROLLBACK, 'update on table "Diary" violates foreign key constraint "fku_Diary_user_seq_User_user_seq"')
      WHERE NEW.user_seq IS NOT NULL AND (SELECT user_seq FROM User WHERE user_seq = NEW.user_seq) IS NULL;
END;

-- Foreign key preventing delete
CREATE TRIGGER fkd_Diary_user_seq_User_user_seq
BEFORE DELETE ON User
FOR EACH ROW BEGIN
  SELECT RAISE(ROLLBACK, 'delete on table "User" violates foreign key constraint "fkd_Diary_user_seq_User_user_seq"')
  WHERE (SELECT user_seq FROM Diary WHERE user_seq = OLD.user_seq) IS NOT NULL;
END;

COMMIT;
