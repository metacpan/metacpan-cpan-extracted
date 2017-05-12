create table directors (
    id              integer primary key not null,
    name            varchar(128)
);


create table locations (
    id              integer primary key not null,
    name            varchar(128)
);


create table films (
    id              integer primary key not null,
    title           varchar(128),
    length          integer,
    comment         text,
    director_id     integer references directors(id),
    location_id     integer references locations(id)
);


create table actors (
    id              integer primary key not null,
    name            varchar(128)
);


create table roles (
    film_id  integer references film(id),
    actor_id integer references actor(id),
    charater varchar(128),
    primary key(film_id,actor_id)
);