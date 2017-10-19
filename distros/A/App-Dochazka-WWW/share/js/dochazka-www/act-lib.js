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
// app/lib.js
//
// application-specific routines
//
"use strict";

define ([
    'jquery',
    'ajax',
    'current-user',
    'lib',
    'stack',
], function (
    $,
    ajax,
    currentUser,
    coreLib,
    stack,
) {

    var cache = [],

        byAID = {},

        byCode = {},

        populateActivitiesCache = function () {
            console.log("Entering populateActivitiesCache()");
            // idempotent
            if (cache.length === 0) {
                ajax(rest, sc, fc);
            } else {
                console.log("populateActivitiesCaches(): noop, caches already populated");
            }
        },

        rest = {
            "method": 'GET',
            "path": 'activity/all'
        },
        // success callback
        sc = function (st) {
            var i;
            console.log("AJAX: " + rest["method"] + " " + rest["path"] + " returned", st);
            cache = [];
            for (i = 0; i < st.payload.length; i += 1) {
                cache.push(st.payload[i]);
                byAID[st.payload[i].aid] = st.payload[i];
                byCode[st.payload[i].code] = st.payload[i];
            }
            coreLib.displayResult(i + 1 + " activity objects loaded into cache");
        },
        fc = function (st) {
            console.log("AJAX: " + rest["method"] + " " + rest["path"] + " failed", st);
            coreLib.displayError(st.payload.message);
        };

    return {

        getActByAID: function (aid) {
            if (cache.length > 0) {
                return byAID[aid];
            }
            console.log('CRITICAL ERROR: activities cache not populated');
            return null;
        },

        getActByCode: function (code) {
            if (cache.length > 0) {
                return byCode[code];
            }
            console.log('CRITICAL ERROR: activities cache not populated');
            return null;
        },

        populateActivitiesCache: populateActivitiesCache,

        selectActivityAction: function (obj) {
            if (cache.length > 0) {
                stack.push('selectActivity', {
                    'pos': 0,
                    'set': cache,
                });
            } else {
                // start selectActivity drowselect target
                ajax(rest, sc, fc);
            }
        },

        selectActivityGo: function (obj) {
            // called from selectActivity drowselect; obj is the selected activity
            // strip off the selectActivity target from top of stack
            var state;
            console.log("Entered selectActivityGo()");
            console.log("Top of stack: ", stack.getTarget());
            if (stack.getTarget().name === 'selectActivity') {
                console.log("Top of stack is selectActivity, as expected");
                stack.popWithoutStart();
            }
            state = stack.getState();
            // replace activity code with the one from obj (selected by user)
            state['iNact'] = obj.code;
            state['acTaid'] = obj.aid;
            stack.restart(state);
        },

        vetActivity: function (code) {
            // exact match
            var i,
                re;
            if (byCode.hasOwnProperty(code)) {
                return byCode[code].code;
            }
            // partial match
            re = new RegExp('^' + code, "i");
            for (i = 0; i < cache.length; i += 1) {
                if (cache[i].code.match(re)) {
                    return cache[i].code;
                }
            }
            return null;
        },

    };

});
