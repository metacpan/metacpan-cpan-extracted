CREATE TABLE users(
    user_id     SERIAL      NOT NULL PRIMARY KEY,
    name        VARCHAR(32) NOT NULL
);

CREATE TABLE account(
    account_id  SERIAL      NOT NULL PRIMARY KEY,
    users       VARCHAR(32) NOT NULL,
    user_id     INTEGER     NOT NULL,

    FOREIGN KEY(user_id) REFERENCES users(user_id)
);
