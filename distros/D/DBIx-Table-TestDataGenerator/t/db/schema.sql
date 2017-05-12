CREATE TABLE test_TDG_ref (
  i  INTEGER PRIMARY KEY
);  

INSERT INTO test_TDG_ref (i) VALUES (11);
INSERT INTO test_TDG_ref (i) VALUES (12);
INSERT INTO test_TDG_ref (i) VALUES (13);
INSERT INTO test_TDG_ref (i) VALUES (14);

CREATE TABLE test_TDG (
  id  INTEGER PRIMARY KEY,
  refid INTEGER,
  ud TEXT,
  dt TEXT,
  j INTEGER NOT NULL,
  UNIQUE (ud,dt),
  CONSTRAINT selfref FOREIGN KEY (refid) REFERENCES test_TDG 	  (id),
  CONSTRAINT fkey    FOREIGN KEY (j)     REFERENCES test_TDG_ref (i)
);

INSERT INTO test_TDG (id, refid, ud, dt, j) VALUES (1,1,'A','12.04.2011', 11);
INSERT INTO test_TDG (id, refid, ud, dt, j) VALUES (2,1,'B1','12.04.2011', 12);
INSERT INTO test_TDG (id, refid, ud, dt, j) VALUES (3,1,'BB','13.04.2011', 11);
INSERT INTO test_TDG (id, refid, ud, dt, j) VALUES (4,4,'CCC','15.04.2011', 13);
INSERT INTO test_TDG (id, refid, ud, dt, j) VALUES (5,4,'X','11.04.2011', 13);
