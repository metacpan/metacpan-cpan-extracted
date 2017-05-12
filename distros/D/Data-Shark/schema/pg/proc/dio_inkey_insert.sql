/*
**  DIO Inkey Insert Proc
**
*/
create or replace function
  dio_inkey_insert(integer,varchar,integer,varchar,text,varchar,varchar)
  returns integer
as '

declare
  vci_cd_id     alias for $1;
  vci_name      alias for $2;
  vci_pos       alias for $3;
  vci_req       alias for $4;
  vci_default   alias for $5;
  vci_key       alias for $6;
  vci_inout     alias for $7;
begin
  /* insert record */
  insert into core_dio_inkey
      (ci_cd_id,ci_name,ci_pos,ci_req,ci_default,ci_key,ci_inout)
    values
      (vci_cd_id,vci_name,vci_pos,vci_req,vci_default,vci_key,vci_inout);

  return vci_cd_id;
end; ' language 'plpgsql';
