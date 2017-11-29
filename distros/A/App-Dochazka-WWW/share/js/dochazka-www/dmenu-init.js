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
// app/dmenu.js
//
// Round one of dmenu initialization - called from app/target-init.js
//
"use strict";

define ([
    'target'
], function (
    target
) {

    return function () {

        target.push('mainAdmin', {
            'name': 'mainAdmin',
            'type': 'dmenu',
            'menuText': 'Admin',
            'title': 'Admin menu',
            'aclProfile': 'admin',
            'entries': ['ldapLookup', 'searchEmployee', 'restServerDetailsAction']
        });

        target.push('mainInt', {
            'name': 'mainInt',
            'type': 'dmenu',
            'menuText': 'Intervals',
            'title': 'Interval menu',
            'aclProfile': 'inactive',
            'entries': ['viewIntervalsPrep', 'createSingleIntMenuItem', 'createMultipleInt',],
        });

        target.push('mainLock', {
            'name': 'mainLock',
            'type': 'dmenu',
            'menuText': 'Locks',
            'title': 'Lock menu',
            'aclProfile': 'inactive',
            'entries': ['viewLocksPrep', 'createLock',],
        });

        target.push('mainMenu', {
            'name': 'mainMenu',
            'type': 'dmenu',
            'menuText': 'Main',
            'title': 'Main menu',
            'aclProfile': 'passerby',
            'entries': ['myProfileAction', 'mainInt', 'mainLock', 'mainSched', 'masqEmployee',
                        'mainAdmin']
        });

        target.push('mainSched', {
            'name': 'mainSched',
            'type': 'dmenu',
            'menuText': 'Schedules',
            'title': 'Schedule menu',
            'aclProfile': 'admin',
            'entries': ['schedLookup',
                        'browseAllSchedules', 'schedNew']
        });

        target.push('schedNew', {
            'name': 'schedNew',
            'type': 'dmenu',
            'menuText': 'Create a new schedule',
            'title': 'Create a new schedule - options',
            'aclProfile': 'admin',
            'entries': ['schedNewBoilerplate', 'schedNewCustom']
        });
    };

});
