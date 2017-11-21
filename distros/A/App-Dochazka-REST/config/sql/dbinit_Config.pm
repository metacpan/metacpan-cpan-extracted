# *************************************************************************
# Copyright (c) 2014-2017, SUSE LLC
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# *************************************************************************
#
# sql/dbinit_Config.pm
#
# database initialization SQL

#
# DBINIT_CONNECT_SUPERUSER
# DBINIT_CONNECT_SUPERAUTH
#
# These should be overrided in Dochazka_SiteConfig.pm with real
# superuser credentials (but only for testing - do not put production
# credentials in any configuration file!!!!)
#
set( 'DBINIT_CONNECT_SUPERUSER', 'postgres' );
set( 'DBINIT_CONNECT_SUPERAUTH', 'bogus_password_to_be_overrided' );

#
# DBINIT_CREATE
# 
#  A list of SQL statements that are executed when the database is first
#  created, to set up the table structure, etc. -- see the create_tables
#  subroutine in REST.pm 
#
set( 'DBINIT_CREATE', [

    # miscellaneous settings

    q/SET client_min_messages=WARNING/,

    # generalized (utility) functions used in multiple datamodel classes

    q#CREATE OR REPLACE FUNCTION round_time(timestamptz)
      RETURNS TIMESTAMPTZ AS $$
          SELECT date_trunc('hour', $1) + INTERVAL '5 min' * ROUND(date_part('minute', $1) / 5.0)
      $$ LANGUAGE sql IMMUTABLE
    #,

    q#COMMENT ON FUNCTION round_time(timestamptz) IS 
      'Round a single timestamp value to the nearest 5 minutes'#,

    q#CREATE OR REPLACE FUNCTION parens(tstzrange)
      RETURNS RECORD AS $$
        DECLARE
            left_paren     text;
            right_paren    text;
        BEGIN
            IF lower_inc($1) THEN
                left_paren := '['::text;
            ELSE
                left_paren := '('::text;
            END IF;
            IF upper_inc($1) THEN
                right_paren := ']'::text;
            ELSE
                right_paren := ')'::text;
            END IF;
        RETURN (left_paren, right_paren);
        END;
      $$ LANGUAGE plpgsql#,

    q/CREATE OR REPLACE FUNCTION overlaps(tstzrange, tstzrange)
      RETURNS boolean AS $$
        BEGIN
            IF $1 && $2 THEN
                RETURN 't'::boolean;
            ELSE
                RETURN 'f'::boolean;
            END IF;
        END;
      $$ LANGUAGE plpgsql/,

    q/COMMENT ON FUNCTION overlaps(tstzrange, tstzrange) IS
      'Tests two tstzranges whether they overlap'/,

    q/CREATE OR REPLACE FUNCTION not_before_1892(timestamptz) 
      RETURNS TIMESTAMPTZ AS $IMM$
      BEGIN
          IF $1 < '1892-01-01'::timestamptz THEN
              RAISE EXCEPTION 'No dates earlier than 1892-01-01 please'; 
          END IF;
          RETURN $1;
      END;
    $IMM$ LANGUAGE plpgsql/,

    q/COMMENT ON FUNCTION not_before_1892(timestamptz) IS 'We enforce dates 1892-01-01 or later'/,

    q#CREATE OR REPLACE FUNCTION valid_intvl() RETURNS trigger AS $$
        BEGIN
            IF ( NEW.intvl IS NULL ) OR
               ( isempty(NEW.intvl) ) OR
               ( lower(NEW.intvl) = '-infinity' ) OR
               ( lower(NEW.intvl) = 'infinity' ) OR
               ( upper(NEW.intvl) = '-infinity' ) OR
               ( upper(NEW.intvl) = 'infinity' ) OR
               ( NOT lower_inc(NEW.intvl) ) OR
               ( upper_inc(NEW.intvl) ) OR
               ( lower_inf(NEW.intvl) ) OR
               ( upper_inf(NEW.intvl) ) THEN
                RAISE EXCEPTION 'illegal attendance interval %s', NEW.intvl;
            END IF;
            PERFORM not_before_1892(upper(NEW.intvl));
            PERFORM not_before_1892(lower(NEW.intvl));
            IF ( upper(NEW.intvl) != round_time(upper(NEW.intvl)) ) OR
               ( lower(NEW.intvl) != round_time(lower(NEW.intvl)) ) THEN
                RAISE EXCEPTION 'upper and lower bounds of interval must be evenly divisible by 5 minutes';
            END IF;
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql IMMUTABLE
    #,

    q#COMMENT ON FUNCTION valid_intvl() IS $body$
This function runs a battery of validation tests on intervals.
The purpose of these tests is to ensure that the only intervals to make
it into the database are those that make sense in the context of employee
attendance.
$body$
#,

    # the 'employees' table

    q/CREATE TABLE IF NOT EXISTS employees (
        eid        serial PRIMARY KEY,
        nick       varchar(32) UNIQUE NOT NULL,
        sec_id     varchar(64) UNIQUE,
        fullname   varchar(96) UNIQUE,
        email      text UNIQUE,
        passhash   text,
        salt       text,
        sync       boolean DEFAULT FALSE NOT NULL,
        supervisor integer REFERENCES employees (eid),
        remark     text,
        CONSTRAINT kosher_nick CHECK (nick ~* '^[[:alnum:]_][[:alnum:]_-]+$')
      )/,

    q#COMMENT ON TABLE employees IS 'Employee profile associating a real (or imagined) employee with an Employee ID (EID)'#,

    # 'employees' triggers

    q/CREATE OR REPLACE FUNCTION eid_immutable() RETURNS trigger AS $IMM$
      BEGIN
          IF OLD.eid <> NEW.eid THEN
              RAISE EXCEPTION 'employees.eid field is immutable';
          END IF;
          RETURN NEW;
      END;
    $IMM$ LANGUAGE plpgsql/,

    q/COMMENT ON FUNCTION eid_immutable() IS 'trigger function to prevent users from modifying the EID field'/,
    
    q/CREATE TRIGGER no_eid_update BEFORE UPDATE ON employees
      FOR EACH ROW EXECUTE PROCEDURE eid_immutable()/,

    q/COMMENT ON TRIGGER no_eid_update ON employees IS 'trigger for eid_immutable()'/,

    q/CREATE OR REPLACE FUNCTION employee_supervise_self() RETURNS trigger AS $IMM$
      BEGIN
          IF NEW.eid = NEW.supervisor THEN
              RAISE EXCEPTION 'employees cannot be their own supervisor';
          END IF;
          RETURN NEW;
      END;
    $IMM$ LANGUAGE plpgsql/,

    q/COMMENT ON FUNCTION employee_supervise_self()
      IS 'trigger function to prevent employees from supervising themselves'/,

    q/CREATE TRIGGER no_employee_supervise_self BEFORE INSERT OR UPDATE ON employees
        FOR EACH ROW EXECUTE PROCEDURE employee_supervise_self()/,

    q/COMMENT ON TRIGGER no_employee_supervise_self ON employees
      IS 'Make it impossible for an employee to supervise her- or himself'/,

    q#-- Given an EID, returns an integer indicating how many "reports"
      -- the employee has (i.e. how many other employees there are, for whom
      -- this EID is their supervisor). The integer return value can be used
      -- as a boolean, too.
      -- foobar
      CREATE OR REPLACE FUNCTION has_reports(INTEGER)
      RETURNS integer AS $$
          SELECT count(*)::integer FROM employees WHERE supervisor = $1
      $$ LANGUAGE sql IMMUTABLE#,

    # the 'schedintvls' table

    q/CREATE SEQUENCE scratch_sid_seq/,

    q/COMMENT ON SEQUENCE scratch_sid_seq IS 'sequence guaranteeing that each scratch SID will have a unique identifier'/,

    q/CREATE TABLE IF NOT EXISTS schedintvls (
        int_id  serial PRIMARY KEY,
        ssid    integer NOT NULL,
        intvl   tstzrange NOT NULL,
        EXCLUDE USING gist (ssid WITH =, intvl WITH &&)
      )/,

    q/COMMENT ON TABLE schedintvls IS $body$
Staging table, used to assemble and test schedules before they
are converted (using translate_schedintvl) and inserted 
into the schedules table. Records inserted into schedintvls
should be deleted after use.
$body$/,

    q/CREATE TRIGGER schedintvls_valid_intvl BEFORE INSERT OR UPDATE ON schedintvls
        FOR EACH ROW EXECUTE PROCEDURE valid_intvl()/,

    q/COMMENT ON TRIGGER schedintvls_valid_intvl ON schedintvls 
      IS 'Run basic validity checks on intervals before they are added to schedintvls table'/,

    q/CREATE OR REPLACE FUNCTION valid_schedintvl() RETURNS trigger AS $$
        DECLARE
            max_upper   timestamptz;
            min_lower   timestamptz;
        BEGIN
            SELECT MAX(upper(intvl)) FROM (
                SELECT ssid, intvl FROM schedintvls WHERE schedintvls.ssid = NEW.ssid
                UNION
                SELECT NEW.ssid, NEW.intvl
            ) AS stlasq INTO max_upper;
            SELECT MIN(lower(intvl)) FROM (
                SELECT ssid, intvl FROM schedintvls WHERE schedintvls.ssid = NEW.ssid
                UNION
                SELECT NEW.ssid, NEW.intvl
            ) AS stlasq INTO min_lower;
            IF max_upper - min_lower > '168:0:0' THEN
                RAISE EXCEPTION 'schedule intervals must fall within a 7-day range';
            END IF;
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql IMMUTABLE/,

    q/COMMENT ON FUNCTION valid_schedintvl() IS $body$
trigger function to ensure that all scratch schedule intervals fall within a
7-day range
$body$
/,

    q/CREATE TRIGGER valid_schedintvl BEFORE INSERT ON schedintvls
        FOR EACH ROW EXECUTE PROCEDURE valid_schedintvl()/,

    q/COMMENT ON TRIGGER valid_schedintvl ON schedintvls IS $body$
After intervals pass basic validity checks in the schedintvls_valid_intvl
trigger, apply schedule-specific checks on the intervals
$body$
/,

    q#CREATE OR REPLACE FUNCTION translate_schedintvl ( 
          ssid int,
          OUT low_dow text,
          OUT low_time text,
          OUT high_dow text,
          OUT high_time text
      ) AS $$
          SELECT 
              to_char(lower(intvl)::timestamptz, 'DY'),
              to_char(lower(intvl)::timestamptz, 'HH24:MI'),
              to_char(upper(intvl)::timestamptz, 'DY'),
              to_char(upper(intvl)::timestamptz, 'HH24:MI')
          FROM schedintvls
          WHERE int_id = $1
      $$ LANGUAGE sql IMMUTABLE#,

    q#COMMENT ON FUNCTION translate_schedintvl(ssid int, OUT low_dow text, OUT low_time text, OUT high_dow text, OUT high_time text) IS $body$
Given a SSID in schedintvls, returns all the intervals for that
SSID. Each interval is expressed as a list ('row', 'composite
value') consisting of 4 strings (two pairs). The first pair of
strings (e.g., "WED" "08:00") denotes the lower bound of the
range, while the second pair denotes the upper bound
$body$#,

    # the 'schedules' table

    q#CREATE TABLE IF NOT EXISTS schedules (
        sid        serial PRIMARY KEY,
        scode      varchar(32) UNIQUE,
        schedule   text UNIQUE NOT NULL,
        disabled   boolean NOT NULL,
        remark     text
    )
    #,

    q/-- trigger function to detect attempts to change 'schedule' field
    CREATE OR REPLACE FUNCTION schedule_immutable() RETURNS trigger AS $IMM$
      BEGIN
          IF OLD.schedule <> NEW.schedule THEN
              RAISE EXCEPTION 'schedule field is immutable'; 
          END IF;
          IF OLD.sid <> NEW.sid THEN
              RAISE EXCEPTION 'schedules.sid field is immutable'; 
          END IF; 
          RETURN NEW;
      END;
    $IMM$ LANGUAGE plpgsql/,
    
    q/-- trigger the trigger
    CREATE TRIGGER no_schedule_update BEFORE UPDATE ON schedules
      FOR EACH ROW EXECUTE PROCEDURE schedule_immutable()/,
    
    q/-- trigger function to convert NULL to 'f' in boolean field
    CREATE OR REPLACE FUNCTION disabled_to_zero() RETURNS trigger AS $$
        BEGIN
            IF NEW.disabled IS NULL THEN
                NEW.disabled = 'f';
            END IF;
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql IMMUTABLE/,

    q/-- trigger the disabled_to_zero trigger as well
    CREATE TRIGGER disabled_to_zero BEFORE INSERT OR UPDATE ON schedules
        FOR EACH ROW EXECUTE PROCEDURE disabled_to_zero()/,

    # the 'schedhistory' table

    q/CREATE TABLE IF NOT EXISTS schedhistory (
        shid       serial PRIMARY KEY,
        eid        integer REFERENCES employees (eid) NOT NULL,
        sid        integer REFERENCES schedules (sid) NOT NULL,
        effective  timestamptz NOT NULL,
        remark     text,
        UNIQUE (eid, effective)
      )/,

    q/-- trigger function to make 'shid' field immutable
    CREATE OR REPLACE FUNCTION shid_immutable() RETURNS trigger AS $IMM$
      BEGIN
          IF OLD.shid <> NEW.shid THEN
              RAISE EXCEPTION 'schedhistory.shid field is immutable'; 
          END IF;
          RETURN NEW;
      END;
    $IMM$ LANGUAGE plpgsql/,
    
    q/-- trigger the trigger
    CREATE TRIGGER no_shid_update BEFORE UPDATE ON schedhistory
      FOR EACH ROW EXECUTE PROCEDURE shid_immutable()/,
    
    # the 'privilege' type

    q/CREATE TYPE privilege AS ENUM ('passerby', 'inactive', 'active', 'admin')/,

    # the 'schedhistory' table

    q/CREATE TABLE IF NOT EXISTS privhistory (
        phid       serial PRIMARY KEY,
        eid        integer REFERENCES employees (eid) NOT NULL,
        priv       privilege NOT NULL,
        effective  timestamptz NOT NULL,
        remark     text,
        UNIQUE (eid, effective)
    )/,

    q/-- trigger function to make 'phid' field immutable
    CREATE OR REPLACE FUNCTION phid_immutable() RETURNS trigger AS $IMM$
      BEGIN
          IF OLD.phid <> NEW.phid THEN
              RAISE EXCEPTION 'privhistory.phid field is immutable'; 
          END IF;
          RETURN NEW;
      END;
    $IMM$ LANGUAGE plpgsql/,
    
    q/-- trigger the trigger
    CREATE TRIGGER no_phid_update BEFORE UPDATE ON privhistory
      FOR EACH ROW EXECUTE PROCEDURE phid_immutable()/,
    
    # triggers shared by 'privhistory' and 'schedhistory'

    q/CREATE OR REPLACE FUNCTION round_effective() RETURNS trigger AS $$
        BEGIN
            NEW.effective = round_time(NEW.effective);
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql IMMUTABLE/,

    q/CREATE OR REPLACE FUNCTION sane_timestamp() RETURNS trigger AS $$
        BEGIN
            PERFORM not_before_1892(NEW.effective);
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql IMMUTABLE/,

    q/CREATE TRIGGER round_effective BEFORE INSERT OR UPDATE ON schedhistory
        FOR EACH ROW EXECUTE PROCEDURE round_effective()/,

    q/CREATE TRIGGER round_effective BEFORE INSERT OR UPDATE ON privhistory
        FOR EACH ROW EXECUTE PROCEDURE round_effective()/,

    q/CREATE TRIGGER enforce_ts_sanity BEFORE INSERT OR UPDATE ON schedhistory
        FOR EACH ROW EXECUTE PROCEDURE sane_timestamp()/,

    q/CREATE TRIGGER enforce_ts_sanity BEFORE INSERT OR UPDATE ON privhistory
        FOR EACH ROW EXECUTE PROCEDURE sane_timestamp()/,

    # stored procedures relating to privhistory, schedhistory, and schedule

    q#-- generalized function to get privilege level for an employee
      -- as of a given timestamp
      -- the complicated SELECT is necessary to ensure that the function
      -- always returns a valid privilege level -- if the EID given doesn't
      -- have a privilege level for the timestamp given, the function
      -- returns 'passerby' (for more information, see t/003-current-priv.t)
      CREATE OR REPLACE FUNCTION priv_at_timestamp (INTEGER, TIMESTAMP WITH TIME ZONE)
      RETURNS privilege AS $$
          SELECT priv FROM (
              SELECT 'passerby' AS priv, '4713-01-01 BC' AS effective 
              UNION
              SELECT priv, effective FROM privhistory 
                  WHERE eid=$1 AND effective <= $2
          ) AS something_like_a_virtual_table
          ORDER BY effective DESC
          FETCH FIRST ROW ONLY
      $$ LANGUAGE sql IMMUTABLE#,

    q#-- function to get SID for an employee as of timestamp
      CREATE OR REPLACE FUNCTION sid_at_timestamp (INTEGER, TIMESTAMP WITH TIME ZONE)
      RETURNS integer AS $$
          SELECT sid FROM (
              SELECT NULL AS sid, '4713-01-01 BC' AS effective
              UNION
              SELECT schedules.sid, schedhistory.effective
                  FROM schedules, schedhistory
                  WHERE schedules.sid = schedhistory.sid AND
                        schedhistory.eid=$1 AND 
                        schedhistory.effective <= $2
          ) AS something_like_a_virtual_table
          ORDER BY effective DESC
          FETCH FIRST ROW ONLY
      $$ LANGUAGE sql IMMUTABLE#,

    q#-- function to get the privhistory record applicable to an employee
      -- as of a timestamp
      CREATE OR REPLACE FUNCTION privhistory_at_timestamp (
          IN INTEGER, 
          IN TIMESTAMP WITH TIME ZONE,
          OUT phid INTEGER, 
          OUT eid INTEGER, 
          OUT priv PRIVILEGE, 
          OUT effective TIMESTAMP WITH TIME ZONE, 
          OUT remark TEXT 
      )
      AS $$
          SELECT phid, eid, priv, effective, remark FROM privhistory 
          WHERE eid=$1 AND effective <= $2
          ORDER BY effective DESC
          FETCH FIRST ROW ONLY
      $$ LANGUAGE sql#,

    q#-- function to get the privhistory record applicable to an employee
      -- as of the beginning of a tsrange
      CREATE OR REPLACE FUNCTION privhistory_at_tsrange (
          IN INTEGER, 
          IN TSTZRANGE,
          OUT phid INTEGER, 
          OUT eid INTEGER, 
          OUT priv PRIVILEGE, 
          OUT effective TIMESTAMP WITH TIME ZONE, 
          OUT remark TEXT 
      )
      AS $$
          SELECT phid, eid, priv, effective, remark
          FROM privhistory_at_timestamp( $1, lower( $2 ) )
      $$ LANGUAGE sql#,

    q#-- function to get schedhistory record applicable to an employee 
      -- as of a timestamp
      CREATE OR REPLACE FUNCTION schedhistory_at_timestamp (
          IN INTEGER, 
          IN TIMESTAMP WITH TIME ZONE,
          OUT shid INTEGER, 
          OUT eid INTEGER, 
          OUT sid INTEGER, 
          OUT effective TIMESTAMP WITH TIME ZONE, 
          OUT remark TEXT 
      )
      AS $$
          SELECT shid, eid, sid, effective, remark FROM schedhistory 
          WHERE eid=$1 AND effective <= $2
          ORDER BY effective DESC
          FETCH FIRST ROW ONLY
      $$ LANGUAGE sql#,

    q#-- function to get the schedhistory record applicable to an employee
      -- as of the beginning of a tsrange
      CREATE OR REPLACE FUNCTION schedhistory_at_tsrange (
          IN INTEGER, 
          IN TSTZRANGE,
          OUT shid INTEGER, 
          OUT eid INTEGER, 
          OUT sid INTEGER, 
          OUT effective TIMESTAMP WITH TIME ZONE, 
          OUT remark TEXT 
      )
      AS $$
          SELECT shid, eid, sid, effective, remark
          FROM schedhistory_at_timestamp( $1, lower( $2 ) )
      $$ LANGUAGE sql#,

    q#-- Given an EID and a tstzrange, returns a boolean value indicating
      -- whether or not the employee's privlevel changed during that tstzrange.
      -- NOTE: history changes lying on an inclusive boundary of the range
      -- do not trigger a positive!
      CREATE OR REPLACE FUNCTION priv_change_during_range(INTEGER, TSTZRANGE)
      RETURNS integer AS $$
          SELECT count(*)::integer FROM
              (
                  SELECT
                      $2::tstzrange @> effective
                      AND NOT
                      (
                          ( lower_inc($2::tstzrange) AND effective = lower($2::tstzrange) )
                          OR
                          ( upper_inc($2::tstzrange) AND effective = upper($2::tstzrange) )
                      )
                  AS priv_changed
                  FROM privhistory WHERE eid=$1
              ) AS tblalias
          WHERE priv_changed = 't'
      $$ LANGUAGE sql IMMUTABLE#,

    q#-- Given an EID and a tstzrange, returns a boolean value indicating
      -- whether or not the employee's schedule changed during that tstzrange.
      -- NOTE: history changes lying on an inclusive boundary of the range
      -- do not trigger a positive!
      CREATE OR REPLACE FUNCTION schedule_change_during_range(INTEGER, TSTZRANGE)
      RETURNS integer AS $$
          SELECT count(*)::integer FROM
              (
                  SELECT
                      $2::tstzrange @> effective
                      AND NOT
                      (
                          ( lower_inc($2::tstzrange) AND effective = lower($2::tstzrange) )
                          OR
                          ( upper_inc($2::tstzrange) AND effective = upper($2::tstzrange) )
                      )
                  AS schedule_changed
                  FROM schedhistory WHERE eid=$1
              ) AS tblalias
          WHERE schedule_changed = 't'
      $$ LANGUAGE sql IMMUTABLE#,

    q#-- wrapper function to get priv as of current timestamp
      CREATE OR REPLACE FUNCTION current_priv (INTEGER)
      RETURNS privilege AS $$
          SELECT priv_at_timestamp($1, current_timestamp)
      $$ LANGUAGE sql IMMUTABLE#,

    q#-- wrapper function to get schedule as of current timestamp
      CREATE OR REPLACE FUNCTION current_schedule (INTEGER)
      RETURNS integer AS $$
          SELECT sid_at_timestamp($1, current_timestamp)
      $$ LANGUAGE sql IMMUTABLE#,

    # the 'activities' table

    q/-- activities
      CREATE TABLE activities (
          aid        serial PRIMARY KEY,
          code       varchar(32) UNIQUE NOT NULL,
          long_desc  text,
          remark     text,
          disabled   boolean NOT NULL,
          stamp      json,
          CONSTRAINT kosher_code CHECK (code ~* '^[[:alnum:]_][[:alnum:]_-]+$')
      )/,
  
    q/-- trigger function to make 'aid' field immutable
    CREATE OR REPLACE FUNCTION aid_immutable() RETURNS trigger AS $IMM$
      BEGIN
          IF OLD.aid <> NEW.aid THEN
              RAISE EXCEPTION 'activities.aid field is immutable'; 
          END IF;
          RETURN NEW;
      END;
    $IMM$ LANGUAGE plpgsql/,
    
    q/-- trigger the trigger
    CREATE TRIGGER no_aid_update BEFORE UPDATE ON activities
      FOR EACH ROW EXECUTE PROCEDURE aid_immutable()/,
    
    q/CREATE OR REPLACE FUNCTION code_to_upper() RETURNS trigger AS $$
        BEGIN
            NEW.code = upper(NEW.code);
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql IMMUTABLE/,

    q/CREATE TRIGGER code_to_upper BEFORE INSERT OR UPDATE ON activities
        FOR EACH ROW EXECUTE PROCEDURE code_to_upper()/,

    q/CREATE TRIGGER disabled_to_zero BEFORE INSERT OR UPDATE ON activities
        FOR EACH ROW EXECUTE PROCEDURE disabled_to_zero()/,

    # the 'components' table

    q#-- components
      CREATE TABLE components (
          cid         serial PRIMARY KEY,
          path        varchar(2048) UNIQUE NOT NULL,
          source      text NOT NULL,
          acl         varchar(16) NOT NULL,
          validations text,
          CONSTRAINT kosher_path CHECK (path ~* '^[[:alnum:]_.][[:alnum:]_/.-]+$')
      )#,
  
    q/-- trigger function to make 'cid' field immutable
    CREATE OR REPLACE FUNCTION cid_immutable() RETURNS trigger AS $IMM$
      BEGIN
          IF OLD.cid <> NEW.cid THEN
              RAISE EXCEPTION 'components.cid field is immutable'; 
          END IF;
          RETURN NEW;
      END;
    $IMM$ LANGUAGE plpgsql/,
    
    q/-- trigger the trigger
    CREATE TRIGGER no_cid_update BEFORE UPDATE ON components
      FOR EACH ROW EXECUTE PROCEDURE cid_immutable()/,
    
    # the 'intervals' table

    q/-- intervals
      CREATE TABLE IF NOT EXISTS intervals (
          iid        serial PRIMARY KEY,
          eid        integer REFERENCES employees (eid) NOT NULL,
          aid        integer REFERENCES activities (aid) NOT NULL,
          intvl      tstzrange NOT NULL,
          long_desc  text,
          remark     text,
          stamp      json,
          EXCLUDE USING gist (eid WITH =, intvl WITH &&)
      )/,

    q#-- trigger function to ensure that a privhistory/schedhistory record
      -- does not fall within an existing attendance interval
    CREATE OR REPLACE FUNCTION history_policy() RETURNS trigger AS $$
        DECLARE
            intvl_count integer;
        BEGIN
            -- the EID is NEW.eid, effective timestamptz is NEW.effective
            SELECT count(*) FROM intervals INTO intvl_count
            WHERE eid=NEW.eid AND intvl @> NEW.effective;
            IF intvl_count > 0 THEN
                RAISE EXCEPTION 'effective timestamp conflicts with existing attendance interval';
            END IF;
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql IMMUTABLE#,

    q/-- trigger the trigger
    CREATE TRIGGER no_intvl_conflict BEFORE INSERT OR UPDATE ON privhistory
      FOR EACH ROW EXECUTE PROCEDURE history_policy()/,
    
    q/-- trigger the trigger
    CREATE TRIGGER no_intvl_conflict BEFORE INSERT OR UPDATE ON schedhistory
      FOR EACH ROW EXECUTE PROCEDURE history_policy()/,
    
    q/-- trigger function to enforce policy that an interval cannot come into
      -- existence unless the employee has only a single privlevel throughout 
      -- the entire interval and that privlevel is either 'active' or 'admin'
    CREATE OR REPLACE FUNCTION priv_policy() RETURNS trigger AS $$
        DECLARE
            priv text;
            pr_count integer;
        BEGIN
            -- the EID is NEW.eid, interval is NEW.intvl
            -- 1. is there a non-passerbu privilege at the beginning of the interval?
            SELECT priv_at_timestamp(NEW.eid, lower(NEW.intvl)) INTO priv;
            IF priv = 'passerby' OR priv = 'inactive' THEN
                RAISE EXCEPTION 'insufficient privileges: check employee privhistory';
            END IF;
            -- 2. are there any privhistory records during the interval?
            SELECT count(*) FROM privhistory INTO pr_count
            WHERE eid=NEW.eid AND effective >= lower(NEW.intvl) AND effective <= upper(NEW.intvl);
            IF pr_count > 0 THEN
                RAISE EXCEPTION 'ambiguous privilege status: check employee privhistory';
            END IF;
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql IMMUTABLE/,

    q/-- trigger function to enforce policy that an interval cannot come into
      -- existence unless the employee has only a single schedule throughout 
      -- the entire interval
    CREATE OR REPLACE FUNCTION schedule_policy() RETURNS trigger AS $$
        DECLARE
            test_sid text;
            sh_count integer;
        BEGIN
            -- the EID is NEW.eid, interval is NEW.intvl
            -- 1. is there a schedule at the beginning of the interval?
            SELECT sid_at_timestamp(NEW.eid, lower(NEW.intvl)) INTO test_sid;
            IF test_sid IS NULL THEN
                RAISE EXCEPTION 'employee schedule for this interval cannot be determined';
            END IF;
            -- 2. are there any schedhistory records during the interval?
            SELECT count(*) FROM schedhistory INTO sh_count
            WHERE eid=NEW.eid AND effective >= lower(NEW.intvl) AND effective <= upper(NEW.intvl);
            IF sh_count > 0 THEN
                RAISE EXCEPTION 'employee schedule for this interval cannot be determined';
            END IF;
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql IMMUTABLE/,

    q/-- trigger function for use in sanity checks on attendance and lock intervals
      -- vets an interval to ensure it does not extend too far into the future
    CREATE OR REPLACE FUNCTION not_too_future() RETURNS trigger AS $$
        DECLARE
            limit_ts timestamptz;
        BEGIN
            --
            -- does the interval extend too far into the future?
            --
            SELECT date_trunc('MONTH', (now() + interval '4 months'))::TIMESTAMPTZ INTO limit_ts;
            IF upper(NEW.intvl) >= limit_ts THEN 
                RAISE EXCEPTION 'interval extends too far into the future';
            END IF;
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql IMMUTABLE/,

    q/-- trigger function to make 'iid' field immutable
    CREATE OR REPLACE FUNCTION iid_immutable() RETURNS trigger AS $IMM$
      BEGIN
          IF OLD.iid <> NEW.iid THEN
              RAISE EXCEPTION 'intervals.iid field is immutable'; 
          END IF;
          RETURN NEW;
      END;
    $IMM$ LANGUAGE plpgsql/,
    
    q/CREATE TRIGGER one_and_only_one_schedule BEFORE INSERT OR UPDATE ON intervals
      FOR EACH ROW EXECUTE PROCEDURE schedule_policy()/,

    q/CREATE TRIGGER enforce_priv_policy BEFORE INSERT OR UPDATE ON intervals
      FOR EACH ROW EXECUTE PROCEDURE priv_policy()/,

    q/CREATE TRIGGER a1_interval_valid_intvl BEFORE INSERT OR UPDATE ON intervals
      FOR EACH ROW EXECUTE PROCEDURE valid_intvl()/,

    q/CREATE TRIGGER a2_interval_not_too_future BEFORE INSERT OR UPDATE ON intervals
      FOR EACH ROW EXECUTE PROCEDURE not_too_future()/,

    q/CREATE TRIGGER a3_no_iid_update BEFORE UPDATE ON intervals
      FOR EACH ROW EXECUTE PROCEDURE iid_immutable()/,
    
    # the 'locks' table

    q/-- locks
      CREATE TABLE locks (
          lid     serial PRIMARY KEY,
          eid     integer REFERENCES Employees (EID),
          intvl   tstzrange NOT NULL,
          remark  text,
          stamp   json,
          EXCLUDE USING gist (eid WITH =, intvl WITH &&)
      )/,

    q/-- trigger function to make 'lid' field immutable
    CREATE OR REPLACE FUNCTION lid_immutable() RETURNS trigger AS $IMM$
      BEGIN
          IF OLD.lid <> NEW.lid THEN
              RAISE EXCEPTION 'locks.lid field is immutable'; 
          END IF;
          RETURN NEW;
      END;
    $IMM$ LANGUAGE plpgsql/,
    
    q/CREATE TRIGGER a1_lock_valid_intvl BEFORE INSERT OR UPDATE ON locks
      FOR EACH ROW EXECUTE PROCEDURE valid_intvl()/,

    q/CREATE TRIGGER a2_lock_not_too_future BEFORE INSERT OR UPDATE ON locks
      FOR EACH ROW EXECUTE PROCEDURE not_too_future()/,

    q/-- trigger the trigger
    CREATE TRIGGER a3_no_lid_update BEFORE UPDATE ON locks
      FOR EACH ROW EXECUTE PROCEDURE lid_immutable()/,

    q/-- lock lookup trigger for intervals table
      CREATE OR REPLACE FUNCTION no_lock_conflict() RETURNS trigger AS $IMM$
      DECLARE
          this_eid integer;
          this_intvl tstzrange;
          lock_count integer;
      BEGIN

          IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
              -- EID and tsrange are NEW.eid and NEW.intvl, respectively
              this_eid := NEW.eid;
              this_intvl := NEW.intvl;
          ELSE
              -- TG_OP = 'DELETE'
              this_eid := OLD.eid;
              this_intvl := OLD.intvl;
          END IF;

          SELECT count(*) INTO lock_count FROM locks WHERE eid=this_eid AND intvl && this_intvl;
          IF lock_count > 0 THEN
              RAISE EXCEPTION 'interval is locked';
          END IF;

          IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
              RETURN NEW;
          ELSE
              RETURN OLD;
          END IF;

      END;
      $IMM$ LANGUAGE plpgsql/,
          
    q/CREATE TRIGGER intvl_not_locked BEFORE INSERT OR UPDATE OR DELETE ON intervals
      FOR EACH ROW EXECUTE PROCEDURE no_lock_conflict()/,

    # the 'tempintvls' table and associated plumbing

    q/CREATE SEQUENCE temp_intvl_seq/,

    q/COMMENT ON SEQUENCE temp_intvl_seq IS 'sequence guaranteeing that each set of temporary intervals will have a unique identifier'/,

    q/-- tempintvls
      -- for staging fillup intervals 
      CREATE TABLE IF NOT EXISTS tempintvls (
          int_id     serial PRIMARY KEY,
          tiid       integer NOT NULL,
          intvl      tstzrange NOT NULL
      )/,

    q/CREATE TRIGGER a2_interval_not_too_future BEFORE INSERT OR UPDATE ON tempintvls
      FOR EACH ROW EXECUTE PROCEDURE not_too_future()/,

    # create 'root' and 'demo' employees

    q/-- insert root employee into employees table and grant admin
      -- privilege to the resulting EID
      WITH cte AS (
        INSERT INTO employees (nick, fullname, email, passhash, salt, remark) 
        VALUES ('root', 'Root Immutable', 'root@site.org', '82100e9bd4757883b4627b3bafc9389663e7be7f76a1273508a7a617c9dcd917428a7c44c6089477c8e1d13e924343051563d2d426617b695f3a3bff74e7c003', '341755e03e1f163f829785d1d19eab9dee5135c0', 'dbinit') 
        RETURNING eid
      ) 
      INSERT INTO privhistory (eid, priv, effective, remark)
      SELECT eid, 'admin', '1892-01-01', 'IMMUTABLE' FROM cte
    /,

    q/-- insert demo employee into employees table
      INSERT INTO employees (nick, fullname, email, passhash, salt, remark) 
      VALUES ('demo', 'Demo Employee', 'demo@dochazka.site', '4962cc89c646261a887219795083a02b899ea960cd84a234444b7342e2222eb22dc06f5db9c71681074859469fdc0abd53e3f1f47a381617b59f4b31608e24b1', '82702be8d9810d8fba774dcb7c9f68f39d0933e8', 'dbinit') 
      RETURNING eid
    /,

    # DEFAULT schedule

    q/-- insert DEFAULT schedule into schedules table
      INSERT INTO schedules (scode, schedule)
      VALUES ('DEFAULT', '[{"high_dow":"MON","high_time":"12:00","low_dow":"MON","low_time":"08:00"},{"high_dow":"MON","high_time":"16:30","low_dow":"MON","low_time":"12:30"},{"high_dow":"TUE","high_time":"12:00","low_dow":"TUE","low_time":"08:00"},{"high_dow":"TUE","high_time":"16:30","low_dow":"TUE","low_time":"12:30"},{"high_dow":"WED","high_time":"12:00","low_dow":"WED","low_time":"08:00"},{"high_dow":"WED","high_time":"16:30","low_dow":"WED","low_time":"12:30"},{"high_dow":"THU","high_time":"12:00","low_dow":"THU","low_time":"08:00"},{"high_dow":"THU","high_time":"16:30","low_dow":"THU","low_time":"12:30"},{"high_dow":"FRI","high_time":"12:00","low_dow":"FRI","low_time":"08:00"},{"high_dow":"FRI","high_time":"16:30","low_dow":"FRI","low_time":"12:30"}]')
    /,
]);

