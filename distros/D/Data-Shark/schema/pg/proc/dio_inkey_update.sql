/*
**  DIO Inkey Update Proc
**
*/
create or replace function
  dio_inkey_update(integer,varchar,varchar,integer,varchar,text,varchar,varchar)
  returns integer
as '

declare
  vci_cd_id     alias for $1;
  vold_name     alias for $2;
  vci_name      alias for $3;
  vci_pos       alias for $4;
  vci_req       alias for $5;
  vci_default   alias for $6;
  vci_key       alias for $7;
  vci_inout     alias for $8;
begin

  /* update record */
  update core_dio_inkey
     set ci_name    = vci_name,
         ci_pos     = vci_pos,
         ci_req     = vci_req,
         ci_default = vci_default,
         ci_key     = vci_key,
         ci_inout   = vci_inout
   where ci_cd_id   = vci_cd_id
     and ci_name    = vold_name;

  return vci_cd_id;
end; ' language 'plpgsql';
