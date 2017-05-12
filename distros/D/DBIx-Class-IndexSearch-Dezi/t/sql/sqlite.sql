create table person (
    person_id       integer primary key not null,
    name            varchar(128) not null,
    age             integer not null,
    email           varchar(128),
    created         timestamp not null    
);

