/*
**  DIO Outkey Delete Proc
**
*/
create or replace function
  dio_outkey_delete(integer,varchar)
  returns integer
as '

declare
  vcd_id         alias for $1;
  vco_name       alias for $2;

  vresult int;
begin
  vresult := 1;

  delete from core_dio_outkey where co_cd_id = vcd_id and co_name = vco_name;

  return vresult;
end; ' language 'plpgsql';
