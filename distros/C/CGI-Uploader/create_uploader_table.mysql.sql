CREATE TABLE uploads (
	upload_id	int AUTO_INCREMENT primary key not null,
	file_name  character varying(255),
	mime_type  character varying(64),
	extension  character varying(8), -- file extension
	width      integer,                 
	height     integer,

	-- refer to the ID of the image used to create this thumbnail, if any
	gen_from_id integer
)
