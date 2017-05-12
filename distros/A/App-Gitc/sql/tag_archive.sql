create table tag_archive (
    id          serial primary key,
    project     varchar(30) not null,
    tag_name    varchar(256) not null,
    sha1        char(40) not null
);
create unique index tag_archive_project_tag_name
    on tag_archive (project,tag_name);
