CREATE TABLE IF NOT EXISTS email_content_type (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
);

INSERT INTO email_content_type (name) VALUES ('multipart/alternative');
INSERT INTO email_content_type (name) VALUES ('text/plain');
INSERT INTO email_content_type (name) VALUES ('multipart/related');

CREATE TABLE IF NOT EXISTS spam_age_unit (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
);

INSERT INTO spam_age_unit (name) VALUES ('hour');

CREATE TABLE IF NOT EXISTS email_charset (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
);

INSERT INTO email_charset (name) VALUES ('charset="utf-8"');

CREATE TABLE IF NOT EXISTS receiver (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL UNIQUE
);

INSERT INTO receiver (email) VALUES ('google-abuse-bounces-reports');
INSERT INTO receiver (email) VALUES ('report_spam@hotmail.com');
INSERT INTO receiver (email) VALUES ('junk@office365.microsoft.com');
INSERT INTO receiver (email) VALUES ('abuse@messaging.microsoft.com');
INSERT INTO receiver (email) VALUES ('abuse#fb.com');

CREATE TABLE IF NOT EXISTS mailer (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
);

INSERT INTO mailer (name) VALUES ('Microsoft Outlook Express 6.00.2600.0000');

CREATE TABLE IF NOT EXISTS summary (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tracking_id TEXT NOT NULL UNIQUE,
  charset_id INTEGER REFERENCES email_charset ON DELETE SET NULL,
  content_type_id INTEGER REFERENCES email_content_type ON DELETE SET NULL,
  age INTEGER NOT NULL,
  age_unit_id INTEGER REFERENCES spam_age_unit ON DELETE SET NULL,
  mailer_id INTEGER REFERENCES mailer ON DELETE SET NULL
);

INSERT INTO summary (tracking_id, charset_id, content_type_id, age, age_unit_id, mailer_id) VALUES ('z6742106109ze8cbd2f6e81334cc1c8682b7e7c9b58fz', 1, 1, 5, 1, NULL);
INSERT INTO summary (tracking_id, charset_id, content_type_id, age, age_unit_id, mailer_id) VALUES ('z6742106110zffc0d6c9bb564d5bf8bb22ca282af66dz', 1, 1, 5, 1, NULL);
INSERT INTO summary (tracking_id, charset_id, content_type_id, age, age_unit_id, mailer_id) VALUES ('z6742944580zfe37d21f97cab7d3e8394912145a9aafz', 1, 1, 5, 1, NULL);
INSERT INTO summary (tracking_id, charset_id, content_type_id, age, age_unit_id, mailer_id) VALUES ('z6743111617z1b645133fa4367cb74765405c24c28eaz', 1, 1, 5, 1, NULL);
INSERT INTO summary (tracking_id, charset_id, content_type_id, age, age_unit_id, mailer_id) VALUES ('z6743499574z7a61bbadf8821e6fd2af587ee2d4e537z', NULL, 3, 10, 1, NULL);
INSERT INTO summary (tracking_id, charset_id, content_type_id, age, age_unit_id, mailer_id) VALUES ('z6743684709z88f10da224f2ae9265d9c322316e16bez', NULL, 2, 2, 1, NULL);
INSERT INTO summary (tracking_id, charset_id, content_type_id, age, age_unit_id, mailer_id) VALUES ('z6744705191z2012f4340223a465e5f95056c53207aez', NULL, 1, 1, 1, 1);
INSERT INTO summary (tracking_id, charset_id, content_type_id, age, age_unit_id, mailer_id) VALUES ('z6745481679z8e9de95700b40206ecf5662680f1d6e6z', 1, 1, 0, 1, NULL);

CREATE TABLE IF NOT EXISTS summary_receiver (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  summary_id INTEGER REFERENCES summary ON DELETE CASCADE,
  receiver_id INTEGER REFERENCES receiver ON DELETE CASCADE,
  report_id TEXT UNIQUE
);

