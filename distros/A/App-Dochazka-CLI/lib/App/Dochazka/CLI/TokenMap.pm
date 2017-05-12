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
# Token map
#
package App::Dochazka::CLI::TokenMap;

use 5.012;
use strict;
use warnings;

use Exporter qw( import );

our @EXPORT_OK = qw( $completion_map $token_map );



=head1 NAME

App::Dochazka::CLI::TokenMap - Token map



=head1 PACKAGE VARIABLES

=over

=item C<< $token_map >>

Maps tokens to regular expression "strings". These strings are just the
"business end" - the final regular expression is generated from each string in
L<App::Dochazka::CLI::Parser>. 

Whatever information you need to get out of the token needs to be in
parentheses. If the token is just a reserved word from which no information
need be extracted, just put the entire thing in parentheses. 

Note that the regex comparison that takes place in
L<App::Dochazka::CLI::Parser> uses the 'i' modifier for a case-insensitive
comparison.

=back

=cut

our $token_map = { 
#    ACTIVE    => '(active)',
    ACTIVITY  => '(activi\S*)',
    ADD       => '(add\S*)',
#    ADMIN     => '(adm\S*)',
    AID       => '(aid\S*)',
    ALL       => '(all\S*)',
#    APRIL     => '(apr\S*)',
#    AUGUST    => '(aug\S*)',
    BUGREPORT => '(bug\S*)',
    CLEAR     => '(cle\S*)',
    CODE      => '(cod\S*)',
    COMMIT    => '(comm\S*)',
    COMPONENT => '(comp\S*)',
    CONFIGINFO => '(conf\S*)',
    COOKIEJAR => '(coo\S*)',
    CORE      => '(cor\S*)',
    COUNT     => '(cou\S*)',
    CURRENT   => '(cur\S*)',
    DATE      => '(date)',
    DATELIST  => '(datel\S*)',
    DBSTATUS  => '(dbs\S*)',
#    DECEMBER  => '(dec\S*)',
    DELETE    => '(del\S*)',
    DISABLED  => '(dis\S*)',
    DOCU      => '(doc\S*)',
    DRY_RUN   => '(dry\S*)',
    DUMP      => '(dum\S*)',
    ECHO      => '(ech\S*)',
    EFFECTIVE => '(eff\S*)',
    EID       => '(eid[^\s=]*)',
    EMPLOYEE  => '(emp[^\s=]*)',
    EMPLOYEE_SPEC => '((emp|sec_id|nick|eid)\S*=([%[:alnum:]_][%[:alnum:]_-]*)*)',
    EXIT      => '(((exi)|(qui)|(\\\\q))\S*)',
#    FEBRUARY  => '(feb\S*)',
    FETCH     => '(fet\S*)',
    FILLUP    => '(fil\S*)',
    FORBIDDEN => '(for\S*)',
#    FRIDAY     => '(fri\S*)',   RESERVED BY _DOW
    FULLNAME  => '(ful\S*)',
    GENERATE  => '(gen\S*)',
    GET       => '(get\S*)',
    HISTORY   => '(his\S*)',
    HOLIDAY   => '(hol\S*)',
    HTML      => '(htm\S*)',
    IID       => '(iid\S*)',
    IMPORT    => '(imp\S*)',
#    INACTIVE  => '(ina\S*)',
    INSERT    => '(ins\S*)',
    INTERVAL  => '(int\S*)',
#    JANUARY   => '(jan\S*)',
#    JULY      => '(jul\S*)',
#    JUNE      => '(jun\S*)',
    LDAP      => '(lda\S*)',
    LID       => '(lid\S*)',
    LIST      => '(lis\S*)',
    LOCK      => '(loc\S*)',
#    MARCH     => '(mar\S*)',
#    MAY       => '(may\S*)',
    MEMORY    => '(mem\S*)',
    META      => '(met\S*)',
#    MONDAY     => '(mon\S*)',   RESERVED BY _DOW
    NEW       => '(new\S*)',
    NICK      => '(nic[^\s=]*)',
    NOOP      => '(noo\S*)',
#    NOVEMBER  => '(nov\S*)',
#    OCTOBER   => '(oct\S*)',
    PARAM     => '(par\S*)',
#    PASSERBY  => '(passe\S*)',
    PASSWORD  => '(passw\S*)',
    PATH      => '(pat\S*)',
    PHID      => '(phi[^\s=]*)',
    PHISTORY_SPEC => 'phi[^\s=]*=(\d+)',
    POD       => '(pod\S*)',
    POST      => '(pos\S*)',
    PRIV      => '(pri\S*)',
    PRIV_SPEC  => '((active)|(adm\S*)|(ina\S*)|(passe\S*))',
    PROFILE   => '(prof\S*)',
    PROMPT    => '(prom\S*)',
    PUT       => '(put\S*)',
    REMARK    => '(rem\S*)',
    REPORT    => '(rep\S*)',
#    SATURDAY    => '(sat\S*)',  RESERVED BY _DOW
    SCHEDULE  => '(sch\S*)',
    SCHEDULE_SPEC => '((sco|sid)[^\s=]*=([%[:alnum:]_][%[:alnum:]_-]*)*)',
    SCODE     => '(sco[^\s=]*)',
    SEARCH    => '(sea\S*)',
    SEC_ID    => '(sec[^\s=]*)',
    SELF      => '(sel\S*)',
#    SEPTEMBER => '(sep\S*)',
    SESSION   => '(ses\S*)',
    SET       => '(set\S*)',
    SHID      => '(shi[^\s=]*)',
    SHISTORY_SPEC => 'shi[^\s=]*=(\d+)',
    SHOW      => '(sho\S*)',
    SID       => '(sid[^\s=]*)',
    SITE      => '(sit\S*)',
#    SUNDAY    => '(sun\S*)',  RESERVED BY _DOW
    SUMMARY   => '(sum\S*)',
    SUPERVISOR => '(sup\S*)',
    TEAM      => '(tea\S*)',
    TEXT      => '(tex\S*)',
#    THURSDAY    => '(thu\S*)',  RESERVED BY _DOW
#    TODAY       => '(tod\S*)',  RESERVED BY _TIMESTAMP
#    TOMORROW    => '(tom\S*)',  RESERVED BY _TIMESTAMP
#    TUESDAY    => '(tue\S*)',  RESERVED BY _DOW
    VERSION   => '(ver\S*)',
#    WEDNESDAY    => '(wed\S*)',  RESERVED BY _DOW
    WHOAMI    => '(who\S*)',
#    YESTERDAY => '(yes\S*)',  RESERVED BY _TIMESTAMP
    _DATE     => '(((\d{2,4}-)?\d{1,2}-\d{1,2})|(tod\S*)|(tom\S*)|(yes\S*)|([\+\-]\d{1,3}))',
    _DOCU     => '(([^\{\s]+)|(\"[^\"]*\"))',
    _DOW      => '((mon\S*)|(tue\S*)|(wed\S*)|(thu\S*)|(fri\S*)|(sat\S*)|(sun\S*))',
    _HYPHEN   => '(-)',
    _JSON     => '(\{[^\{]*\})',
    _MONTH    => '((jan\S*)|(feb\S*)|(mar\S*)|(apr\S*)|(may\S*)|(jun\S*)|(jul\S*)|(aug\S*)|(sep\S*)|(oct\S*)|(nov\S*)|(dec\S*))',
    _NUM      => '([123456789][0123456789]*)',
    _PATH     => '([[:alnum:]_.][[:alnum:]_/.-]+)',
    _TERM     => '([%[:alnum:]_][%[:alnum:]_-]*)',
    _TIME     => '(\d{1,2}:\d{1,2}(:\d{1,2})?)',
    _TIMERANGE => '(\d{1,2}:\d{1,2}-\d{1,2}:\d{1,2})',
    _TIMESTAMP => '(\"?(\d{2,4}-)?\d{1,2}-\d{1,2}(\s+\d{1,2}:\d{1,2}(:\d{1,2})?)?\"?)',
    _TIMESTAMPDEPR => '(\"?((?<dp>((\d{2,4}-)?\d{1,2}-\d{1,2})|(tod\S*)|(tom\S*)|(yes\S*))\s+)?(?<tp>\d{1,2}:\d{1,2}(:\d{1,2})?)\"?)',
    _TSRANGE  => '([\[\(][^\[\(\]\)]*,[^\[\(]*[\]\)])',
};

