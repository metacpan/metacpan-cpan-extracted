-- Create a fresh and new database

DROP DATABASE IF EXISTS BBSUniversal;
CREATE DATABASE BBSUniversal CHARACTER SET utf8;
USE BBSUniversal;

-- Type       | Maximum length
-- -----------+-------------------------------------
--   TINYTEXT |           255 bytes
--       TEXT |        65,535 bytes = 64 KiB
-- MEDIUMTEXT |    16,777,215 bytes = 16 MiB
--   LONGTEXT | 4,294,967,295 bytes =  4 GiB
-- -----------+-------------------------------------

-- Tables

CREATE TABLE config (
    config_name  VARCHAR(255) PRIMARY KEY,
    config_value VARCHAR(255)
);

CREATE TABLE text_modes (
    id        TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    text_mode ENUM('ASCII', 'ANSI', 'ATASCII', 'PETSCII')
);

CREATE TABLE users (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username        VARCHAR(32) UNIQUE NOT NULL,
    password        CHAR(128) NOT NULL,
    given           VARCHAR(255) NOT NULL,
    family          VARCHAR(255) NOT NULL,
    nickname        VARCHAR(255),
    email           VARCHAR(255) DEFAULT '',
    max_columns     SMALLINT UNSIGNED DEFAULT 80,
    max_rows        SMALLINT UNSIGNED DEFAULT 25,
    accomplishments TEXT,
    retro_systems   TEXT,
    birthday        DATE,
    date_format     ENUM('YEAR/MONTH/DAY','MONTH/DAY/YEAR','DAY/MONTH/YEAR') NOT NULL DEFAULT 'YEAR/MONTH/DAY',
    file_category   INT UNSIGNED NOT NULL DEFAULT 1,
    forum_category  INT UNSIGNED NOT NULL DEFAULT 1,
    rss_category    INT UNSIGNED NOT NULL DEFAULT 1,
    location        VARCHAR(255),
    baud_rate       ENUM('FULL', '115200', '57600', '38400', '19200', '9600', '4800', '2400', '1200', '300') NOT NULL DEFAULT 'FULL',
    access_level    ENUM('USER','VETERAN','JUNIOR SYSOP','SYSOP') NOT NULL DEFAULT 'USER',
    login_time      TIMESTAMP NOT NULL DEFAULT NOW(),
    logout_time     TIMESTAMP NOT NULL DEFAULT NOW(),
    text_mode       TINYINT UNSIGNED NOT NULL
);

CREATE TABLE permissions (
    id              INT UNSIGNED PRIMARY KEY,
    show_email      BOOLEAN DEFAULT FALSE,
    view_files      BOOLEAN DEFAULT FALSE,
    upload_files    BOOLEAN DEFAULT FALSE,
    download_files  BOOLEAN DEFAULT FALSE,
    remove_files    BOOLEAN DEFAULT FALSE,
    read_message    BOOLEAN DEFAULT FALSE,
    post_message    BOOLEAN DEFAULT FALSE,
    remove_message  BOOLEAN DEFAULT FALSE,
    sysop           BOOLEAN DEFAULT FALSE,
    prefer_nickname BOOLEAN DEFAULT FALSE,
    play_fortunes   BOOLEAN DEFAULT TRUE,
    banned          BOOLEAN DEFAULT FALSE,
    timeout         SMALLINT UNSIGNED DEFAULT 10
);

