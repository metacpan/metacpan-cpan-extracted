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
    'app/daction-start'
], function (
    target,
    dactionStart
) {

    return function () {

        // generalized actions
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
            'menuText': 'My profile',
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
            'aclProfile': 'admin',
            'start': dactionStart('actionEmplSearch'),
            'pushable': false
        });
        target.push('masqEmployee', {
            'name': 'masqEmployee',
            'type': 'daction',
            'menuText': 'Masquerade (begin/end)',
            'aclProfile': 'admin',
            'start': dactionStart('masqEmployee'),
            'pushable': false
        });

        // Privhistory actions
        target.push('actionPrivHistory', { // read-only
            'name': 'actionPrivHistory',
            'type': 'daction',
            'menuText': 'Privilege (status) history',
            'aclProfile': 'passerby',
            'start': dactionStart('actionPrivHistory'),
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
        target.push('actionSchedHistory', { // read-only
            'name': 'actionSchedHistory',
            'type': 'daction',
            'menuText': 'Schedule history',
            'aclProfile': 'passerby',
            'start': dactionStart('actionSchedHistory'),
            'pushable': true
        });
        target.push('actionSchedHistoryEdit', { // read-write
            'name': 'actionSchedHistoryEdit',
            'type': 'daction',
            'menuText': 'Edit',
            'aclProfile': 'admin',
            'start': dactionStart('actionSchedHistoryEdit'),
            'pushable': false
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
            'menuText': 'Lookup',
            'aclProfile': 'admin',
            'start': dactionStart('actionSchedLookup'),
            'pushable': true
        });
        target.push('createSchedule', {
            'name': 'createSchedule',
            'type': 'daction',
            'menuText': 'Create',
            'aclProfile': 'admin',
            'start': dactionStart('createSchedule'),
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

        // Adminitrivia actions
        target.push('restServerDetailsAction', {
            'name': 'restServerDetailsAction',
            'type': 'daction',
            'menuText': 'REST server details',
            'aclProfile': 'passerby',
            'start': dactionStart('restServerDetailsAction'),
            'pushable': false
        });

        // Run unit tests
        target.push('unitTests', {
            'name': 'unitTests',
            'menuText': 'Run unit tests',
            'aclProfile': 'passerby'
        }),
        
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
