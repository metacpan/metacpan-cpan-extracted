// ************************************************************************* 
// Copyright (c) 2014-2017, SUSE LLC
// 
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
// 
// 3. Neither the name of SUSE LLC nor the names of its contributors may be
// used to endorse or promote products derived from this software without
// specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// ************************************************************************* 
//
// app/dform-init.js
//
// Round one of dform initialization (called from app/target-init)
//
"use strict";

define ([
    'current-user',
    'lib',
    'app/lib',
    'app/emp-lib',
    'app/rest-lib',
    'app/sched-lib',
    'app/prototypes',
    'target'
], function (
    currentUser,
    coreLib,
    appLib,
    empLib,
    restLib,
    schedLib,
    prototypes,
    target
) {

    var entries = appLib.entries;
    
    return function () {

        target.push('empProfile', {
            'name': 'empProfile',
            'type': 'dform',
            'menuText': 'My profile',
            'title': 'My profile',
            'preamble': null,
            'aclProfile': 'passerby',
            'entriesRead': [entries.ePfullname, entries.ePnick,
                entries.ePsec_id, entries.ePemail, entries.ePremark,
                entries.ePpriv, entries.ePprivEffective,
                entries.ePsched, entries.ePschedEffective],
            'entriesWrite': [],
            'miniMenu': {
                entries: ['empProfileEdit', 'ldapSync']
            }
        }); // target.push('empProfile'

        target.push('empProfileEdit', {
            'name': 'empProfileEdit',
            'type': 'dform',
            'menuText': 'Edit',
            'title': 'Employee profile edit',
            'preamble': 'Only the remark field can be modified;<br>' +
                        'All other fields are synced from LDAP',
            'aclProfile': 'admin',
            'entriesRead': [entries.ePfullname, entries.ePnick,
                entries.ePsec_id, entries.ePemail],
            'entriesWrite': [entries.ePremark],
            'miniMenu': {
                entries: ['empProfileEditSave']
            }
        }); // target.push('empProfileEdit'

        target.push('ldapLookup', {
            'name': 'ldapLookup',
            'type': 'dform',
            'menuText': 'Look up an LDAP employee',
            'title': 'Look up an LDAP employee',
            'preamble': 'Enter employee nick for exact (case insensitive) match',
            'aclProfile': 'active',
            'entriesRead': null,
            'entriesWrite': [entries.ePnick],
            'miniMenu': {
                entries: ['ldapLookupSubmit']
            }
        }); // target.push('ldapLookup'

        target.push('ldapDisplayEmployee', {
            'name': 'ldapDisplayEmployee',
            'type': 'dform',
            'title': 'LDAP employee record',
            'preamble': null,
            'aclProfile': 'active',
            'entriesRead': [entries.ePfullname, entries.ePnick,
                entries.ePsec_id, entries.ePemail, entries.LDAPdochazka],
            'entriesWrite': [],
            'miniMenu': {
                entries: ['ldapSync']
            }
        }); // target.push('ldapDisplayEmployee'

        target.push('searchEmployee', {
            'name': 'searchEmployee',
            'type': 'dform',
            'menuText': 'Search Dochazka employees',
            'title': 'Search Dochazka employees',
            'preamble': 'Enter search key, % is wildcard',
            'aclProfile': 'admin',
            'entriesRead': null,
            'entriesWrite': [entries.sEnick],
            'miniMenu': {
                entries: ['actionEmplSearch']
            }
        }); // target.push('searchEmployee'

        target.push('restServerDetails', {
            'name': 'restServerDetails',
            'type': 'dform',
            'menuText': 'REST server',
            'title': 'REST server details',
            'preamble': '<b>URI</b> used by this App::Dochazka::WWW instance to communicate ' +
                        'with REST server;<br><b>version</b> of App::Dochazka::REST running ' +
                        'on REST server',
            'aclProfile': 'admin',
            'entriesRead': [entries.rSDurl, entries.rSDversion],
            'miniMenu': {
                entries: []
            }
        }); // target.push('restServerDetails'

        target.push('privHistoryAddRecord', {
            'name': 'privHistoryAddRecord',
            'type': 'dform',
            'menuText': 'Add record',
            'title': 'Add privhistory (status) record',
            'preamble': '<b>Effective</b> date format YYYY-MM-DD;<br>' +
                        '<b>Priv</b> one of (passerby, inactive, active, admin)',
            'aclProfile': 'admin',
            'entriesRead': [entries.ePnick], 
            'entriesWrite': [entries.pHeffective, entries.pHpriv],
            'miniMenu': {
                entries: ['privHistorySaveAction']
            }
        }); // target.push('privHistoryAddRecord'

        target.push('schedHistoryAddRecord', {
            'name': 'schedHistoryAddRecord',
            'type': 'dform',
            'menuText': 'Add record',
            'title': 'Add schedule history record',
            'preamble': '<b>Effective date</b> format YYYY-MM-DD;<br>' +
                        'Enter schedule ID or schedule code - not both',
            'aclProfile': 'admin',
            'entriesRead': [entries.ePnick],
            'entriesWrite': [entries.pHeffective, entries.sDid, entries.sDcode],
            'hook': function () {
                    return {
                        'nick': currentUser('obj').nick,
                        'effective': null,
                        'sid': null,
                        'scode': null
                    };
                },
            'miniMenu': {
                entries: ['schedHistorySaveAction']
            }
        }); // target.push('schedHistoryAddRecord'

        target.push('schedLookup', {
            'name': 'schedLookup',
            'type': 'dform',
            'menuText': 'Look up schedule by code or ID',
            'title': 'Look up schedule by code or ID',
            'preamble': 'Enter a schedule code or ID',
            'aclProfile': 'passerby',
            'entriesRead': null,
            'entriesWrite': [entries.sScode, entries.sSid],
            'rememberState': false,
            'hook': function () {
                return {
                    searchKeySchedCode: null,
                    searchKeySchedID: null
                };
            },
            'miniMenu': {
                entries: ['actionSchedLookup']
            }
        }); // target.push('schedLookup'

        target.push('schedDisplay', {
            'name': 'schedDisplay',
            'type': 'dform',
            'menuText': 'schedDisplay',
            'title': 'Schedule',
            'aclProfile': 'passerby',
            'entriesRead': [entries.sDid, entries.sDcode,
                            coreLib.emptyLineEntry, entries.sDmon,
                            entries.sDtue, entries.sDwed, entries.sDthu,
                            entries.sDfri, entries.sDsat, entries.sDsun,
                            coreLib.emptyLineEntry, entries.ePremark],
            'entriesWrite': null,
            'miniMenu': {
                entries: ['schedEdit', 'schedDelete']
            }
        }); // target.push('schedDisplay'

        var schedEditObj = {
                'name': 'schedEdit',
                'type': 'dform',
                'menuText': 'Edit',
                'title': 'Schedule edit',
                'preamble': 'Only schedule code and remark can be modified<br>' +
                            'Note: code change will affect <b>all employees</b> with this schedule',
                'aclProfile': 'admin',
                'entriesRead': [entries.sDid,
                                coreLib.emptyLineEntry, entries.sDmon,
                                entries.sDtue, entries.sDwed, entries.sDthu,
                                entries.sDfri, entries.sDsat, entries.sDsun],
                'entriesWrite': [entries.sDcode, entries.ePremark],
                'miniMenu': {
                    entries: ['schedEditSave']
                }
            },
            schedEditFromBrowserObj = coreLib.shallowCopy(schedEditObj);
        schedEditFromBrowserObj.name = 'schedEditFromBrowser';
        // schedEditFromBrowserObj.miniMenu.back = ['Back', 'returnToBrowser'];
        schedEditFromBrowserObj.hook = function () {
            return coreLib.dbrowserState.set[coreLib.dbrowserState.pos];
        };
        target.push('schedEdit', schedEditObj);
        target.push('schedEditFromBrowser', schedEditFromBrowserObj);

        var schedDeleteObj = {
                'name': 'schedDelete',
                'type': 'dform',
                'menuText': 'Delete',
                'title': 'Schedule delete',
                'preamble': 'If you are really sure you want to delete this schedule,<br>' +
                            'select "Yes, I really mean it" below',
                'aclProfile': 'admin',
                'entriesRead': [entries.sDid, entries.sDcode,
                                coreLib.emptyLineEntry, entries.sDmon,
                                entries.sDtue, entries.sDwed, entries.sDthu,
                                entries.sDfri, entries.sDsat, entries.sDsun,
                                coreLib.emptyLineEntry, entries.ePremark],
                'entriesWrite': null,
                'miniMenu': {
                    entries: ['schedReallyDelete']
                }
            },
            schedDeleteFromBrowserObj = coreLib.shallowCopy(schedDeleteObj);
        schedDeleteFromBrowserObj.name = 'schedDeleteFromBrowser';
        schedDeleteFromBrowserObj.miniMenu.back = ['Back', 'returnToBrowser'];
        schedDeleteFromBrowserObj.hook = function () {
            return coreLib.dbrowserState.set[coreLib.dbrowserState.pos];
        };
        target.push('schedDelete', schedDeleteObj);
        target.push('schedDeleteFromBrowser', schedDeleteFromBrowserObj);

        target.push('schedNewBoilerplate', {
            'name': 'schedNewBoilerplate',
            'type': 'dform',
            'menuText': 'Boilerplate (quick form for Mon-Fri schedules)',
            'title': 'Create a new schedule - boilerplate',
            'preamble': 'Hint: separate schedule intervals by semi-colon<br>' +
                        'Example: 8:00-12:00; 12:30-16:30<br>' +
                        '<b>Schedule intervals will be replicated for Monday-Friday</b><br>' +
                        'Note: schedule code is optional',
            'aclProfile': 'admin',
            'entriesRead': null,
            'entriesWrite': [entries.sCboiler, entries.sDcode],
            'hook': function () {
                 return {
                     'scode': null,
                     'boilerplate': null,
                 };
            },
            'miniMenu': {
                entries: ['createSchedule']
            }
        }); // target.push('schedDisplay'

        target.push('schedNewCustom', {
            'name': 'schedNewCustom',
            'type': 'dform',
            'menuText': 'Custom (long form)',
            'title': 'Create a new schedule - custom',
            'preamble': 'Hint: separate schedule intervals by semi-colon<br>' +
                        'Example: 8:00-12:00; 12:30-16:30<br>' +
                        'Note: schedule code is optional',
            'aclProfile': 'admin',
            'entriesRead': null,
            'entriesWrite': [entries.sDmon, entries.sDtue,
                             entries.sDwed, entries.sDthu, entries.sDfri,
                             entries.sDsat, entries.sDsun, entries.sDcode],
            'hook': function () {
                 return {
                     'scode': null,
                     'mon': null,
                     'tue': null,
                     'wed': null,
                     'thu': null,
                     'fri': null,
                     'sat': null,
                     'sun': null,
                 };
            },
            'miniMenu': {
                entries: ['createSchedule']
            }
        }); // target.push('schedDisplay'

    }; // return function ()
    
});