CREATE TABLE message_categories (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    access_level ENUM('USER', 'VETERAN', 'JUNIOR SYSOP', 'SYSOP') NOT NULL DEFAULT 'USER',
    name        VARCHAR(255) NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE messages (
    id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category INT UNSIGNED NOT NULL,
    from_id  INT UNSIGNED NOT NULL,
    title    VARCHAR(255) NOT NULL,
    hidden   BOOLEAN DEFAULT FALSE,
    message  TEXT NOT NULL,
    created  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE rss_feed_categories (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    access_level ENUM('USER', 'VETERAN', 'JUNIOR SYSOP', 'SYSOP') NOT NULL DEFAULT 'USER',
    title        VARCHAR(255) NOT NULL,
    description  VARCHAR(255) NOT NULL
);

CREATE TABLE rss_feeds (
    id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category INT UNSIGNED NOT NULL,
    title    VARCHAR(255) NOT NULL,
    url      VARCHAR(255) NOT NULL
);

CREATE TABLE file_categories (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title       VARCHAR(255) NOT NULL,
	path        VARCHAR(255),
    description TEXT
);

CREATE TABLE files (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    filename     VARCHAR(255) NOT NULL,
    title        VARCHAR(255) NOT NULL,
    user_id      INT UNSIGNED NOT NULL DEFAULT 1,
    category     INT UNSIGNED NOT NULL DEFAULT 1,
    file_type    SMALLINT NOT NULL,
    description  TEXT NOT NULL,
    file_size    BIGINT UNSIGNED NOT NULL,
    uploaded     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    thumbs_up    INT UNSIGNED DEFAULT 0,
    thumbs_down  INT UNSIGNED DEFAULT 0
);

CREATE TABLE file_types (
    id        SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    type      VARCHAR(255),
    extension VARCHAR(5)
);

CREATE TABLE bbs_listing (
    bbs_id        INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    bbs_name      VARCHAR(255) NOT NULL UNIQUE,
    bbs_hostname  VARCHAR(255) NOT NULL UNIQUE,
    bbs_port      SMALLINT UNSIGNED DEFAULT 9999,
    bbs_poster_id INT UNSIGNED NOT NULL
);

CREATE TABLE news (
    news_id      INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    news_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    news_title   VARCHAR(255),
    news_content TEXT
);

-- Views

CREATE VIEW rss_view
 AS
 SELECT
    rss_feeds.id                     AS id,
    rss_feeds.category               AS category,
    rss_feeds.title                  AS title,
    rss_feeds.url                    AS url,
    rss_feed_categories.description  AS category_description,
    rss_feed_categories.title        AS category_title,
    rss_feed_categories.access_level AS access_level
 FROM
    rss_feeds
 INNER JOIN
    rss_feed_categories ON rss_feed_categories.id=rss_feeds.category;

CREATE VIEW users_view
 AS
 SELECT
    users.id                             AS id,
    users.username                       AS username,
    CONCAT(users.given,' ',users.family) AS fullname,
    users.password                       AS password,
    users.given                          AS given,
    users.family                         AS family,
    users.nickname                       AS nickname,
    users.max_columns                    AS max_columns,
    users.max_rows                       AS max_rows,
    users.birthday                       AS birthday,
    users.location                       AS location,
    users.date_format                    AS date_format,
    users.baud_rate                      AS baud_rate,
    users.login_time                     AS login_time,
    users.logout_time                    AS logout_time,
    users.file_category                  AS file_category,
	file_categories.title                AS file_category_title,
	file_categories.path                 AS file_category_path,
    users.forum_category                 AS forum_category,
	message_categories.name              AS forum_category_title,
    users.rss_category                   AS rss_category,
	rss_feed_categories.title            AS rss_category_title,
    users.email                          AS email,
    users.access_level                   AS access_level,
    text_modes.text_mode                 AS text_mode,
    permissions.timeout                  AS timeout,
    users.retro_systems                  AS retro_systems,
    users.accomplishments                AS accomplishments,
    permissions.show_email               AS show_email,
    permissions.prefer_nickname          AS prefer_nickname,
    permissions.view_files               AS view_files,
    permissions.upload_files             AS upload_files,
    permissions.download_files           AS download_files,
    permissions.remove_files             AS remove_files,
    permissions.read_message             AS read_message,
    permissions.post_message             AS post_message,
    permissions.remove_message           AS remove_message,
    permissions.sysop                    AS sysop,
    permissions.play_fortunes            AS play_fortunes,
    permissions.banned                   AS banned
 FROM
    users
 INNER JOIN
    permissions ON users.id=permissions.id
 INNER JOIN
    text_modes ON text_modes.id=users.text_mode
 INNER JOIN
    file_categories ON file_categories.id=users.file_category
 INNER JOIN
    rss_feed_categories ON rss_feed_categories.id=users.rss_category
 INNER JOIN
    message_categories ON message_categories.id=users.forum_category;

CREATE VIEW messages_view
 AS
 SELECT
    messages.id                          AS id,
    messages.from_id                     AS from_id,
    messages.category                    AS category,
    CONCAT(users.given,' ',users.family) AS author_fullname,
    users.nickname                       AS author_nickname,
    users.username                       AS author_username,
    messages.title                       AS title,
    messages.message                     AS message,
    messages.created                     AS created
 FROM
    messages
 LEFT JOIN
    users ON messages.from_id=users.id
 WHERE messages.hidden=FALSE;

CREATE VIEW files_view
AS
SELECT
    files.id                             AS id,
    files.filename                       AS filename,
    files.title                          AS title,
    file_categories.title                AS category,
    file_categories.id                   AS category_id,
	file_categories.path                 AS category_path,
    file_types.type                      AS type,
    file_types.extension                 AS extension,
    files.description                    AS description,
    files.file_size                      AS file_size,
    files.uploaded                       AS uploaded,
    files.thumbs_up                      AS thumbs_up,
    files.thumbs_down                    AS thumbs_down,
    users.username                       AS username,
    users.nickname                       AS nickname,
    permissions.prefer_nickname          AS prefer_nickname,
    CONCAT(users.given,' ',users.family) AS fullname

FROM
    files
INNER JOIN
    file_categories ON files.category=file_categories.id
INNER JOIN
    file_types ON files.file_type=file_types.id
INNER JOIN
    users ON files.user_id=users.id
INNER JOIN
    permissions ON users.id=permissions.id;

CREATE VIEW bbs_listing_view
  AS
  SELECT
    bbs_id         AS bbs_id,
    bbs_name       AS bbs_name,
    bbs_hostname   AS bbs_hostname,
    bbs_port       AS bbs_port,
    users.username AS bbs_poster
  FROM
    bbs_listing
  INNER JOIN
    users ON users.id=bbs_listing.bbs_poster_id;

-- Inserts

INSERT INTO rss_feed_categories (title, description) VALUES ('World News',  'General World News Topics');      -- 1
INSERT INTO rss_feed_categories (title, description) VALUES ('Latest News', 'Latest News Topics');             -- 2
INSERT INTO rss_feed_categories (title, description) VALUES ('Politics',    'General World Political Topics'); -- 3
INSERT INTO rss_feed_categories (title, description) VALUES ('Science',     'General World Science Topics');   -- 4
INSERT INTO rss_feed_categories (title, description) VALUES ('Health',      'General World Health Topics');    -- 5
INSERT INTO rss_feed_categories (title, description) VALUES ('Sports',      'General World Sports Topics');    -- 6
INSERT INTO rss_feed_categories (title, description) VALUES ('Travel',      'General World Travel Topics');    -- 7
INSERT INTO rss_feed_categories (title, description) VALUES ('Opinion',     'General World Opinion Topics');   -- 8
INSERT INTO rss_feed_categories (title, description) VALUES ('General USA', 'General World USA Topics');       -- 9

INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='World News'),  'PJ Media World News',         'https://pjmedia.com/feed');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='World News'),  'Gateway Pundit World News',   'https://www.thegatewaypundit.com/feed/');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='World News'),  'Hot Air World News',          'https://hotair.com/feed');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='World News'),  'Daily Wire World News',       'https://www.dailywire.com/feeds/rss.xml');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='World News'),  'Fox News World News',         'https://moxie.foxnews.com/google-publisher/world.xml');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='World News'),  'The Blaze World News',        'https://www.theblaze.com/feeds/feed.rss');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='Latest News'), 'Fox News Latest News',        'https://moxie.foxnews.com/google-publisher/latest.xml');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='Politics'),    'Fox News Political News',     'https://moxie.foxnews.com/google-publisher/politics.xml');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='World News'),  'Daily Signal World News',     'https://www.dailysignal.com/feed');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='Politics'),    'Daily Signal Political News', 'https://www.dailysignal.com/category/politics-topics/feed');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='Politics'),    'Breitbart Political News',    'https://feeds.feedburner.com/breitbart');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='Politics'),    'NewsMax Political News',      'https://www.newsmax.com/rss/Politics/1/');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='Science'),     'Fox News Science News',       'https://moxie.foxnews.com/google-publisher/science.xml');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='Health'),      'Fox News Health News',        'https://moxie.foxnews.com/google-publisher/health.xml');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='Sports'),      'Fox News Sports News',        'https://moxie.foxnews.com/google-publisher/sports.xml');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='Travel'),      'Fox News Travel News',        'https://moxie.foxnews.com/google-publisher/travel.xml');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='Opinion'),     'Fox News Opinion News',       'https://moxie.foxnews.com/google-publisher/opinion.xml');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='General USA'), 'Fox News USA News',           'https://moxie.foxnews.com/google-publisher/us.xml');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='General USA'), 'American Thinker USA News',   'https://feeds.feedburner.com/AmericanThinkerBlog');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='General USA'), 'NewsBusters USA News',        'https://www.newsbusters.org/blog/feed');
INSERT INTO rss_feeds (category, title, url) VALUES ((SELECT id FROM rss_feed_categories WHERE title='General USA'), 'National Review',             'https://www.nationalreview.com/feed/');