# DBINIT_SELECT_EID_OF
#   after create_tables (REST.pm) executes the above list of SQL
#   statements, it needs to find the EID of the root and demo employees
#
set('DBINIT_SELECT_EID_OF', q/
    SELECT eid FROM employees WHERE nick = ?/);

# DBINIT_MAKE_ROOT_IMMUTABLE
#   after finding the EID of the root employee, create_tables executes
#   another batch of SQL statements to make root immutable
#   (for more information, see t/002-root.t)
#
set('DBINIT_MAKE_ROOT_IMMUTABLE', [

    q/
    -- trigger function to detect attempts to change nick of the
    -- root employee
    CREATE OR REPLACE FUNCTION root_immutable() RETURNS trigger AS $IMM$
      BEGIN
          IF OLD.eid = ? THEN
              IF NEW.eid <> ? THEN
                  RAISE EXCEPTION 'root employee is immutable'; 
              END IF;
              IF NEW.nick <> 'root' THEN
                  RAISE EXCEPTION 'root employee is immutable'; 
              END IF;
              IF NEW.supervisor IS NOT NULL THEN
                  RAISE EXCEPTION 'root employee is immutable';
              END IF;
          END IF;
          RETURN NEW;
      END;
    $IMM$ LANGUAGE plpgsql/,
    
    q/
    CREATE OR REPLACE FUNCTION root_immutable_new() RETURNS trigger AS $IMM$
      BEGIN
          IF NEW.eid = ? THEN
              RAISE EXCEPTION 'root employee is immutable'; 
          END IF;
          RETURN NEW;
      END;
    $IMM$ LANGUAGE plpgsql/,
    
    q/
    -- for use in BEFORE UPDATE triggers
    CREATE OR REPLACE FUNCTION root_immutable_old_update() RETURNS trigger AS $IMM$
      BEGIN
          IF OLD.eid = ? THEN
              RAISE EXCEPTION 'root employee is immutable'; 
          END IF;
          RETURN NEW;
      END;
    $IMM$ LANGUAGE plpgsql/,

    q/
    -- for use in BEFORE DELETE triggers
    CREATE OR REPLACE FUNCTION root_immutable_old_delete() RETURNS trigger AS $IMM$
      BEGIN
          IF OLD.eid = ? THEN
              RAISE EXCEPTION 'root employee is immutable'; 
          END IF;
          RETURN OLD;
      END;
    $IMM$ LANGUAGE plpgsql/,

    q/
    -- this trigger makes it impossible to update the root employee
    CREATE TRIGGER no_root_change BEFORE UPDATE ON employees
      FOR EACH ROW EXECUTE PROCEDURE root_immutable()/,
    
    q/
    -- this trigger makes it impossible to delete the root employee
    CREATE TRIGGER no_root_delete BEFORE DELETE ON employees
      FOR EACH ROW EXECUTE PROCEDURE root_immutable_old_delete()/,
    
    q/
    -- this trigger makes it impossible to introduce any new privhistory 
    -- rows for the root employee
    CREATE TRIGGER no_root_new BEFORE INSERT OR UPDATE ON privhistory
      FOR EACH ROW EXECUTE PROCEDURE root_immutable_new()/,
    
    q/
    -- this trigger makes it impossible to update the root
    -- employee's privhistory row
    CREATE TRIGGER no_root_update BEFORE UPDATE ON privhistory
      FOR EACH ROW EXECUTE PROCEDURE root_immutable_old_update()/,
    
    q/
    -- this trigger makes it impossible to delete the root
    -- employee's privhistory row
    CREATE TRIGGER no_root_old_delete BEFORE DELETE ON privhistory
      FOR EACH ROW EXECUTE PROCEDURE root_immutable_old_delete()/,
    
]);

# DBINIT_GRANTS
#
#       whatever GRANT statements we need to do, put them here and they will
#       get executed after DBINIT_CREATE; ? will be replaced with DOCHAZKA_DBUSER
#       site param
set( 'DBINIT_GRANTS', [

    q/GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "$dbuser"/,

    q/GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO "$dbuser"/,

    q/GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "$dbuser"/,

    q/GRANT CONNECT ON DATABASE "$dbname" TO "$dbuser"/,

] );

# SQL_NOOF_CONNECTIONS
#    used by 'GET dbstatus'
#
set('SQL_NOOF_CONNECTIONS', q/SELECT sum(numbackends) FROM pg_stat_database/);
#set('SQL_NOOF_CONNECTIONS', q/SELECT count(*) FROM pg_stat_activity/);

# -----------------------------------
# DO NOT EDIT ANYTHING BELOW THIS LINE
# -----------------------------------
use strict;
use warnings;

1;
