DROP TABLE grouped_user_images;
DROP TABLE grouped_users;
DROP TABLE groups;
DROP TABLE users;

CREATE TABLE users (
    user_id INT8 PRIMARY KEY,
    username VARCHAR(40),
    signup TIMESTAMP,
    active BOOL
);

CREATE TABLE groups (
    group_id INT8 PRIMARY KEY,
    groupname VARCHAR,
    description VARCHAR(1000)
);

CREATE TABLE grouped_users (
    group_id INT8 NOT NULL REFERENCES groups,
    user_id INT8 NOT NULL REFERENCES users,
    PRIMARY KEY (group_id, user_id)
);

CREATE TABLE grouped_user_images (
    group_id INT8 NOT NULL,
    user_id INT8 NOT NULL,
    image TEXT, 
    PRIMARY KEY(group_id, user_id),
    CONSTRAINT img_constraint FOREIGN KEY (group_id,user_id) 
    REFERENCES grouped_users
);
