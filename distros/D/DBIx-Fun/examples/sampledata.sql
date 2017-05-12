drop table scott.DEPT;


CREATE TABLE scott.DEPT
(
 DEPT_ID         NUMBER NOT NULL,
 DEPT_DESC       VARCHAR2(80) NULL,
 PARENT_DEPT_ID  NUMBER NULL
)
/

insert into dept values ( 1, 'IT', NULL );
insert into dept values ( 2, 'Software Engineering', 1 );
insert into dept values ( 10, 'Application Development', 2 );
insert into dept values ( 20, 'Web Development', 2 );
insert into dept values ( 30, 'EDI', 2 );
insert into dept values ( 40, 'Software Infrastructure Development', 2 );


commit;


drop table scott.LOCATION;


CREATE TABLE scott.LOCATION
(
 LOCATION_ID    NUMBER NOT NULL,
 LOCATION_DESC  VARCHAR2(80) NULL
)
/

insert into location values ( 1, 'Grand Rapids, MI' );
insert into location values ( 2, 'Holland, MI' );
insert into location values ( 3, 'Bermuda' );

commit;


drop table scott.POSITION;


CREATE TABLE scott.POSITION
(
 POSITION_ID    NUMBER NOT NULL,
 POSITION_DESC  VARCHAR2(80) NULL
)
/

insert into position values ( 1, 'Software Developer - Associate' );
insert into position values ( 2, 'Software Developer' );
insert into position values ( 3, 'Software Developer - Senior' );
insert into position values ( 4, 'Software Developer - Lead' );
insert into position values ( 5, 'Software Developer - Specialist' );
insert into position values ( 6, 'Supreme Commander' );

commit;


drop table scott.EMPLOYEE;


CREATE TABLE scott.EMPLOYEE
(
 EMP_ID      NUMBER NOT NULL,
 DEPT_ID      NUMBER NULL,
 POSITION_ID  NUMBER NULL,
 LOCATION_ID  NUMBER NULL,
 START_DATE   DATE NULL,
 END_DATE     DATE NULL
)
/

insert into employee values ( 1, 10, 1, 1, to_date( '06/07/2003', 'mm/dd/YYYY' ), NULL );
insert into employee values ( 2, 10, 1, 1, to_date( '05/05/2001', 'mm/dd/YYYY' ), to_date( '09/23/2006', 'mm/dd/YYYY' ) );
insert into employee values ( 3, 10, 2, 1, to_date( '08/12/2003', 'mm/dd/YYYY' ), NULL );
insert into employee values ( 4, 10, 3, 1, to_date( '10/23/2004', 'mm/dd/YYYY' ), NULL );
insert into employee values ( 5, 20, 1, 2, to_date( '01/29/2005', 'mm/dd/YYYY' ), NULL );
insert into employee values ( 6, 20, 1, 2, to_date( '03/15/1995', 'mm/dd/YYYY' ), NULL );
insert into employee values ( 7, 20, 2, 2, to_date( '11/14/2005', 'mm/dd/YYYY' ), NULL );
insert into employee values ( 8, 20, 3, 2, to_date( '06/07/2003', 'mm/dd/YYYY' ), NULL );
insert into employee values ( 9, 40, 4, 3, to_date( '12/13/2004', 'mm/dd/YYYY' ), NULL );
insert into employee values ( 10, 40, 6, 3, to_date( '08/10/2003', 'mm/dd/YYYY' ), NULL );

commit;


CREATE OR REPLACE FUNCTION scott.GET_DEPT( emp_id IN number )
RETURN VARCHAR2
AS
    dept_desc VARCHAR2(80);
BEGIN

select dept_desc into dept_desc
from dept d,
     employee e
where e.emp_id = GET_DEPT.emp_id
and   e.end_date is null
and   e.dept_id = d.dept_id;

RETURN (dept_desc);

END;
/

CREATE OR REPLACE PROCEDURE scott.hire_employee( 
    dept_id in number,
    position_id in number,
    location_id in number,
    emp_id out number,
    disp_date out varchar2 )
is
    new_emp_id number;
    hire_date date;
begin
    select max( emp_id )
    into new_emp_id
    from employee;

    new_emp_id := new_emp_id + 1;
    hire_date  := sysdate;

    insert into employee ( 
        emp_id,
        dept_id,
        position_id,
        location_id,
        start_date,
        end_date )
    values (
        new_emp_id,
        dept_id,
        position_id,
        location_id,
        hire_date,
        NULL );

    commit;

    hire_employee.emp_id := new_emp_id;  
    hire_employee.disp_date := to_char( hire_date, 'mm/dd/YYYY' );
