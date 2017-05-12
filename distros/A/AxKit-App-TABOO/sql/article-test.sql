INSERT INTO mediatypes (mimetype,name) VALUES ( 'text/plain','Text');
INSERT INTO mediatypes (mimetype,name) VALUES ( 'text/html', 'HTML');
INSERT INTO mediatypes (mimetype,name) VALUES ( 'application/xml', 'XML');
INSERT INTO mediatypes (mimetype,name) VALUES ( 'application/xhtml+xml', 'XHTML');
INSERT INTO mediatypes (mimetype,name) VALUES ( 'application/vnd.sun.xml.writer', 'OpenOffice.org Writer');

INSERT INTO languages (code, localname) VALUES ( 'en', 'English');
INSERT INTO languages (code, localname) VALUES ( 'no' , 'Norsk');
INSERT INTO languages (code, localname) VALUES ( 'nb' , 'Bokmål');


INSERT INTO articles (
       filename,
       title,
       description,
       date,
       format_ID,
       lang_ID,
       authorok,
       editorok
) VALUES (
	'thedahuts',
	'The Freedom of the Dahut Hill',
	'Several herds of dahuts lived peacefully on a hill, until they heard the yell.',
	'2005-01-09',
	4,
	1,
	true,
	true
);



INSERT INTO articles (
       filename,
       title,
       description,
       date,
       format_ID,
       lang_ID
) VALUES (
	'dafoooo',
	'The foo of the dahut',
	'An article about the foo of the dahuts.',
	'2005-01-12',
	1,
	1
);

INSERT INTO articlecats (Article_ID, Cat_ID, field) VALUES (1, 2, 'primcat');
INSERT INTO articlecats (Article_ID, Cat_ID, field) VALUES (1, 4, 'seccat');
INSERT INTO articlecats (Article_ID, Cat_ID, field) VALUES (1, 3, 'seccat');

INSERT INTO articlecats (Article_ID, Cat_ID, field) VALUES (2, 4, 'primcat');
INSERT INTO articlecats (Article_ID, Cat_ID, field) VALUES (2, 3, 'seccat');

INSERT INTO articleuserroles (Code, Name) VALUES ('author', 'Author');

INSERT INTO articleusers (Article_ID, Users_ID, Role_ID) VALUES (1, 2, 1);
INSERT INTO articleusers (Article_ID, Users_ID, Role_ID) VALUES (1, 3, 1);
INSERT INTO articleusers (Article_ID, Users_ID, Role_ID) VALUES (2, 5, 1);
