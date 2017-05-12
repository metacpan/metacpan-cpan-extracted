-- this file contains definitions used for storing arbitrary raw data
-- such as images (only thing so far).
-- An image contains its ID, a path to the image data (e.g. a URL or file path),
-- the name of the table in which more information can be found (probably violates
-- lots of database rules) and the primary id.
CREATE TABLE image (
    image_id         integer(11) not null AUTO_INCREMENT PRIMARY KEY;
    image_path       varchar(256) not null,
    table_name       varchar(64),
    table_id         integer(11)
);

