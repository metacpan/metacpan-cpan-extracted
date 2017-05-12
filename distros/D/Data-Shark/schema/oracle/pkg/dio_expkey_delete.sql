/*
**  DIO Exp Key Delete Proc
**
*/
create or replace function
  dio_expkey_delete(integer,integer,varchar)
  returns integer
as '

declare
  vcd_id   alias for $1;
  vce_id   alias for $2;
  vck_key  alias for $3;

  vcount   integer;
begin
  select count(*) into vcount from core_dio_cache_exp_key where ck_cd_id = vcd_id and ck_exp_id = vce_id and ck_key = vck_key;

  delete from core_dio_cache_exp_key where ck_cd_id = vcd_id and ck_exp_id = vce_id and ck_key = vck_key;

  return vcount;
end; ' language 'plpgsql';
