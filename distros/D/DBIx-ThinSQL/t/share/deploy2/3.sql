CREATE TABLE film_actors (
    actor_id integer references actors(id),
    film_id integer references films(id),
    primary key (actor_id,film_id)
);
