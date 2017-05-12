CREATE TABLE IF NOT EXISTS _deploy (
    app VARCHAR(40) NOT NULL PRIMARY KEY,
    seq INTEGER NOT NULL DEFAULT 0,
    ctime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    type VARCHAR(20),
    data VARCHAR
);

CREATE TRIGGER IF NOT EXISTS au__deploy AFTER UPDATE ON _deploy
FOR EACH ROW WHEN OLD.seq = NEW.seq
BEGIN
    UPDATE
        _deploy
    SET
        seq = seq + 1
    WHERE
        app = OLD.app
    ;
END;
