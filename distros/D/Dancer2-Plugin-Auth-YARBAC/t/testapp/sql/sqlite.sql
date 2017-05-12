DROP TABLE IF EXISTS `users`;
CREATE TABLE users (
    id       INTEGER     PRIMARY KEY,
    username VARCHAR(32) NOT NULL UNIQUE,
    password TEXT NOT NULL
);

DROP TABLE IF EXISTS `yarbac_roles`;
CREATE TABLE yarbac_roles (
    id   INTEGER     PRIMARY KEY,
    role_name VARCHAR(32) NOT NULL UNIQUE,
    description TEXT NULL
);

DROP TABLE IF EXISTS `yarbac_groups`;
CREATE TABLE yarbac_groups (
    id   INTEGER     PRIMARY KEY,
    group_name VARCHAR(32) NOT NULL UNIQUE,
    description TEXT NULL
);

DROP TABLE IF EXISTS `yarbac_permissions`;
CREATE TABLE yarbac_permissions (
    id   INTEGER     PRIMARY KEY,
    permission_name VARCHAR(32) NOT NULL UNIQUE,
    description TEXT NULL
);

DROP TABLE IF EXISTS `yarbac_user_roles`;
CREATE TABLE yarbac_user_roles (
    user_id  INTEGER  NOT NULL,
    role_id  INTEGER  NOT NULL
);
CREATE UNIQUE INDEX user_role on yarbac_user_roles (user_id, role_id);

DROP TABLE IF EXISTS `yarbac_role_groups`;
CREATE TABLE yarbac_role_groups (
    role_id  INTEGER  NOT NULL,
    group_id INTEGER  NOT NULL
);
CREATE UNIQUE INDEX group_role on yarbac_role_groups (role_id, group_id);

DROP TABLE IF EXISTS `yarbac_group_permissions`;
CREATE TABLE yarbac_group_permissions (
    group_id      INTEGER  NOT NULL,
    permission_id INTEGER  NOT NULL
);
CREATE UNIQUE INDEX group_permissions on yarbac_group_permissions (group_id, permission_id);

insert into users (username, password) values ('sarah', '{X-PBKDF2}HMACSHA2+512:AAAH0A:1InV1B6JUBcn0bBeIP7IVzMwDqsBHpda:aiqE49oieQ9Jbj2fitnCmJau3CZWpYiart+hk9qdglEIlLybOuEuwNqzbJOyPUrToG7eS3Unq9/KagucvE/SsQ==');
insert into users (username, password) values ('craig', '{X-PBKDF2}HMACSHA2+512:AAAH0A:HoxvN7Er7/kWWRDBjah5OkXpW7Pp06mC:kj5k7d31J7mLUV+Egn++Zxm6A+xKjAxP68+IeUsxZXbJ2tenIS026rW/3gb6mu0Q+hlfQWlpdJi14NdvvDef7g==');
insert into yarbac_roles (role_name, description) values ('admin', 'The rulers of this little universe.');
insert into yarbac_roles (role_name, description) values ('manager', 'The people who manage this little universe.');
insert into yarbac_roles (role_name, description) values ('dummy', 'The people who manage this little universe.');
insert into yarbac_user_roles (user_id, role_id) values ('1', '1');
insert into yarbac_user_roles (user_id, role_id) values ('1', '3');
insert into yarbac_user_roles (user_id, role_id) values ('2', '2');
insert into yarbac_groups (group_name, description) values ('cs', 'customer service.');
insert into yarbac_groups (group_name, description) values ('ops', 'system administrators responsible for day to day operations.');
insert into yarbac_groups (group_name, description) values ('devops', 'devops responsible for development & operations.');
insert into yarbac_groups (group_name, description) values ('finance', 'financial information');
insert into yarbac_role_groups (role_id, group_id) values ('1', '1');
insert into yarbac_role_groups (role_id, group_id) values ('1', '2');
insert into yarbac_role_groups (role_id, group_id) values ('1', '3');
insert into yarbac_role_groups (role_id, group_id) values ('2', '1');
insert into yarbac_role_groups (role_id, group_id) values ('2', '2');
insert into yarbac_role_groups (role_id, group_id) values ('2', '3');
insert into yarbac_role_groups (role_id, group_id) values ('2', '4');
insert into yarbac_permissions (permission_name, description) values ('read', 'Well going by they name, lets say this grants read access');
insert into yarbac_permissions (permission_name, description) values ('write', 'Well going by they name, lets say this grants write access');
insert into yarbac_group_permissions (group_id, permission_id) values (1, 1);
insert into yarbac_group_permissions (group_id, permission_id) values (2, 2);
insert into yarbac_group_permissions (group_id, permission_id) values (3, 1);
