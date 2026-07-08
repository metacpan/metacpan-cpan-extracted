CREATE TABLE things (
    id   SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    tag  TEXT
);

CREATE FUNCTION things_set_tag() RETURNS trigger AS $$
BEGIN
    UPDATE things SET tag = 'DB:' || NEW.name WHERE id = NEW.id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER things_ai AFTER INSERT ON things
    FOR EACH ROW EXECUTE PROCEDURE things_set_tag();

CREATE TABLE plain (
    id   SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);
