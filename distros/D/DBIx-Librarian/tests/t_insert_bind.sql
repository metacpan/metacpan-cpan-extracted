insert into BUG (
       bugid,
       groupset,
       assigned_to,
       bug_severity,
       bug_status,
       creation_ts,
       op_sys,
       priority,
       product,
       reporter,
       version,
       component,
       resolution
) values (
  7,
  :groupset,
# :nothing,
  $assigned_to,
  "HIGH",
  "NEW",
  current_timestamp,
  "RH",
  "HIGH",
  :testnode.product_name,
  3,
  "0.1",
  "Statement",
  ""
)



select1	bugid
from	BUG
where	groupset = :groupset
