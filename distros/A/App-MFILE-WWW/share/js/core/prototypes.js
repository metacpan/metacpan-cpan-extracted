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
// prototypes.js
//
"use strict";

define([
    'jquery',
], function (
    $,
) {
    return {

        // prototype for front-end primitives ("targets")
        target: {
            name: 'protoTarget',
            aclProfile: 'passerby',
            getEntries: function () {
                    // return all entries, first read and then write
                    console.log("In getEntries(), this.entriesRead", this.entriesRead);
                    console.log("In getEntries(), this.entriesWrite", this.entriesWrite);
                    var entries;
                    if (this.entriesRead === undefined || this.entriesRead === null) {
                        this.entriesRead = [];
                    }
                    if (this.entriesWrite === undefined || this.entriesWrite === null) {
                        this.entriesWrite = [];
                    }
                    entries = this.entriesRead.concat(this.entriesWrite);
                    return entries;
                },
            getVetter: function (entryName) {
                    // given an entry name, look up the entry and return the
                    // vetter function if it exists, otherwise null
                    var entry,
                        i;
                    for (i = 0; i < this.entriesWrite.length; i += 1) {
                        entry = this.entriesWrite[i];
                        if (entry.name === entryName) {
                            if (typeof entry.vetter === 'function') {
                                return entry.vetter;
                            }
                        }
                    }
                    return null;
                },
            entriesRead: [],
            entriesWrite: [],
            menuText: '(none)',
            pushable: true,
            source: '(none)',
            start: function () {},
            onlyWhen: function () { return true; },
        },

        // prototype for users ("employees" in App::Dochazka::WWW)
        user: {
            nick: '',
        },

        // prototype for menus (dmenu and miniMenu)
        menu: {
            entries: [],
            isDmenu: false,
            isMiniMenu: false,
            isEmpty: true,
        },

    };
});