INSERT INTO bbs_listing (bbs_name,bbs_hostname,bbs_port,bbs_poster_id) VALUES ('BBS Universal Sample','localhost',9999,1);

INSERT INTO config (config_name, config_value) VALUES ('HOST',                '0.0.0.0');
INSERT INTO config (config_name, config_value) VALUES ('BBS NAME',            'BBS Universal');
INSERT INTO config (config_name, config_value) VALUES ('PORT',                '9999');
INSERT INTO config (config_name, config_value) VALUES ('BBS ROOT',            '~/source/github/BBS-Universal');
INSERT INTO config (config_name, config_value) VALUES ('DEFAULT BAUD RATE',   'FULL');
INSERT INTO config (config_name, config_value) VALUES ('DEFAULT TEXT MODE',   'ASCII');
INSERT INTO config (config_name, config_value) VALUES ('THREAD MULTIPLIER',   '2');
INSERT INTO config (config_name, config_value) VALUES ('DATE FORMAT',         'YEAR/MONTH/DAY');
INSERT INTO config (config_name, config_value) VALUES ('DEFAULT TIMEOUT',     '10');
INSERT INTO config (config_name, config_value) VALUES ('FILES PATH',          'files/files/');
INSERT INTO config (config_name, config_value) VALUES ('LOGIN TRIES',         '3');
INSERT INTO config (config_name, config_value) VALUES ('MEMCACHED HOST',      'localhost');
INSERT INTO config (config_name, config_value) VALUES ('MEMCACHED PORT',      '11211');
INSERT INTO config (config_name, config_value) VALUES ('MEMCACHED NAMESPACE', 'BBSUniversal::');
INSERT INTO config (config_name, config_value) VALUES ('PLAY SYSOP SOUNDS',   'ON');
INSERT INTO config (config_name, config_value) VALUES ('USE DUF',             'OFF'); -- Use "duf" or instead "df"?
INSERT INTO config (config_name, config_value) VALUES ('SYSOP ANIMATED MENU', 'ON');

