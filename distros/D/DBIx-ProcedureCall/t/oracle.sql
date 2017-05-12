-- You can run the SQL below to enable additional tests for DBIx::ProcedureCall.
--
-- After testing you can drop the created objects again (they are only used in the test)
--


create or replace type dbixproccall_type as table of varchar2(100);
/

create or replace package dbixproccall as
	function str2tbl (p_str in varchar2, 
		p_delim in varchar2	default ',' ) 
		return dbixproccall_type pipelined;
	function refcur
		return sys_refcursor;
	function oddnum ( num number)
		return boolean;
end dbixproccall;
/

create or replace package body dbixproccall is

	function str2tbl( p_str in varchar2, p_delim in varchar2 
	default ',' ) return dbixproccall_type
	PIPELINED
	as
	    l_str      long default p_str || p_delim;
	    l_n        number;
	begin
	    loop
		l_n := instr( l_str, p_delim );
		exit when (nvl(l_n,0) = 0);
		pipe row( ltrim(rtrim(substr(l_str,1,l_n-1))) );
		l_str := substr( l_str, l_n+1 );
	    end loop;
	    return;
	end;
	
	function refcur 
	return sys_refcursor
	is
		c_result sys_refcursor;
	begin
		open c_result for
		select * from dual;
		return c_result;
	end;
	
	function oddnum ( num number)
		return boolean
	is
	begin
		if mod(num,2) = 0 then
			return true;
		end if;
		return false;
	end;

end dbixproccall;
/
