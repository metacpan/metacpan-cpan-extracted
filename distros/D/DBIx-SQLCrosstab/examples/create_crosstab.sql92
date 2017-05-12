BEGIN ;
CREATE TABLE xtab_categories (
    cat_id INTEGER UNSIGNED NOT NULL,
    category CHAR(30) NOT NULL,
    PRIMARY KEY (cat_id)
);
INSERT INTO xtab_categories VALUES(1,'employee');
INSERT INTO xtab_categories VALUES(2,'contractor');
INSERT INTO xtab_categories VALUES(3,'consultant');
create index category on xtab_categories (category);
COMMIT;

BEGIN ;
CREATE TABLE xtab_countries (
    country_id INTEGER UNSIGNED NOT NULL,
    country CHAR(30) NOT NULL,
    PRIMARY KEY (country_id)
);
INSERT INTO xtab_countries VALUES(1,'UK');
INSERT INTO xtab_countries VALUES(2,'Germany');
INSERT INTO xtab_countries VALUES(3,'Italy');
create index country on xtab_countries (country);
COMMIT;

BEGIN ;
CREATE TABLE xtab_departments (
    dept_id INTEGER UNSIGNED NOT NULL,
    department CHAR(30) NOT NULL,
    PRIMARY KEY (dept_id)
);
INSERT INTO xtab_departments VALUES(1,'pers');
INSERT INTO xtab_departments VALUES(2,'xtab_sales');
INSERT INTO xtab_departments VALUES(3,'dev');
INSERT INTO xtab_departments VALUES(4,'research');
create index department on xtab_departments (department);
COMMIT;

BEGIN ;
CREATE TABLE xtab_locations (
    loc_id INTEGER UNSIGNED NOT NULL,
    loc CHAR(30) NOT NULL,
    country_id INTEGER UNSIGNED NOT NULL,
    PRIMARY KEY (loc_id)
);
INSERT INTO xtab_locations VALUES(1,'Rome',3);
INSERT INTO xtab_locations VALUES(2,'London',1);
INSERT INTO xtab_locations VALUES(3,'Munich',2);
INSERT INTO xtab_locations VALUES(4,'Berlin',2);
INSERT INTO xtab_locations VALUES(5,'Bonn',2);
CREATE INDEX country_id on xtab_locations (country_id);
COMMIT;

BEGIN ;
CREATE TABLE xtab_person (
    person_id INTEGER UNSIGNED NOT NULL,
    name CHAR(20) NOT NULL,
    salary INTEGER,
    gender CHAR(1),
    dept_id INTEGER UNSIGNED NOT NULL,
    cat_id INTEGER UNSIGNED NOT NULL,
    loc_id INTEGER UNSIGNED NOT NULL,
    PRIMARY KEY (person_id)
);
INSERT INTO xtab_person VALUES(1,'John',5000,'m',1,2,2);
INSERT INTO xtab_person VALUES(2,'Mario',6000,'m',1,1,1);
INSERT INTO xtab_person VALUES(3,'Frank',5000,'m',2,1,5);
INSERT INTO xtab_person VALUES(4,'Otto',6000,'m',3,1,4);
INSERT INTO xtab_person VALUES(5,'Susan',5500,'f',2,3,3);
INSERT INTO xtab_person VALUES(6,'Martin',5500,'m',2,2,2);
INSERT INTO xtab_person VALUES(7,'Mary',5500,'f',1,1,4);
INSERT INTO xtab_person VALUES(8,'Bill',5000,'m',1,1,3);
INSERT INTO xtab_person VALUES(9,'June',6000,'f',3,3,1);
CREATE INDEX cat_id on xtab_person (cat_id);
CREATE INDEX dept_id on xtab_person (dept_id);
CREATE INDEX loc_id on xtab_person (loc_id);
COMMIT;

BEGIN ;
CREATE TABLE xtab_class (
    class_id INTEGER UNSIGNED NOT NULL,
    class_name CHAR(20) NOT NULL,
    PRIMARY KEY (class_id)
);
INSERT INTO xtab_class VALUES(1,'software');
INSERT INTO xtab_class VALUES(2,'hardware');
INSERT INTO xtab_class VALUES(3,'services');
create index class_ndx on xtab_class (class_name);
COMMIT;

BEGIN ;
CREATE TABLE xtab_customers (
    customer_id INTEGER UNSIGNED NOT NULL,
    customer CHAR(40) NOT NULL,
    PRIMARY KEY (customer_id)
);
INSERT INTO xtab_customers VALUES(1,'DataSmart');
INSERT INTO xtab_customers VALUES(2,'ViewData');
INSERT INTO xtab_customers VALUES(3,'NewHardware');
INSERT INTO xtab_customers VALUES(4,'SmartEdu');
COMMIT;

BEGIN ;
CREATE TABLE xtab_sales (
    person_id INTEGER UNSIGNED NOT NULL,
    class_id INTEGER UNSIGNED NOT NULL,
    sale_date DATE NOT NULL,
    customer_id INTEGER UNSIGNED NOT NULL,
    sale_amount INTEGER NOT NULL,
    PRIMARY KEY (person_id, class_id, sale_date, customer_id)
);
INSERT INTO xtab_sales VALUES(3,1,'2003-10-01',1,23000);
INSERT INTO xtab_sales VALUES(3,2,'2003-10-12',3,45000);
INSERT INTO xtab_sales VALUES(6,2,'2003-10-12',4,50000);
INSERT INTO xtab_sales VALUES(5,3,'2003-10-13',4,18000);
INSERT INTO xtab_sales VALUES(5,1,'2003-11-02',2,25000);
INSERT INTO xtab_sales VALUES(3,3,'2003-11-04',1,60000);
create index person_id on xtab_sales (person_id);
COMMIT;

