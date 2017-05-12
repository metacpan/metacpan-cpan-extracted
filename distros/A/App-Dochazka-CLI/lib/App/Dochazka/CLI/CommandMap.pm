# ************************************************************************* 
# Copyright (c) 2014-2016, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 
#
# Command map
#
package App::Dochazka::CLI::CommandMap;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL );
use App::Dochazka::CLI::Commands::Activity qw( 
    activity_all 
);
use App::Dochazka::CLI::Commands::Component qw( 
    component_path
    generate_report
);
use App::Dochazka::CLI::Commands::Employee qw( 
    employee_ldap
    employee_ldap_import
    employee_list
    employee_profile
    employee_team
    set_employee_self_sec_id 
    set_employee_other_sec_id 
    set_employee_self_fullname
    set_employee_other_fullname 
    set_employee_self_password
    set_employee_other_password 
    set_employee_supervisor
);
use App::Dochazka::CLI::Commands::History qw(
    add_priv_history
    add_schedule_history
    dump_priv_history
    dump_schedule_history
    set_history_remark
);
use App::Dochazka::CLI::Commands::Interval qw(
    interval_date
    interval_date_date1
    interval_datelist
    interval_tsrange
    interval_month
    interval_num_num1
    interval_promptdate
    interval_new_date_time_date1_time1
    interval_new_time_time1
    interval_new_timerange
);
use App::Dochazka::CLI::Commands::Misc qw( 
    change_prompt_date 
    noop
);
use App::Dochazka::CLI::Commands::Priv qw(
    show_priv_as_at
);
use App::Dochazka::CLI::Commands::Schedule qw( 
    add_memsched_entry 
    assign_memsched_scode
    clear_memsched_entries
    dump_memsched_entries
    fetch_all_schedules
    replicate_memsched_entry
    schedule_all
    schedule_new
    schedulespec
    schedulespec_remark
    schedulespec_scode
    show_schedule_as_at
);
use Data::Dumper;
use Exporter qw( import );


=head1 NAME

App::Dochazka::CLI::CommandMap - Command map




=head1 PACKAGE VARIABLES

=cut

# bring in the _method... functions
require App::Dochazka::CLI::Commands::RestTest::Activity;
require App::Dochazka::CLI::Commands::RestTest::Employee;
require App::Dochazka::CLI::Commands::RestTest::Interval;
require App::Dochazka::CLI::Commands::RestTest::Lock;
require App::Dochazka::CLI::Commands::RestTest::Priv;
require App::Dochazka::CLI::Commands::RestTest::Schedule;
require App::Dochazka::CLI::Commands::RestTest::Top;

