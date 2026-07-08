CREATE SEQUENCE users_id_seq;
CREATE SEQUENCE account_id_seq;

CREATE TABLE users(
    user_id     INTEGER     NOT NULL PRIMARY KEY DEFAULT nextval('users_id_seq'),
    name        VARCHAR(32) NOT NULL
);

CREATE TABLE account(
    account_id  INTEGER     NOT NULL PRIMARY KEY DEFAULT nextval('account_id_seq'),
    users       VARCHAR(32) NOT NULL,
    user_id     INTEGER     NOT NULL,

    FOREIGN KEY(user_id) REFERENCES users(user_id)
);
