-- arch-tag: cf379bd5-b773-481f-b026-38932dbb9c78

	-- Note the Postgres specific syntax here
    CREATE SEQUENCE upload_id_seq;
	CREATE TABLE uploads (
		upload_id   int primary key not null 
		                default nextval('upload_id_seq'),
		mime_type   character varying(64),
		extension   character varying(8), -- file extension
		width       integer,                 
		height      integer,
		thumbnail_of_id integer
	);

 CREATE SEQUENCE friend_id_seq;
 CREATE TABLE address_book (
    friend_id       int primary key NOT NULL DEFAULT nextval('friend_id_seq'),
    full_name       varchar(64),

    -- these two reference uploads('upload_id'),
    photo_id            int,  
    photo_thumbnail_id  int 
 );
