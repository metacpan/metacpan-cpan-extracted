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
// app/priv-lib.js
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
    coreLib,
    target,
    stack,
    start
) {

    var genPrivHistoryAction = function (tgt) {
            return function (obj) {
                console.log("Entering some privHistory-related function, target is " + tgt);
                var nick = currentUser('obj').nick,
                    rest = {
                        "method": 'GET',
                        "path": 'priv/history/nick/' + nick
                    },
                    // success callback
                    sc = function (st) {
                        if (st.code === 'DISPATCH_RECORDS_FOUND') {
                            var history = st.payload.history.map(
                                function (row) {
                                    return {
                                        "nick": nick,
                                        "phid": row.phid,
                                        "priv": row.priv,
                                        "effective": datetime.readableDate(row.effective)
                                    };
                                }
                            );
                            if (tgt === 'privHistoryDtable') {
                                stack.push(tgt, history, { "xtarget": "myProfileAction" });
                            } else if (tgt === 'privHistoryDrowselect') {
                                stack.push(tgt, {
                                    'pos': 0,
                                    'set': history
                                });
                            }
                        }
                    },
                    fc = function (st) {
                        if (st.payload.code === "404") {
                            // The employee has no history records. This is not
                            // really an error condition.
                            if (tgt === 'privHistoryDtable') {
                                stack.push(tgt, [], { "xtarget": "empProfile" });
                            } else if (tgt === 'privHistoryDrowselect') {
                                stack.push(tgt, {
                                    'pos': 0,
                                    'set': []
                                });
                            }
                        }
                        coreLib.displayError(st.payload.message);
                    };
                ajax(rest, sc, fc);
            };
        },
        privHistoryAddRecordAction = function (obj) {
            var cu = currentUser('obj');
            console.log("Entering privHistoryAddRecordAction with nick " + cu.nick);
            stack.push('privHistoryAddRecord', {
                'nick': cu.nick
            });
        },
        privHistoryDeleteAction = function (obj) {
            var phid,
                set = coreLib.drowselectState.set,
                pos = coreLib.drowselectState.pos,
                rest = {
                    "method": 'DELETE',
                    "path": 'priv/history/phid/'
                },
                // success callback
                sc = function (st) {
                    if (st.code === 'DOCHAZKA_CUD_OK') {
                        console.log("Payload is", st.payload);
                        stack.unwindToTarget("actionPrivHistory");
                        coreLib.displayError("Priv (status) history record successfully deleted");
                    }
                },
                fc = function (st) {
                    coreLib.displayError(st.payload.message);
                };

            if (set === null || set === undefined || set.length === 0) {
                coreLib.displayError("Nothing to do");
                start.drowselectListen();
            }
            phid = set[pos].phid;
            console.log("Going to delete PHID " + phid);
            rest.path += phid;
            ajax(rest, sc, fc);
            // start.drowselectListen();
        },
        privHistorySaveAction = function (obj) {
            console.log("Entering privHistorySaveAction with obj", obj);
            var rest = {
                    "method": 'POST',
                    "path": 'priv/history/nick/' + currentUser('obj').nick,
                    "body": {
                        "effective": $("#pHeffective").val(),
                        "priv": $("#pHpriv").val()
                    }
                },
                // success callback
                sc = function (st) {
                    if (st.code === 'DOCHAZKA_CUD_OK') {
                        stack.unwindToTarget("actionPrivHistory");
                        coreLib.displayError("Priv (status) history record successfully added");
                    }
                },
                fc = function (st) {
                    coreLib.displayError(st.payload.message);
                };
            ajax(rest, sc, fc);
            // start.drowselectListen();
        },
        vetPrivLevel = function (pl) {
            var plm = String(pl).trim().toLowerCase().slice(0, 2);
            if (plm === 'ad') {
                return 'admin';
            } else if (plm === 'ac') {
                return 'active';
            }
            plm = plm.slice(0,1);
            if (plm === 'i') {
                return 'inactive';
            } else if (plm == 'p') {
                return 'passerby';
            }
            return null;
        }
        ;
    
    return {
        "actionPrivHistory": genPrivHistoryAction('privHistoryDtable'),
        "actionPrivHistoryEdit": genPrivHistoryAction('privHistoryDrowselect'),
        "privHistoryAddRecordAction": privHistoryAddRecordAction,
        "privHistoryDeleteAction": privHistoryDeleteAction,
        "privHistorySaveAction": privHistorySaveAction,
        "vetPrivLevel": vetPrivLevel,
    };

});
