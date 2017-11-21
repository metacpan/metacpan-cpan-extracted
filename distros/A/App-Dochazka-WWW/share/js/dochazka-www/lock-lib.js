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
// app/lock-lib.js
//
"use strict";

define ([
    'jquery',
    'ajax',
    'app/caches',
    'current-user',
    'datetime',
    'lib',
    'stack',
], function (
    $,
    ajax,
    appCaches,
    currentUser,
    dt,
    coreLib,
    stack,
) {

    var
        createLockCheckMandatoryProps = function (obj) {
            return true;
        },

        createLockSave = function (obj) {
            var caller = stack.getTarget().name,
                cu = currentUser('obj'),
                intvl,
                rest,
                sc = function (st) {
                         stack.unwindToTarget(
                             'createLock',
                             emptyObj,
                             {
                                 "resultLine": "Lock " + st.payload.lid + " created",
                                 "inputId": "iNyear",
                             }
                         );
                     };
            console.log("Entering createLockSave() from caller " + caller + " with obj", obj);
            if (! createLockCheckMandatoryProps(obj)) {
                return null;
            }
            intvl = scrapeForm();
            if (! intvl) {
                return null;
            }
            rest = {
                "method": 'POST',
                "path": 'lock/new',
                "body": {
                    "eid": cu.eid,
                    "intvl": intvl,
                    "remark": null,
                },
            }
            ajax(rest, sc);
        },

        deleteLock = function (obj) {
            var rest = {
                    "method": "DELETE",
                    "path": "lock/lid/" + obj.lid,
                },
                sc = function (st) {
                    if (st.code === 'DOCHAZKA_CUD_OK') {
                        stack.unwindToTarget('viewLocksAction');
                    } else {
                        coreLib.displayError(st.text);
                    }
                };
            console.log("Entering deleteLock() with obj", obj);
            ajax(rest, sc);
        },

        emptyObj = {
            "iNyear": "",
            "iNmonth": "",
        },

        scrapeForm = function () {
            var begin,
                end,
                month = $('input[id="iNmonth"]').val(),
                year = $('input[id="iNyear"]').val();
            if (! coreLib.isInteger(month)) {
                month = dt.monthToInt(month);
            }
            if (month < 1 || month > 12) {
                coreLib.displayError("Invalid month");
                return null;
            }
            begin = String(year) + "-" + String(month) + "-1";
            end = String(year) + "-" + String(month) + "-" + String(dt.daysInMonth(year, month));
            return "[ " + String(begin) + " 00:00, " + String(end) + " 24:00 )";
        },

        viewLocksActionCache = function () {
            var i, frm = [];
            frm[0] = coreLib.nullify($('input[id="iNyear"]').val()); 
            for (i = 0; i < 1; i += 1) {
                if (frm[i]) {
                    viewLocksCache[i] = frm[i];
                } else {
                    frm[i] = viewLocksCache[i];
                }
            }
            // console.log("viewLocksActionCache() returning", frm);
            return frm;
        },
        viewLocksAction = function () {
            // scrape year and month from form, generate tsrange
            // call GET lock/eid/:eid/:tsrange
            // viewLocksDrowselect on the resulting object
            var begin,
                cu = currentUser('obj'),
                end,
                intvl,
                i,
                obj,
                opts,
                year,
                rest,
                sc = function (st) {
                    var ld;
                    if (st.code === 'DISPATCH_RECORDS_FOUND' ) {
                        opts = { "resultLine": st.count + " locks found" };
                        opts['xtarget'] = 'viewLocksPrep'; // so we don't land in viewLocksAction
                        stack.push('viewLocksDrowselect', {
                            'pos': 0,
                            'set': st.payload
                        }, opts);
                    } else if (st.code === 'DISPATCH_NO_RECORDS_FOUND' ) {
                        coreLib.displayError(st.code + ": " + st.text);
                    } else {
                        coreLib.displayError(st.code + ": " + st.text);
                    }
                },
                fc = function (st) {
                    stack.pop(undefined, {"resultLine": st.payload.message});
                };
            // scrape year from form
            [year] = viewLocksActionCache();
            begin = String(year) + "-1-1";
            end = String(year) + "-12-31";
            intvl = "[ " + String(begin) + " 00:00, " + String(end) + " 24:00 )";
            rest = {
                "method": 'GET',
                "path": 'lock/eid/' + cu.eid + "/" + intvl,
            };
            ajax(rest, sc, fc);
        },
        viewLocksCache = []
        ;

    // here is where we define methods implementing the various
    // interval-related actions (see daction-start.js)
    return {
        createLockSave: createLockSave,
        deleteLock: deleteLock,
        viewLocksAction: viewLocksAction,
    };

});
