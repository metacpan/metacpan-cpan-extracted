CREATE TABLE film (
	id	SERIAL PRIMARY KEY,
	name	TEXT
);

CREATE TABLE actor (
	id	SERIAL PRIMARY KEY,
	name	TEXT
);

CREATE TABLE role (
	id		SERIAL PRIMARY KEY,
	film_id		INTEGER REFERENCES film (id),
	actor_id	INTEGER REFERENCES actor (id),
	part		TEXT
);

CREATE VIEW film_roles AS
SELECT 
	a.name AS player,
	f.name AS movie,
	r.part AS part,
	a.name || ' played ' || r.part || ' in ' || f.name AS DESCRIPTION
FROM	film AS f
JOIN	role AS r	ON r.film_id = f.id
JOIN	actor AS a	ON r.actor_id = a.id;

CREATE VIEW actor_roles AS
SELECT
	a.name AS actor,
	r.part AS role
FROM	actor AS a
JOIN	role AS r	ON r.actor_id = a.id;

INSERT INTO film (name) VALUES ('Dr. No');
INSERT INTO film (name) VALUES ('Casino Royale');
INSERT INTO film (name) VALUES ('Die another day');
INSERT INTO film (name) VALUES ('The world is not enough');

INSERT INTO actor (name) VALUES ('Sean Connery');
INSERT INTO actor (name) VALUES ('Peter Sellers');
INSERT INTO actor (name) VALUES ('Pierce Brosnan');

INSERT INTO role (
	film_id,
	actor_id,
	part
)
VALUES (
	(SELECT id FROM film WHERE name = 'Dr. No' LIMIT 1),
	(SELECT id FROM actor WHERE name = 'Sean Connery' LIMIT 1),
	'James Bond'
);

INSERT INTO role (
	film_id,
	actor_id,
	part
)
VALUES (
	(SELECT id FROM film WHERE name = 'Casino Royale' LIMIT 1),
	(SELECT id FROM actor WHERE name = 'Peter Sellers' LIMIT 1),
	'James Bond'
);

INSERT INTO role (
	film_id,
	actor_id,
	part
)
VALUES (
	(SELECT id FROM film WHERE name = 'Casino Royale' LIMIT 1),
	(SELECT id FROM actor WHERE name = 'Peter Sellers' LIMIT 1),
	'Evelyn Tremble'
);

INSERT INTO role (
	film_id,
	actor_id,
	part
)
VALUES (
	(SELECT id FROM film WHERE name = 'Die another day' LIMIT 1),
	(SELECT id FROM actor WHERE name = 'Pierce Brosnan' LIMIT 1),
	'James Bond'
);

INSERT INTO role (
	film_id,
	actor_id,
	part
)
VALUES (
	(SELECT id FROM film WHERE name = 'The world is not enough' LIMIT 1),
	(SELECT id FROM actor WHERE name = 'Pierce Brosnan' LIMIT 1),
	'James Bond'
);
