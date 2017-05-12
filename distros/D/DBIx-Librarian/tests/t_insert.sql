insert into BUG (
       bugid,
       groupset,
       assigned_to,
       bug_severity,
       bug_status,
       creation_ts,
       op_sys,
# embedded comment
       priority,
       product,
       reporter,
       version,
       component,
       resolution
) values (
  5,
  42,
  3,
  "HIGH",
  "NEW",
  current_timestamp,
  "RH",
  "HIGH",
  "DBIx::Librarian",
  3,
  "0.1",
  "Statement",
  ""
)



select1	bugid
from	BUG
where	groupset = 42
