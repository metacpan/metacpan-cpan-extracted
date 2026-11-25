CREATE TABLE IF NOT EXISTS attean_version (
	attean_version VARCHAR(16),
	store_version VARCHAR(16),
	model_version INTEGER NOT NULL,
	notes LONGTEXT,
	created DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS term (
	term_id INTEGER PRIMARY KEY,
	type CHAR(7),
	datatype_id BIGINT REFERENCES term(term_id),
	value LONGTEXT NOT NULL,
	language TEXT
);

CREATE UNIQUE INDEX term_idx ON term (type, datatype_id, language, value);

CREATE TABLE IF NOT EXISTS quad (
	subject BIGINT NOT NULL REFERENCES term,
	predicate BIGINT NOT NULL REFERENCES term,
	object BIGINT NOT NULL REFERENCES term,
	graph BIGINT NOT NULL REFERENCES term,
	PRIMARY KEY (subject, predicate, object, graph)
);

CREATE TABLE IF NOT EXISTS triple_term (
	term_id INTEGER PRIMARY KEY REFERENCES term,
	subject BIGINT NOT NULL REFERENCES term,
	predicate BIGINT NOT NULL REFERENCES term,
	object BIGINT NOT NULL REFERENCES term
);

CREATE INDEX quad_pogs_idx ON quad (predicate,object,graph,subject);
CREATE INDEX quad_gpso_idx ON quad (graph,predicate,subject,object);
CREATE INDEX quad_g ON quad (graph);
CREATE INDEX triple_term_spo ON triple_term (subject, predicate, object);
CREATE INDEX triple_term_pos ON triple_term (predicate, object, subject);
CREATE INDEX triple_term_osp ON triple_term (object, subject, predicate);

INSERT INTO attean_version (attean_version, store_version, model_version, notes) VALUES ("", "0.004", 1, "populated by schema creation");
