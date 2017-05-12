/*
**  Key Sequence Table
**
*/

drop table sharkapi2.seqkey;
create table sharkapi2.seqkey
(
tableName                      varchar2(30)    not null,
lastKey                        int             not null,
pagePad1                       char(250)       not null,
pagePad2                       char(250)       not null,
pagePad3                       char(250)       not null,
pagePad4                       char(250)       not null
)
;

CREATE UNIQUE INDEX seqkey_i1
  ON sharkapi2.seqkey (tablename);

create public synonym seqkey for sharkapi2.seqkey;

