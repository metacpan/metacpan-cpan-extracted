[% IF not table %][% table = '<Table>' %][% END -%]
-- Create the [% table %] table and initial contents

-- DROP TABLE [% table %];

CREATE TABLE [% table %] (
[% FOREACH column = columns -%]
	[% column %][% i = column.length %][% WHILE i <= 11 + table.length %][% i = i + 1 %] [% END %] [%
		IF column == table _ '_id'
		%]SERIAL PRIMARY KEY,[%
		ELSIF column == table _ '_created'
		%]TIMESTAMP WITH TIME ZONE DEFAULT NOW(),[%
		ELSIF column == table _ '_type_id'
		%]INTEGER REFERENCES [% table %]_type  ([% table %]_type_id ) NOT NULL,[%
		ELSIF column == table _ '_state_id'
		%]INTEGER REFERENCES [% table %]_state ([% table %]_state_id) NOT NULL,[%
		ELSIF column == table
		%]VARCHAR NOT NULL UNIQUE,[%
		ELSIF column.search('_id$')
		%][% tables = column.match('^(\w+)_id$')
		%]INTEGER REFERENCES [% tables.1 %] ([% column %]),[%
		ELSE
		%]VARCHAR,[%
		END %]
[% END -%]
);

[%- FOREACH column = columns %]
COMMENT ON COLUMN [% table %].[% column %][% i = column.length %][% WHILE i <= 11 + table.length %][% i = i + 1 %] [% END %] IS '';
[%- END %]

INSERT INTO [% table %] VALUES ([% FOREACH column = columns %], [% IF column == table _ '_id' || column == table _ '_created' %]DEFAULT[% ELSIF column.search('_id$') %]0[% ELSE %]''[% END %][% END %]);
