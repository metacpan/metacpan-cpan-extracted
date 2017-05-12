/*
**  DIO Insert Proc
**
*/
create or replace function
  dio_insert(integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,
             varchar,varchar,text,text,varchar,varchar,varchar)
  returns integer
as '

declare
  vcd_id           alias for $1;
  vcd_namespace    alias for $2;
  vcd_name         alias for $3;
  vcd_version      alias for $4;
  vcd_sysclass     alias for $5;
  vcd_type         alias for $6;
  vcd_return       alias for $7;
  vcd_profile      alias for $8;
  vcd_cache        alias for $9;
  vcd_cache_expire alias for $10;
  vcd_stmt         alias for $11;
  vcd_stmt_noarg   alias for $12;
  vcd_repl         alias for $13;
  vcd_action       alias for $14;
  vcd_audit        alias for $15;

  c_id int;
begin
  /* Get an ID if needed */
  if vcd_id = 0 or vcd_id is NULL then
    select get_seqkey(''core_dio'') into c_id;
    if c_id = 0 or c_id is NULL then
      raise exception ''Unable to get a key'';
      return 0;
    end if;
  else
    c_id := vcd_id;
  end if;

  /* insert record */
  insert into core_dio
      (cd_id,cd_namespace,cd_name,cd_version,cd_sysclass,cd_type,cd_return,
       cd_profile,cd_cache,cd_cache_expire,cd_stmt,cd_stmt_noarg,cd_repl,
       cd_action,cd_audit)
    values
      (c_id,vcd_namespace,vcd_name,vcd_version,vcd_sysclass,vcd_type,vcd_return,
       vcd_profile,vcd_cache,vcd_cache_expire,vcd_stmt,vcd_stmt_noarg,vcd_repl,
       vcd_action,vcd_audit);

  return c_id;
end; ' language 'plpgsql';
