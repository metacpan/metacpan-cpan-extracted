INSERT INTO categories (
       catname,
       name,
       type,
       uri,
       description
)
VALUES ( 
       'subqueue',
       'Innsendte',
       'stsec',
       'http://demo.kjernsmo.net/news/subqueue',
       'Dit innsendte artikler går for godkjennelse'
);

INSERT INTO users (
       username, 
       name,
       email,
       passwd
) 
VALUES (
       'guest',
       'En forbipasserende',
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
