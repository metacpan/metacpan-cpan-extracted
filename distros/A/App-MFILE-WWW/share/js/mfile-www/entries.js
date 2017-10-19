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
// app/entries.js
//
// definitions of individual fields ("entries") used by dform, dbrowser, etc.
//
"use strict";

define ([
    'lib',
], function (
    coreLib,
) {

    return {

        'browserEntry1': {
            name: 'browserEntry1',
            aclProfileRead: 'passerby',
            text: 'Entry 1',
            prop: 'prop1',
            maxlen: 20
        },
        'browserEntry2': {
            name: 'browserEntry2',
            aclProfileRead: 'passerby',
            text: 'Entry 2',
            prop: 'prop2',
            maxlen: 20
        },
        'ROFormEntry1': {
            name: 'ROFormEntry1',
            aclProfileRead: 'passerby',
            aclProfileWrite: null,
            text: 'RO Entry 1',
            prop: 'roentry1',
            maxlen: 20
        },
        'RWFormEntry1': {
            name: 'RWFormEntry1',
            aclProfileRead: 'passerby',
            aclProfileWrite: 'passerby',
            text: 'RW Entry 1',
            prop: 'rwentry1',
            maxlen: 20
        },
        'RWprop1': {
            name: 'RWProp1',
            aclProfileRead: 'passerby',
            aclProfileWrite: 'passerby',
            text: 'prop1',
            prop: 'prop1',
            maxlen: 20
        },
        'RWprop2': {
            name: 'RWProp2',
            aclProfileRead: 'passerby',
            aclProfileWrite: 'passerby',
            text: 'prop2',
            prop: 'prop2',
            maxlen: 20
        },
        'rowselectEntry1': {
            name: 'rowselectEntry1',
            aclProfileRead: 'passerby',
            text: 'Entry 1',
            prop: 'prop1',
            maxlen: 20
        },
        'rowselectEntry2': {
            name: 'rowselectEntry2',
            aclProfileRead: 'passerby',
            text: 'Entry 2',
            prop: 'prop2',
            maxlen: 20
        },
        'tableEntry1': {
            name: 'tableEntry1',
            aclProfileRead: 'passerby',
            text: 'Entry 1',
            prop: 'prop1',
            maxlen: 20
        },
        'tableEntry2': {
            name: 'tableEntry2',
            aclProfileRead: 'passerby',
            text: 'Entry 2',
            prop: 'prop2',
            maxlen: 20
        },

    };

});
