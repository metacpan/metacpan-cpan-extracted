CREATE TABLE IF NOT EXISTS attean_version (
	attean_version VARCHAR(16),
	store_version VARCHAR(16),
	model_version INTEGER NOT NULL,
	notes LONGTEXT,
	created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

CREATE TABLE IF NOT EXISTS term (
	term_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`type` ENUM('iri', 'literal', 'blank', 'triple'),
	datatype_id BIGINT REFERENCES term(term_id),
	value LONGTEXT NOT NULL,
	language TEXT,
	INDEX (`type`, datatype_id, value(64), language(64))
) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

CREATE TABLE IF NOT EXISTS quad (
	subject BIGINT UNSIGNED NOT NULL REFERENCES term,
	predicate BIGINT UNSIGNED NOT NULL REFERENCES term,
	object BIGINT UNSIGNED NOT NULL REFERENCES term,
	graph BIGINT UNSIGNED NOT NULL REFERENCES term,
	PRIMARY KEY (subject, predicate, object, graph),
	KEY (predicate,object,graph,subject),
	KEY (graph,predicate,subject,object),
	INDEX (graph)
);

CREATE TABLE IF NOT EXISTS triple_term (
	term_id BIGINT UNSIGNED PRIMARY KEY REFERENCES term,
	subject BIGINT UNSIGNED NOT NULL REFERENCES term,
	predicate BIGINT UNSIGNED NOT NULL REFERENCES term,
	object BIGINT UNSIGNED NOT NULL REFERENCES term,
	KEY (subject, predicate, object),
	KEY (predicate, object, subject),
	KEY (object, subject, predicate)
);

INSERT INTO attean_version (attean_version, store_version, model_version, notes) VALUES ("", "0.004", 1, "populated by schema creation");
