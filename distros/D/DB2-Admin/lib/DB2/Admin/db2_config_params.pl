#
# db2_config_params - Data on database manager and database
#                     configuration parameters.
#
# Copyright (c) 2007-2009, Morgan Stanley & Co. Incorporated
# See ..../COPYING for terms of distribution.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation;
# version 2.1 of the License.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
# General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301  USA
#
# THE FOLLOWING DISCLAIMER APPLIES TO ALL SOFTWARE CODE AND OTHER
# MATERIALS CONTRIBUTED IN CONNECTION WITH THIS DB2 ADMINISTRATIVE API
# LIBRARY:
#
# THIS SOFTWARE IS LICENSED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE AND ANY WARRANTY OF NON-INFRINGEMENT, ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. THIS
# SOFTWARE MAY BE REDISTRIBUTED TO OTHERS ONLY BY EFFECTIVELY USING
# THIS OR ANOTHER EQUIVALENT DISCLAIMER AS WELL AS ANY OTHER LICENSE
# TERMS THAT MAY APPLY.
#
# $Id: db2_config_params.pl,v 165.3 2009/03/03 18:31:34 biersma Exp $
#

#
# The db2CfgGet and db2CfgSet calls expect the caller to provide a
# configuration parameter code and a pointer to the data.  The caller
# must know the type and maximum size, or bad things will happen.
#
# In order to deal with this (frankly misdesigned) API, this table
# records the known types and, for strings, data sizes for each known
# parameter.
#
# As to why IBM doesn't use the self-describing format used for
# snapshots and events, who knows?
#
# Entries have the following keys:
# - Name
# - Type
# - Length (type String only)
# - Updatable
# - Domain (Database / Manager)
#
$config_params = {
    'SQLF_KTN_AGENT_STACK_SZ' => {
        'Type'      => 'u16bit',
        'Name'      => 'agent_stack_sz',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_AGENTPRI' => {
        'Type'      => '16bit',
        'Name'      => 'agentpri',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_ALT_COLLATE' => {
        'Type'      => 'u32bit',
        'Name'      => 'alt_collate',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_KTN_ALTERNATE_AUTH_ENC' => { # New with V9.7
        'Type'      => 'u16bit',
        'Name'      => 'alternate_auth_enc',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_APP_CTL_HEAP_SZ' => {
        'Name'      => 'app_ctl_heap_sz',
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_APPGROUP_MEM_SZ' => {
        'Type'      => 'u32bit',
        'Name'      => 'appgroup_mem_sz',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_APPLHEAPSZ' => {
        'Type'      => 'u16bit',
        'Name'      => 'applheapsz',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_APPL_MEMORY' => { # New with V9.5
        'Type'      => 'u64bit',
        'Name'      => 'appl_memory',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_ARCHRETRYDELAY' => {
        'Type'      => 'u16bit',
        'Name'      => 'archretrydelay',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_KTN_ASLHEAPSZ' => {
        'Type'      => 'u32bit',
        'Name'      => 'aslheapsz',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_AUDIT_BUF_SZ' => {
        'Type'      => '32bit',
        'Name'      => 'audit_buf_sz',
        'Updatable' => 1,
        'Domain'    => [ 'Manager', 'Database' ],
    },
    'SQLF_KTN_AUTHENTICATION' => {
        'Type'      => 'u16bit',
        'Name'      => 'authentication',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_AUTO_DEL_REC_OBJ' => { # New with V9.5
        'Type'      => 'u16bit',
        'Name'      => 'auto_del_rec_obj',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_AUTO_REVAL' => { # New with V9.7
        'Type'      => 'u16bit',
        'Name'      => 'auto_revalidation',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_AUTONOMIC_SWITCHES' => {
        'Type'      => 'u32bit',
        'Name'      => 'autonomic_switches',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_AUTO_RESTART' => {
        'Type'      => 'u16bit',
        'Name'      => 'autorestart',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_AUTO_STMT_STATS' => { # New with V9.5
        'Type'      => 'u16bit',
        'Name'      => 'auto_stmt_stats',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_AUTO_STMT_STATS_EFF' => { # New with V9.5
        'Type'      => 'u16bit',
        'Name'      => 'auto_stmt_stats_eff', # Not documented
        'Updatable' => 0, # Not sure
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_AVG_APPLS' => {
        'Type'      => 'u16bit',
        'Name'      => 'avg_appls',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_BACKUP_PENDING' => {
        'Type'      => 'u16bit',
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'backup_pending',
    },
    'SQLF_DBTN_BLK_LOG_DSK_FUL' => {
        'Type'      => 'u16bit',
        'Name'      => 'blk_log_dsk_ful',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_BUFF_PAGE' => {
        'Type'      => 'u32bit',
        'Name'      => 'buffpage',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_KTN_CATALOG_NOAUTH' => {
        'Type'      => 'u16bit',
        'Name'      => 'catalog_noauth',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_CATALOGCACHE_SZ' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'catalogcache_sz',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_CHNGPGS_THRESH' => {
        'Type'      => 'u16bit',
        'Name'      => 'chngpgs_thresh',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_KTN_CLNT_KRB_PLUGIN' => {
        'Type'      => 'string',
	'Length'    => 33,
        'Updatable' => 1,
        'Name'      => 'clnt_krb_plugin',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_CLNT_PW_PLUGIN' => {
        'Type'      => 'string',
	'Length'    => 33,
        'Updatable' => 1,
        'Name'      => 'clnt_pw_plugin',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_CLUSTER_MGR' => {	# New with V9.7
        'Type'      => 'string',
	'Length'    => 262,
        'Updatable' => 0,
        'Name'      => 'cluster_mgr',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_CODEPAGE' => {
        'Type'      => 'u16bit',
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'codepage',
    },
    'SQLF_DBTN_CODESET' => {
        'Type'      => 'string',
        'Name'      => 'codeset',
        'Length'    => 17,
        'Domain'    => 'Database',
        'Updatable' => 0,
    },
    'SQLF_DBTN_COLLATE_INFO' => {
        'Type'      => 'string',
        'Name'      => 'collate_info',
        'Length'    => 260,
        'Domain'    => 'Database',
        'Updatable' => 0,
    },
    'SQLF_KTN_COMM_BANDWIDTH' => {
        'Type'      => 'float',
        'Name'      => 'comm_bandwidth',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_CONN_ELAPSE' => {
        'Type'      => 'u16bit',
        'Name'      => 'conn_elapse',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_CONSISTENT' => {
        'Type'      => 'u16bit',
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'database_consistent',
    },
    'SQLF_DBTN_COPY_PROTECT' => {
        'Type'      => 'u16bit',
        'Name'      => 'copyprotect',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_COUNTRY' => {
        'Type'      => 'u16bit',
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'country',
    },
    'SQLF_KTN_CPUSPEED' => {
        'Type'      => 'float',
        'Name'      => 'cpuspeed',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_CUR_COMMIT' => {	# New with V9.7
        'Type'      => 'u32bit',
        'Name'      => 'cur_commit',
        'Updatable' => 0,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DATABASE_LEVEL' => {
        'Type'      => 'u16bit',
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'database_level',
    },
    'SQLF_DBTN_DATABASE_MEMORY' => {
        'Type'      => 'u64bit',
        'Updatable' => 1,
        'Name'      => 'database_memory',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_DATALINKS' => {
        'Type'      => '16bit',
        'Name'      => 'datalinks',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_DATE_COMPAT' => { # New with V9.7
        'Type'      => 'u16bit',
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'date_compat',
    },
    'SQLF_DBTN_DB_COLLNAME' => {
        'Type'      => 'string',
	'Length'    => 128,
        'Updatable' => 1,
        'Name'      => 'db_collname',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DB_HEAP' => {
        'Type'      => 'u64bit',
        'Name'      => 'dbheap',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DB_MEM_THRESH' => {
        'Type'      => 'u16bit',
        'Name'      => 'db_mem_thresh',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DECFLT_ROUNDING' => { # New with V9.5
        'Type'      => 'u16bit',
        'Name'      => 'decflt_rounding',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DEC_TO_CHAR_FMT' => {  # New with V9.7
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'dec_to_char_fmt',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_DFT_ACCOUNT_STR' => {
        'Type'      => 'string',
	'Length'    => 25,
        'Updatable' => 1,
        'Name'      => 'dft_account_str',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_DFTDBPATH' => {
        'Type'      => 'string',
        'Length'    => 215,
        'Updatable' => 1,
        'Name'      => 'dftdbpath',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_DFT_DEGREE' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'dft_degree',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DFT_EXTENT_SZ' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'dft_extent_sz',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DFT_LOADREC_SES' => {
        'Type'      => '16bit',
        'Name'      => 'dft_loadrec_ses',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_KTN_DFT_MONSWITCHES' => {
        'Type'      => 'u16bit',
        'Name'      => 'dft_monswitches',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_DFT_MTTB_TYPES' => {
        'Type'      => 'u32bit',
        'Name'      => 'dft_mttb_types',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DFT_PREFETCH_SZ' => {
        'Type'      => '16bit',
        'Updatable' => 1,
        'Name'      => 'dft_prefetch_sz',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DFT_QUERYOPT' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'dft_queryopt',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DFT_REFRESH_AGE' => {
        'Type'      => 'string',
        'Length'    => 22,
        'Name'      => 'dft_refresh_age',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DFT_SQLMATHWARN' => {
        'Type'      => '16bit',
        'Updatable' => 1,
        'Name'      => 'dft_sqlmathwarn',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_DIAGLEVEL' => {
        'Type'      => 'u16bit',
        'Name'      => 'diaglevel',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_DIAGPATH' => {
        'Type'      => 'string',
        'Length'    => 215,
        'Name'      => 'diagpath',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_DIAGSIZE' => {	# New with V9.7
        'Type'      => 'u64bit',
        'Name'      => 'diagsize',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_DIR_CACHE' => {
        'Type'      => '16bit',
        'Updatable' => 1,
        'Name'      => 'dir_cache',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_DIR_OBJ_NAME' => {
        'Type'      => 'string',
        'Length'    => 255,
        'Updatable' => 1,
        'Name'      => 'dir_obj_name',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DISCOVER' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'discover',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_DISCOVER' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'discover',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_DISCOVER_INST' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'discover_inst',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_DLCHKTIME' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'dlchktime',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DL_EXPINT' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'dl_expint',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DL_NUM_COPIES' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'dl_num_copies',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DL_TIME_DROP' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'dl_time_drop',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DL_TOKEN' => {
        'Type'      => 'string',
        'Length'    => 10,
        'Updatable' => 1,
        'Name'      => 'dl_token',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DL_UPPER' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'dl_upper',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DL_WT_IEXPINT' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'dl_wt_iexpint',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_DYN_QUERY_MGMT' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'dyn_query_mgmt',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_ENABLE_XMLCHAR' => { # New with V9.5
        'Type'      => 'u32bit', # But boolean
        'Name'      => 'enable_xmlchar',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_ESTORE_SEG_SZ' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'estore_seg_sz',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_FAILARCHPATH' => {
        'Type'      => 'string',
        'Name'      => 'failarchpath',
        'Length'    => 243,
        'Domain'    => 'Database',
        'Updatable' => 0,
    },
    'SQLF_KTN_FCM_NUM_ANCHORS' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'fcm_num_anchors',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_FCM_NUM_BUFFERS' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'fcm_num_buffers',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_FCM_NUM_CHANNELS' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'fcm_num_channels',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_FCM_NUM_CONNECT' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'fcm_num_connect',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_FCM_NUM_RQB' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'fcm_num_rqb',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_FEDERATED' => {
        'Type'      => '16bit',
        'Updatable' => 1,
        'Name'      => 'federated',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_FEDERATED_ASYNC' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'federated_async',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_FED_NOAUTH' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'fed_noauth',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_FENCED_POOL' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'fenced_pool',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_GROUPHEAP_RATIO' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'groupheap_ratio',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_GROUP_PLUGIN' => {
        'Type'      => 'string',
	'Length'    => 33,
        'Updatable' => 1,
        'Name'      => 'group_plugin',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_INDEXREC' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'indexrec',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_HADR_DB_ROLE' => {
        'Type'      => '32bit',
        'Updatable' => 0,
        'Name'      => 'hadr_db_role',
        'Domain'    => 'Database',
    },
     'SQLF_DBTN_HADR_LOCAL_HOST' => {
        'Type'      => 'string',
	'Length'    => 255,
        'Updatable' => 0,
        'Name'      => 'hadr_local_host',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_HADR_LOCAL_SVC' => {
        'Type'      => 'string',
	'Length'    => 40,
        'Updatable' => 0,
        'Name'      => 'hadr_local_svc',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_HADR_PEER_WINDOW' => { # New with V9.5
        'Type'      => 'u32bit',
        'Updatable' => 0,
        'Name'      => 'hadr_peer_window',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_HADR_REMOTE_HOST' => {
        'Type'      => 'string',
	'Length'    => 255,
        'Updatable' => 0,
        'Name'      => 'hadr_remote_host',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_HADR_REMOTE_INST' => {
        'Type'      => 'string',
	'Length'    => 8,
        'Updatable' => 0,
        'Name'      => 'hadr_remote_inst',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_HADR_REMOTE_SVC' => {
        'Type'      => 'string',
	'Length'    => 40,
        'Updatable' => 0,
        'Name'      => 'hadr_remote_svc',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_HADR_SYNCMODE' => {
        'Type'      => 'u32bit',
        'Updatable' => 0,
        'Name'      => 'hadr_syncmode',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_HADR_TIMEOUT' => {
        'Type'      => '32bit',
        'Updatable' => 0,
        'Name'      => 'hadr_timeout',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_HEALTH_MON' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'health_mon',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_INDEXREC' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'indexrec',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_INDEXSORT' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'indexsort',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_INSTANCE_MEMORY' => {
        'Type'      => 'u64bit',
        'Updatable' => 1,
        'Name'      => 'instance_memory',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_INTRA_PARALLEL' => {
        'Type'      => '16bit',
        'Updatable' => 1,
        'Name'      => 'intra_parallel',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_JAVA_HEAP_SZ' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'java_heap_sz',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_JDK_PATH' => {
        'Type'      => 'string',
        'Length'    => 255,
        'Updatable' => 1,
        'Name'      => 'jdk_path',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_JDK11_PATH' => {
        'Type'      => 'string',
        'Length'    => 255,
        'Updatable' => 1,
        'Name'      => 'jdk11_path',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_KEEPFENCED' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'keepfenced',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_LOCAL_GSSPLUGIN' => {
        'Type'      => 'string',
	'Length'    => 33,
        'Updatable' => 1,
        'Name'      => 'local_gssplugin',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_LOCK_LIST' => {
        'Type'      => 'u64bit',
        'Updatable' => 1,
        'Name'      => 'locklist',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_LOCKTIMEOUT' => {
        'Type'      => '16bit',
        'Updatable' => 1,
        'Name'      => 'locktimeout',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_LOGARCHMETH1' => {
        'Type'      => 'string',
	'Length'    => 252,
        'Updatable' => 1,
        'Name'      => 'logarchmeth1',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_LOGARCHMETH2' => {
        'Type'      => 'string',
	'Length'    => 252,
        'Updatable' => 1,
        'Name'      => 'logarchmeth2',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_LOGARCHOPT1' => {
        'Type'      => 'string',
	'Length'    => 243,
        'Updatable' => 1,
        'Name'      => 'logarchopt1',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_LOGARCHOPT2' => {
        'Type'      => 'string',
	'Length'    => 243,
        'Updatable' => 1,
        'Name'      => 'logarchopt2',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_LOGBUFSZ' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'logbufsz',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_LOGFIL_SIZ' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'logfilsiz',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_LOGHEAD' => {
        'Type'      => 'string',
        'Length'    => 12,
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'loghead',
    },
    'SQLF_DBTN_LOGINDEXBUILD' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'logindexbuild',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_LOGPATH' => {
        'Type'      => 'string',
        'Name'      => 'logpath',
        'Length'    => 242,
        'Domain'    => 'Database',
        'Updatable' => 0,
    },
    'SQLF_DBTN_LOGPRIMARY' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'logprimary',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_LOG_RETAIN' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'logretain',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_LOGSECOND' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'logsecond',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_LOG_RETAIN_STATUS' => {
        'Type'      => 'u16bit',
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'log_retain_status',
    },
    'SQLF_KTN_MAXAGENTS' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'maxagents',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_MAXAPPLS' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'maxappls',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_MAXCAGENTS' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'maxcagents',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_MAX_CONNECTIONS' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'max_connections',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_MAX_CONNRETRIES' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'max_connretries',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_MAX_COORDAGENTS' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'max_coordagents',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_MAXFILOP' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'maxfilop',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_MAXTOTFILOP' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'maxtotfilop',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_MAXLOCKS' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'maxlocks',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_MAX_LOG' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'max_log',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_MAX_QUERYDEGREE' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'max_querydegree',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_MAX_TIME_DIFF' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'max_time_diff',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_MINCOMMIT' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'mincommit',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_MIN_DEC_DIV_3' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'min_dec_div_3',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_MIN_PRIV_MEM' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'min_priv_mem',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_MIRRORLOGPATH' => {
        'Type'      => 'string',
        'Length'    => 242,
        'Updatable' => 1,
        'Name'      => 'mirrorlogpath',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_MON_ACT_METRICS' => { # New with V9.7
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'mon_act_metrics',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_MON_DEADLOCK' => { # New with V9.7
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'mon_deadlock',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_MON_HEAP_SZ' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'mon_heap_sz',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_MON_LOCKTIMEOUT' => { # New with V9.7
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'mon_locktimeout',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_MON_LOCKWAIT' => { # New with V9.7
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'mon_lockwait',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_MON_LW_THRESH' => { # New with V9.7
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'mon_lw_thresh',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_MON_OBJ_METRICS' => { # New with V9.7
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'mon_obj_metrics',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_MON_REQ_METRICS' => { # New with V9.7
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'mon_req_metrics',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_MON_UOW_DATA' => { # New with V9.7
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'mon_uow_data',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_MULTIPAGE_ALLOC' => {
        'Type'      => 'u16bit',
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'multipage_alloc',
    },
    'SQLF_DBTN_NEWLOGPATH' => {
        'Type'      => 'string',
        'Length'    => 242,
        'Name'      => 'newlogpath',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_KTN_NNAME' => {
        'Type'      => 'string',
        'Length'    => 8,
        'Name'      => 'nname',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_NODETYPE' => {
        'Type'      => 'u16bit',
        'Name'      => 'nodetype',
        'Updatable' => 0,
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_NOTIFYLEVEL' => {
        'Type'      => '16bit',
        'Name'      => 'notifylevel',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_NUMARCHRETRY' => {
        'Type'      => 'u16bit',
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'numarchretry',
    },
    'SQLF_KTN_NUMDB' => {
        'Type'      => 'u16bit',
        'Name'      => 'numdb',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_NUM_DB_BACKUPS' => {
        'Type'      => 'u16bit',
        'Name'      => 'num_db_backups',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_NUM_ESTORE_SEGS' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'num_estore_segs',
        'Domain'    => 'Database',

    },
    'SQLF_DBTN_NUM_FREQVALUES' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'num_freqvalues',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_NUM_INITAGENTS' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'num_initagents',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_NUM_INITFENCED' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'num_initfenced',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_NUM_IOCLEANERS' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'num_iocleaners',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_NUM_IOSERVERS' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'num_ioservers',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_NUM_LOG_SPAN' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'num_log_span',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_NUM_POOLAGENTS' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'num_poolagents',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_NUM_QUANTILES' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'num_quantiles',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_NUMSEGS' => {
        'Type'      => 'u16bit',
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'numsegs',
    },
    'SQLF_DBTN_OVERFLOWLOGPATH' => {
        'Type'      => 'string',
        'Length'    => 242,
        'Updatable' => 1,
        'Name'      => 'overflowlogpath',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_PAGESIZE' => {
        'Type'      => 'u32bit',
        'Updatable' => 0,
        'Name'      => 'pagesize',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_PCKCACHESZ' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'pckcachesz',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_PCKCACHE_SZ' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'pckcachesz',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_PRIV_MEM_THRESH' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'priv_mem_thresh',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_QUERY_HEAP_SZ' => {
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'query_heap_sz',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_REC_HIS_RETENTN' => {
        'Type'      => '16bit',
        'Updatable' => 1,
        'Name'      => 'rec_his_retentn',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_RELEASE' => {
        'Type'      => 'u16bit',
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'release',
    },
    'SQLF_KTN_RELEASE' => {
        'Type'      => 'u16bit',
        'Name'      => 'release',
        'Updatable' => 0,
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_RESTORE_PENDING' => {
        'Type'      => 'u16bit',
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'restore_pending',
    },
    'SQLF_DBTN_RESTRICT_ACCESS' => {
        'Type'      => '32bit',
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'restrict_access',
    },
    'SQLF_KTN_RESYNC_INTERVAL' => {
        'Type'      => 'u16bit',
        'Name'      => 'resync_interval',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_ROLLFWD_PENDING' => {
        'Type'      => 'u16bit',
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'rollfwd_pending',
    },
    'SQLF_KTN_RQRIOBLK' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'rqrioblk',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_SELF_TUNING_MEM' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'self_tuning_mem',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_SEQDETECT' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'seqdetect',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_SHEAPTHRES' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'sheapthres',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_SHEAPTHRES' => {
        'Type'      => 'u64bit',
        'Updatable' => 1,
        'Name'      => 'sheapthres',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_SHEAPTHRES_SHR' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'sheapthres_shr',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_SMTP_SERVER' => { # New with V9.7
        'Type'      => 'string',
	'Length'    => 255,
        'Updatable' => 1,
        'Name'      => 'smtp_server',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_SOFTMAX' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'softmax',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_SORT_HEAP' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'sortheap',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_SPM_LOG_FILE_SZ' => {
        'Type'      => '32bit',
        'Name'      => 'spm_log_file_sz',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SPM_LOG_PATH' => {
        'Type'      => 'string',
	'Length'    => 226,
        'Updatable' => 1,
        'Name'      => 'spm_log_path',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SPM_MAX_RESYNC' => {
        'Type'      => '32bit',
        'Name'      => 'spm_max_resync',
        'Updatable' => 1,
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SPM_NAME' => {
        'Type'      => 'string',
	'Length'    => 8,
        'Updatable' => 1,
        'Name'      => 'spm_name',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SSL_CIPHERSPECS' => { # New with V9.7
        'Type'      => 'string',
	'Length'    => 255,
        'Updatable' => 1,
        'Name'      => 'ssl_cipherspecs',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SSL_CLNT_KEYDB' => { # New with V9.7
        'Type'      => 'string',
	'Length'    => 1023,
        'Updatable' => 1,
        'Name'      => 'ssl_clnt_keydb',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SSL_CLNT_STASH' => { # New with V9.7
        'Type'      => 'string',
	'Length'    => 1023,
        'Updatable' => 1,
        'Name'      => 'ssl_clnt_stash',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SSL_SVCENAME' => { # New with V9.7
        'Type'      => 'string',
	'Length'    => 14,
        'Updatable' => 1,
        'Name'      => 'ssl_svcename',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SSL_SVR_KEYDB' => { # New with V9.7
        'Type'      => 'string',
	'Length'    => 1023,
        'Updatable' => 1,
        'Name'      => 'ssl_svr_keydb',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SSL_SVR_LABEL' => { # New with V9.7
        'Type'      => 'string',
	'Length'    => 1023,
        'Updatable' => 1,
        'Name'      => 'ssl_svr_label',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SSL_SVR_STASH' => { # New with V9.7
        'Type'      => 'string',
	'Length'    => 1023,
        'Updatable' => 1,
        'Name'      => 'ssl_svr_stash',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SSL_SVR_VERSIONS' => { # New with V9.7
        'Type'      => 'string',
	'Length'    => 255,
        'Updatable' => 1,
        'Name'      => 'ssl_versions',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_START_STOP_TIME' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'start_stop_time',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_STAT_HEAP_SZ' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'stat_heap_sz',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_STMT_CONC' => { 	# New with V9.7
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'stmt_conc',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_STMT_HEAP' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'stmtheap',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_STMTHEAP' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'stmtheap',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_SRVCON_AUTH' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'srvcon_auth',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SRVCON_GSSPLUGIN_LIST' => {
        'Type'      => 'string',
	'Length'    => 256,
        'Updatable' => 1,
        'Name'      => 'srvcon_gssplugin_list',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SRVCON_PW_PLUGIN' => {
        'Type'      => 'string',
	'Length'    => 33,
        'Updatable' => 1,
        'Name'      => 'srvcon_pw_plugin',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SRV_PLUGIN_MODE' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'srv_plugin_mode',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SVCENAME' => {
        'Type'      => 'string',
	'Length'    => 14,
        'Updatable' => 1,
        'Name'      => 'svcename',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SYSADM_GROUP' => {
        'Type'      => 'string',
        'Length'    => 128, # 16 in V8.1 and before, 30 in V8.2/V9.1
        'Updatable' => 1,
        'Name'      => 'sysadm_group',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SYSCTRL_GROUP' => {
        'Type'      => 'string',
        'Length'    => 128, # 16 in V8.1 and before, 30 in V8.2/V9.1
        'Updatable' => 1,
        'Name'      => 'sysctrl_group',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SYSMAINT_GROUP' => {
        'Type'      => 'string',
        'Length'    => 128, # 16 in V8.1 and before, 30 in V8.2/V9.1
        'Updatable' => 1,
        'Name'      => 'sysmaint_group',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_SYSMON_GROUP' => { # New with DB2 V8.2
        'Type'      => 'string',
        'Length'    => 128, # 30 in V8.2/V9.1
        'Updatable' => 1,
        'Name'      => 'sysmon_group',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_TERRITORY' => {
        'Type'      => 'string',
        'Length'    => 33,
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'territory',
    },
    'SQLF_KTN_TM_DATABASE' => {
        'Type'      => 'string',
	'Length'    => 8,
        'Updatable' => 1,
        'Name'      => 'tm_database',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_TP_MON_NAME' => {
        'Type'      => 'string',
	'Length'    => 19,
        'Updatable' => 1,
        'Name'      => 'tp_mon_name',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_TRACKMOD' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'trackmod',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_TRUST_ALLCLNTS' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'trust_allclnts',
        'Domain'    => 'Manager',
    },
    'SQLF_KTN_TRUST_CLNTAUTH' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Name'      => 'trust_clntauth',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_TSM_MGMTCLASS' => {
        'Type'      => 'string',
        'Length'    => 64,
        'Updatable' => 1,
        'Name'      => 'tsm_mgmtclass',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_TSM_NODENAME' => {
        'Type'      => 'string',
        'Length'    => 64,
        'Updatable' => 1,
        'Name'      => 'tsm_nodename',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_TSM_OWNER' => {
        'Type'      => 'string',
        'Length'    => 64,
        'Name'      => 'tsm_owner',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_TSM_PASSWORD' => {
        'Type'      => 'string',
        'Length'    => 64,
        'Name'      => 'tsm_password',
        'Updatable' => 1,
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_USER_EXIT' => {
        'Type'      => 'u16bit',
        'Updatable' => 1,
        'Domain'    => 'Database',
        'Name'      => 'userexit',
    },
    'SQLF_DBTN_USER_EXIT_STATUS' => {
        'Type'      => 'u16bit',
        'Domain'    => 'Database',
        'Updatable' => 0,
        'Name'      => 'user_exit_status',
    },
    'SQLF_DBTN_UTIL_HEAP_SZ' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'util_heap_sz',
        'Domain'    => 'Database',
    },
    'SQLF_KTN_UTIL_IMPACT_LIM' => {
        'Type'      => 'u32bit',
        'Updatable' => 1,
        'Name'      => 'util_impact_lim',
        'Domain'    => 'Manager',
    },
    'SQLF_DBTN_VENDOROPT' => {
        'Type'      => 'string',
	'Length'    => 242,
        'Updatable' => 1,
        'Name'      => 'vendoropt',
        'Domain'    => 'Database',
    },
    'SQLF_DBTN_WLM_COLLECT_INT' => { # New with V9.5
        'Type'      => '32bit',
        'Updatable' => 1,
        'Name'      => 'wlm_collect_int',
        'Domain'    => 'Database',
    },
    };

1;
