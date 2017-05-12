CREATE TABLE job_times (
  id INTEGER PRIMARY KEY,
  job_id INTEGER,
  year TEXT,
  month TEXT,
  day TEXT,
  hour TEXT,
  minute TEXT,
  weekday TEXT,
  created_on TEXT,
  updated_at TEXT
);
CREATE TABLE jobs (
  id INTEGER PRIMARY KEY,
  user TEXT,
  command TEXT,
  memo TEXT,
  created_on TEXT,
  updated_at TEXT
);