our $completion_map = {
    active => 'PRIV_SPEC',
    activity => 'ACTIVITY',
    add => 'ADD',
    admin => 'PRIV_SPEC',
    aid => 'AID',
    all => 'ALL',
    april => '_MONTH',
    august => '_MONTH',
    bugreport => 'BUGREPORT',
    clear => 'CLEAR',
    code => 'CODE',
    commit => 'COMMIT',
    component => 'COMPONENT',
    configinfo => 'CONFIGINFO',
    cookiejar => 'COOKIEJAR',
    core => 'CORE',
    count => 'COUNT',
    current => 'CURRENT',
    date => 'DATE',
    datelist => 'DATELIST',
    dbstatus => 'DBSTATUS',
    december => '_MONTH',
    delete => 'DELETE',
    disabled => 'DISABLED',
    docu => 'DOCU',
    dry_run => 'DRY_RUN',
    dump => 'DUMP',
    echo => 'ECHO',
    effective => 'EFFECTIVE',
    eid => 'EID',
    'eid=' => 'EMPLOYEE_SPEC',
    employee => 'EMPLOYEE',
    'employee=' => 'EMPLOYEE_SPEC',
    exit => 'EXIT',
    february => '_MONTH',
    fetch => 'FETCH',
    fillup => 'FILLUP',
    forbidden => 'FORBIDDEN',
    friday => '_DOW',
    fullname => 'FULLNAME',
    generate => 'GENERATE',
    get => 'GET',
    history => 'HISTORY',
    holiday => 'HOLIDAY',
    html => 'HTML',
    iid => 'IID',
    import => 'IMPORT',
    inactive => 'PRIV_SPEC',
    insert => 'INSERT',
    interval => 'INTERVAL',
    january => '_MONTH',
    july => '_MONTH',
    june => '_MONTH',
    ldap => 'LDAP',
    lid => 'LID',
    list => 'LIST',
    lock => 'LOCK',
    march => '_MONTH',
    may => '_MONTH',
    memory => 'MEMORY',
    meta => 'META',
    monday => '_DOW',
    new => 'NEW',
    nick => 'NICK',
    'nick=' => 'EMPLOYEE_SPEC',
    noop => 'NOOP',
    november => '_MONTH',
    october => '_MONTH',
    param => 'PARAM',
    passerby => 'PRIV_SPEC',
    password => 'PASSWORD',
    path => 'PATH',
    phid => 'PHID',
    'phid=' => 'PHISTORY_SPEC',
    pod => 'POD',
    post => 'POST',
    priv => 'PRIV',
    profile => 'PROFILE',
    prompt => 'PROMPT',
    put => 'PUT',
    quit => 'QUIT',
    remark => 'REMARK',
    report => 'REPORT',
    saturday => '_DOW',
    schedule => 'SCHEDULE',
    scode => 'SCODE',
    'scode=' => 'SCHEDULE_SPEC',
    search => 'SEARCH',
    sec_id => 'SEC_ID',
    'sec_id=' => 'EMPLOYEE_SPEC',
    self => 'SELF',
    september => '_MONTH',
    session => 'SESSION',
    set => 'SET',
    shid => 'SHID',
    'shid=' => 'SHISTORY_SPEC',
    show => 'SHOW',
    sid => 'SID',
    'sid=' => 'SCHEDULE_SPEC',
    site => 'SITE',
    sunday => '_DOW',
    summary => 'SUMMARY',
    supervisor => 'SUPERVISOR',
    team => 'TEAM',
    text => 'TEXT',
    thursday => '_DOW',
    today => '_TIMESTAMP',
    tomorrow => '_TIMESTAMP',
    tuesday => '_DOW',
    version => 'VERSION',
    wednesday => '_DOW',
    whoami => 'WHOAMI',
    yesterday => '_TIMESTAMP',
};

1;
