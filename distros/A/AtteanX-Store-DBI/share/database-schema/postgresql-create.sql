CREATE TABLE IF NOT EXISTS attean_version (
	attean_version VARCHAR(16),
	store_version VARCHAR(16),
	model_version INTEGER NOT NULL,
	notes TEXT,
	created TIMESTAMP DEFAULT NOW(),
	updated TIMESTAMP DEFAULT NOW()
);

CREATE TYPE TERM_TYPE AS ENUM ('iri', 'literal', 'blank', 'triple');
CREATE TABLE IF NOT EXISTS term (
	term_id SERIAL PRIMARY KEY,
	type TERM_TYPE,
	datatype_id BIGINT REFERENCES term(term_id),
	value TEXT NOT NULL,
	language TEXT,
	UNIQUE (datatype_id, value, language)
);

CREATE TABLE IF NOT EXISTS quad (
	subject BIGINT NOT NULL REFERENCES term,
	predicate BIGINT NOT NULL REFERENCES term,
	object BIGINT NOT NULL REFERENCES term,
	graph BIGINT NOT NULL REFERENCES term,
	PRIMARY KEY (subject, predicate, object, graph)
);

CREATE TABLE IF NOT EXISTS triple_term (
	term_id BIGINT PRIMARY KEY REFERENCES term,
	subject BIGINT NOT NULL REFERENCES term,
	predicate BIGINT NOT NULL REFERENCES term,
	object BIGINT NOT NULL REFERENCES term
);

CREATE INDEX IF NOT EXISTS quad_graph_idx ON quad (graph);
CREATE INDEX IF NOT EXISTS quad_pogs_idx ON quad (predicate,object,graph,subject);
CREATE INDEX IF NOT EXISTS quad_gpso_idx ON quad (graph,predicate,subject,object);
CREATE INDEX IF NOT EXISTS triple_term_spo ON triple_term (subject, predicate, object);
CREATE INDEX IF NOT EXISTS triple_term_pos ON triple_term (predicate, object, subject);
CREATE INDEX IF NOT EXISTS triple_term_osp ON triple_term (object, subject, predicate);

INSERT INTO attean_version (attean_version, store_version, model_version, notes) VALUES ('', '0.004', 1, 'populated by schema creation');
