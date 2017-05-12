/*
**  Core DIO Audit Insert Insert Trigger
**
*/
create or replace function
  dio_audit_insert(integer,integer,varchar,varchar)
  returns integer
as '

declare
  vca_id      alias for $1;
  vca_cd_id   alias for $2;
  vca_ip      alias for $3;
  vca_user    alias for $4;

  loginid         int;
  ccreated_by     int;
  ccreated_on     timestamp with time zone;

  tca_id          int;
begin

  /* Get an ID if needed */
  if vca_id = 0 or vca_id is NULL then
    select get_seqkey(''core_dio_audit'') into tca_id;
    if tca_id = 0 or tca_id is NULL then
      raise exception ''Unable to get a key'';
      return 0;
    end if;
  else
    tca_id := vca_id;
  end if;

  /* get login id for created_by */
  select get_loginid(vca_user) into loginid;
  if loginid = 0 then
      raise exception ''Unable to get login id'';
      return 0;
  end if;

  ccreated_by := loginid;
  select current_timestamp into ccreated_on;

  insert into core_dio_audit
    (ca_id, ca_cd_id, ca_ip, ca_user, ca_ts)
  values
    (tca_id, vca_cd_id, vca_ip, ccreated_by, ccreated_on);

  return tca_id;
end; ' language 'plpgsql';
