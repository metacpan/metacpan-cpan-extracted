INSERT INTO categories (
       catname,
       type,
       name,
       uri,
       description
)
VALUES ( 
       'felines',
       'categ',
       'Catcategory',
       'http://dev.kjernsmo.net/cats/felines',
       'This is a cat about felines'
);

INSERT INTO categories (
       catname,
       type,
       name,
       uri,
       description
)
VALUES ( 
       'kittens',
       'categ',
       'Kittens',
       'http://dev.kjernsmo.net/cats/kittens',
       'Cats are cute when small'
);


INSERT INTO categories (
       catname,
       type,
       name,
       uri,
       description
)
VALUES ( 
       'cats',
       'categ',
       'Another Cats category',
       'http://dev.kjernsmo.net/cats/cats',
       'This is a cat about cats'
);


INSERT INTO categories (
       catname,
       type,
       name
)
VALUES ( 
       'test1',
       'frees',
       'Free Subject test 1'
);


INSERT INTO categories (
       catname,
       type,
       name,
       uri,
       description
)
VALUES ( 
       'test2',
       'frees',
       'Free Subject test 2',
       'http://dev.kjernsmo.net/test1',
       'Test 2'
);

INSERT INTO categories (
       catname,
       type,
       name,
       uri,
       description
)
VALUES ( 
       'testsec',
       'stsec',
       'Test Section',
       'http://localhost/news/testsec',
       'Just Tessting'
);

INSERT INTO categories (
       catname,
       name,
       type,
       uri,
       description
)
VALUES ( 
       'features',
       'Features',
       'stsec',
       'http://localhost/news/features',
       'The really nice feature articles'
);




INSERT INTO users (
       username, 
       name,
       email,
       uri,
       passwd
) 
VALUES (
       'kjetil',
       'Kjetil Kjernsmo',
       'kjetil@kjernsmo.net',
       'http://www.kjetil.kjernsmo.net/',
       '$1$1ee9HLjU$7/gwrsXwt0UDEjyIDhiz8.'
);

INSERT INTO users (
       username, 
       name,
       email,
       uri,
       passwd
) 
VALUES (
       'foo',
       'Foo',
       'foo@example.com',
       'http://www.example.com/foo/',
       '$1$1ee9HLjU$7/gwrsXwt0UDEjyIDhiz8.'
);


INSERT INTO users (
       username, 
       name,
       uri,
       passwd
) 
VALUES (
       'bar',
       'Bar',
       'http://www.example.com/bar',
       '$1$1ee9HLjU$7/gwrsXwt0UDEjyIDhiz8.'
);

INSERT INTO users (
       username, 
       name,
       email,
       uri,
       passwd
) 
VALUES (
       'foobar',
       'Foo Bar',
       'foobar@foobar.org',
       'http://www.foobar.org/',
       '$1$1ee9HLjU$7/gwrsXwt0UDEjyIDhiz8.'
);



INSERT INTO contributors (
	Users_ID,	
       username, 
       authlevel,
       bio
) 
VALUES (
	2,
       'kjetil',
       9,
       'TABOO developer'
);

INSERT INTO contributors (
       Users_ID,
	username, 
       authlevel,
       bio
) 
VALUES (
	3,
       'foo',
       1,
       'We all know Foo'
);


INSERT INTO contributors (
       Users_ID,
	username, 
       authlevel,
       bio
) 
VALUES (
	4,
       'bar',
       5,
       'Bar is an well known editor'
);

INSERT INTO contributors (
	Users_ID,
       username, 
       authlevel
) 
VALUES (
	5,
       'foobar',
       1
);





  
INSERT INTO stories (
       storyname,
       sectionid,
       primcat,
       title,
       content,
       username,
       submitterid,
       timestamp,
       lasttimestamp
) 
VALUES (
       'coolhack',
       'features',
       'cats',
       'Article about Cool Hacks',
       'Once upon a time, there was this really cool hack',
       'kjetil',
       'kjetil',
       '20030209',
       '20030227'
);



INSERT INTO stories (
       storyname,
       sectionid,
       primcat,
       seccat,
       freesubject,
       title,
       content,
       username,
       submitterid,
       timestamp,
       lasttimestamp
) 
VALUES (
       'smallcats',
       'features',
       'felines',
       '{"kittens","cats"}',
       '{"test1","test2"}',
       'Interesting post about smaller cats.',
       'There are a bunch of small cats running around out there.',
       'kjetil',
       'foobar',
       '20031205',
       '20031211'
);





INSERT INTO comments (
       commentpath,
       storyname,
       sectionid,
       title,
       content,
       timestamp,
       username
) 
VALUES (
       '/foo',
       'coolhack',
       'features',
       'Comment title',
       'Yeah, that was cool!',
       '20020210',
       'foo'
);


INSERT INTO comments (
       commentpath,
       storyname,
       sectionid,
       title,
       content,
       timestamp,
       username
) 
VALUES (
       '/foo/bar',
       'coolhack',
       'features',
       'Huh, what?',
       'aint seen a thing!',
       '20030219',
       'bar'
);


INSERT INTO comments (
       commentpath,
       storyname,
       sectionid,
       title,
       content,
       timestamp,
       username
) 
VALUES (
       '/foo/foobar',
       'coolhack',
       'features',
       'Re: Comment title',
       'Yeah, agreed',
       '20030222',
       'foobar'
);



INSERT INTO comments (
       commentpath,
       storyname,
       sectionid,
       title,
       content,
       timestamp,
       username
) 
VALUES (
       '/foo/foobar/foo',
       'coolhack',
       'features',
       'Re: Huh',
       'The hack! That was cool!',
       '20030227',
       'foo'
);


INSERT INTO comments (
       commentpath,
       storyname,
       sectionid,
       title,
       content,
       timestamp,
       username
) 
VALUES (
       '/bar',
       'coolhack',
       'features',
       'Whaddayamean?',
       'Am I blind, or is this story devoid of content?',
       '20030307',
       'bar'
);


INSERT INTO comments (
       commentpath,
       storyname,
       sectionid,
       title,
       content,
       timestamp,
       username
) 
VALUES (
       '/bar/kjetil',
       'coolhack',
       'features',
       'Editors comment',
       'Well, it is not easy to see, but...',
       '20030310',
       'kjetil'
);


INSERT INTO comments (
       commentpath,
       storyname,
       sectionid,
       title,
       content,
       timestamp,
       username
) 
VALUES (
       '/foo',
       'smallcats',
       'features',
       'The point is:',
       'Check out the expanded category info',
       '20031211',
       'foo'
);

