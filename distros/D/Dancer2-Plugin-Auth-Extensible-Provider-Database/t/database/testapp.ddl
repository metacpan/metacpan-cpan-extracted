CREATE TABLE users (
    id       INTEGER     PRIMARY KEY,
    username VARCHAR(32) NOT NULL,
    password VARCHAR(40) NOT NULL,
    name     VARCHAR(128),
    pw_reset_code VARCHAR(128)
);
CREATE UNIQUE INDEX idx_users ON users (username);
CREATE TABLE roles (
    id    INTEGER     PRIMARY KEY,
    role  VARCHAR(32) NOT NULL
);
CREATE TABLE user_roles (
    user_id  INTEGER  NOT NULL,
    role_id  INTEGER  NOT NULL
);
CREATE UNIQUE INDEX idx_user_roles ON user_roles (user_id, role_id);
