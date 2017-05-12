CREATE TABLE uploads (
    -- Notice AUTOINCREMENT has no underscore like MySQL does.  
	upload_id  INTEGER primary key AUTOINCREMENT NOT NULL, 
	file_name  character varying(255),
	mime_type  character varying(64),
	extension  character varying(8), -- file extension
	width      integer,                 
	height     integer,

	-- refer to the ID of the image used to create this thumbnail, if any
	gen_from_id integer
)