INSERT INTO summary_receiver (summary_id, receiver_id, report_id) VALUES(
  (SELECT id FROM summary WHERE tracking_id='z6742106109ze8cbd2f6e81334cc1c8682b7e7c9b58fz'),
  (SELECT id FROM receiver WHERE email = 'google-abuse-bounces-reports'),
  NULL
);
INSERT INTO summary_receiver (summary_id, receiver_id, report_id) VALUES(
  (SELECT id FROM summary WHERE tracking_id='z6742106110zffc0d6c9bb564d5bf8bb22ca282af66dz'),
  (SELECT id FROM receiver WHERE email = 'google-abuse-bounces-reports'),
  NULL
);
INSERT INTO summary_receiver (summary_id, receiver_id, report_id) VALUES(
  (SELECT id FROM summary WHERE tracking_id='z6742944580zfe37d21f97cab7d3e8394912145a9aafz'),
  (SELECT id FROM receiver WHERE email = 'google-abuse-bounces-reports'),
  NULL
);
INSERT INTO summary_receiver (summary_id, receiver_id, report_id) VALUES(
  (SELECT id FROM summary WHERE tracking_id='z6743111617z1b645133fa4367cb74765405c24c28eaz'),
  (SELECT id FROM receiver WHERE email = 'google-abuse-bounces-reports'),
  NULL
);
INSERT INTO summary_receiver (summary_id, receiver_id, report_id) VALUES(
  (SELECT id FROM summary WHERE tracking_id='z6743499574z7a61bbadf8821e6fd2af587ee2d4e537z'),
  (SELECT id FROM receiver WHERE email = 'abuse@messaging.microsoft.com'),
  '7170289303'
);
INSERT INTO summary_receiver (summary_id, receiver_id, report_id) VALUES(
  (SELECT id FROM summary WHERE tracking_id='z6743499574z7a61bbadf8821e6fd2af587ee2d4e537z'),
  (SELECT id FROM receiver WHERE email = 'junk@office365.microsoft.com'),
  '7170289302'
);
INSERT INTO summary_receiver (summary_id, receiver_id, report_id) VALUES(
  (SELECT id FROM summary WHERE tracking_id='z6743499574z7a61bbadf8821e6fd2af587ee2d4e537z'),
  (SELECT id FROM receiver WHERE email = 'report_spam@hotmail.com'),
  '7170289301'
);
INSERT INTO summary_receiver (summary_id, receiver_id, report_id) VALUES(
  (SELECT id FROM summary WHERE tracking_id='z6743499574z7a61bbadf8821e6fd2af587ee2d4e537z'),
  (SELECT id FROM receiver WHERE email = 'abuse#fb.com'),
  NULL
);
INSERT INTO summary_receiver (summary_id, receiver_id, report_id) VALUES(
  (SELECT id FROM summary WHERE tracking_id='z6743684709z88f10da224f2ae9265d9c322316e16bez'),
  (SELECT id FROM receiver WHERE email = 'google-abuse-bounces-reports'),
  NULL
);
INSERT INTO summary_receiver (summary_id, receiver_id, report_id) VALUES(
  (SELECT id FROM summary WHERE tracking_id='z6744705191z2012f4340223a465e5f95056c53207aez'),
  (SELECT id FROM receiver WHERE email = 'abuse@retail.telecomitalia.it'),
  '7172109956'
);
INSERT INTO summary_receiver (summary_id, receiver_id, report_id) VALUES(
  (SELECT id FROM summary WHERE tracking_id='z6744705191z2012f4340223a465e5f95056c53207aez'),
  (SELECT id FROM receiver WHERE email = 'cop_report@alice.it'),
  '7172109955'
);
INSERT INTO summary_receiver (summary_id, receiver_id, report_id) VALUES(
  (SELECT id FROM summary WHERE tracking_id='z6744705191z2012f4340223a465e5f95056c53207aez'),
  (SELECT id FROM receiver WHERE email = 'abuse@datacamp.co.uk'),
  '7172109954'
);

INSERT INTO summary_receiver (summary_id, receiver_id, report_id) VALUES(
  (SELECT id FROM summary WHERE tracking_id='z6745481679z8e9de95700b40206ecf5662680f1d6e6z'),
  (SELECT id FROM receiver WHERE email = 'google-abuse-bounces-reports'),
  NULL
);
