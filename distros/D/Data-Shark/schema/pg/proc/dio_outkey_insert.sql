/*
**  DIO Outkey Insert Proc
**
*/
create or replace function
  dio_outkey_insert(integer,varchar,integer,text,varchar,varchar)
  returns integer
as '

declare
  vco_cd_id     alias for $1;
  vco_name      alias for $2;
  vco_pos       alias for $3;
  vco_default   alias for $4;
  vco_key       alias for $5;
  vco_inout     alias for $6;
begin
  /* insert record */
  insert into core_dio_outkey
      (co_cd_id,co_name,co_pos,co_default,co_key,co_inout)
    values
      (vco_cd_id,vco_name,vco_pos,vco_default,vco_key,vco_inout);

  return vco_cd_id;
end; ' language 'plpgsql';
