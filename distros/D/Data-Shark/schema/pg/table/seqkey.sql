/*
**  Key Sequence Table
**
*/

drop table seqkey;
create table seqkey
(
tableName                      varchar(30)     not null,
lastKey                        int             not null,
pagePad1                       char(250)       not null,
pagePad2                       char(250)       not null,
pagePad3                       char(250)       not null,
pagePad4                       char(250)       not null
)
;
DROP INDEX public.seqkey_i1;

CREATE UNIQUE INDEX seqkey_i1
  ON public.seqkey
  USING btree
  (tablename);

