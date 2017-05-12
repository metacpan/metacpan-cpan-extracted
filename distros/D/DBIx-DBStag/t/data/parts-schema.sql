CREATE TABLE component (
        component_id SERIAL NOT NULL PRIMARY KEY,
        name    VARCHAR(32) NOT NULL,
        descr   TEXT,

        UNIQUE (name)
);
CREATE TABLE part_of (
        part_of_id SERIAL NOT NULL PRIMARY KEY,
        subject_id INTEGER NOT NULL REFERENCES component(component_id),
        object_id INTEGER NOT NULL REFERENCES component(component_id),

        UNIQUE (subject_id,object_id)
);
