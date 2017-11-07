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
// app/dcallback-init.js
//
// Round one of dcallback initialization (called from app/target-init)
//
"use strict";

define ([
    "app/int-lib",
    "app/viewer",
    "target",
], function (
    intLib,
    viewer,
    target,
) {

    return function () {

        target.push('multiDayViewer', {
            'name': 'multiDayViewer',
            'type': 'dcallback',
            'menuText': 'multiDayViewer',
            'aclProfile': 'inactive',
            'callback': viewer.multiDayViewer,
            'rememberState': true,
            'miniMenu': {
                entries: ['viewIntervalsMultiDayRaw'],
            }
        });

        target.push('viewIntervalsMultiDayRaw', {
            'name': 'viewIntervalsMultiDayRaw',
            'type': 'dcallback',
            'menuText': 'Raw JSON',
            'title': 'Multi-day interval viewer (RAW)',
            'preamble': 'Attendance intervals from [BEGIN] to [END]',
            'aclProfile': 'inactive',
            'callback': intLib.viewIntervalsMultiDayCallbackRaw,
            'miniMenu': {
                entries: [],
            }
        });

    };
    
});
