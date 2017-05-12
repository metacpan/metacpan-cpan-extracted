drop table if exists BUG;

create table BUG (
    bugid mediumint not null,
    groupset bigint not null,
    assigned_to mediumint not null, # This is a comment.
    bug_file_loc text,
    bug_severity enum("HIGH", "MED", "LOW") not null,
    bug_status enum("UNCONFIRMED", "NEW", "ASSIGNED", "REOPENED", "RESOLVED", "VERIFIED", "CLOSED") not null,
    creation_ts datetime not null,
    delta_ts timestamp,
    short_desc mediumtext,
    op_sys enum("RH", "SOLARIS", "WIN2K", "MACOSX") not null,
    priority enum("HIGH", "MED", "LOW") not null,
    product varchar(64) not null,
    reporter mediumint not null,
    version varchar(64) not null,
    component varchar(50) not null,
    resolution enum("", "FIXED", "INVALID", "WONTFIX", "LATER", "REMIND", "DUPLICATE", "WORKSFORME", "MOVED") not null
) type = innodb;
