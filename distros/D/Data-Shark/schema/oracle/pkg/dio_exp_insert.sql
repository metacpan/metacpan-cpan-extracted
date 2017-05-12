/*
**  DIO Exp Insert Proc
**
*/
create or replace function
  dio_exp_insert(integer,integer)
  returns integer
as '

declare
  vcd_id   alias for $1;
  vce_id   alias for $2;

  vcount   integer;
begin
  select count(*) into vcount from core_dio_cache_exp where ce_cd_id = vcd_id and ce_exp_id = vce_id;

  if vcount = 0 then
    /* insert record */
    insert into core_dio_cache_exp
        (ce_cd_id,ce_exp_id)
      values
        (vcd_id,vce_id);
  end if;

  return vcount;
end; ' language 'plpgsql';
