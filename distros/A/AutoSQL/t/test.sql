CREATE TABLE email (
    email_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    person_id INT UNSIGNED,
    address VARCHAR(255),
    PRIMARY KEY (email_id),
    KEY (person_id)
);

--
CREATE TABLE person (
    person_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    PRIMARY KEY (person_id)
);

