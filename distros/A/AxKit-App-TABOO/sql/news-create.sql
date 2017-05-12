CREATE TABLE categories (
	ID	 	SERIAL PRIMARY KEY,
       catname	 	VARCHAR(15) UNIQUE NOT NULL,
       name	 	VARCHAR(30) NOT NULL, 
       type 		CHAR(5) NOT NULL,
       uri	 	VARCHAR(254),
       description 	VARCHAR(254)
);



CREATE TABLE users (
	ID 		SERIAL PRIMARY KEY,
       username		VARCHAR(8) UNIQUE NOT NULL,
       name	 	VARCHAR(30) NOT NULL,
       email	 	VARCHAR(129), 
       uri	 	VARCHAR(254),
       passwd 		CHAR(34)
);


CREATE TABLE contributors (
	Users_ID 	INTEGER UNIQUE NOT NULL REFERENCES users ON DELETE CASCADE ON UPDATE CASCADE,
       username         VARCHAR(8) UNIQUE, /* TODO: remove and change Perl code */
       authlevel 	SMALLINT,
       bio	 	VARCHAR(254)
);

CREATE TABLE stories (
       storyname     VARCHAR(30) NOT NULL,
       sectionid     VARCHAR(15),
       image	     VARCHAR(100),
       primcat	     VARCHAR(15) NOT NULL REFERENCES categories (catname) ON DELETE RESTRICT ON UPDATE CASCADE,
       seccat	     VARCHAR(15)[],
       freesubject   VARCHAR(15)[],
       editorok	     BOOLEAN DEFAULT false,
       title	     VARCHAR(40) NOT NULL,
       minicontent   TEXT,
       content	     TEXT,
       username	     VARCHAR(8) NOT NULL REFERENCES users (username) ON DELETE SET NULL ON UPDATE CASCADE,
       submitterid   VARCHAR(8),
       linktext      VARCHAR(30),
       timestamp     TIMESTAMP NOT NULL,
       lasttimestamp TIMESTAMP NOT NULL,
       PRIMARY KEY (storyname, sectionid)
);
  
 
CREATE TABLE comments (
       commentpath   VARCHAR(254),
       storyname     VARCHAR(12),
       sectionid     VARCHAR(15),
       title	     VARCHAR(40) NOT NULL,
       content	     TEXT,
       timestamp     TIMESTAMP NOT NULL,
       username	     VARCHAR(8) REFERENCES users (username) ON DELETE CASCADE ON UPDATE CASCADE, 
       PRIMARY KEY (commentpath, storyname, sectionid),
       FOREIGN KEY (storyname, sectionid) REFERENCES stories ON DELETE SET NULL ON UPDATE CASCADE       
);

