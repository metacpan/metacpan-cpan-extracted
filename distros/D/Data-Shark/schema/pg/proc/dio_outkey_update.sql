/*
**  DIO Outkey Update Proc
**
*/
create or replace function
  dio_outkey_update(integer,varchar,varchar,integer,text,varchar,varchar)
  returns integer
as '

declare
  vco_cd_id     alias for $1;
  vold_name     alias for $2;
  vco_name      alias for $3;
  vco_pos       alias for $4;
  vco_default   alias for $5;
  vco_key       alias for $6;
  vco_inout     alias for $7;
begin

  /* update record */
  update core_dio_outkey
     set co_name    = vco_name,
         co_pos     = vco_pos,
         co_default = vco_default,
         co_key     = vco_key,
         co_inout   = vco_inout
   where co_cd_id   = vco_cd_id
     and co_name    = vold_name;

  return vco_cd_id;
end; ' language 'plpgsql';
