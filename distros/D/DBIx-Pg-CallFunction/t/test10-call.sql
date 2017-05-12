CREATE OR REPLACE FUNCTION get_userid_by_username(username text) RETURNS INTEGER AS $$
SELECT 123;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_user_hosts(userid integer) RETURNS SETOF INET AS $$
SELECT '127.0.0.1'::inet
UNION ALL
SELECT '192.168.0.1'::inet
UNION ALL
SELECT '10.0.0.1'::inet
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_user_details(OUT firstname text, OUT lastname text, OUT creationdate date, userid integer) RETURNS RECORD AS $$
SELECT 'Joel'::text, 'Jacobson'::text, '2012-05-25'::date;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_user_friends(INOUT userid integer, OUT firstname text, OUT lastname text, OUT creationdate date) RETURNS SETOF RECORD AS $$
SELECT 234, 'Claes'::text, 'Jakobsson'::text, '2012-05-26'::date
UNION ALL
SELECT 345, 'Magnus'::text, 'Hagander'::text, '2012-05-27'::date
UNION ALL
SELECT 456, 'Lukas'::text, 'Gratte'::text, '2012-05-28'::date;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION same_name_same_input_arguments(foo integer) RETURNS BOOLEAN AS $$
SELECT TRUE;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION same_name_same_input_arguments(foo text) RETURNS BOOLEAN AS $$
SELECT TRUE;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION test_default_values(one text, two text, three text default 'three', four text default 'four') RETURNS TEXT AS $$
SELECT $1 || $2 || $3 || $4;
$$ LANGUAGE sql;
