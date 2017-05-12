/*
**  DIO Duplicate Proc
**
*/
create or replace function
  dio_duplicate(integer)
  returns integer
as '

declare
  vcd_id         alias for $1;

  c_id   int;
  c_name varchar;
begin
  /* grab a new key */
  select get_seqkey(''core_dio'') into c_id;
  if c_id = 0 or c_id is NULL then
    raise exception ''Unable to get a key'';
    return 0;
  end if;

  select cd_name || ''_'' || c_id into c_name from core_dio where cd_id = vcd_id;

  /* new DIO record */
  insert into core_dio (cd_id,cd_namespace,cd_name,cd_version,cd_sysclass,cd_type,cd_return, cd_profile, cd_cache, cd_stmt, cd_stmt_noarg, cd_repl, cd_action,cd_audit) select c_id,cd_namespace,c_name,cd_version,cd_sysclass,cd_type,cd_return, cd_profile, cd_cache,cd_stmt,cd_stmt_noarg, cd_repl, cd_action, cd_audit from core_dio where cd_id = vcd_id;

  /* new in/out key records */
  insert into core_dio_inkey (ci_cd_id,ci_name,ci_pos,ci_req,ci_default,ci_key) select c_id,ci_name,ci_pos,ci_req,ci_default,ci_key from core_dio_inkey where ci_cd_id = vcd_id;
  insert into core_dio_outkey (co_cd_id,co_name,co_pos,co_default,co_key) select c_id,co_name,co_pos,co_default,co_key from core_dio_outkey where co_cd_id = vcd_id;

  insert into core_dio_cache_exp (ce_cd_id, ce_exp_id) select c_id, ce_exp_id from core_dio_cache_exp where ce_cd_id = vcd_id;

  insert into core_dio_cache_exp_key (ck_cd_id, ck_exp_id, ck_key) select c_id, ck_exp_id, ck_key from core_dio_cache_exp_key where ck_cd_id = vcd_id;

  return c_id;
end; ' language 'plpgsql';
