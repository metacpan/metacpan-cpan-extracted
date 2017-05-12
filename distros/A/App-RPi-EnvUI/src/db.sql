CREATE TABLE IF NOT EXISTS stats (
  id integer primary key autoincrement,
  datetime DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
  temp tinyint(3) not NULL,
  humidity tinyint(3) not NULL
);

DROP TABLE IF EXISTS aux;

CREATE TABLE aux (
    id VARCHAR(4),
    desc VARCHAR(50),
    pin TINYINT(2),
    state TINYINT(1),
    override TINYINT(1),
    on_time INTEGER
);

INSERT INTO aux VALUES ('aux1', 'temp', -1, 0, 0, 0);
INSERT INTO aux VALUES ('aux2', 'humidity', -1, 0, 0, 0);
INSERT INTO aux VALUES ('aux3', 'light', -1, 0, 0, 0);
INSERT INTO aux VALUES ('aux4', '', -1, 0, 0, 0);
INSERT INTO aux VALUES ('aux5', '', -1, 0, 0, 0);
INSERT INTO aux VALUES ('aux6', '', -1, 0, 0, 0);
INSERT INTO aux VALUES ('aux7', '', -1, 0, 0, 0);
INSERT INTO aux VALUES ('aux8', '', -1, 0, 0, 0);

DROP TABLE IF EXISTS control;

CREATE TABLE control (
    id VARCHAR(50),
    value VARCHAR(50)
);

INSERT INTO control VALUES ('temp_limit', 80);
INSERT INTO control VALUES ('humidity_limit', 20);
INSERT INTO control VALUES ('temp_aux_on_time', 1800);
INSERT INTO control VALUES ('humidity_aux_on_time', 1800);

INSERT INTO control VALUES ('temp_aux', 'aux1');
INSERT INTO control VALUES ('humidity_aux', 'aux2');
INSERT INTO control VALUES ('light_aux', 'aux3');

DROP TABLE IF EXISTS core;

CREATE TABLE core (
    id VARCHAR(20),
    value VARCHAR(50)
);

INSERT INTO core VALUES ('event_fetch_timer', 15);
INSERT INTO core VALUES ('event_action_timer', 3);
INSERT INTO core VALUES ('event_display_timer', 4);
INSERT INTO core VALUES ('time_zone', 'America/Edmonton');
INSERT INTO core VALUES ('sensor_pin', -1);
INSERT INTO core VALUES ('testing', 0);
INSERT INTO core VALUES ('debug_sensor', 0);
INSERT INTO core VALUES ('log_file', "");
INSERT INTO core VALUES ('log_level', -1);

DROP TABLE IF EXISTS light;

CREATE TABLE light (
    id VARCHAR(20),
    value VARCHAR(50)
);

INSERT INTO light VALUES ('on_at', '18:00');
INSERT INTO light VALUES ('on_hours', '12');
INSERT INTO light VALUES ('on_time', 0);
INSERT INTO light VALUES ('off_time', 0);
INSERT INTO light VALUES ('toggle', 'disabled');
INSERT INTO light VALUES ('enable', 0);

DROP TABLE IF EXISTS auth;

CREATE TABLE auth (
    user VARCHAR(50),
    pass VARCHAR(50)
);

INSERT INTO auth VALUES ('admin', '{SSHA1}B3WvkiZINyUB1JiP83xQ4evOe9EsrpIK');

