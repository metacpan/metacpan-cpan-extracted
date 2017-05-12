create or replace package sharkapi2.util_pkg is

        type     cursorType is ref cursor;

        procedure get_seqkey(table_name in varchar2, new_key in out number);

        end util_pkg;
/
show errors;

