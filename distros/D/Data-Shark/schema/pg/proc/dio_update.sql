/*
**  DIO Update Proc
**
*/
create or replace function
  dio_update(integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,
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
begin

  /* update record */
  update core_dio
     set cd_namespace    = vcd_namespace,
         cd_name         = vcd_name,
         cd_version      = vcd_version,
         cd_sysclass     = vcd_sysclass,
         cd_type         = vcd_type,
         cd_return       = vcd_return,
         cd_cache        = vcd_cache,
         cd_profile      = vcd_profile,
         cd_cache_expire = vcd_cache_expire,
         cd_stmt         = vcd_stmt,
         cd_stmt_noarg   = vcd_stmt_noarg,
         cd_repl         = vcd_repl,
         cd_action       = vcd_action,
         cd_audit        = vcd_audit
   where cd_id           = vcd_id;

  return vcd_id;
end; ' language 'plpgsql';
