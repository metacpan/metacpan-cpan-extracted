/*
**  DIO Inkey Delete Proc
**
*/
create or replace function
  dio_inkey_delete(integer,varchar)
  returns integer
as '

declare
  vcd_id         alias for $1;
  vci_name       alias for $2;

  vresult int;
begin
  vresult := 1;

  delete from core_dio_inkey where ci_cd_id = vcd_id and ci_name = vci_name;

  return vresult;
end; ' language 'plpgsql';
