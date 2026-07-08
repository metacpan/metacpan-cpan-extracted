CREATE SEQUENCE users_id_seq;
CREATE SEQUENCE message_id_seq;
CREATE SEQUENCE team_id_seq;
CREATE SEQUENCE node_id_seq;

CREATE TABLE users(
    user_id     INTEGER     NOT NULL PRIMARY KEY DEFAULT nextval('users_id_seq'),
    name        VARCHAR(32) NOT NULL
);

CREATE TABLE message(
    message_id   INTEGER     NOT NULL PRIMARY KEY DEFAULT nextval('message_id_seq'),
    body         VARCHAR(64) NOT NULL,
    sender_id    INTEGER     NOT NULL,
    recipient_id INTEGER     NOT NULL,

    FOREIGN KEY(sender_id)    REFERENCES users(user_id),
    FOREIGN KEY(recipient_id) REFERENCES users(user_id)
);

CREATE TABLE team(
    team_id     INTEGER     NOT NULL PRIMARY KEY DEFAULT nextval('team_id_seq'),
    name        VARCHAR(32) NOT NULL,

    owner_id    INTEGER     DEFAULT NULL,

    FOREIGN KEY(owner_id) REFERENCES users(user_id)
);

CREATE TABLE node(
    node_id     INTEGER     NOT NULL PRIMARY KEY DEFAULT nextval('node_id_seq'),
    name        VARCHAR(32) NOT NULL,

    parent_id   INTEGER     DEFAULT NULL,

    FOREIGN KEY(parent_id) REFERENCES node(node_id)
);
