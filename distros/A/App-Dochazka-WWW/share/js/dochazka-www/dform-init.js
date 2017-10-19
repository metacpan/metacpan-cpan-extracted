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
    'app/emp-lib',
    'app/entries',
    'app/rest-lib',
    'app/sched-lib',
    'app/prototypes',
    'target'
], function (
    currentUser,
    coreLib,
    empLib,
    entries,
    restLib,
    schedLib,
    prototypes,
    target
) {

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
                coreLib.emptyLineEntry,
                entries.ePpriv, entries.ePprivEffective,
                coreLib.emptyLineEntry,
                entries.ePsched, entries.ePschedEffective],
            'miniMenu': {
                entries: ['empProfileEdit', 'ldapSync']
            }
        }); // empProfile

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
        }); // empProfileEdit

        target.push('ldapLookup', {
            'name': 'ldapLookup',
            'type': 'dform',
            'menuText': 'Look up an LDAP employee',
            'title': 'Look up an LDAP employee',
            'preamble': 'Enter employee nick for exact (case insensitive) match',
            'aclProfile': 'active',
            'entriesWrite': [entries.ePnick],
            'rememberState': true,
            'miniMenu': {
                entries: ['ldapLookupSubmit']
            }
        }); // ldapLookup

        target.push('ldapDisplayEmployee', {
            'name': 'ldapDisplayEmployee',
            'type': 'dform',
            'title': 'LDAP employee record',
            'preamble': null,
            'aclProfile': 'active',
            'entriesRead': [entries.ePfullname, entries.ePnick,
                entries.ePsec_id, entries.ePemail, entries.LDAPdochazka],
            'miniMenu': {
                entries: ['ldapSync']
            }
        }); // ldapDisplayEmployee

        target.push('searchEmployee', {
            'name': 'searchEmployee',
            'type': 'dform',
            'menuText': 'Search Dochazka employees',
            'title': 'Search Dochazka employees',
            'preamble': 'Enter search key, % is wildcard',
            'aclProfile': 'admin',
            'entriesWrite': [entries.sEnick],
            'miniMenu': {
                entries: ['actionEmplSearch']
            }
        }); // searchEmployee

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
        }); // restServerDetails

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
        }); // privHistoryAddRecord

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
            'miniMenu': {
                entries: ['schedHistorySaveAction']
            }
        }); // schedHistoryAddRecord

        target.push('schedLookup', {
            'name': 'schedLookup',
            'type': 'dform',
            'menuText': 'Look up schedule by code or ID',
            'title': 'Look up schedule by code or ID',
            'preamble': 'Enter a schedule code or ID (must be an exact match)',
            'aclProfile': 'passerby',
            'entriesWrite': [entries.sScode, entries.sSid],
            'rememberState': true,
            'miniMenu': {
                entries: ['actionSchedLookup']
            }
        }); // schedLookup

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
            'miniMenu': {
                entries: ['schedEdit', 'schedDelete']
            }
        }); // schedDisplay

        var schedEditObj = {
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

        schedEditObj['name'] = 'schedEdit';
        target.push('schedEdit', schedEditObj);
        schedEditFromBrowserObj['name'] = 'schedEditFromBrowser';
        target.push('schedEditFromBrowser', schedEditFromBrowserObj);

        var schedDeleteObj = {
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
                'miniMenu': {
                    entries: ['schedReallyDelete']
                }
            },
            schedDeleteFromBrowserObj = coreLib.shallowCopy(schedDeleteObj);

        schedDeleteObj.name = 'schedDelete';
        target.push('schedDelete', schedDeleteObj);
        schedDeleteFromBrowserObj['name'] = 'schedDeleteFromBrowser';
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
            'entriesRead': [entries.sDid],
            'entriesWrite': [entries.sCboiler, entries.sDcode],
            'miniMenu': {
                entries: ['createSchedule']
            }
        }); // schedNewBoilerPlate

        target.push('schedNewCustom', {
            'name': 'schedNewCustom',
            'type': 'dform',
            'menuText': 'Custom (long form)',
            'title': 'Create a new schedule - custom',
            'preamble': 'Hint: separate schedule intervals by semi-colon<br>' +
                        'Example: 8:00-12:00; 12:30-16:30<br>' +
                        'Note: schedule code is optional',
            'aclProfile': 'admin',
            'entriesRead': [entries.sDid],
            'entriesWrite': [entries.sDmon, entries.sDtue,
                             entries.sDwed, entries.sDthu, entries.sDfri,
                             entries.sDsat, entries.sDsun, entries.sDcode],
            'miniMenu': {
                entries: ['createSchedule']
            }
        }); // schedNewCustom

        target.push('createSingleInt', {
            'name': 'createSingleInt',
            'type': 'dform',
            'menuText': 'Single interval',
            'title': 'Create a single interval',
            'preamble': 'Enter date in format YYYY-MM-DD<br>' +
                        'Enter time range using 24hr format, example 11:30-15:00<br>' +
                        'Description is optional',
            'aclProfile': 'active',
            'entriesWrite': [entries.iNdate, entries.iNtimerange, entries.iNact, entries.iNdesc,],
            'rememberState': true,
            'miniMenu': {
                entries: ['selectActivityAction', 'createSingleIntSave']
            }
        }); // createSingleInt

        target.push('createLastPlusOffset', {
            // before doing any calculations, look up:
            // - employee's schedule
            // - schedule intervals on date
            // - existing intervals on date
            // timerange start will be:
            // - end of last existing interval, if there are existing intervals
            // - start of first schedule interval, if there are schedule intervals
            // - 00:00 otherwise
            // timerange end will be timerange start plus offset
            'name': 'createLastPlusOffset',
            'type': 'dform',
            'menuText': "Last plus offset",
            'title': "Create interval \"last plus offset\"",
            'aclProfile': 'active',
            'entriesRead': [entries.iNdate, entries.iNact, entries.iNdesc,
                            entries.iNschedintvls, entries.iNlastexistintvl, entries.iNlastplusoffset,],
            'miniMenu': {
                entries: ['createLastPlusOffsetSave'],
            }
        }); // createLastPlusOffset

        target.push('createNextScheduled', {
            // before doing any calculations, look up/calculate:
            // - employee's schedule
            // - existing intervals on date
            // - schedule intervals on date
            // timerange will be:
            // - first schedule interval that does not conflict/overlap with an existing interval
            'name': 'createNextScheduled',
            'type': 'dform',
            'menuText': "Next scheduled",
            'title': "Create interval \"next scheduled\"",
            'aclProfile': 'active',
            'entriesRead': [entries.iNdate, entries.iNact, entries.iNdesc,
                            entries.iNschedintvls, entries.iNlastexistintvl, entries.iNnextscheduled,],
            'miniMenu': {
                entries: ['createNextScheduledSave'],
            }
        }); // createNextScheduled

        target.push('createMultipleInt', {
            'name': 'createMultipleInt',
            'type': 'dform',
            'menuText': 'Multiple intervals',
            'title': 'Fill up a period with intervals',
            'aclProfile': 'active',
            'entriesRead': [entries.iNdate, entries.iNtimerange, entries.iNact, entries.iNdesc,],
            'miniMenu': {
                entries: ['fillUpAction']
            }
        }); // createMultipleInt

        target.push('displaySingleInt', {
            'name': 'displaySingleInt',
            'type': 'dform',
            'menuText': 'Single interval',
            'title': 'Display a single interval',
            'aclProfile': 'active',
            'entriesRead': [entries.iNdaterange, entries.iNtimerange, entries.iNact, entries.iNdesc,],
            'miniMenu': {
                entries: []
            }
        }); // displaySingleInt

    }; // return function ()
    
});
