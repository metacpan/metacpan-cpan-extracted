/*
**  Get Sequence Key Procedure
**
*/
create or replace function get_seqkey(varchar) returns integer as '
declare
  table_name alias for $1;
  new_key integer;
begin 

  new_key := 0;

  update seqkey set lastKey = lastKey + 1 where tablename = table_name;
  select lastKey into new_key from seqkey where tablename = table_name;

  if not found then 
    commit transaction;
    raise exception ''Unable to get a key'';
    return 0;
  else
    return new_key;
  end if;
end;
' language 'plpgsql';
