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
    'app/entries',
    'lib',
    'target',
], function (
    entries,
    lib,
    target,
) {

    return function () {
        //
        // push dform object definitions onto 'target' here
        //
        target.push('demoForm', {
            'name': 'demoForm',
            'type': 'dform',
            'menuText': 'Demonstrate simple forms',
            'title': 'Demo form',
            'preamble': 'This is just an illustration',
            'aclProfile': 'passerby',
            'entriesRead': [ entries.ROFormEntry1 ],
            'entriesWrite': [ entries.RWFormEntry1 ],
            'miniMenu': {
                entries: ['demoActionFromForm']
            }
        });

        target.push('demoEditFromBrowser', {
            'name': 'demoEditFromBrowser',
            'type': 'dform',
            'menuText': 'Edit',
            'title': 'Demo edit from browser',
            'preamble': 'This is just an illustration',
            'aclProfile': 'passerby',
            'entriesRead': null,
            'entriesWrite': [entries.RWprop1, entries.RWprop2],
            'miniMenu': {
                entries: ['saveToBrowser']
            }
        });

        target.push('demoEditFromRowselect', {
            'name': 'demoEditFromRowselect',
            'type': 'dform',
            'menuText': 'Edit',
            'title': 'Demo edit from rowselect',
            'preamble': 'This is just an illustration',
            'aclProfile': 'passerby',
            'entriesWrite': [entries.RWprop1, entries.RWprop2],
            'miniMenu': {
                entries: ['saveToRowselect']
            }
        });

    };
    
});
