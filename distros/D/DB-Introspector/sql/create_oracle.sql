DROP TABLE grouped_user_images;
DROP TABLE grouped_users;
DROP TABLE groups;
DROP TABLE users;

CREATE TABLE users (
    user_id NUMBER PRIMARY KEY,
    username VARCHAR2(40),
    signup TIMESTAMP,
    active CHAR
);

CREATE TABLE groups (
    group_id NUMBER PRIMARY KEY,
    groupname VARCHAR2(50),
    description VARCHAR2(1000)
);

CREATE TABLE grouped_users (
    group_id NUMBER NOT NULL REFERENCES groups,
    user_id NUMBER NOT NULL REFERENCES users,
    PRIMARY KEY (group_id, user_id)
);

CREATE TABLE grouped_user_images (
    group_id NUMBER NOT NULL,
    user_id NUMBER NOT NULL,
    image CLOB, 
    PRIMARY KEY(group_id, user_id),
    CONSTRAINT img_constraint FOREIGN KEY (group_id,user_id) 
    REFERENCES grouped_users
);
