CREATE TABLE contactgroup (
    contactgroup_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(255),
    PRIMARY KEY (contactgroup_id)
)
;
CREATE TABLE email (
    email_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    person_id INT UNSIGNED NOT NULL,
    purpose VARCHAR(255),
    address VARCHAR(255) NOT NULL,
    PRIMARY KEY (email_id),
    KEY (person_id)
)
;
CREATE TABLE location (
    location_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    country VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    PRIMARY KEY (location_id)
)
;
CREATE TABLE nric (
    nric_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    person_id INT UNSIGNED NOT NULL,
    no VARCHAR(255),
    issued_date DATETIME,
    PRIMARY KEY (nric_id),
    KEY (person_id)
)
;
CREATE TABLE person (
    person_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    last_name VARCHAR(255),
    first_name VARCHAR(255),
    PRIMARY KEY (person_id)
)
;
CREATE TABLE person_alias (
    person_alias_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    person_id INT UNSIGNED NOT NULL,
    alias VARCHAR(255),
    PRIMARY KEY (person_alias_id),
    KEY (person_id)
)
;
CREATE TABLE person_contactgroup (
    person_contactgroup_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    person_id_id INT UNSIGNED NOT NULL,
    contactgroup_id_id INT UNSIGNED NOT NULL,
    junkSeeSQLGenerator130 INT,
    PRIMARY KEY (person_contactgroup_id),
    KEY (person_id_id),
    KEY (contactgroup_id_id)
)
