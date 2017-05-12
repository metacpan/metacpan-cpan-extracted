create or replace package sharkapi2.dio_pkg is

  type       cursorType is ref cursor;

  procedure  dio_insert(vcd_id           in out integer,
                        vcd_namespace    in varchar2,
                        vcd_name         in varchar2,
                        vcd_version      in varchar2,
                        vcd_sysclass     in varchar2,
                        vcd_type         in varchar2,
                        vcd_return       in varchar2,
                        vcd_profile      in varchar2,
                        vcd_cache        in varchar2,
                        vcd_cache_expire in varchar2,
                        vcd_stmt         in varchar2,
                        vcd_stmt_noarg   in varchar2,
                        vcd_repl         in varchar2,
                        vcd_action       in varchar2,
                        vcd_audit        in varchar2);

  procedure  dio_update(vcd_id           in integer,
                        vcd_namespace    in varchar2,
                        vcd_name         in varchar2,
                        vcd_version      in varchar2,
                        vcd_sysclass     in varchar2,
                        vcd_type         in varchar2,
                        vcd_return       in varchar2,
                        vcd_profile      in varchar2,
                        vcd_cache        in varchar2,
                        vcd_cache_expire in varchar2,
                        vcd_stmt         in varchar2,
                        vcd_stmt_noarg   in varchar2,
                        vcd_repl         in varchar2,
                        vcd_action       in varchar2,
                        vcd_audit        in varchar2);

  procedure  dio_delete(vcd_id           in integer);

  procedure  dio_duplicate(vnew_id       in out integer,
                           vcd_id        in integer);

  /**/

  procedure  dio_inkey_insert(vci_cd_id   in integer,
                              vci_name    in varchar2,
                              vci_pos     in integer,
                              vci_req     in varchar2,
                              vci_default in varchar2,
                              vci_key     in varchar2,
                              vci_inout   in varchar2,
                              vci_opt     in varchar2);

  procedure  dio_inkey_update(vci_cd_id   in integer,
                              vold_name   in varchar2,
                              vci_name    in varchar2,
                              vci_pos     in integer,
                              vci_req     in varchar2,
                              vci_default in varchar2,
                              vci_key     in varchar2,
                              vci_inout   in varchar2,
                              vci_opt     in varchar2);

  procedure  dio_inkey_delete(vci_cd_id   in integer,
                              vci_name    in varchar2);

  /**/

  procedure  dio_outkey_insert(vco_cd_id   in integer,
                               vco_name    in varchar2,
                               vco_pos     in integer,
                               vco_default in varchar2,
                               vco_key     in varchar2,
                               vco_inout   in varchar2);

  procedure  dio_outkey_update(vco_cd_id   in integer,
                               vold_name   in varchar2,
                               vco_name    in varchar2,
                               vco_pos     in integer,
                               vco_default in varchar2,
                               vco_key     in varchar2,
                               vco_inout   in varchar2);

  procedure  dio_outkey_delete(vco_cd_id   in integer,
                               vco_name    in varchar2);

  /**/

end dio_pkg;
/
show errors;

