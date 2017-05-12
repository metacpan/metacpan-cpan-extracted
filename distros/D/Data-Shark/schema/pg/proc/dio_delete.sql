/*
**  DIO Delete Proc
**
*/
create or replace function
  dio_delete(integer)
  returns integer
as '

declare
  vcd_id         alias for $1;

  vresult int;
begin
  vresult := 1;

  delete from core_dio_inkey where ci_cd_id = vcd_id;

  delete from core_dio_outkey where co_cd_id = vcd_id;

  delete from core_dio_cache_exp_key where ck_exp_id = vcd_id;

  delete from core_dio_cache_exp where ce_exp_id = vcd_id;

  delete from core_dio_cache_exp_key where ck_cd_id = vcd_id;

  delete from core_dio_cache_exp where ce_cd_id = vcd_id;

  delete from core_dio where cd_id = vcd_id;

  return vresult;
end; ' language 'plpgsql';
