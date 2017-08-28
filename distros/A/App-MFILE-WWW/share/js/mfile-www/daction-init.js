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
    'stack',
    'target',
    'app/daction-start',
], function (
    stack,
    target,
    dactionStart
) {

    return function () {

        //
        // demo dactions that can safely be deleted after making sure they
        // aren't mentioned anywhere in your app-specific code
        //
        target.push('demoActionFromMenu', {
            'name': 'demoActionFromMenu',
            'type': 'daction',
            'menuText': 'Do something from main menu',
            'aclProfile': 'passerby',
            'start': dactionStart('demoActionFromMenu'),
            'pushable': false
        }),
        target.push('demoNoticeAction', {
            'name': 'demoNoticeAction',
            'type': 'daction',
            'menuText': 'Demo notice',
            'aclProfile': 'passerby',
            'start': dactionStart('demoNoticeAction'),
            'pushable': false
        }),
        target.push('demoActionFromSubmenu', {
            'name': 'demoActionFromSubmenu',
            'type': 'daction',
            'menuText': 'Do something from submenu',
            'aclProfile': 'passerby',
            'start': dactionStart('demoActionFromSubmenu'),
            'pushable': false
        }),
        target.push('demoActionFromForm', {
            'name': 'demoActionFromForm',
            'type': 'daction',
            'menuText': 'Action!',
            'aclProfile': 'passerby',
            'start': dactionStart('demoActionFromSubmenu'),
            'pushable': false
        }),
        target.push('demoActionFromTable', {
            'name': 'demoActionFromTable',
            'type': 'daction',
            'menuText': 'Action!',
            'aclProfile': 'passerby',
            'start': dactionStart('demoActionFromSubmenu'),
            'pushable': false
        }),
        target.push('demoBrowserAction', {
            'name': 'demoBrowserAction',
            'type': 'daction',
            'menuText': 'Demo Browser',
            'aclProfile': 'passerby',
            'start': dactionStart('demoBrowserAction'),
            'pushable': false
        }),
        target.push('demoTableAction', {
            'name': 'demoTableAction',
            'type': 'daction',
            'menuText': 'Demo Table',
            'aclProfile': 'passerby',
            'start': dactionStart('demoTableAction'),
            'pushable': false
        }),
        target.push('demoRowselectAction', {
            'name': 'demoRowselectAction',
            'type': 'daction',
            'menuText': 'Demo Rowselect',
            'aclProfile': 'passerby',
            'start': dactionStart('demoRowselectAction'),
            'pushable': false
        }),
        //
        // dactions that you will probably want to use in your app
        //
        target.push('saveToBrowser', {
            'name': 'saveToBrowser',
            'type': 'daction',
            'menuText': 'Save',
            'aclProfile': 'passerby',
            'start': dactionStart('saveToBrowser')
        }),
        target.push('saveToRowselect', {
            'name': 'saveToRowselect',
            'type': 'daction',
            'menuText': 'Save',
            'aclProfile': 'passerby',
            'start': dactionStart('saveToRowselect')
        }),
        target.push('logout', {
            'name': 'logout',
            'type': 'daction',
            'menuText': 'Logout',
            'aclProfile': 'passerby',
            'start': dactionStart('logout')
        })

    };

});
