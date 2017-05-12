INSERT INTO categories (
       catname,
       name,
       type,
       uri,
       description
)
VALUES ( 
       'subqueue',
       'Submission Queue',
       'stsec',
       'http://demo.kjernsmo.net/news/subqueue',
       'Where submissions go for approval'
);

INSERT INTO users (
       username, 
       name,
       email,
       passwd
) 
VALUES (
       'guest',
       'A passer-by',
       'nobody@taboo.invalid',
       '$1$AAH/cKYw$bw8soWkaoYUnWwLKlmxLz1'
);

INSERT INTO contributors (
	Users_ID, 
      username, 
       authlevel
) 
VALUES (
	1,
       'guest',
       0
);