INSERT INTO text_modes (text_mode) VALUES ('ASCII');
INSERT INTO text_modes (text_mode) VALUES ('ATASCII');
INSERT INTO text_modes (text_mode) VALUES ('PETSCII');
INSERT INTO text_modes (text_mode) VALUES ('ANSI');

INSERT INTO users (username,nickname,password,given,family,text_mode,baud_rate,accomplishments,retro_systems,birthday,access_level,max_columns,max_rows)
    VALUES (
        'sysop',
        'SysOp',
        SHA2('BBS::Universal',512),
        'System','Operator',
        (SELECT text_modes.id FROM text_modes WHERE text_modes.text_mode='ANSI'),
        'FULL',
        'I manage and maintain this system',
        'Stuff',
        now(),
        'SYSOP',
        264,
        50
    );
INSERT INTO permissions (id,view_files,show_email,upload_files,download_files,remove_files,read_message,post_message,remove_message,sysop,timeout)
    VALUES (
        LAST_INSERT_ID(),
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        65535
    );
INSERT INTO users (username,nickname,password,given,family,text_mode,accomplishments,birthday)
    VALUES (
        'testuser',
        'Testmeister',
        SHA2('test',512),
        'Test','User',
        (SELECT text_modes.id FROM text_modes WHERE text_modes.text_mode='ANSI'),
        'My existence is destined to end soon',
        now()
    );
INSERT INTO permissions (
    id
  )
  VALUES (
      LAST_INSERT_ID()
  );

INSERT INTO message_categories (name,description) VALUES ('General',                       'General Discussion');                      -- 1
INSERT INTO message_categories (name,description) VALUES ('Atari 8 Bit',                   'Atari 400/800/XL/XE/XEGS Computers');      -- 2
INSERT INTO message_categories (name,description) VALUES ('Atari ST/STE',                  'Atari ST/STE Computers');                  -- 3
INSERT INTO message_categories (name,description) VALUES ('Atari TT030',                   'Atari Falcon03 Computers');                -- 4
INSERT INTO message_categories (name,description) VALUES ('Atari Falcon030',               'Atari Falcon03 Computers');                -- 5
INSERT INTO message_categories (name,description) VALUES ('Commodore PET',                 'Commodore PET Computers');                 -- 6
INSERT INTO message_categories (name,description) VALUES ('Commodore VIC-20',              'Commodore VIC-20 Computers');              -- 7
INSERT INTO message_categories (name,description) VALUES ('Commodore C64/128',             'Commodore C64/128 Computers');             -- 8
INSERT INTO message_categories (name,description) VALUES ('Commodore TED',                 'Commodore C16/Plus4 Computers');           -- 9
INSERT INTO message_categories (name,description) VALUES ('Commodore Amiga',               'Commodore Amiga Computers');               -- 10
INSERT INTO message_categories (name,description) VALUES ('Timex/Sinclair ZX81/1000/1500', 'Timex/Sinclair ZX81/1000/1500 Computers'); -- 11
INSERT INTO message_categories (name,description) VALUES ('Timex/Sinclair 2048',           'Timex/Sinclair 2048 Computer');            -- 12
INSERT INTO message_categories (name,description) VALUES ('Timex/Sinclair 2068',           'Timex/Sinclair 2068 Computer');            -- 13
INSERT INTO message_categories (name,description) VALUES ('Amstrad',                       'Amstrad Computers');                       -- 14
INSERT INTO message_categories (name,description) VALUES ('Sinclair ZX-Spectrum',          'Sinclair Research Computers');             -- 15
INSERT INTO message_categories (name,description) VALUES ('Heathkit',                      'Heathkit Computers');                      -- 16
INSERT INTO message_categories (name,description) VALUES ('CP/M',                          'CP/M Computers');                          -- 17
INSERT INTO message_categories (name,description) VALUES ('TRS-80 Portables',              'TRS-80 Model 100/200 Discussion');         -- 18
INSERT INTO message_categories (name,description) VALUES ('TRS-80 Color Computer',         'TRS-80 Color Computer Discussion');        -- 19
INSERT INTO message_categories (name,description) VALUES ('TRS-80 Z80 Models',             'TRS-80 Model 1/II/III/4 Discussion');      -- 20
INSERT INTO message_categories (name,description) VALUES ('TRS-80 68K Models',             'TRS-80 Model 16/6000 Discussion');         -- 21
INSERT INTO message_categories (name,description) VALUES ('Apple ][',                      'Apple ][/Franklin Ace Computers');         -- 22
INSERT INTO message_categories (name,description) VALUES ('Apple Macintosh 680x0',         'Apple Macintosh 680x0 Discussion');        -- 23
INSERT INTO message_categories (name,description) VALUES ('Apple Macintosh PPC',           'Apple Macintosh PowerPC Discussion');      -- 24
INSERT INTO message_categories (name,description) VALUES ('Apple Macintosh OS-X',          'Apple Macintosh OS-X Discussion');         -- 25
INSERT INTO message_categories (name,description) VALUES ('MS-DOS',                        'MS-DOS Discussion');                       -- 26
INSERT INTO message_categories (name,description) VALUES ('Windows 3.xx',                  'Windows 16 Bit Discussion');               -- 27
INSERT INTO message_categories (name,description) VALUES ('Windows NT',                    'Windows NT Discussion');                   -- 28
INSERT INTO message_categories (name,description) VALUES ('Windows 32/64',                 'Windows 32/64 Bit Discussion');            -- 29
INSERT INTO message_categories (name,description) VALUES ('Linux',                         'Linux Discussion');                        -- 30
INSERT INTO message_categories (name,description) VALUES ('FreeBSD',                       'FreeBSD Discussion');                      -- 31
INSERT INTO message_categories (name,description) VALUES ('Texas Instruments',             'Texas Instruments Computers');             -- 32
INSERT INTO message_categories (name,description) VALUES ('Homebrew',                      'Homebrew Computers');                      -- 33
INSERT INTO message_categories (name,description) VALUES ('BBC Acorn',                     'BBC Acorn Discussion');                    -- 34
INSERT INTO message_categories (name,description) VALUES ('BBC Micro',                     'BBC Micro Discussion');                    -- 35
INSERT INTO message_categories (name,description) VALUES ('MSX',                           'MSX Computers');                           -- 36
INSERT INTO message_categories (name,description) VALUES ('Wang',                          'Wang Computers');                          -- 37
INSERT INTO message_categories (name,description) VALUES ('Oric',                          'Oric Computers');                          -- 38
INSERT INTO message_categories (name,description) VALUES ('Tektronix',                     'Tektronics Computers');                    -- 39

INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='General'),                       (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Atari 8 Bit'),                   (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Atari ST/STE'),                  (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Atari TT030'),                   (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Atari Falcon030'),               (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Commodore PET'),                 (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Commodore VIC-20'),              (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Commodore C64/128'),             (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Commodore TED'),                 (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Commodore Amiga'),               (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Timex/Sinclair ZX81/1000/1500'), (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Timex/Sinclair 2048'),           (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Timex/Sinclair 2068'),           (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Amstrad'),                       (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Sinclair ZX-Spectrum'),          (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Heathkit'),                      (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='CP/M'),                          (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='TRS-80 Portables'),              (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='TRS-80 Color Computer'),         (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='TRS-80 Z80 Models'),             (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='TRS-80 68K Models'),             (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Apple ]['),                      (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Apple Macintosh 680x0'),         (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Apple Macintosh PPC'),           (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Apple Macintosh OS-X'),          (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='MS-DOS'),                        (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Windows 3.xx'),                  (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Windows NT'),                    (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Windows 32/64'),                 (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Linux'),                         (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='FreeBSD'),                       (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Texas Instruments'),             (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Homebrew'),                      (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='BBC Acorn'),                     (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='BBC Micro'),                     (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='MSX'),                           (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Wang'),                          (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Oric'),                          (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');
INSERT INTO messages (category,from_id,title,message) VALUES ((SELECT id FROM message_categories WHERE name='Tektronix'),                     (SELECT id FROM users WHERE username='sysop'), 'First (test) Message', 'This is the first message, which can be deleted by the SysOp');

INSERT INTO file_types (type, extension) VALUES ('Plain Text',                                          'TXT');
INSERT INTO file_types (type, extension) VALUES ('ASCII Text',                                          'ASC');
INSERT INTO file_types (type, extension) VALUES ('Atari ATASCII Text',                                  'ATA');
INSERT INTO file_types (type, extension) VALUES ('Commodore PETSCII Text',                              'PET');
INSERT INTO file_types (type, extension) VALUES ('DEC VT-102 Text',                                     'VT');
INSERT INTO file_types (type, extension) VALUES ('ANSI Text',                                           'ANS');
INSERT INTO file_types (type, extension) VALUES ('GitHub Markdown Text',                                'MD');
INSERT INTO file_types (type, extension) VALUES ('Rich Text File',                                      'RTF');
INSERT INTO file_types (type, extension) VALUES ('Information File',                                    'INF');
INSERT INTO file_types (type, extension) VALUES ('Configuration File',                                  'CFG');
INSERT INTO file_types (type, extension) VALUES ('Microsoft Word Document',                             'DOC');
INSERT INTO file_types (type, extension) VALUES ('Microsoft Word Document',                             'DOCX');
INSERT INTO file_types (type, extension) VALUES ('Perl Script',                                         'PL');
INSERT INTO file_types (type, extension) VALUES ('Perl Module',                                         'PM');
INSERT INTO file_types (type, extension) VALUES ('Python Script',                                       'PY');
INSERT INTO file_types (type, extension) VALUES ('C Source',                                            'C');
INSERT INTO file_types (type, extension) VALUES ('C++ Source',                                          'CPP');
INSERT INTO file_types (type, extension) VALUES ('C Include',                                           'H');
INSERT INTO file_types (type, extension) VALUES ('C-Shell Script',                                      'SH');
INSERT INTO file_types (type, extension) VALUES ('Cascading Style Sheet',                               'CSS');
INSERT INTO file_types (type, extension) VALUES ('Hypter-Text Markup Language',                         'HTM');
INSERT INTO file_types (type, extension) VALUES ('Hypter-Text Markup Language',                         'HTML');
INSERT INTO file_types (type, extension) VALUES ('Special Hypter-Text Markup Language',                 'SHTML');
INSERT INTO file_types (type, extension) VALUES ('Javascript',                                          'JS');
INSERT INTO file_types (type, extension) VALUES ('Java Source',                                         'JAVA');
INSERT INTO file_types (type, extension) VALUES ('Macintosh File Descriptor',                           'DS');

