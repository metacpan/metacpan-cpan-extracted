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
// app/daction-init.js
//
// Round one of daction initialization - called from app/target-init.js
//
"use strict";

define ([
    'target',
    'app/daction-start',
    'app/emp-lib',
], function (
    target,
    dactionStart,
    empLib,
) {

    return function () {

        // generalized actions
        target.push('actionNoop', {
            'name': 'actionNoop',
            'type': 'daction',
            'menuText': 'actionNoop',
            'aclProfile': 'passerby',
            'start': dactionStart('actionNoop'),
            'pushable': false
        });
        target.push('drowselectListen', {
            'name': 'drowselectListen',
            'type': 'daction',
            'menuText': 'drowselectListen',
            'aclProfile': 'passerby',
            'start': dactionStart('drowselectListen'),
            'pushable': false
        });
        target.push('returnToBrowser', {
            'name': 'returnToBrowser',
            'type': 'daction',
            'menuText': 'returnToBrowser',
            'aclProfile': 'passerby',
            'start': dactionStart('returnToBrowser'),
            'pushable': false
        });

        // Employee actions
        target.push('myProfileAction', {
            'name': 'myProfileAction',
            'type': 'daction',
            'menuText': 'Profile',
            'aclProfile': 'passerby',
            'start': dactionStart('myProfileAction'),
            'pushable': true
        });
        target.push('empProfileEditSave', {
            'name': 'empProfileEditSave',
            'type': 'daction',
            'menuText': 'Save changes',
            'aclProfile': 'active',
            'start': dactionStart('empProfileEditSave'),
            'pushable': false
        });
        target.push('ldapLookupSubmit', {
            'name': 'ldapLookupSubmit',
            'type': 'daction',
            'menuText': 'Lookup',
            'aclProfile': 'passerby',
            'start': dactionStart('ldapLookupSubmit'),
            'pushable': false
        });
        target.push('ldapSync', {
            'name': 'ldapSync',
            'type': 'daction',
            'menuText': 'LDAP sync',
            'aclProfile': 'admin',
            'start': dactionStart('ldapSync'),
            'pushable': false
        });
        target.push('ldapSyncFromBrowser', {
            'name': 'ldapSyncFromBrowser',
            'type': 'daction',
            'menuText': 'LDAP sync',
            'aclProfile': 'admin',
            'start': dactionStart('ldapSyncFromBrowser'),
            'pushable': false
        });
        target.push('actionEmplSearch', {
            'name': 'actionEmplSearch',
            'type': 'daction',
            'menuText': 'Search',
            'aclProfile': 'inactive',
            'start': dactionStart('actionEmplSearch'),
            'pushable': false
        });
        target.push('masqEmployee', {
            'name': 'masqEmployee',
            'type': 'daction',
            'menuText': 'Masquerade',
            'aclProfile': 'inactive',
            'start': dactionStart('masqEmployee'),
            'pushable': false,
            'onlyWhen': empLib.currentEmpHasReports,
        });
        target.push('empProfileSetSuperChoose', {
            'name': 'empProfileSetSuperChoose',
            'type': 'daction',
            'menuText': 'Set supervisor',
            'aclProfile': 'admin',
            'start': dactionStart('empProfileSetSuperChoose'),
            'pushable': false
        });
        target.push('empProfileSetSuperCommit', {
            'name': 'empProfileSetSuperCommit',
            'type': 'daction',
            'menuText': 'Yes, I really do',
            'aclProfile': 'admin',
            'start': dactionStart('empProfileSetSuperCommit'),
            'pushable': false
        });
        target.push('empProfileSetSuperDelete', {
            'name': 'empProfileSetSuperDelete',
            'type': 'daction',
            'menuText': 'Remove supervisor',
            'aclProfile': 'admin',
            'start': dactionStart('empProfileSetSuperDelete'),
            'pushable': false
        });
        target.push('empProfileSetSuperSearch', {
            'name': 'empProfileSetSuperSearch',
            'type': 'daction',
            'menuText': 'Set supervisor',
            'aclProfile': 'admin',
            'start': dactionStart('empProfileSetSuperSearch'),
            'pushable': false
        });

        // Privhistory actions
        target.push('actionPrivHistory', { // read-only
            'name': 'actionPrivHistory',
            'type': 'daction',
            'menuText': 'Status history',
            'aclProfile': 'passerby',
            'start': dactionStart('actionPrivHistory'),
            // this starts the privhistory dtable, and if the dataset changes
            // we might want to unwind the stack to this action to reset that
            // dtable
            'pushable': true
        });
        target.push('actionPrivHistoryEdit', { // read-write
            'name': 'actionPrivHistoryEdit',
            'type': 'daction',
            'menuText': 'Edit',
            'aclProfile': 'admin',
            'start': dactionStart('actionPrivHistoryEdit'),
            'pushable': false
        });
        target.push('privHistorySaveAction', {
            'name': 'privHistorySaveAction',
            'type': 'daction',
            'menuText': 'Commit to database',
            'aclProfile': 'admin',
            'start': dactionStart('privHistorySaveAction'),
            'pushable': false
        });
        target.push('privHistoryDeleteAction', {
            'name': 'privHistoryDeleteAction',
            'type': 'daction',
            'menuText': 'Delete record',
            'aclProfile': 'admin',
            'start': dactionStart('privHistoryDeleteAction'),
            'pushable': false
        });
        target.push('privHistoryAddRecordAction', {
            'name': 'privHistoryAddRecordAction',
            'type': 'daction',
            'menuText': 'Add record',
            'aclProfile': 'admin',
            'start': dactionStart('privHistoryAddRecordAction'),
            'pushable': false
        });

        // Schedhistory actions
        target.push('actionSchedHistory', {
            'name': 'actionSchedHistory',
            'type': 'daction',
            'menuText': 'Schedule history',
            'aclProfile': 'inactive',
            'start': dactionStart('actionSchedHistory'),
            'pushable': true
        });
        target.push('schedHistorySaveAction', {
            'name': 'schedHistorySaveAction',
            'type': 'daction',
            'menuText': 'Commit to database',
            'aclProfile': 'admin',
            'start': dactionStart('schedHistorySaveAction'),
            'pushable': false
        });
        target.push('schedHistoryDeleteAction', {
            'name': 'schedHistoryDeleteAction',
            'type': 'daction',
            'menuText': 'Delete record',
            'aclProfile': 'admin',
            'start': dactionStart('schedHistoryDeleteAction'),
            'pushable': false
        });
        target.push('schedHistoryAddRecordAction', {
            'name': 'schedHistoryAddRecordAction',
            'type': 'daction',
            'menuText': 'Add record',
            'aclProfile': 'admin',
            'start': dactionStart('schedHistoryAddRecordAction'),
            'pushable': false
        });

        // Schedule actions
        target.push('browseAllSchedules', {
            'name': 'browseAllSchedules',
            'type': 'daction',
            'menuText': 'Browse schedules',
            'aclProfile': 'admin',
            'start': dactionStart('browseAllSchedules'),
            'pushable': false
        });
        target.push('actionSchedLookup', {
            'name': 'actionSchedLookup',
            'type': 'daction',
            'menuText': 'Detail',
            'aclProfile': 'inactive',
            'start': dactionStart('actionSchedLookup'),
            'pushable': false
        });
        target.push('createSchedule', {
            'name': 'createSchedule',
            'type': 'daction',
            'menuText': 'Create',
            'aclProfile': 'admin',
            'start': dactionStart('createSchedule'),
            'pushable': false
        });
        target.push('actionDisplaySchedule', {
            'name': 'actionDisplaySchedule',
            'type': 'daction',
            'menuText': 'Display',
            'aclProfile': 'inactive',
            'start': dactionStart('actionDisplaySchedule'),
            'pushable': false
        });
        target.push('schedEditSave', {
            'name': 'schedEditSave',
            'type': 'daction',
            'menuText': 'Save changes',
            'aclProfile': 'active',
            'start': dactionStart('schedEditSave'),
            'pushable': false
        });
        target.push('schedReallyDelete', {
            'name': 'schedReallyDelete',
            'type': 'daction',
            'menuText': 'Yes, I really mean it',
            'aclProfile': 'admin',
            'start': dactionStart('schedReallyDelete'),
            'pushable': false
        });

        // Interval actions
        target.push('createMultipleIntSave', {
            'name': 'createMultipleIntSave',
            'type': 'daction',
            'menuText': 'Save',
            'aclProfile': 'active',
            'start': dactionStart('createMultipleIntSave'),
            'pushable': false
        });
        target.push('createSingleIntMenuItem', {
            'name': 'createSingleIntMenuItem',
            'type': 'daction',
            'menuText': 'Create single',
            'aclProfile': 'active',
            'start': dactionStart('createSingleIntMenuItem'),
            'pushable': false
        });
        target.push('createSingleIntSave', {
            'name': 'createSingleIntSave',
            'type': 'daction',
            'menuText': 'Save',
            'aclProfile': 'active',
            'start': dactionStart('createSingleIntSave'),
            'pushable': false
        });
        target.push('createLockSave', {
            'name': 'createLockSave',
            'type': 'daction',
            'menuText': 'Save',
            'aclProfile': 'active',
            'start': dactionStart('createLockSave'),
            'pushable': false
        });
        target.push('deleteSingleInt', {
            'name': 'deleteSingleInt',
            'type': 'daction',
            'menuText': 'Delete',
            'aclProfile': 'active',
            'start': dactionStart('deleteSingleInt'),
            'pushable': false
        });
        target.push('deleteLock', {
            'name': 'deleteLock',
            'type': 'daction',
            'menuText': 'Delete',
            'aclProfile': 'active',
            'start': dactionStart('deleteLock'),
            'pushable': false
        });
        target.push('updateSingleIntSave', {
            'name': 'updateSingleIntSave',
            'type': 'daction',
            'menuText': 'Save',
            'aclProfile': 'active',
            'start': dactionStart('updateSingleIntSave'),
            'pushable': false
        });
        target.push('viewIntervalsAction', {
            'name': 'viewIntervalsAction',
            'type': 'daction',
            'menuText': 'View',
            'aclProfile': 'active',
            'start': dactionStart('viewIntervalsAction'),
            'pushable': true
        });
        target.push('viewLocksAction', {
            'name': 'viewLocksAction',
            'type': 'daction',
            'menuText': 'View',
            'aclProfile': 'active',
            'start': dactionStart('viewLocksAction'),
            'pushable': true
        });

        // Activity actions - select
        target.push('selectActivityAction', {
            'name': 'selectActivityAction',
            'type': 'daction',
            'menuText': 'Select activity',
            'aclProfile': 'active',
            'start': dactionStart('selectActivityAction'),
            'pushable': false
        });
        target.push('selectActivityGo', {
            'name': 'selectActivityGo',
            'type': 'daction',
            'menuText': 'Select',
            'aclProfile': 'active',
            'start': dactionStart('selectActivityGo'),
            'pushable': false
        });

        // Adminitrivia actions
        target.push('restServerDetailsAction', {
            'name': 'restServerDetailsAction',
            'type': 'daction',
            'menuText': 'REST server details',
            'aclProfile': 'passerby',
            'start': dactionStart('restServerDetailsAction'),
            'pushable': false
        });

        // return to (saved) browser state 
        target.push('returnToBrowser', {
            'name': 'returnToBrowser',
            'type': 'daction',
            'menuText': 'Return to browser',
            'aclProfile': 'passerby',
            'start': dactionStart('returnToBrowser')
        }), 

        // logout
        target.push('logout', {
            'name': 'logout',
            'type': 'daction',
            'menuText': 'Logout',
            'aclProfile': 'passerby',
            'start': dactionStart('logout')
        })

    };

});
