// ************************************************************************* 
// Copyright (c) 2014-2016, SUSE LLC
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
// app/daction.js
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

        // demo action
        target.push('demoAction', {
            'name': 'demoAction',
            'type': 'daction',
            'menuText': 'Do something',
            'aclProfile': 'passerby',
            'start': dactionStart('demoAction')
        });

        // general actions
        target.push('drowselectListen', {
            'name': 'drowselectListen',
            'type': 'daction',
            'menuText': 'drowselectListen',
            'aclProfile': 'passerby',
            'start': dactionStart('drowselectListen')
        });
        target.push('returnToBrowser', {
            'name': 'returnToBrowser',
            'type': 'daction',
            'menuText': 'returnToBrowser',
            'aclProfile': 'passerby',
            'start': dactionStart('returnToBrowser')
        });

        // Employee actions
        target.push('myProfile', {
            'name': 'myProfile',
            'type': 'daction',
            'menuText': 'My profile',
            'aclProfile': 'passerby',
            'start': dactionStart('myProfile')
        });
        target.push('empProfileEditSave', {
            'name': 'empProfileEditSave',
            'type': 'daction',
            'menuText': 'Save changes',
            'aclProfile': 'active',
            'start': dactionStart('empProfileEditSave')
        });
        target.push('ldapLookupSubmit', {
            'name': 'ldapLookupSubmit',
            'type': 'daction',
            'menuText': 'Lookup',
            'aclProfile': 'passerby',
            'start': dactionStart('ldapLookupSubmit')
        });
        target.push('ldapSync', {
            'name': 'ldapSync',
            'type': 'daction',
            'menuText': 'LDAP sync',
            'aclProfile': 'admin',
            'start': dactionStart('ldapSync')
        });
        target.push('ldapSyncSelf', {
            'name': 'ldapSync',
            'type': 'daction',
            'menuText': 'LDAP sync',
            'aclProfile': 'active',
            'start': dactionStart('ldapSyncSelf')
        });
        target.push('actionEmplSearch', {
            'name': 'actionEmplSearch',
            'type': 'daction',
            'menuText': 'Search',
            'aclProfile': 'admin',
            'start': dactionStart('actionEmplSearch')
        });
        target.push('masqEmployee', {
            'name': 'masqEmployee',
            'type': 'daction',
            'menuText': 'Masquerade (begin/end)',
            'aclProfile': 'admin',
            'start': dactionStart('masqEmployee')
        });

        // Privhistory actions
        target.push('actionPrivHistory', { // read-only
            'name': 'actionPrivHistory',
            'type': 'daction',
            'menuText': 'Privilege (status) history',
            'aclProfile': 'passerby',
            'start': dactionStart('actionPrivHistory')
        });
        target.push('actionPrivHistoryEdit', { // read-write
            'name': 'actionPrivHistoryEdit',
            'type': 'daction',
            'menuText': 'Edit',
            'aclProfile': 'admin',
            'start': dactionStart('actionPrivHistoryEdit')
        });
        target.push('privHistorySaveAction', {
            'name': 'privHistorySaveAction',
            'type': 'daction',
            'menuText': 'Commit to database',
            'aclProfile': 'admin',
            'start': dactionStart('privHistorySaveAction')
        });
        target.push('privHistoryDeleteAction', {
            'name': 'privHistoryDeleteAction',
            'type': 'daction',
            'menuText': 'Delete record',
            'aclProfile': 'admin',
            'start': dactionStart('privHistoryDeleteAction')
        });

        // Schedhistory actions
        target.push('actionSchedHistory', { // read-only
            'name': 'actionSchedHistory',
            'type': 'daction',
            'menuText': 'Schedule history',
            'aclProfile': 'passerby',
            'start': dactionStart('actionSchedHistory')
        });
        target.push('actionSchedHistoryEdit', { // read-write
            'name': 'actionSchedHistoryEdit',
            'type': 'daction',
            'menuText': 'Edit',
            'aclProfile': 'admin',
            'start': dactionStart('actionSchedHistoryEdit')
        });
        target.push('schedHistorySaveAction', {
            'name': 'schedHistorySaveAction',
            'type': 'daction',
            'menuText': 'Commit to database',
            'aclProfile': 'admin',
            'start': dactionStart('schedHistorySaveAction')
        });
        target.push('schedHistoryDeleteAction', {
            'name': 'schedHistoryDeleteAction',
            'type': 'daction',
            'menuText': 'Delete record',
            'aclProfile': 'admin',
            'start': dactionStart('schedHistoryDeleteAction')
        });

        // Schedule actions
        target.push('browseAllSchedules', {
            'name': 'browseAllSchedules',
            'type': 'daction',
            'menuText': 'Browse schedules',
            'aclProfile': 'admin',
            'start': dactionStart('browseAllSchedules')
        });
        target.push('actionSchedLookup', {
            'name': 'actionSchedLookup',
            'type': 'daction',
            'menuText': 'Lookup a schedule by name or ID',
            'aclProfile': 'admin',
            'start': dactionStart('actionSchedLookup')
        });
        target.push('createSchedule', {
            'name': 'createSchedule',
            'type': 'daction',
            'menuText': 'Create',
            'aclProfile': 'admin',
            'start': dactionStart('createSchedule')
        });
        target.push('schedEditFromBrowser', {
            'name': 'schedEditFromBrowser',
            'type': 'daction',
            'menuText': 'Edit',
            'aclProfile': 'admin',
            'start': dactionStart('schedEditFromBrowser')
        });
        target.push('schedDeleteFromBrowser', {
            'name': 'schedDeleteFromBrowser',
            'type': 'daction',
            'menuText': 'Delete',
            'aclProfile': 'admin',
            'start': dactionStart('schedDeleteFromBrowser')
        });
        target.push('schedEditSave', {
            'name': 'schedEditSave',
            'type': 'daction',
            'menuText': 'Save changes',
            'aclProfile': 'active',
            'start': dactionStart('schedEditSave')
        });
        target.push('schedReallyDelete', {
            'name': 'schedReallyDelete',
            'type': 'daction',
            'menuText': 'Yes, I really mean it',
            'aclProfile': 'admin',
            'start': dactionStart('schedReallyDelete')
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