INSERT INTO file_types (type, extension) VALUES ('Portable Network Graphics Image',                     'PNG');
INSERT INTO file_types (type, extension) VALUES ('JPEG Image',                                          'JPG');
INSERT INTO file_types (type, extension) VALUES ('CompuServe Graphics Interchange Format Image',        'GIF');
INSERT INTO file_types (type, extension) VALUES ('JPEG Image',                                          'JPEG');
INSERT INTO file_types (type, extension) VALUES ('Tagged Image File Format Image',                      'TIFF');
INSERT INTO file_types (type, extension) VALUES ('Targa Image',                                         'TGA');
INSERT INTO file_types (type, extension) VALUES ('Web Image',                                           'WEBP');
INSERT INTO file_types (type, extension) VALUES ('Icon',                                                'ICO');

INSERT INTO file_types (type, extension) VALUES ('MPEG 4 Video',                                        'MP4');
INSERT INTO file_types (type, extension) VALUES ('Matroska Packaged Video',                             'MKV');
INSERT INTO file_types (type, extension) VALUES ('Audio Video Interchange Video',                       'AVI');
INSERT INTO file_types (type, extension) VALUES ('MPEG 4 Video',                                        'MPV');
INSERT INTO file_types (type, extension) VALUES ('MPEG 2 Video',                                        'MPG');
INSERT INTO file_types (type, extension) VALUES ('Motion JPEG Video',                                   'MJPG');

INSERT INTO file_types (type, extension) VALUES ('MPEG 2 Layer 3 Audio',                                'MP3');
INSERT INTO file_types (type, extension) VALUES ('Advanced Audio Coding Audio',                         'AAC');
INSERT INTO file_types (type, extension) VALUES ('Windows Audio',                                       'WAV');
INSERT INTO file_types (type, extension) VALUES ('Windows Media Audio',                                 'WMA');
INSERT INTO file_types (type, extension) VALUES ('Free Lossless Audio Compression Audio',               'FLAC');
INSERT INTO file_types (type, extension) VALUES ('Musical Instrument Digital Interface Audio',          'MID');
INSERT INTO file_types (type, extension) VALUES ('Tracker Audio',                                       'TRK');
INSERT INTO file_types (type, extension) VALUES ('Tracker Audio',                                       'MOD');

INSERT INTO file_types (type, extension) VALUES ('Atari 400/800/XL/XE Disk Image',                      'ATR');
INSERT INTO file_types (type, extension) VALUES ('Atari 400/800/XL/XE Binary Executable',               'XEX');
INSERT INTO file_types (type, extension) VALUES ('Atari ST/STE/TT/Falcon GEM Program',                  'PRG');
INSERT INTO file_types (type, extension) VALUES ('Atari ST/STE/TT/Falcon TOS Program',                  'TOS');
INSERT INTO file_types (type, extension) VALUES ('Atari ST/STE/TT/Falcon TOS Takes Parameters Program', 'TTP');
INSERT INTO file_types (type, extension) VALUES ('Atari ST/STE/TT/Falcon Desk Accessory',               'ACC');
INSERT INTO file_types (type, extension) VALUES ('Atari ST/STE/TT/Falcon Extendable Desk Accessory',    'CPX');
INSERT INTO file_types (type, extension) VALUES ('Atari ST/STE/TT/Falcon Menu Resource',                'RSC');

INSERT INTO file_types (type, extension) VALUES ('7-Zip Compressed',                                    '7Z');
INSERT INTO file_types (type, extension) VALUES ('Zip Compressed',                                      'ZIP');
INSERT INTO file_types (type, extension) VALUES ('RAR Compressed',                                      'RAR');
INSERT INTO file_types (type, extension) VALUES ('Compressed Archive',                                  'ARC');
INSERT INTO file_types (type, extension) VALUES ('TAR Archive Compressed',                              'TGZ');
INSERT INTO file_types (type, extension) VALUES ('TAR Archive',                                         'TAR');
INSERT INTO file_types (type, extension) VALUES ('GZip Compressed',                                     'GZ');

INSERT INTO file_types (type, extension) VALUES ('Excel',                                               'XLS');
INSERT INTO file_types (type, extension) VALUES ('eXtensibe Markup Language',                           'XML');

