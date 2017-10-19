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
// app/sched-history-lib.js
//
"use strict";

define ([
    'jquery',
    'ajax',
    'current-user',
    'datetime',
    'lib',
    'target',
    'stack',
    'start'
], function (
    $,
    ajax,
    currentUser,
    datetime,
    lib,
    target,
    stack,
    start
) {

    var genSchedHistoryAction = function (tgt) {
            return function () {
                var nick = currentUser('obj').nick,
                    rest = {
                        "method": 'GET',
                        "path": 'schedule/history/nick/' + currentUser('obj').nick
                    },
                    // success callback
                    sc = function (st) {
                        if (st.code === 'DISPATCH_RECORDS_FOUND') {
                            console.log("Payload is", st.payload);
                            var history = st.payload.history.map(
                                function (row) {
                                    return {
                                        "nick": nick,
                                        "shid": row.shid,
                                        "sid": row.sid,
                                        "effective": datetime.readableDate(row.effective),
                                        "scode": row.scode
                                    };
                                }
                            );
                            if (tgt === 'schedHistoryDtable') {
                                stack.push(tgt, history, {
                                    "xtarget": "mainSched"
                                });
                            } else if (tgt === 'schedHistoryDrowselect') {
                                stack.push(tgt, {
                                    'pos': 0,
                                    'set': history
                                });
                            }
                        }
                    },
                    fc = function (st) {
                        console.log("AJAX: " + rest["path"] + " failed with", st);
                        lib.displayError(st.payload.message);
                        if (st.payload.code === "404") {
                            // The employee has no history records. This is not
                            // really an error condition.
                            if (tgt === 'schedHistoryDtable') {
                                stack.push(tgt, [], {
                                    "xtarget": "mainSched"
                                });
                            } else if (tgt === 'schedHistoryDrowselect') {
                                stack.push(tgt, {
                                    'pos': 0,
                                    'set': []
                                });
                            }
                        }
                    };
                ajax(rest, sc, fc);
            };
        };

    return {
        "actionSchedHistory":     genSchedHistoryAction(
                                     'schedHistoryDtable'
                                 ),
        "actionSchedHistoryEdit": genSchedHistoryAction(
                                     'schedHistoryDrowselect'
                                 ),
        "schedHistorySaveAction": function () {
            var rest = {
                    "method": 'POST',
                    "path": 'schedule/history/nick/' + currentUser('obj').nick,
                    "body": {
                        "effective": $("#pHeffective").val(),
                        "sid": $("#sDid").val(),
                        "scode": $("#sDcode").val()
                    }
                },
                // success callback
                sc = function (st) {
                    if (st.code === 'DOCHAZKA_CUD_OK') {
                        console.log("Payload is", st.payload);
                        stack.unwindToTarget("actionSchedHistory");
                    }
                },
                fc = function (st) {
                    console.log("AJAX: " + rest["path"] + " failed with", st);
                    lib.displayError(st.payload.message);
                    if (st.payload.code === '404') {
                        // go back to miniMenu listener
                        $('input[name="sel"]').val('').focus();
                    }
                };
            ajax(rest, sc, fc);
            // start.drowselectListen();
        },
        "schedHistoryDeleteAction": function () {
            var shid,
                set = lib.drowselectState.set,
                pos = lib.drowselectState.pos,
                rest = {
                    "method": 'DELETE',
                    "path": 'schedule/history/shid/'
                },
                // success callback
                sc = function (st) {
                    if (st.code === 'DOCHAZKA_CUD_OK') {
                        console.log("Payload is", st.payload);
                        stack.unwindToTarget("actionSchedHistory");
                    }
                },
                fc = function (st) {
                    console.log("AJAX: " + rest["path"] + " failed with", st);
                    lib.displayError(st.payload.message);
                    $('input[name="sel"]').val('').focus();
                };

            if (set === null || set === undefined || set.length === 0) {
                lib.displayError("Nothing to do");
                $('input[name="sel"]').val('').focus();
                // start.drowselectListen();
            }
            shid = set[pos].shid;
            console.log("Going to delete SHID " + shid);
            rest.path += shid;
            ajax(rest, sc, fc);
            // start.drowselectListen();
        },
        "schedHistoryAddRecordAction": function (obj) {
            console.log("Entering schedHistoryAddRecordAction with obj", obj);
            stack.push('schedHistoryAddRecord', {
                'nick': obj.nick
            });
        }
    };
});

