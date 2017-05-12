CREATE TABLE sportsteam (
	id INTEGER
	,sports VARCHAR(40) NOT NULL
	,PRIMARY KEY (id)
    , UNIQUE (sports)
	);

CREATE TABLE salaryclass (
	id INTEGER
	,minimum INTEGER NOT NULL
	,maximum INTEGER
	,PRIMARY KEY (id)
	);

CREATE TABLE employee (
	id INTEGER
	,lastname VARCHAR(20) NOT NULL
	,boss INTEGER
	,sportsteam INTEGER
	,salary INTEGER
	,PRIMARY KEY (id)
	,FOREIGN KEY (boss) REFERENCES employee(id)
	,FOREIGN KEY (sportsteam) REFERENCES sportsteam(id)
	,FOREIGN KEY (salary) REFERENCES salaryclass(id)
	);

INSERT INTO salaryclass (id, minimum, maximum) VALUES (1, 120000, NULL);
INSERT INTO salaryclass (id, minimum, maximum) VALUES (2, 100000, 120000);
INSERT INTO salaryclass (id, minimum, maximum) VALUES (3, 80000, 100000);
INSERT INTO salaryclass (id, minimum, maximum) VALUES (4, 60000, 80000);
INSERT INTO salaryclass (id, minimum, maximum) VALUES (5, 40000, 60000);

INSERT INTO sportsteam (id, sports) VALUES (1, 'Basketball');
INSERT INTO sportsteam (id, sports) VALUES (2, 'Soccer');
INSERT INTO sportsteam (id, sports) VALUES (3, 'Tennis');
INSERT INTO sportsteam (id, sports) VALUES (4, 'Mud Wrestling');
INSERT INTO sportsteam (id, sports) VALUES (5, 'Chess');

INSERT INTO employee (id, lastname, boss, sportsteam, salary) VALUES (1, 'Miller', NULL, 1, 5);
INSERT INTO employee (id, lastname, boss, sportsteam, salary) VALUES (2, 'Smith', 1, 1, 4);
INSERT INTO employee (id, lastname, boss, sportsteam, salary) VALUES (4, 'Kowalski', NULL, 4, 4);
INSERT INTO employee (id, lastname, boss, sportsteam, salary) VALUES (3, 'Doe', 4, 2, 3);
INSERT INTO employee (id, lastname, boss, sportsteam, salary) VALUES (5, 'Schneider', 4, 5, 3);
INSERT INTO employee (id, lastname, boss, sportsteam, salary) VALUES (6, 'Beck', 2, 2, 2);
INSERT INTO employee (id, lastname, boss, sportsteam, salary) VALUES (7, 'Swensson', 4, 5, 3);
INSERT INTO employee (id, lastname, boss, sportsteam, salary) VALUES (8, 'Clouseau', NULL, 4, 5);
INSERT INTO employee (id, lastname, boss, sportsteam, salary) VALUES (9, 'Hilton', 8, 3, 3);
INSERT INTO employee (id, lastname, boss, sportsteam, salary) VALUES (10, 'Kim', 9, 3, 2);