our $dispatch_map = { 

    # Top-level commands
    "GET" => \&_method,
    "PUT" => \&_method,
    "POST" => \&_method,
    "DELETE" => \&_method,
    "GET BUGREPORT" => \&_method_bugreport,
    "PUT BUGREPORT" => \&_method_bugreport,
    "POST BUGREPORT" => \&_method_bugreport,
    "DELETE BUGREPORT" => \&_method_bugreport,
    "GET CONFIGINFO" => \&_method_configinfo,
    "PUT CONFIGINFO" => \&_method_configinfo,
    "POST CONFIGINFO" => \&_method_configinfo,
    "DELETE CONFIGINFO" => \&_method_configinfo,
    "GET COOKIEJAR" => \&_method_cookiejar,
    "PUT COOKIEJAR" => \&_method_cookiejar,
    "POST COOKIEJAR" => \&_method_cookiejar,
    "DELETE COOKIEJAR" => \&_method_cookiejar,
    "GET DBSTATUS" => \&_method_dbstatus,
    "PUT DBSTATUS" => \&_method_dbstatus,
    "POST DBSTATUS" => \&_method_dbstatus,
    "DELETE DBSTATUS" => \&_method_dbstatus,
    "GET DOCU" => \&_method_docu,
    "PUT DOCU" => \&_method_docu,
    "POST DOCU" => \&_method_docu,
    "DELETE DOCU" => \&_method_docu,
    "GET DOCU POD" => \&_method_docu_pod,
    "PUT DOCU POD" => \&_method_docu_pod,
    "POST DOCU POD" => \&_method_docu_pod,
    "DELETE DOCU POD" => \&_method_docu_pod,
    "GET DOCU POD _DOCU" => \&_method_docu_pod_docu,
    "PUT DOCU POD _DOCU" => \&_method_docu_pod_docu,
    "POST DOCU POD _DOCU" => \&_method_docu_pod_docu,
    "DELETE DOCU POD _DOCU" => \&_method_docu_pod_docu,
    "GET HOLIDAY _TSRANGE" => \&_method_holiday_tsrange,
    "PUT HOLIDAY _TSRANGE" => \&_method_holiday_tsrange,
    "POST HOLIDAY _TSRANGE" => \&_method_holiday_tsrange,
    "DELETE HOLIDAY _TSRANGE" => \&_method_holiday_tsrange,
    "GET DOCU HTML" => \&_method_docu_html,
    "PUT DOCU HTML" => \&_method_docu_html,
    "POST DOCU HTML" => \&_method_docu_html,
    "DELETE DOCU HTML" => \&_method_docu_html,
    "GET DOCU HTML _DOCU" => \&_method_docu_html_docu,
    "PUT DOCU HTML _DOCU" => \&_method_docu_html_docu,
    "POST DOCU HTML _DOCU" => \&_method_docu_html_docu,
    "DELETE DOCU HTML _DOCU" => \&_method_docu_html_docu,
    "GET DOCU TEXT" => \&_method_docu_text,
    "PUT DOCU TEXT" => \&_method_docu_text,
    "POST DOCU TEXT" => \&_method_docu_text,
    "DELETE DOCU TEXT" => \&_method_docu_text,
    "GET DOCU TEXT _DOCU" => \&_method_docu_text_docu,
    "PUT DOCU TEXT _DOCU" => \&_method_docu_text_docu,
    "POST DOCU TEXT _DOCU" => \&_method_docu_text_docu,
    "DELETE DOCU TEXT _DOCU" => \&_method_docu_text_docu,
    "GET ECHO" => \&_method_echo,
    "PUT ECHO" => \&_method_echo,
    "POST ECHO" => \&_method_echo,
    "DELETE ECHO" => \&_method_echo,
    "GET FORBIDDEN" => \&_method_forbidden,
    "PUT FORBIDDEN" => \&_method_forbidden,
    "POST FORBIDDEN" => \&_method_forbidden,
    "DELETE FORBIDDEN" => \&_method_forbidden,
    "GET NOOP" => \&_method_noop,
    "PUT NOOP" => \&_method_noop,
    "POST NOOP" => \&_method_noop,
    "DELETE NOOP" => \&_method_noop,
    "GET PARAM" => \&_method_param,
    "PUT PARAM" => \&_method_param,
    "POST PARAM" => \&_method_param,
    "DELETE PARAM" => \&_method_param,
    "GET PARAM CORE" => \&_method_param_core,
    "PUT PARAM CORE" => \&_method_param_core,
    "POST PARAM CORE" => \&_method_param_core,
    "DELETE PARAM CORE" => \&_method_param_core,
    "GET PARAM CORE _TERM" => \&_method_param_core_term,
    "PUT PARAM CORE _TERM" => \&_method_param_core_term,
    "POST PARAM CORE _TERM" => \&_method_param_core_term,
    "DELETE PARAM CORE _TERM" => \&_method_param_core_term,
    "GET PARAM META" => \&_method_param_meta,
    "PUT PARAM META" => \&_method_param_meta,
    "POST PARAM META" => \&_method_param_meta,
    "DELETE PARAM META" => \&_method_param_meta,
    "GET PARAM META _TERM" => \&_method_param_meta_term,
    "PUT PARAM META _TERM" => \&_method_param_meta_term,
    "POST PARAM META _TERM" => \&_method_param_meta_term,
    "DELETE PARAM META _TERM" => \&_method_param_meta_term,
    "GET PARAM SITE" => \&_method_param_site,
    "PUT PARAM SITE" => \&_method_param_site,
    "POST PARAM SITE" => \&_method_param_site,
    "DELETE PARAM SITE" => \&_method_param_site,
    "GET PARAM SITE _TERM" => \&_method_param_site_term,
    "PUT PARAM SITE _TERM" => \&_method_param_site_term,
    "POST PARAM SITE _TERM" => \&_method_param_site_term,
    "DELETE PARAM SITE _TERM" => \&_method_param_site_term,
    "GET SESSION" => \&_method_session,
    "PUT SESSION" => \&_method_session,
    "POST SESSION" => \&_method_session,
    "DELETE SESSION" => \&_method_session,
    "GET VERSION" => \&_method_version,
    "PUT VERSION" => \&_method_version,
    "POST VERSION" => \&_method_version,
    "DELETE VERSION" => \&_method_version,
    "GET WHOAMI" => \&_method_whoami,
    "PUT WHOAMI" => \&_method_whoami,
    "POST WHOAMI" => \&_method_whoami,
    "DELETE WHOAMI" => \&_method_whoami,
    "EXIT" => \&go_exit,

    # Activity commands
    "GET ACTIVITY" => \&_method_activity,
    "PUT ACTIVITY" => \&_method_activity,
    "POST ACTIVITY" => \&_method_activity,
    "DELETE ACTIVITY" => \&_method_activity,
    "GET ACTIVITY AID" => \&_method_activity_aid,
    "PUT ACTIVITY AID" => \&_method_activity_aid,
    "POST ACTIVITY AID" => \&_method_activity_aid,
    "DELETE ACTIVITY AID" => \&_method_activity_aid,
    "GET ACTIVITY AID _JSON" => \&_method_activity_aid,
    "PUT ACTIVITY AID _JSON" => \&_method_activity_aid,
    "POST ACTIVITY AID _JSON" => \&_method_activity_aid,
    "DELETE ACTIVITY AID _JSON" => \&_method_activity_aid,
    "GET ACTIVITY AID _NUM" => \&_method_activity_aid_num,
    "PUT ACTIVITY AID _NUM" => \&_method_activity_aid_num,
    "POST ACTIVITY AID _NUM" => \&_method_activity_aid_num,
    "DELETE ACTIVITY AID _NUM" => \&_method_activity_aid_num,
    "GET ACTIVITY ALL" => \&_method_activity_all,
    "PUT ACTIVITY ALL" => \&_method_activity_all,
    "POST ACTIVITY ALL" => \&_method_activity_all,
    "DELETE ACTIVITY ALL" => \&_method_activity_all,
    "GET ACTIVITY ALL DISABLED" => \&_method_activity_all_disabled,
    "PUT ACTIVITY ALL DISABLED" => \&_method_activity_all_disabled,
    "POST ACTIVITY ALL DISABLED" => \&_method_activity_all_disabled,
    "DELETE ACTIVITY ALL DISABLED" => \&_method_activity_all_disabled,
    "GET ACTIVITY CODE" => \&_method_activity_code,
    "PUT ACTIVITY CODE" => \&_method_activity_code,
    "POST ACTIVITY CODE" => \&_method_activity_code,
    "DELETE ACTIVITY CODE" => \&_method_activity_code,
    "GET ACTIVITY CODE _JSON" => \&_method_activity_code,
    "PUT ACTIVITY CODE _JSON" => \&_method_activity_code,
    "POST ACTIVITY CODE _JSON" => \&_method_activity_code,
    "DELETE ACTIVITY CODE _JSON" => \&_method_activity_code,
    "GET ACTIVITY CODE _TERM" => \&_method_activity_code_term,
    "PUT ACTIVITY CODE _TERM" => \&_method_activity_code_term,
    "POST ACTIVITY CODE _TERM" => \&_method_activity_code_term,
    "DELETE ACTIVITY CODE _TERM" => \&_method_activity_code_term,

    # Employee commands
    "GET EMPLOYEE" => \&_method_employee,
    "PUT EMPLOYEE" => \&_method_employee,
    "POST EMPLOYEE" => \&_method_employee,
    "DELETE EMPLOYEE" => \&_method_employee,
    "GET EMPLOYEE COUNT" => \&_method_employee_count,
    "PUT EMPLOYEE COUNT" => \&_method_employee_count,
    "POST EMPLOYEE COUNT" => \&_method_employee_count,
    "DELETE EMPLOYEE COUNT" => \&_method_employee_count,
    "GET EMPLOYEE COUNT PRIV" => \&_method_employee_count_priv,
    "PUT EMPLOYEE COUNT PRIV" => \&_method_employee_count_priv,
    "POST EMPLOYEE COUNT PRIV" => \&_method_employee_count_priv,
    "DELETE EMPLOYEE COUNT PRIV" => \&_method_employee_count_priv,
    "GET EMPLOYEE CURRENT" => \&_method_employee_current,
    "PUT EMPLOYEE CURRENT" => \&_method_employee_current,
    "POST EMPLOYEE CURRENT" => \&_method_employee_current,
    "DELETE EMPLOYEE CURRENT" => \&_method_employee_current,
    "GET EMPLOYEE CURRENT PRIV" => \&_method_employee_current_priv,
    "PUT EMPLOYEE CURRENT PRIV" => \&_method_employee_current_priv,
    "POST EMPLOYEE CURRENT PRIV" => \&_method_employee_current_priv,
    "DELETE EMPLOYEE CURRENT PRIV" => \&_method_employee_current_priv,
    "GET EMPLOYEE EID" => \&_method_employee_eid,
    "PUT EMPLOYEE EID" => \&_method_employee_eid,
    "POST EMPLOYEE EID" => \&_method_employee_eid,
    "DELETE EMPLOYEE EID" => \&_method_employee_eid,
    "GET EMPLOYEE EID _JSON" => \&_method_employee_eid_json,
    "PUT EMPLOYEE EID _JSON" => \&_method_employee_eid_json,
    "POST EMPLOYEE EID _JSON" => \&_method_employee_eid_json,
    "DELETE EMPLOYEE EID _JSON" => \&_method_employee_eid_json,
    "GET EMPLOYEE EID _NUM" => \&_method_employee_eid_num,
    "PUT EMPLOYEE EID _NUM" => \&_method_employee_eid_num,
    "POST EMPLOYEE EID _NUM" => \&_method_employee_eid_num,
    "DELETE EMPLOYEE EID _NUM" => \&_method_employee_eid_num,
    "GET EMPLOYEE EID _NUM _JSON" => \&_method_employee_eid_num_json,
    "PUT EMPLOYEE EID _NUM _JSON" => \&_method_employee_eid_num_json,
    "POST EMPLOYEE EID _NUM _JSON" => \&_method_employee_eid_num_json,
    "DELETE EMPLOYEE EID _NUM _JSON" => \&_method_employee_eid_num_json,
    "GET EMPLOYEE EID _NUM TEAM" => \&_method_employee_eid_num_team,
    "PUT EMPLOYEE EID _NUM TEAM" => \&_method_employee_eid_num_team,
    "POST EMPLOYEE EID _NUM TEAM" => \&_method_employee_eid_num_team,
    "DELETE EMPLOYEE EID _NUM TEAM" => \&_method_employee_eid_num_team,
    "GET EMPLOYEE LIST" => \&_method_employee_list,
    "PUT EMPLOYEE LIST" => \&_method_employee_list,
    "POST EMPLOYEE LIST" => \&_method_employee_list,
    "DELETE EMPLOYEE LIST" => \&_method_employee_list,
    "GET EMPLOYEE LIST _TERM" => \&_method_employee_list_priv,
    "PUT EMPLOYEE LIST _TERM" => \&_method_employee_list_priv,
    "POST EMPLOYEE LIST _TERM" => \&_method_employee_list_priv,
    "DELETE EMPLOYEE LIST _TERM" => \&_method_employee_list_priv,
    "GET EMPLOYEE NICK" => \&_method_employee_nick,
    "PUT EMPLOYEE NICK" => \&_method_employee_nick,
    "POST EMPLOYEE NICK" => \&_method_employee_nick,
    "DELETE EMPLOYEE NICK" => \&_method_employee_nick,
    "GET EMPLOYEE NICK _JSON" => \&_method_employee_nick_json,
    "PUT EMPLOYEE NICK _JSON" => \&_method_employee_nick_json,
    "POST EMPLOYEE NICK _JSON" => \&_method_employee_nick_json,
    "DELETE EMPLOYEE NICK _JSON" => \&_method_employee_nick_json,
    "GET EMPLOYEE NICK _TERM" => \&_method_employee_nick_term,
    "PUT EMPLOYEE NICK _TERM" => \&_method_employee_nick_term,
    "POST EMPLOYEE NICK _TERM" => \&_method_employee_nick_term,
    "DELETE EMPLOYEE NICK _TERM" => \&_method_employee_nick_term,
    "GET EMPLOYEE NICK _TERM LDAP" => \&_method_employee_nick_term_ldap,
    "PUT EMPLOYEE NICK _TERM LDAP" => \&_method_employee_nick_term_ldap,
    "POST EMPLOYEE NICK _TERM LDAP" => \&_method_employee_nick_term_ldap,
    "DELETE EMPLOYEE NICK _TERM LDAP" => \&_method_employee_nick_term_ldap,
    "GET EMPLOYEE NICK _TERM _JSON" => \&_method_employee_nick_term_json,
    "PUT EMPLOYEE NICK _TERM _JSON" => \&_method_employee_nick_term_json,
    "POST EMPLOYEE NICK _TERM _JSON" => \&_method_employee_nick_term_json,
    "DELETE EMPLOYEE NICK _TERM _JSON" => \&_method_employee_nick_term_json,
    "GET EMPLOYEE NICK _TERM TEAM" => \&_method_employee_nick_term_team,
    "PUT EMPLOYEE NICK _TERM TEAM" => \&_method_employee_nick_term_team,
    "POST EMPLOYEE NICK _TERM TEAM" => \&_method_employee_nick_term_team,
    "DELETE EMPLOYEE NICK _TERM TEAM" => \&_method_employee_nick_term_team,
    "GET EMPLOYEE SEARCH" => \&_method_employee_search,
    "PUT EMPLOYEE SEARCH" => \&_method_employee_search,
    "POST EMPLOYEE SEARCH" => \&_method_employee_search,
    "DELETE EMPLOYEE SEARCH" => \&_method_employee_search,
    "GET EMPLOYEE SEARCH NICK _TERM" => \&_method_employee_search_nick,
    "PUT EMPLOYEE SEARCH NICK _TERM" => \&_method_employee_search_nick,
    "POST EMPLOYEE SEARCH NICK _TERM" => \&_method_employee_search_nick,
    "DELETE EMPLOYEE SEARCH NICK _TERM" => \&_method_employee_search_nick,
    "GET EMPLOYEE SELF" => \&_method_employee_self,
    "PUT EMPLOYEE SELF" => \&_method_employee_self,
    "POST EMPLOYEE SELF" => \&_method_employee_self,
    "DELETE EMPLOYEE SELF" => \&_method_employee_self,
    "GET EMPLOYEE SELF PRIV" => \&_method_employee_self_priv,
    "PUT EMPLOYEE SELF PRIV" => \&_method_employee_self_priv,
    "POST EMPLOYEE SELF PRIV" => \&_method_employee_self_priv,
    "DELETE EMPLOYEE SELF PRIV" => \&_method_employee_self_priv,
    "GET EMPLOYEE TEAM" => \&_method_employee_team,
    "PUT EMPLOYEE TEAM" => \&_method_employee_team,
    "POST EMPLOYEE TEAM" => \&_method_employee_team,
    "DELETE EMPLOYEE TEAM" => \&_method_employee_team,

    # Interval commands
    "GET INTERVAL" => \&_method_interval,
    "PUT INTERVAL" => \&_method_interval,
    "POST INTERVAL" => \&_method_interval,
    "DELETE INTERVAL" => \&_method_interval,
    "GET INTERVAL EID _NUM" => \&_method_interval_eid,
    "PUT INTERVAL EID _NUM" => \&_method_interval_eid,
    "POST INTERVAL EID _NUM" => \&_method_interval_eid,
    "DELETE INTERVAL EID _NUM" => \&_method_interval_eid,
    "GET INTERVAL EID _NUM _TSRANGE" => \&_method_interval_eid_tsrange,
    "PUT INTERVAL EID _NUM _TSRANGE" => \&_method_interval_eid_tsrange,
    "POST INTERVAL EID _NUM _TSRANGE" => \&_method_interval_eid_tsrange,
    "DELETE INTERVAL EID _NUM _TSRANGE" => \&_method_interval_eid_tsrange,
    "GET INTERVAL FILLUP" => \&_method_interval_fillup,
    "PUT INTERVAL FILLUP" => \&_method_interval_fillup,
    "POST INTERVAL FILLUP" => \&_method_interval_fillup,
    "DELETE INTERVAL FILLUP" => \&_method_interval_fillup,
    "GET INTERVAL IID _NUM" => \&_method_interval_iid,
    "PUT INTERVAL IID _NUM" => \&_method_interval_iid,
    "POST INTERVAL IID _NUM" => \&_method_interval_iid,
    "DELETE INTERVAL IID _NUM" => \&_method_interval_iid,
    "GET INTERVAL NEW" => \&_method_interval_new,
    "PUT INTERVAL NEW" => \&_method_interval_new,
    "POST INTERVAL NEW" => \&_method_interval_new,
    "DELETE INTERVAL NEW" => \&_method_interval_new,
    "GET INTERVAL NICK _TERM" => \&_method_interval_nick,
    "PUT INTERVAL NICK _TERM" => \&_method_interval_nick,
    "POST INTERVAL NICK _TERM" => \&_method_interval_nick,
    "DELETE INTERVAL NICK _TERM" => \&_method_interval_nick,
    "GET INTERVAL NICK _TERM _TSRANGE" => \&_method_interval_nick_tsrange,
    "PUT INTERVAL NICK _TERM _TSRANGE" => \&_method_interval_nick_tsrange,
    "POST INTERVAL NICK _TERM _TSRANGE" => \&_method_interval_nick_tsrange,
    "DELETE INTERVAL NICK _TERM _TSRANGE" => \&_method_interval_nick_tsrange,
    "GET INTERVAL SELF" => \&_method_interval_self,
    "PUT INTERVAL SELF" => \&_method_interval_self,
    "POST INTERVAL SELF" => \&_method_interval_self,
    "DELETE INTERVAL SELF" => \&_method_interval_self,
    "GET INTERVAL SELF _TSRANGE" => \&_method_interval_self_tsrange,
    "PUT INTERVAL SELF _TSRANGE" => \&_method_interval_self_tsrange,
    "POST INTERVAL SELF _TSRANGE" => \&_method_interval_self_tsrange,
    "DELETE INTERVAL SELF _TSRANGE" => \&_method_interval_self_tsrange,

    # Lock commands
    "GET LOCK" => \&_method_lock,
    "PUT LOCK" => \&_method_lock,
    "POST LOCK" => \&_method_lock,
    "DELETE LOCK" => \&_method_lock,
    "GET LOCK EID _NUM" => \&_method_lock_eid,
    "PUT LOCK EID _NUM" => \&_method_lock_eid,
    "POST LOCK EID _NUM" => \&_method_lock_eid,
    "DELETE LOCK EID _NUM" => \&_method_lock_eid,
    "GET LOCK EID _NUM _TSRANGE" => \&_method_lock_eid_tsrange,
    "PUT LOCK EID _NUM _TSRANGE" => \&_method_lock_eid_tsrange,
    "POST LOCK EID _NUM _TSRANGE" => \&_method_lock_eid_tsrange,
    "DELETE LOCK EID _NUM _TSRANGE" => \&_method_lock_eid_tsrange,
    "GET LOCK LID _NUM" => \&_method_lock_lid,
    "PUT LOCK LID _NUM" => \&_method_lock_lid,
    "POST LOCK LID _NUM" => \&_method_lock_lid,
    "DELETE LOCK LID _NUM" => \&_method_lock_lid,
    "GET LOCK NEW" => \&_method_lock_new,
    "PUT LOCK NEW" => \&_method_lock_new,
    "POST LOCK NEW" => \&_method_lock_new,
    "DELETE LOCK NEW" => \&_method_lock_new,
    "GET LOCK NICK _TERM" => \&_method_lock_nick,
    "PUT LOCK NICK _TERM" => \&_method_lock_nick,
    "POST LOCK NICK _TERM" => \&_method_lock_nick,
    "DELETE LOCK NICK _TERM" => \&_method_lock_nick,
    "GET LOCK NICK _TERM _TSRANGE" => \&_method_lock_nick_tsrange,
    "PUT LOCK NICK _TERM _TSRANGE" => \&_method_lock_nick_tsrange,
    "POST LOCK NICK _TERM _TSRANGE" => \&_method_lock_nick_tsrange,
    "DELETE LOCK NICK _TERM _TSRANGE" => \&_method_lock_nick_tsrange,
    "GET LOCK SELF" => \&_method_lock_self,
    "PUT LOCK SELF" => \&_method_lock_self,
    "POST LOCK SELF" => \&_method_lock_self,
    "DELETE LOCK SELF" => \&_method_lock_self,
    "GET LOCK SELF _TSRANGE" => \&_method_lock_self_tsrange,
    "PUT LOCK SELF _TSRANGE" => \&_method_lock_self_tsrange,
    "POST LOCK SELF _TSRANGE" => \&_method_lock_self_tsrange,
    "DELETE LOCK SELF _TSRANGE" => \&_method_lock_self_tsrange,

    # Priv commands
    "GET PRIV" => \&_method_priv,
    "PUT PRIV" => \&_method_priv,
    "POST PRIV" => \&_method_priv,
    "DELETE PRIV" => \&_method_priv,
    "GET PRIV EID _NUM" => \&_method_priv_eid_num,
    "PUT PRIV EID _NUM" => \&_method_priv_eid_num,
    "POST PRIV EID _NUM" => \&_method_priv_eid_num,
    "DELETE PRIV EID _NUM" => \&_method_priv_eid_num,
    "GET PRIV EID _NUM _TIMESTAMP" => \&_method_priv_eid_num_timestamp,
    "PUT PRIV EID _NUM _TIMESTAMP" => \&_method_priv_eid_num_timestamp, 
    "POST PRIV EID _NUM _TIMESTAMP" => \&_method_priv_eid_num_timestamp, 
    "DELETE PRIV EID _NUM _TIMESTAMP" => \&_method_priv_eid_num_timestamp,
    "GET PRIV HISTORY EID _NUM" => \&_method_priv_history_eid_num,
    "PUT PRIV HISTORY EID _NUM" => \&_method_priv_history_eid_num,
    "POST PRIV HISTORY EID _NUM" => \&_method_priv_history_eid_num,
    "DELETE PRIV HISTORY EID _NUM" => \&_method_priv_history_eid_num,
    "GET PRIV HISTORY EID _NUM _TSRANGE" => \&_method_priv_history_eid_num_tsrange,
    "PUT PRIV HISTORY EID _NUM _TSRANGE" => \&_method_priv_history_eid_num_tsrange,
    "POST PRIV HISTORY EID _NUM _TSRANGE" => \&_method_priv_history_eid_num_tsrange,
    "DELETE PRIV HISTORY EID _NUM _TSRANGE" => \&_method_priv_history_eid_num_tsrange,
    "GET PRIV HISTORY NICK _TERM" => \&_method_priv_history_nick_term,
    "PUT PRIV HISTORY NICK _TERM" => \&_method_priv_history_nick_term,
    "POST PRIV HISTORY NICK _TERM" => \&_method_priv_history_nick_term,
    "DELETE PRIV HISTORY NICK _TERM" => \&_method_priv_history_nick_term,
    "GET PRIV HISTORY NICK _TERM _TSRANGE" => \&_method_priv_history_nick_term_tsrange,
    "PUT PRIV HISTORY NICK _TERM _TSRANGE" => \&_method_priv_history_nick_term_tsrange,
    "POST PRIV HISTORY NICK _TERM _TSRANGE" => \&_method_priv_history_nick_term_tsrange,
    "DELETE PRIV HISTORY NICK _TERM _TSRANGE" => \&_method_priv_history_nick_term_tsrange,
    "GET PRIV HISTORY PHID _NUM" => \&_method_priv_history_phid_num,
    "PUT PRIV HISTORY PHID _NUM" => \&_method_priv_history_phid_num,
    "POST PRIV HISTORY PHID _NUM" => \&_method_priv_history_phid_num,
    "DELETE PRIV HISTORY PHID _NUM" => \&_method_priv_history_phid_num,
    "GET PRIV HISTORY SELF" => \&_method_priv_history_self,
    "PUT PRIV HISTORY SELF" => \&_method_priv_history_self,
    "POST PRIV HISTORY SELF" => \&_method_priv_history_self,
    "DELETE PRIV HISTORY SELF" => \&_method_priv_history_self,
    "GET PRIV HISTORY SELF _TSRANGE" => \&_method_priv_history_self_tsrange,
    "PUT PRIV HISTORY SELF _TSRANGE" => \&_method_priv_history_self_tsrange,
    "POST PRIV HISTORY SELF _TSRANGE" => \&_method_priv_history_self_tsrange,
    "DELETE PRIV HISTORY SELF _TSRANGE" => \&_method_priv_history_self_tsrange,
    "GET PRIV NICK _TERM" => \&_method_priv_nick_term,
    "PUT PRIV NICK _TERM" => \&_method_priv_nick_term,
    "POST PRIV NICK _TERM" => \&_method_priv_nick_term,
    "DELETE PRIV NICK _TERM" => \&_method_priv_nick_term,
    "GET PRIV NICK _TERM _TIMESTAMP" => \&_method_priv_nick_term_timestamp,
    "PUT PRIV NICK _TERM _TIMESTAMP" => \&_method_priv_nick_term_timestamp,
    "POST PRIV NICK _TERM _TIMESTAMP" => \&_method_priv_nick_term_timestamp,
    "DELETE PRIV NICK _TERM _TIMESTAMP" => \&_method_priv_nick_term_timestamp,
    "GET PRIV SELF" => \&_method_priv_self,
    "PUT PRIV SELF" => \&_method_priv_self,
    "POST PRIV SELF" => \&_method_priv_self,
    "DELETE PRIV SELF" => \&_method_priv_self,
    "GET PRIV SELF _TIMESTAMP" => \&_method_priv_self_timestamp,
    "PUT PRIV SELF _TIMESTAMP" => \&_method_priv_self_timestamp,
    "POST PRIV SELF _TIMESTAMP" => \&_method_priv_self_timestamp,
    "DELETE PRIV SELF _TIMESTAMP" => \&_method_priv_self_timestamp,

    # Schedule commands
    "GET SCHEDULE" => \&_method_schedule,
    "PUT SCHEDULE" => \&_method_schedule,
    "POST SCHEDULE" => \&_method_schedule,
    "DELETE SCHEDULE" => \&_method_schedule,
    "GET SCHEDULE ALL" => \&_method_schedule_all,
    "PUT SCHEDULE ALL" => \&_method_schedule_all,
    "POST SCHEDULE ALL" => \&_method_schedule_all,
    "DELETE SCHEDULE ALL" => \&_method_schedule_all,
    "GET SCHEDULE ALL DISABLED" => \&_method_schedule_all_disabled,
    "PUT SCHEDULE ALL DISABLED" => \&_method_schedule_all_disabled,
    "POST SCHEDULE ALL DISABLED" => \&_method_schedule_all_disabled,
    "DELETE SCHEDULE ALL DISABLED" => \&_method_schedule_all_disabled,
    "GET SCHEDULE EID _NUM" => \&_method_schedule_eid_num,
    "PUT SCHEDULE EID _NUM" => \&_method_schedule_eid_num,
    "POST SCHEDULE EID _NUM" => \&_method_schedule_eid_num,
    "DELETE SCHEDULE EID _NUM" => \&_method_schedule_eid_num,
    "GET SCHEDULE EID _NUM _TIMESTAMP" => \&_method_schedule_eid_num_timestamp,
    "PUT SCHEDULE EID _NUM _TIMESTAMP" => \&_method_schedule_eid_num_timestamp,
    "POST SCHEDULE EID _NUM _TIMESTAMP" => \&_method_schedule_eid_num_timestamp,
    "DELETE SCHEDULE EID _NUM _TIMESTAMP" => \&_method_schedule_eid_num_timestamp,
    "GET SCHEDULE HISTORY EID _NUM" => \&_method_schedule_history_eid_num,
    "PUT SCHEDULE HISTORY EID _NUM" => \&_method_schedule_history_eid_num,
    "POST SCHEDULE HISTORY EID _NUM" => \&_method_schedule_history_eid_num,
    "DELETE SCHEDULE HISTORY EID _NUM" => \&_method_schedule_history_eid_num,
    "GET SCHEDULE HISTORY EID _NUM _TSRANGE" => \&_method_schedule_history_eid_num_tsrange,
    "PUT SCHEDULE HISTORY EID _NUM _TSRANGE" => \&_method_schedule_history_eid_num_tsrange,
    "POST SCHEDULE HISTORY EID _NUM _TSRANGE" => \&_method_schedule_history_eid_num_tsrange,
    "DELETE SCHEDULE HISTORY EID _NUM _TSRANGE" => \&_method_schedule_history_eid_num_tsrange,
    "GET SCHEDULE HISTORY NICK _TERM" => \&_method_schedule_history_nick_term,
    "PUT SCHEDULE HISTORY NICK _TERM" => \&_method_schedule_history_nick_term,
    "POST SCHEDULE HISTORY NICK _TERM" => \&_method_schedule_history_nick_term,
    "DELETE SCHEDULE HISTORY NICK _TERM" => \&_method_schedule_history_nick_term,
    "GET SCHEDULE HISTORY NICK _TERM _TSRANGE" => \&_method_schedule_history_nick_term_tsrange,
    "PUT SCHEDULE HISTORY NICK _TERM _TSRANGE" => \&_method_schedule_history_nick_term_tsrange,
    "POST SCHEDULE HISTORY NICK _TERM _TSRANGE" => \&_method_schedule_history_nick_term_tsrange,
    "DELETE SCHEDULE HISTORY NICK _TERM _TSRANGE" => \&_method_schedule_history_nick_term_tsrange,
    "GET SCHEDULE HISTORY SELF" => \&_method_schedule_history_self,
    "PUT SCHEDULE HISTORY SELF" => \&_method_schedule_history_self,
    "POST SCHEDULE HISTORY SELF" => \&_method_schedule_history_self,
    "DELETE SCHEDULE HISTORY SELF" => \&_method_schedule_history_self,
    "GET SCHEDULE HISTORY SELF _TSRANGE" => \&_method_schedule_history_self_tsrange,
    "PUT SCHEDULE HISTORY SELF _TSRANGE" => \&_method_schedule_history_self_tsrange,
    "POST SCHEDULE HISTORY SELF _TSRANGE" => \&_method_schedule_history_self_tsrange,
    "DELETE SCHEDULE HISTORY SELF _TSRANGE" => \&_method_schedule_history_self_tsrange,
    "GET SCHEDULE HISTORY SHID _NUM" => \&_method_schedule_history_shid_num,
    "PUT SCHEDULE HISTORY SHID _NUM" => \&_method_schedule_history_shid_num,
    "POST SCHEDULE HISTORY SHID _NUM" => \&_method_schedule_history_shid_num,
    "DELETE SCHEDULE HISTORY SHID _NUM" => \&_method_schedule_history_shid_num,
    "GET SCHEDULE NICK _TERM" => \&_method_schedule_nick_term,
    "PUT SCHEDULE NICK _TERM" => \&_method_schedule_nick_term,
    "POST SCHEDULE NICK _TERM" => \&_method_schedule_nick_term,
    "DELETE SCHEDULE NICK _TERM" => \&_method_schedule_nick_term,
    "GET SCHEDULE NICK _TERM _TIMESTAMP" => \&_method_schedule_nick_term_timestamp,
    "PUT SCHEDULE NICK _TERM _TIMESTAMP" => \&_method_schedule_nick_term_timestamp,
    "POST SCHEDULE NICK _TERM _TIMESTAMP" => \&_method_schedule_nick_term_timestamp,
    "DELETE SCHEDULE NICK _TERM _TIMESTAMP" => \&_method_schedule_nick_term_timestamp,
    "GET SCHEDULE SCODE _TERM" => \&_method_schedule_scode_term,
    "PUT SCHEDULE SCODE _TERM" => \&_method_schedule_scode_term,
    "POST SCHEDULE SCODE _TERM" => \&_method_schedule_scode_term,
    "DELETE SCHEDULE SCODE _TERM" => \&_method_schedule_scode_term,
    "GET SCHEDULE SELF" => \&_method_schedule_self,
    "PUT SCHEDULE SELF" => \&_method_schedule_self,
    "POST SCHEDULE SELF" => \&_method_schedule_self,
    "DELETE SCHEDULE SELF" => \&_method_schedule_self,
    "GET SCHEDULE SELF _TIMESTAMP" => \&_method_schedule_self_timestamp,
    "PUT SCHEDULE SELF _TIMESTAMP" => \&_method_schedule_self_timestamp,
    "POST SCHEDULE SELF _TIMESTAMP" => \&_method_schedule_self_timestamp,
    "DELETE SCHEDULE SELF _TIMESTAMP" => \&_method_schedule_self_timestamp,
    "GET SCHEDULE SID _NUM" => \&_method_schedule_sid_num,
    "PUT SCHEDULE SID _NUM" => \&_method_schedule_sid_num,
    "POST SCHEDULE SID _NUM" => \&_method_schedule_sid_num,
    "DELETE SCHEDULE SID _NUM" => \&_method_schedule_sid_num,

    # Activity commands
    "ACTIVITY" => \&activity_all,
    "ACTIVITY ALL" => \&activity_all,
    "ACTIVITY ALL DISABLED" => \&activity_all,
    
    # Report commands
    #"COMPONENT PATH _PATH" => \&component_path,
    "GENERATE REPORT _PATH" => \&generate_report,
    "GENERATE REPORT _PATH _JSON" => \&generate_report,

    # Employee commands
    "EMPLOYEE" => \&employee_profile,
    "EID" => \&noop,
    "NICK" => \&noop,
    "SEC_ID" => \&noop,
    "EMPLOYEE LDAP" => \&employee_ldap,
    "EMPLOYEE LIST" => \&employee_list,
    "EMPLOYEE LIST _TERM" => \&employee_list,
    "EMPLOYEE PROFILE" => \&employee_profile,
    "EMPLOYEE SHOW" => \&employee_profile,
    "EMPLOYEE_SPEC" => \&employee_profile,
    "EMPLOYEE_SPEC LDAP" => \&employee_ldap,
    "EMPLOYEE_SPEC LDAP IMPORT" => \&employee_ldap_import,
    "EMPLOYEE_SPEC PROFILE" => \&employee_profile,
    "EMPLOYEE_SPEC SHOW" => \&employee_profile,
    "EMPLOYEE SEC_ID _TERM" => \&set_employee_self_sec_id,
    "EMPLOYEE SET SEC_ID _TERM" => \&set_employee_self_sec_id,
    "EMPLOYEE FULLNAME" => \&set_employee_self_fullname,
    "EMPLOYEE SET FULLNAME" => \&set_employee_self_fullname,
    "EMPLOYEE_SPEC SEC_ID _TERM" => \&set_employee_other_sec_id,
    "EMPLOYEE_SPEC SET SEC_ID _TERM" => \&set_employee_other_sec_id,
    "EMPLOYEE_SPEC FULLNAME" => \&set_employee_other_fullname,
    "EMPLOYEE_SPEC SET FULLNAME" => \&set_employee_other_fullname,
    "EMPLOYEE_SPEC SUPERVISOR _TERM" => \&set_employee_supervisor,
    "EMPLOYEE_SPEC SET SUPERVISOR _TERM" => \&set_employee_supervisor,
    "EMPLOYEE PASSWORD" => \&set_employee_self_password,
    "EMPLOYEE SET PASSWORD" => \&set_employee_self_password,
    "EMPLOYEE_SPEC PASSWORD" => \&set_employee_other_password,
    "EMPLOYEE_SPEC SET PASSWORD" => \&set_employee_other_password,
    "EMPLOYEE TEAM" => \&employee_team,
    "EMPLOYEE_SPEC TEAM" => \&employee_team,

    # History commands
    "PRIV HISTORY" => \&dump_priv_history,
    "EMPLOYEE_SPEC PRIV HISTORY" => \&dump_priv_history,
    "SCHEDULE HISTORY" => \&dump_schedule_history,
    "EMPLOYEE_SPEC SCHEDULE HISTORY" => \&dump_schedule_history,
    "EMPLOYEE_SPEC PRIV_SPEC _DATE" => \&add_priv_history,
    "EMPLOYEE_SPEC PRIV_SPEC EFFECTIVE _DATE" => \&add_priv_history,
    "EMPLOYEE_SPEC SCHEDULE_SPEC _DATE" => \&add_schedule_history,
    "EMPLOYEE_SPEC SCHEDULE_SPEC EFFECTIVE _DATE" => \&add_schedule_history,
    "EMPLOYEE_SPEC SID" => \&noop,
    "EMPLOYEE_SPEC SCODE" => \&noop,
    "EMPLOYEE_SPEC SET PRIV_SPEC _DATE" => \&add_priv_history,
    "EMPLOYEE_SPEC SET PRIV_SPEC EFFECTIVE _DATE" => \&add_priv_history,
    "EMPLOYEE_SPEC SET SCHEDULE_SPEC _DATE" => \&add_schedule_history,
    "EMPLOYEE_SPEC SET SCHEDULE_SPEC EFFECTIVE _DATE" => \&add_schedule_history,
    "PHISTORY_SPEC REMARK" => \&set_history_remark,
    "PHISTORY_SPEC SET REMARK" => \&set_history_remark,
    "SHISTORY_SPEC REMARK" => \&set_history_remark,
    "SHISTORY_SPEC SET REMARK" => \&set_history_remark,

    # Interval commands

    # fetch/fillup intervals
    "INTERVAL" => \&interval_promptdate,
    "EMPLOYEE_SPEC INTERVAL" => \&interval_promptdate,
    "INTERVAL FETCH" => \&interval_promptdate,
    "EMPLOYEE_SPEC INTERVAL FETCH" => \&interval_promptdate,
    "INTERVAL FILLUP" => \&interval_promptdate,
    "EMPLOYEE_SPEC INTERVAL FILLUP" => \&interval_promptdate,
    "INTERVAL FILLUP DRY_RUN" => \&interval_promptdate,
    "EMPLOYEE_SPEC INTERVAL FILLUP DRY_RUN" => \&interval_promptdate,
    "INTERVAL SUMMARY" => \&interval_promptdate,
    "EMPLOYEE_SPEC INTERVAL SUMMARY" => \&interval_promptdate,
    "INTERVAL REPORT" => \&interval_promptdate,
    "EMPLOYEE_SPEC INTERVAL REPORT" => \&interval_promptdate,
    "INTERVAL DELETE" => \&interval_promptdate,
    "EMPLOYEE_SPEC INTERVAL DELETE" => \&interval_promptdate,

    "INTERVAL _DATE" => \&interval_date,
    "EMPLOYEE_SPEC INTERVAL _DATE" => \&interval_date,
    "INTERVAL FETCH _DATE" => \&interval_date,
    "EMPLOYEE_SPEC INTERVAL FETCH _DATE" => \&interval_date,
    "INTERVAL FILLUP _DATE" => \&interval_date,
    "EMPLOYEE_SPEC INTERVAL FILLUP _DATE" => \&interval_date,
    "INTERVAL FILLUP DRY_RUN _DATE" => \&interval_date,
    "EMPLOYEE_SPEC INTERVAL FILLUP DRY_RUN _DATE" => \&interval_date,
    "INTERVAL SUMMARY _DATE" => \&interval_date,
    "EMPLOYEE_SPEC INTERVAL SUMMARY _DATE" => \&interval_date,
    "INTERVAL REPORT _DATE" => \&interval_date,
    "EMPLOYEE_SPEC INTERVAL REPORT _DATE" => \&interval_date,
    "INTERVAL DELETE _DATE" => \&interval_date,
    "EMPLOYEE_SPEC INTERVAL DELETE _DATE" => \&interval_date,

    "INTERVAL _DATE _DATE1" => \&interval_date_date1,
    "EMPLOYEE_SPEC INTERVAL _DATE _DATE1" => \&interval_date_date1,
    "INTERVAL FETCH _DATE _DATE1" => \&interval_date_date1,
    "EMPLOYEE_SPEC INTERVAL FETCH _DATE _DATE1" => \&interval_date_date1,
    "INTERVAL FILLUP _DATE _DATE1" => \&interval_date_date1,
    "EMPLOYEE_SPEC INTERVAL FILLUP _DATE _DATE1" => \&interval_date_date1,
    "INTERVAL FILLUP DRY_RUN _DATE _DATE1" => \&interval_date_date1,
    "EMPLOYEE_SPEC INTERVAL FILLUP DRY_RUN _DATE _DATE1" => \&interval_date_date1,
    "INTERVAL SUMMARY _DATE _DATE1" => \&interval_date_date1,
    "EMPLOYEE_SPEC INTERVAL SUMMARY _DATE _DATE1" => \&interval_date_date1,
    "INTERVAL REPORT _DATE _DATE1" => \&interval_date_date1,
    "EMPLOYEE_SPEC INTERVAL REPORT _DATE _DATE1" => \&interval_date_date1,
    "INTERVAL DELETE _DATE _DATE1" => \&interval_date_date1,
    "EMPLOYEE_SPEC INTERVAL DELETE _DATE _DATE1" => \&interval_date_date1,

    "INTERVAL _DATE _HYPHEN _DATE1" => \&interval_date_date1,
    "EMPLOYEE_SPEC INTERVAL _DATE _HYPHEN _DATE1" => \&interval_date_date1,
    "INTERVAL FETCH _DATE _HYPHEN _DATE1" => \&interval_date_date1,
    "EMPLOYEE_SPEC INTERVAL FETCH _DATE _HYPHEN _DATE1" => \&interval_date_date1,
    "INTERVAL FILLUP _DATE _HYPHEN _DATE1" => \&interval_date_date1,
    "EMPLOYEE_SPEC INTERVAL FILLUP _DATE _HYPHEN _DATE1" => \&interval_date_date1,
    "INTERVAL FILLUP DRY_RUN _DATE _HYPHEN _DATE1" => \&interval_date_date1,
    "EMPLOYEE_SPEC INTERVAL FILLUP DRY_RUN _DATE _HYPHEN _DATE1" => \&interval_date_date1,
    "INTERVAL SUMMARY _DATE _HYPHEN _DATE1" => \&interval_date_date1,
    "EMPLOYEE_SPEC INTERVAL SUMMARY _DATE _HYPHEN _DATE1" => \&interval_date_date1,
    "INTERVAL REPORT _DATE _HYPHEN _DATE1" => \&interval_date_date1,
    "EMPLOYEE_SPEC INTERVAL REPORT _DATE _HYPHEN _DATE1" => \&interval_date_date1,
    "INTERVAL DELETE _DATE _HYPHEN _DATE1" => \&interval_date_date1,
    "EMPLOYEE_SPEC INTERVAL DELETE _DATE _HYPHEN _DATE1" => \&interval_date_date1,

    "INTERVAL _MONTH" => \&interval_month,
    "EMPLOYEE_SPEC INTERVAL _MONTH" => \&interval_month,
    "INTERVAL FETCH _MONTH" => \&interval_month,
    "EMPLOYEE_SPEC INTERVAL FETCH _MONTH" => \&interval_month,
    "INTERVAL FILLUP _MONTH" => \&interval_month,
    "EMPLOYEE_SPEC INTERVAL FILLUP _MONTH" => \&interval_month,
    "INTERVAL FILLUP DRY_RUN _MONTH" => \&interval_month,
    "EMPLOYEE_SPEC INTERVAL FILLUP DRY_RUN _MONTH" => \&interval_month,
    "INTERVAL SUMMARY _MONTH" => \&interval_month,
    "EMPLOYEE_SPEC INTERVAL SUMMARY _MONTH" => \&interval_month,
    "INTERVAL REPORT _MONTH" => \&interval_month,
    "EMPLOYEE_SPEC INTERVAL REPORT _MONTH" => \&interval_month,
    "INTERVAL DELETE _MONTH" => \&interval_month,
    "EMPLOYEE_SPEC INTERVAL DELETE _MONTH" => \&interval_month,

    "INTERVAL _MONTH _NUM" => \&interval_month,
    "EMPLOYEE_SPEC INTERVAL _MONTH _NUM" => \&interval_month,
    "INTERVAL FETCH _MONTH _NUM" => \&interval_month,
    "EMPLOYEE_SPEC INTERVAL FETCH _MONTH _NUM" => \&interval_month,
    "INTERVAL FILLUP _MONTH _NUM" => \&interval_month,
    "EMPLOYEE_SPEC INTERVAL FILLUP _MONTH _NUM" => \&interval_month,
    "INTERVAL FILLUP DRY_RUN _MONTH _NUM" => \&interval_month,
    "EMPLOYEE_SPEC INTERVAL FILLUP DRY_RUN _MONTH _NUM" => \&interval_month,
    "INTERVAL SUMMARY _MONTH _NUM" => \&interval_month,
    "EMPLOYEE_SPEC INTERVAL SUMMARY _MONTH _NUM" => \&interval_month,
    "INTERVAL REPORT _MONTH _NUM" => \&interval_month,
    "EMPLOYEE_SPEC INTERVAL REPORT _MONTH _NUM" => \&interval_month,
    "INTERVAL DELETE _MONTH _NUM" => \&interval_month,
    "EMPLOYEE_SPEC INTERVAL DELETE _MONTH _NUM" => \&interval_month,

    "INTERVAL _NUM" => \&interval_num_num1,
    "EMPLOYEE_SPEC INTERVAL _NUM" => \&interval_num_num1,
    "INTERVAL FETCH _NUM" => \&interval_num_num1,
    "EMPLOYEE_SPEC INTERVAL FETCH _NUM" => \&interval_num_num1,
    "INTERVAL FILLUP _NUM" => \&interval_num_num1,
    "EMPLOYEE_SPEC INTERVAL FILLUP _NUM" => \&interval_num_num1,
    "INTERVAL FILLUP DRY_RUN _NUM" => \&interval_num_num1,
    "EMPLOYEE_SPEC INTERVAL FILLUP DRY_RUN _NUM" => \&interval_num_num1,
    "INTERVAL SUMMARY _NUM" => \&interval_num_num1,
    "EMPLOYEE_SPEC INTERVAL SUMMARY _NUM" => \&interval_num_num1,
    "INTERVAL REPORT _NUM" => \&interval_num_num1,
    "EMPLOYEE_SPEC INTERVAL REPORT _NUM" => \&interval_num_num1,
    "INTERVAL DELETE _NUM" => \&interval_num_num1,
    "EMPLOYEE_SPEC INTERVAL DELETE _NUM" => \&interval_num_num1,

    "INTERVAL _NUM _NUM1" => \&interval_num_num1,
    "EMPLOYEE_SPEC INTERVAL _NUM _NUM1" => \&interval_num_num1,
    "INTERVAL FETCH _NUM _NUM1" => \&interval_num_num1,
    "EMPLOYEE_SPEC INTERVAL FETCH _NUM _NUM1" => \&interval_num_num1,
    "INTERVAL FILLUP _NUM _NUM1" => \&interval_num_num1,
    "EMPLOYEE_SPEC INTERVAL FILLUP _NUM _NUM1" => \&interval_num_num1,
    "INTERVAL FILLUP DRY_RUN _NUM _NUM1" => \&interval_num_num1,
    "EMPLOYEE_SPEC INTERVAL FILLUP DRY_RUN _NUM _NUM1" => \&interval_num_num1,
    "INTERVAL SUMMARY _NUM _NUM1" => \&interval_num_num1,
    "EMPLOYEE_SPEC INTERVAL SUMMARY _NUM _NUM1" => \&interval_num_num1,
    "INTERVAL REPORT _NUM _NUM1" => \&interval_num_num1,
    "EMPLOYEE_SPEC INTERVAL REPORT _NUM _NUM1" => \&interval_num_num1,
    "INTERVAL DELETE _NUM _NUM1" => \&interval_num_num1,
    "EMPLOYEE_SPEC INTERVAL DELETE _NUM _NUM1" => \&interval_num_num1,

    "INTERVAL FILLUP _TSRANGE" => \&interval_tsrange,
    "EMPLOYEE_SPEC INTERVAL FILLUP _TSRANGE" => \&interval_tsrange,
    "INTERVAL FILLUP DRY_RUN _TSRANGE" => \&interval_tsrange,
    "EMPLOYEE_SPEC INTERVAL FILLUP DRY_RUN _TSRANGE" => \&interval_tsrange,
    "INTERVAL SUMMARY _TSRANGE" => \&interval_tsrange,
    "EMPLOYEE_SPEC INTERVAL SUMMARY _TSRANGE" => \&interval_tsrange,
    "INTERVAL REPORT _TSRANGE" => \&interval_tsrange,
    "EMPLOYEE_SPEC INTERVAL REPORT _TSRANGE" => \&interval_tsrange,

    "INTERVAL FILLUP DATELIST _TERM" => \&interval_datelist,
    "EMPLOYEE_SPEC INTERVAL FILLUP DATELIST _TERM" => \&interval_datelist,
    "INTERVAL FILLUP DATELIST DRY_RUN _TERM" => \&interval_datelist,
    "EMPLOYEE_SPEC INTERVAL FILLUP DATELIST DRY_RUN _TERM" => \&interval_datelist,

    # add/insert new intervals
    "INTERVAL _TIME _TIME1 _TERM" => \&interval_new_time_time1,
    "INTERVAL _TIME _HYPHEN _TIME1 _TERM" => \&interval_new_time_time1,
    "INTERVAL _TIMERANGE _TERM" => \&interval_new_timerange,
    "INTERVAL _DATE _TIME _TIME1 _TERM" => \&interval_new_time_time1,
    "INTERVAL _DATE _TIME _HYPHEN _TIME1 _TERM" => \&interval_new_time_time1,
    "INTERVAL _DATE _TIMERANGE _TERM" => \&interval_new_timerange,
    "INTERVAL _DATE _TIME _DATE1 _TIME1 _TERM" => \&interval_new_date_time_date1_time1,
    "INTERVAL _DATE _TIME _HYPHEN _DATE1 _TIME1 _TERM" => \&interval_new_date_time_date1_time1,

    # Lock commands

    # Priv commands
    "PRIV" => \&show_priv_as_at,
    "PRIV _DATE" => \&show_priv_as_at,
    "EMPLOYEE_SPEC PRIV" => \&show_priv_as_at,
    "EMPLOYEE_SPEC PRIV _DATE" => \&show_priv_as_at,

    # Prompt date commands
    "PROMPT _DATE" => \&change_prompt_date,
    "PROMPT DATE _DATE" => \&change_prompt_date,

    # Schedule commands
    "SCHEDULE ALL" => \&schedule_all,
    "SCHEDULE ALL DISABLED" => \&schedule_all,
    "SCHEDULE" => \&show_schedule_as_at,
    "SCHEDULE _DATE" => \&show_schedule_as_at,
    "EMPLOYEE_SPEC SCHEDULE" => \&show_schedule_as_at,
    "EMPLOYEE_SPEC SCHEDULE _DATE" => \&show_schedule_as_at,
    "SCHEDULE _DOW _TIME _DOW1 _TIME1" => \&add_memsched_entry,
    "SCHEDULE _DOW _TIME _HYPHEN _DOW1 _TIME1" => \&add_memsched_entry,
    "SCHEDULE _DOW _TIMERANGE" => \&add_memsched_entry,
    "SCHEDULE ALL _TIMERANGE" => \&replicate_memsched_entry,
    "SCHEDULE CLEAR" => \&clear_memsched_entries,
    "SCHEDULE DUMP" => \&dump_memsched_entries,
    "SCHEDULE FETCH ALL" => \&fetch_all_schedules,
    "SCHEDULE FETCH ALL DISABLED" => \&fetch_all_schedules,
    "SCHEDULE MEMORY" => \&dump_memsched_entries,
    "SCHEDULE NEW" => \&schedule_new,
    "SCHEDULE SCODE _TERM" => \&assign_memsched_scode,
    "SCHEDULE_SPEC" => \&schedulespec,
    "SCHEDULE_SPEC SHOW" => \&schedulespec,
    "SCHEDULE_SPEC REMARK" => \&schedulespec_remark,
    "SCHEDULE_SPEC SCODE _TERM" => \&schedulespec_scode,
    "SCHEDULE_SPEC SET REMARK" => \&schedulespec_remark,
    "SCHEDULE_SPEC SET SCODE _TERM" => \&schedulespec_scode,

};



=head1 FUNCTIONS

=head2 go_exit

Return the "magic" status code that causes dochazka-cli to exit.

=cut

sub go_exit {
    return $CELL->status_ok( 'DOCHAZKA_CLI_EXIT', payload => "Dochazka over and out" );
}

1;
