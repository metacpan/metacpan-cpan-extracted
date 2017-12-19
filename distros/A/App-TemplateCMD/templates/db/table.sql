[% IF not table %][% table = '<Table>' %][% END -%]
-- Create the [% table %] table and initial contents

-- DROP TABLE [% table %];

CREATE TABLE [% table %] (
	[% table %]_id          SERIAL PRIMARY KEY,
	[% table %]_created     TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
	[% table %]_type_id     INTEGER REFERENCES [% table %]_type  ([% table %]_type_id ) NOT NULL,
	[% table %]_state_id    INTEGER REFERENCES [% table %]_state ([% table %]_state_id) NOT NULL,
	[% table %]             VARCHAR NOT NULL UNIQUE,
	[% table %]_description VARCHAR,
[% FOREACH column = columns -%]
	[% column %][% i = column.length %][% WHILE i <= 11 + table.length %][% i = i + 1 %] [% END %] VARCHAR,
[% END -%]
);

COMMENT ON TABLE  [% table %]                         IS '';
COMMENT ON COLUMN [% table %].[% table %]_created     IS '';
COMMENT ON COLUMN [% table %].[% table %]_type_id     IS '';
COMMENT ON COLUMN [% table %].[% table %]_state_id    IS '';
COMMENT ON COLUMN [% table %].[% table %]             IS '';
COMMENT ON COLUMN [% table %].[% table %]_description IS '';
[%- FOREACH column = columns %]
COMMENT ON COLUMN [% table %].[% column %][% i = column.length %][% WHILE i <= 11 + table.length %][% i = i + 1 %] [% END %] IS '';
[%- END %]

INSERT INTO [% table %] VALUES (DEFAULT, DEFAULT, 1, 1, ''[% FOREACH column = columns %], ''[% END %]);
INSERT INTO [% table %] VALUES (DEFAULT, DEFAULT, 1, 1, ''[% FOREACH column = columns %], ''[% END %]);
INSERT INTO [% table %] VALUES (DEFAULT, DEFAULT, 1, 1, ''[% FOREACH column = columns %], ''[% END %]);
INSERT INTO [% table %] VALUES (DEFAULT, DEFAULT, 1, 1, ''[% FOREACH column = columns %], ''[% END %]);
