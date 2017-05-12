
begin;

delete from enum;
delete from enum_map;
delete from enum_legacy_map;

-- hack, temporarily misusing the enum_id field
insert into enum_legacy_map (context,field,enum_id,sortval) 
select context,field,row_id,sortval from esrp_main.esrp_enum 
where context != 'object'; 

insert into enum (handle,name,override_id) select handle,name,val from esrp_main.esrp_enum where context != 'object' group by handle, name, val;

update enum e,
       enum_legacy_map m,
       esrp_main.esrp_enum l

       set
       m.enum_id = e.enum_id
       where

       -- find the map record we want to update
       m.enum_id     = l.row_id and

       -- scan for the enum we want to set it to
       e.override_id = l.val and 
       e.handle      = l.handle and
       e.name        = l.name;

-- Now we insert the field mappings yes, the fuzzy match is a little sketchy
insert into enum_map (field_id,enum_id,sortval) 
       select f.field_id, m.enum_id, m.sortval 
       from dbr_fields f, dbr_tables t, enum_legacy_map m
       where
	   f.table_id = t.table_id and
	   (
	       t.name = m.context or
	       t.name = concat(m.context,'s') or 
	       concat(t.name,'s') = m.context
	   ) and
	   f.name = m.field;
	

update dbr_fields f, enum_map m set f.trans_id = 1 where f.field_id = m.field_id;
   
commit;
