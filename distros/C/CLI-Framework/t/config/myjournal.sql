/* myjournal.sql: Example database for demo My::Journal CLIF application */

BEGIN TRANSACTION;
DROP TABLE IF EXISTS journal;

CREATE TABLE journal_entry (
    id          INTEGER     PRIMARY KEY AUTOINCREMENT,
    entry_text  TEXT        NOT NULL
);
CREATE TABLE entry2tag (
    entry_id    INTEGER     NOT NULL,
    tag_id      INTEGER     NOT NULL,
    PRIMARY KEY (entry_id, tag_id),
    FOREIGN KEY (entry_id) REFERENCES journal_entry(id),
    FOREIGN KEY (tag_id) REFERENCES tag(id)
);
CREATE TABLE tag (
    id          INTEGER     PRIMARY KEY AUTOINCREMENT,
    tag_text    TEXT        NOT NULL UNIQUE
);

COMMIT;
