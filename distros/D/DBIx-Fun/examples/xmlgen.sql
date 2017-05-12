create or replace function get_xml( qry in varchar2 )
return clob
as
  ctx dbms_xmlgen.ctxhandle;
begin
  ctx := dbms_xmlgen.newContext( get_xml.sql );
  return dmbs_xmlgen.getXML( ctx );
end;
/
    
