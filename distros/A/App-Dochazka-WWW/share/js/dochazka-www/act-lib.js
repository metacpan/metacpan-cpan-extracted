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
    'app/caches',
    'stack',
], function (
    $,
    appCaches,
    stack,
) {

    return {

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
            var cache = appCaches.activityCache,
                exactMatch = appCaches.getActivityByCode(code),
                i,
                re;
            if (exactMatch) {
                return exactMatch.code;
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
