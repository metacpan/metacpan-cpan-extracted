// ************************************************************************* 
// Copyright (c) 2014-2015, SUSE LLC
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
// app/prototypes
//
"use strict";

define(['lib'], function (lib) {
    return {
        empProfile: {
            eid: null,
            nick: null,
            fullname: null,
            email: null,
            password: null,
            remark: null,
            sec_id: null,
            priv: null,
            effective: null,
            sanitize: function () {
                // object might contain properties that don't belong -
                // this method removes them
                var sanitized = lib.hairCut(this, [
                    'eid', 'nick', 'fullname', 'email', 'password', 'remark',
                    'sec_id', 'priv', 'effective'
                ]);
                console.log("Sanitized empProfile", sanitized);
                return sanitized;
            }
        },
        empObject: {
            eid: null,
            nick: null,
            fullname: null,
            email: null,
            password: null,
            remark: null,
            sec_id: null,
            sanitize: function () {
                // object might contain properties that don't belong -
                // this method removes them
                var sanitized = lib.hairCut(this, [
                    'eid', 'nick', 'fullname', 'email', 'password', 'remark',
                    'sec_id'
                ]);
                console.log("Sanitized empObject", sanitized);
                return sanitized;
            }
        },
        ldapEmpObject: {
            eid: null,
            nick: null,
            fullname: null,
            email: null,
            password: null,
            remark: null,
            sec_id: null,
            dochazka: null,
            sanitize: function () {
                // object might contain properties that don't belong -
                // this method removes them
                var sanitized = lib.hairCut(this, [
                    'eid', 'nick', 'fullname', 'email', 'password', 'remark',
                    'sec_id', 'dochazka'
                ]);
                console.log("Sanitized empObject", sanitized);
                return sanitized;
            }
        },
        schedObjectForCreate: {
            scode: null,
            schedule: null,
            sanitize: function () {
                // object might contain properties that don't belong -
                // this method removes them
                var sanitized = lib.hairCut(this, [
                    'scode', 'schedule'
                ]);
                console.log("Sanitized schedObject", sanitized);
                return sanitized;
            }
        },
        schedObjectForDisplay: {
            sid: null,
            scode: null,
            schedule: null,
            disabled: null,
            remark: null,
            mon: null,
            tue: null,
            wed: null,
            thu: null,
            fri: null,
            sat: null,
            sun: null,
            sanitize: function () {
                // object might contain properties that don't belong -
                // this method removes them
                var sanitized = lib.hairCut(this, [
                    'sid', 'scode', 'schedule', 'disabled', 'remark',
                    'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'
                ]);
                console.log("Sanitized schedObject", sanitized);
                return sanitized;
            }
        }
    };
});

