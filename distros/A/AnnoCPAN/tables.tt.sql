[% 
    # define the id. It has to auto-increment 
    IF db == 'mysql';
        id = 'id          integer not null auto_increment primary key';
        index_len = 1;
    ELSE;
        # this works for sqlite. I do not know about others
        id = 'id          integer not null primary key';
    END;
%]
create table dist (
    [% id %],
    name            varchar(255),
    rating          integer,
    review_count    integer,
    creation_time   integer
);
create index name_index on dist(name[% "(10)" IF index_len %]);

create table distver (
    [% id %],
    dist        integer,
    version     varchar(255),
    maturity    integer,
    path        varchar(255),
    distver     varchar(255),
    mtime       integer,
    -- pause_author    integer,
    pause_id    varchar(255)
);
create index dist_index on distver(dist);
create index distver_index on distver(distver[% "(10)" IF index_len %]);
create index distver_path_index on distver(path[% "(24)" IF index_len %]);
create index pause_id_index on distver(pause_id[% "(4)" IF index_len %]);

create table pod (
    [% id %],
    name        varchar(255)
);
create index pod_index on pod(name);

create table pod_dist (
    [% id %],
    dist        integer,
  --  name        varchar(255),
    pod      integer
);
create index pod_dist_dist_index on pod_dist(dist);
create index pod_dist_pod_index on pod_dist(pod);

create table podver (
    [% id %],
    pod         integer,
    distver     integer,
    path        varchar(255),
    signature   varchar(255),
    description text,
    html        [% 'long' IF db == 'mysql' %]blob
    -- version     varchar(255), -- same as distver version
);
create index podver_pod_index on podver(pod);
create index podver_path_index on podver(path[% "(12)" IF index_len %]);
create index podver_distver_index on podver(distver);

create table section ( 
    [% id %],
    podver      integer,
    pos         integer, -- position from 0 to n_sections
    content     text,
    type        smallint
    -- html       text,  -- for "micro-caching"
    -- version     varchar(255)
);
create index podver_index on section(podver);

create table user (
    [% id %],
    username    varchar(255),
    password    varchar(255),
    name        varchar(255),
    email       varchar(255),
    profile     text,
    reputation  integer,
    member_since    integer,
    last_visit  integer,
    privs       integer
);
create index username_index on [% db == 'mysql' ? '`user`' : 'user' %](username);

create table vote (
    [% id %],
    note        integer not null,
    user        integer not null,
    value       smallint
);

create index vote_index_note on vote(note);
create index vote_index_user on vote(user);

create table note (
    [% id %],
    pod         integer,
    min_ver     varchar(255),
    max_ver     varchar(255),
    note        text,
    -- longnote    text,
    ip          varchar(255),
    time        integer,
    score       smallint,
    section     integer, -- section to which the note originally belonged
    user        integer
);
create index note_pod_index on note(pod);

-- this is the many-to-many link
create table notepos (
    [% id %],
    -- ? pod         integer,
    note        integer,
    section     integer,
    score       integer,
    status      integer
);

create index notepos_index_note on notepos(note);
create index notepos_index_section on notepos(section);

create table author (
    [% id %],
    pause_id    varchar(255),
    name        varchar(255),
    email       varchar(255),
    url         varchar(255)
);

create table prefs (
    [% id %],
    user        integer,
    name        varchar(255),
    value       text
);
create index user_index on prefs(user);