INSERT INTO file_types (type, extension) VALUES ('MS-DOS Command Executable',                           'COM');
INSERT INTO file_types (type, extension) VALUES ('MS-DOS Batch',                                        'BAT');
INSERT INTO file_types (type, extension) VALUES ('MS-DOS/Windows Executable',                           'EXE');

INSERT INTO file_categories (title,description,path) VALUES ('BBS::Universal Specific',       'All Files Relating to BBS Universal', 'BBS');                   -- 1
INSERT INTO file_categories (title,description,path) VALUES ('General',                       'General Files',                       'General');               -- 2
INSERT INTO file_categories (title,description,path) VALUES ('Atari 8 Bit',                   'Atari 400/800/XL/XE/XEGS Files',      'A800');                  -- 3
INSERT INTO file_categories (title,description,path) VALUES ('Atari ST/STE',                  'Atari ST/STE Files',                  'Atari-ST');              -- 4
INSERT INTO file_categories (title,description,path) VALUES ('Atari TT030',                   'Atari TT030 Files',                   'Atari-TT');              -- 5
INSERT INTO file_categories (title,description,path) VALUES ('Atari Falcon030',               'Atari Falcon030 Files',               'Atari-Falcon');          -- 6
INSERT INTO file_categories (title,description,path) VALUES ('Commodore PET',                 'Commodore PET Files',                 'Commoedore-PET');        -- 7
INSERT INTO file_categories (title,description,path) VALUES ('Commodore VIC-20',              'Commodore VIC-20 Files',              'Commodore-VIC20');       -- 8
INSERT INTO file_categories (title,description,path) VALUES ('Commodore C64/128',             'Commodore C64/128 Files',             'Commodore-C64');         -- 9
INSERT INTO file_categories (title,description,path) VALUES ('Commodore TED',                 'Commodore C16/Plus4 Files',           'Commodore-TED');         -- 10
INSERT INTO file_categories (title,description,path) VALUES ('Commodore Amiga',               'Commodore Amiga Files',               'Commodore-Amiga');       -- 11
INSERT INTO file_categories (title,description,path) VALUES ('Timex/Sinclair ZX81/1000/1500', 'Timex/Sinclair ZX81/1000/1500 Files', 'TS-1000');               -- 12
INSERT INTO file_categories (title,description,path) VALUES ('Timex/Sinclair 2048',           'Timex/Sinclair 2048 Files',           'TS-2048');               -- 13
INSERT INTO file_categories (title,description,path) VALUES ('Timex/Sinclair 2068',           'Timex/Sinclair 2068 Files',           'TS-2068');               -- 14
INSERT INTO file_categories (title,description,path) VALUES ('Sinclair Spectrum',             'Sinclair Spectrum Files',             'ZX-Spectrum');           -- 15
INSERT INTO file_categories (title,description,path) VALUES ('Heathkit',                      'Heathkit Files',                      'Heathkit');              -- 16
INSERT INTO file_categories (title,description,path) VALUES ('CP/M',                          'CP/M Files',                          'CP-M');                  -- 17
INSERT INTO file_categories (title,description,path) VALUES ('TRS-80 CoCo',                   'TRS-80 Color Computer Files',         'TRS-80-CoCo');           -- 18
INSERT INTO file_categories (title,description,path) VALUES ('TRS-80 Portables',              'TRS-80 Model 100/200 Files',          'TRS-80-Portables');      -- 19
INSERT INTO file_categories (title,description,path) VALUES ('TRS-80 Z80',                    'TRS-80 Model I/II/III/4 Files',       'TRS-80-Z80');            -- 20
INSERT INTO file_categories (title,description,path) VALUES ('TRS-80 68000',                  'TRS-80 Model 16/6000 Files',          'TRS-80-68000');          -- 21
INSERT INTO file_categories (title,description,path) VALUES ('Apple ][',                      'Apple ][/Franklin Ace Files',         'Apple-II');              -- 22
INSERT INTO file_categories (title,description,path) VALUES ('Apple Macintosh 680x0',         'Macintosh 68000 Files',               'Apple-Macintosh-68000'); -- 23
INSERT INTO file_categories (title,description,path) VALUES ('Apple Macintosh PPC',           'Macintosh PowerPC Files',             'Apple-Macintosh-PPC');   -- 24
INSERT INTO file_categories (title,description,path) VALUES ('Apple Macintosh OS-X',          'Macintosh OS-X Files',                'Apple-Macintosh-OS-X');  -- 25
INSERT INTO file_categories (title,description,path) VALUES ('MS-DOS',                        'MS-DOS Files',                        'MS-DOS');                -- 26
INSERT INTO file_categories (title,description,path) VALUES ('Windows 3.xx',                  'Windows 16 Bit Files',                'Win-3.11');              -- 27
INSERT INTO file_categories (title,description,path) VALUES ('Windows NT',                    'Windows NT Files',                    'Win-NT');                -- 28
INSERT INTO file_categories (title,description,path) VALUES ('Windows 32/64 Bit',             'Windows 32/64 Bit Files',             'Modern-Windows');        -- 29
INSERT INTO file_categories (title,description,path) VALUES ('Linux',                         'Linux Files',                         'Linux');                 -- 30
INSERT INTO file_categories (title,description,path) VALUES ('FreeBSD',                       'FreeBSD Files',                       'FreeBSD');               -- 31
INSERT INTO file_categories (title,description,path) VALUES ('Homebrew',                      'Homebrew Files',                      'Homebrew');              -- 32
INSERT INTO file_categories (title,description,path) VALUES ('MSX',                           'MSX Files',                           'MSX');                   -- 33
INSERT INTO file_categories (title,description,path) VALUES ('Wang',                          'Wang Files',                          'Wang');                  -- 34
INSERT INTO file_categories (title,description,path) VALUES ('Oric',                          'Oric Files',                          'Oric');                  -- 35
INSERT INTO file_categories (title,description,path) VALUES ('Tektronix',                     'Tektronix Files',                     'Tektronix');             -- 36

INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="BBS::Universal Specific"),       'BBS_Universal.png','BBS::Universal Logo',(SELECT id FROM file_types WHERE extension='PNG'),'The BBS::Universal Logo in PNG format', 148513);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="BBS::Universal Specific"),       'BBS_Universal_banner.vt','ANSI BBS::Universal Logo',(SELECT id FROM file_types WHERE extension='VT'),'The BBS::Universal Logo in ANSI format', 533);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="General"),                       'usa.ans','ANSI Token File USA',(SELECT id FROM file_types WHERE extension='ANS'),'USA in USA Themed Font in ANSI Token Format', 5303);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="Sinclair Spectrum"),             'sinclair.ans','ANSI Token File Sinclair Logo',(SELECT id FROM file_types WHERE extension='ANS'),'Sinclair Logo in ANSI Token Format', 6447);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="Timex/Sinclair ZX81/1000/1500"), 'timex-sinclair.ans','ANSI Token File Timex/Sinclair Logo',(SELECT id FROM file_types WHERE extension='ANS'),'Timex/Sinclair Logo in ANSI Token Format', 4206);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="Timex/Sinclair ZX81/1000/1500"), 'timex-sinclair-1000.ans','ANSI Token File Timex/Sinclair 1000 Logo',(SELECT id FROM file_types WHERE extension='ANS'),'Timex/Sinclair 1000 Logo in ANSI Token Format', 5109);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="Timex/Sinclair ZX81/1000/1500"), 'timex-sinclair-1500.ans','ANSI Token File Timex/Sinclair 1500 Logo',(SELECT id FROM file_types WHERE extension='ANS'),'Timex/Sinclair 1500 Logo in ANSI Token Format', 5582);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="Timex/Sinclair 2048"),           'timex-sinclair-2048.ans','ANSI Token File Timex/Sinclair 2048 Logo',(SELECT id FROM file_types WHERE extension='ANS'),'Timex/Sinclair 2048 Logo in ANSI Token Format', 5151);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="Timex/Sinclair 2068"),           'timex-sinclair-2068.ans','ANSI Token File Timex/Sinclair 2068 Logo',(SELECT id FROM file_types WHERE extension='ANS'),'Timex/Sinclair 2068 Logo in ANSI Token Format', 5179);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="Linux"),                         'linux.vt','ANSI Linux Logo',(SELECT id FROM file_types WHERE extension='VT'),'Linux logo in ANSI format', 2650);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="Linux"),                         'Linux.png','Linux Penguin Logo',(SELECT id FROM file_types WHERE extension='PNG'),'Linux penguin logo in PNG format', 13381);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="MS-DOS"),                        'ms-dos.png','MS-DOS Logo',(SELECT id FROM file_types WHERE extension='PNG'),'Linux logo in PNG format', 377300);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="MS-DOS"),                        'ibm.jpg','IBM Logo',(SELECT id FROM file_types WHERE extension='JPG'),'IBM logo in JPEG format', 95944);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="MS-DOS"),                        'ibm-white.jpg','IBM Logo',(SELECT id FROM file_types WHERE extension='JPG'),'IBM logo with white background in JPEG format', 145312);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="MS-DOS"),                        'ms-dos.ans','MS-DOS Logo',(SELECT id FROM file_types WHERE extension='ANS'),'MS-DOS logo in ANSI markup format', 1383);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="MSX"),                           'msx.png','MSX Logo',(SELECT id FROM file_types WHERE extension='PNG'),'MSX logo in PNG format', 15518);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="TRS-80 CoCo"),                   'coco-logo.jpg','TRS-80 CoCo Logo',(SELECT id FROM file_types WHERE extension='JPG'),'Coco logo in JPEG format', 49501);
INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES ((SELECT id FROM file_categories WHERE title="Tektronix"),                     'tektronix-logo.jpg','Tektronix Logo',(SELECT id FROM file_types WHERE extension='JPG'),'Tektronix logo in JPEG format', 54515);

INSERT INTO news (news_title,news_content) VALUES ('BBS Universal Installation','BBS::Universal, written by Richard Kelsch, a Perl based BBS server designed for retro and modern computers has been installed on this server.');

-- END
