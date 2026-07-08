CREATE TABLE users(
    user_id     INTEGER     NOT NULL PRIMARY KEY AUTOINCREMENT,
    name        VARCHAR(32) NOT NULL
);

CREATE TABLE account(
    account_id  INTEGER     NOT NULL PRIMARY KEY AUTOINCREMENT,
    users       VARCHAR(32) NOT NULL,
    user_id     INTEGER     NOT NULL,

    FOREIGN KEY(user_id) REFERENCES users(user_id)
);
