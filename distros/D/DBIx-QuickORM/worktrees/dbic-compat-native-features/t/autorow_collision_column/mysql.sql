CREATE TABLE users(
    user_id     INTEGER     NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(32) NOT NULL
);

CREATE TABLE account(
    account_id  INTEGER     NOT NULL PRIMARY KEY AUTO_INCREMENT,
    users       VARCHAR(32) NOT NULL,
    user_id     INTEGER     NOT NULL,

    FOREIGN KEY(user_id) REFERENCES users(user_id)
);
