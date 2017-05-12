/*
**  DIO Exp Key Insert Proc
**
*/
create or replace function
  dio_expkey_insert(integer,integer,varchar)
  returns integer
as '

declare
  vcd_id   alias for $1;
  vce_id   alias for $2;
  vck_key  alias for $3;

  vcount   integer;
begin
  select count(*) into vcount from core_dio_cache_exp_key where ck_cd_id = vcd_id and ck_exp_id = vce_id and ck_key = vck_key;

  if vcount = 0 then
    /* insert record */
    insert into core_dio_cache_exp_key
        (ck_cd_id,ck_exp_id,ck_key)
      values
        (vcd_id,vce_id,vck_key);
  end if;

  return vcount;
end; ' language 'plpgsql';