end;
/

CREATE OR REPLACE PROCEDURE GET_ALL_EMPLOYEES(employees out sys_refcursor)
IS
BEGIN
    OPEN employees FOR
    select emp_id, dept_desc, position_desc, location_desc, start_date, end_date
    from employee e,
         dept d,
         position p,
         location l
    where e.dept_id = d.dept_id
    and e.position_id = p.position_id
    and e.location_id = l.location_id;
END;
/

CREATE OR REPLACE PROCEDURE SCOTT.UPDATE_EMPLOYEE (
  emp_id IN NUMBER,
  dept_id IN NUMBER default NULL,
  position_id IN NUMBER default NULL,
  location_id IN NUMBER default NULL,
  start_date IN DATE default NULL,
  end_date IN DATE default NULL
) AS
  PRAGMA autonomous_transaction;
BEGIN
  IF dept_id IS NOT NULL
  THEN
    UPDATE employee SET dept_id = UPDATE_EMPLOYEE.dept_id WHERE emp_id = UPDATE_EMPLOYEE.emp_id;
  END IF;
  
  IF position_id IS NOT NULL
  THEN
    UPDATE employee SET position_id = UPDATE_EMPLOYEE.position_id WHERE emp_id = UPDATE_EMPLOYEE.emp_id;
  END IF;

  IF location_id IS NOT NULL
  THEN
    UPDATE employee SET location_id = UPDATE_EMPLOYEE.location_id WHERE emp_id = UPDATE_EMPLOYEE.emp_id;
  END IF;
  
  IF start_date IS NOT NULL
  THEN
    UPDATE employee SET start_date = UPDATE_EMPLOYEE.start_date WHERE emp_id = UPDATE_EMPLOYEE.emp_id;
  END IF;
  
  IF end_date IS NOT NULL
  THEN
    UPDATE employee SET end_date = UPDATE_EMPLOYEE.end_date WHERE emp_id = UPDATE_EMPLOYEE.emp_id;
  END IF;
  
  COMMIT;
END;
/

CREATE OR REPLACE FUNCTION SCOTT.EMPLOYEE_DETAIL ( emp_id IN NUMBER )
RETURN SYS_REFCURSOR AS
  retval SYS_REFCURSOR;
BEGIN
  open retval for
    SELECT e.emp_id        AS id,
           e.dept_id       AS dept_id,
           e.position_id   AS position_id,
           e.location_id   AS location_id,
           d.dept_desc     AS department,
           l.location_desc AS location,
           p.position_desc AS position,
           TO_CHAR(e.start_date, 'YYYY-MM-DD HH24:Mi:SS') AS start_date,
           TO_CHAR(e.end_date, 'YYYY-MM-DD HH24:Mi:SS')   AS end_date
    FROM employee e,
         dept d,
         location l,
         position p
    WHERE e.emp_id = EMPLOYEE_DETAIL.emp_id
      AND d.dept_id = e.dept_id
      AND l.location_id = e.location_id
      AND p.position_id = e.position_id;
  RETURN retval;
END;
/

CREATE OR REPLACE FUNCTION SCOTT.LIST_DEPARTMENTS
RETURN SYS_REFCURSOR AS
  retval SYS_REFCURSOR;
BEGIN
  open retval for
    select dpt.dept_id    AS id,
           dpt.dept_desc  AS name,
           prnt.dept_desc AS parent
    FROM dept dpt,
         dept prnt
    WHERE prnt.dept_id = dpt.parent_dept_id
    ORDER BY dpt.dept_desc ASC;
  RETURN retval;
END;
/

CREATE OR REPLACE FUNCTION SCOTT.LIST_LOCATIONS
RETURN SYS_REFCURSOR AS
  retval SYS_REFCURSOR;
BEGIN
  open retval for
    select location_id   AS id,
           location_desc AS name
    FROM location
    ORDER BY location_desc ASC;

  RETURN retval;
END;
/

CREATE OR REPLACE FUNCTION SCOTT.LIST_positionS
RETURN SYS_REFCURSOR AS
  retval SYS_REFCURSOR;
BEGIN
  open retval for
    select position_id   AS id,
           position_desc AS name
    FROM position
    ORDER BY position_desc ASC;
  RETURN retval;
END;
/

quit;
/
