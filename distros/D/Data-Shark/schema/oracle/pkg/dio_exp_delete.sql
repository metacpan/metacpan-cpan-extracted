/*
**  DIO Exp Delete Proc
**
*/
create or replace function
  dio_exp_delete(integer,integer)
  returns integer
as '

declare
  vcd_id   alias for $1;
  vce_id   alias for $2;

  vcount   integer;
begin
  select count(*) into vcount from core_dio_cache_exp where ce_cd_id = vcd_id and ce_exp_id = vce_id;

  delete from core_dio_cache_exp where ce_cd_id = vcd_id and ce_exp_id = vce_id;
  delete from core_dio_cache_exp_key where ck_cd_id = vcd_id and ck_exp_id = vce_id;

  return vcount;
end; ' language 'plpgsql';
