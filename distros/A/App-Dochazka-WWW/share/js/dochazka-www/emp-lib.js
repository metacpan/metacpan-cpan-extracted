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
// app/emp-lib.js
//
"use strict";

define ([
    'jquery',
    'app/caches',
    'app/lib',
    'app/sched-lib',
    'app/prototypes',
    'ajax',
    'current-user',
    'datetime',
    'lib',
    'populate',
    'stack',
], function (
    $,
    appCaches,
    appLib,
    schedLib,
    prototypes,
    ajax,
    currentUser,
    datetime,
    coreLib,
    populate,
    stack,
) {

    var 
        actionEmplSearch = function (obj) {
            // obj is searchKeyNick from the form
            if (! obj) {
                obj = stack.getState();
            }
            console.log("Entering target 'actionEmplSearch' with argument", obj);
            var rest = {
                    "method": 'GET',
                    "path": 'employee/search/nick/' + encodeURIComponent(obj.searchKeyNick)
                },
                // success callback
                sc = function (st) {
                    if (st.code === 'DISPATCH_RECORDS_FOUND') {
        
                        // if only one record is returned, it might be in a result_set
                        // or it might be alone in the payload
                        var rs = st.payload.result_set || st.payload,
                            count = rs.length;
        
                        console.log("Search found " + count + " employees");
                        stack.push(
                            "simpleEmployeeBrowser",
                            {"set": rs, "pos": 0},
                            {"flag": true},
                        );
                    } else {
                        coreLib.displayError("Unexpected status code " + st.code);
                    }
                },
                // failure callback
                fc = function (st) {
                    console.log("AJAX: " + rest["path"] + " failed with", st);
                    coreLib.displayError(st.payload.message);
                };
            ajax(rest, sc, fc);
        },

        empProfileEditSave = function (emp) {
            var protoEmp = Object.create(prototypes.empProfile),
                employeeProfile,
                parentTarget;
            console.log("Entering empProfileEditSave with object", emp);
            $.extend(protoEmp, emp);
            var rest = {
                    "method": 'POST',
                    "path": 'employee/nick',
                    "body": protoEmp.sanitize()
                },
                sc = function (st) {
                    console.log("POST employee/nick returned status", st);
                    // what we do now depends on what targets are on the stack
                    // the target on the top of the stack will be "empProfileEdit"
                    // but the one below that can be either "empProfile" or
                    // "simpleEmployeeBrowser"
                    parentTarget = stack.getTarget(-1);
                    console.log("parentTarget", parentTarget);
                    employeeProfile = Object.create(prototypes.empProfile);
                    $.extend(employeeProfile, st.payload);
                    if (parentTarget.name === 'empProfile') {
                        console.log("Profile object is", employeeProfile);
                        currentUser('obj', employeeProfile);
                        stack.pop(employeeProfile, {"resultLine": "Employee profile updated"});
                    } else if (parentTarget.name === 'simpleEmployeeBrowser') {
                        console.log("Parent target is " + parentTarget.name);
                        console.log("current object in dbrowerState set",
                                    coreLib.dbrowserState.set[coreLib.dbrowserState.pos]);
                        $.extend(
                            coreLib.dbrowserState.set[coreLib.dbrowserState.pos],
                            employeeProfile
                        );
                        stack.pop(undefined, {"resultLine": "Employee profile updated"});
                    } else {
                        console.log("FATAL ERROR: unexpected parent target", parentTarget);
                    }
                },
                fc = function (st) {
                    console.log("AJAX: " + rest["path"] + " failed with", st);
                    coreLib.displayError(st.payload.message);
                };
            ajax(rest, sc, fc);
        },

        myProfileAction = function () {
            var cu = currentUser('obj'),
                profileObj = appCaches.getProfileByEID(cu.eid),
                obj = {},
                m;
            // if the employee profile has not been loaded into the cache, we have a problem
            if (! profileObj) {
                m = "CRITICAL ERROR: the employee profile has not been loaded into the cache";
                console.log(m);
                coreLib.displayError(m);
                return null;
            }
            if (profileObj.privhistory !== null) {
                obj['priv'] = profileObj.privhistory.priv;
                obj['privEffective'] = datetime.readableDate(
                    profileObj.privhistory.effective
                );
            } else {
                obj['priv'] = '(none)';
                obj['privEffective'] = '(none)';
            }
            if (profileObj.schedhistory !== null) {
                obj['sid'] = profileObj.schedhistory.sid;
                if (profileObj.schedhistory.scode !== null) {
                    obj['scode'] = profileObj.schedhistory.scode;
                } else {
                    obj['scode'] = '(none)';
                }
                obj['schedEffective'] = datetime.readableDate(
                    profileObj.schedhistory.effective
                );
            } else {
                obj['sid'] = '(none)';
                obj['scode'] = '(none)';
                obj['schedEffective'] = '(none)';
            }
            obj['eid'] = profileObj.emp.eid;
            obj['nick'] = profileObj.emp.nick;
            obj['fullname'] = profileObj.emp.fullname;
            obj['email'] = profileObj.emp.email;
            obj['remark'] = profileObj.emp.remark;
            obj['sec_id'] - profileObj.emp.sec_id;
            stack.push('empProfile', obj);
        };

    return {
        actionEmplSearch: actionEmplSearch,
        empProfileEditSave: empProfileEditSave,
        myProfileAction: myProfileAction,
    };

});
