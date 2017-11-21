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

    var empProfileEmp,

        actionEmplSearch = function (obj) {
            var count, masquerade, opts, rs, supervisor;
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
                        rs = st.payload.result_set || st.payload;
                        count = rs.length;
                        opts = stack.getOpts();
                        masquerade = ('masquerade' in opts) ? opts.masquerade : false;
                        supervisor = ('supervisor' in opts) ? opts.supervisor : false;
        
                        console.log("Search found " + count + " employees");
                        if (masquerade) {
                            stack.push(
                                "masqueradeCandidatesBrowser",
                                {"set": rs, "pos": 0},
                            );
                        } else if (supervisor) {
                            stack.push(
                                "setSupervisorBrowser",
                                {"set": rs, "pos": 0},
                            );
                        } else {
                            stack.push(
                                "simpleEmployeeBrowser",
                                {"set": rs, "pos": 0},
                            );
                        }
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

        currentEmpHasReports = function () {
            var cu = currentUser('obj'),
                cup = appCaches.getProfileByEID(cu.eid),
                priv = currentUser('priv');
            console.log("Entering currentEmpHasReports(), current employee profile", cup);
            if (priv === 'admin') {
                // not applicable to admins
                return true;
            }
            if (typeof cup !== 'object' || ! 'hasReports' in cup || typeof cup.hasReports !== 'function') {
                throw "Profile of current user has not been loaded into the cache";
            }
            if (typeof cup.hasReports === 'function') {
                return cup.hasReports();
            }
            console.log("CRITICAL ERROR: Bad current user profile object", cup);
            throw "Bad current user profile object";
        },

        empProfileEditSave = function (emp) {
                // protoEmp = Object.create(prototypes.empProfile),
            var empObj,
                parentTarget,
                protoEmp = $.extend(Object.create(prototypes.empObject), emp);
            console.log("Entering empProfileEditSave with object", emp);
            // protoEmp = {
            //     'emp': { 'eid': emp.eid,
            //              'email': coreLib.nullify(emp.email),
            //              'fullname': coreLib.nullify(emp.fullname),
            //              'nick': coreLib.nullify(emp.nick),
            //              'remark': coreLib.nullify(emp.remark),
            //              'sec_id': coreLib.nullify(emp.sec_id), },
            //     'has_reports': emp.has_reports,
            //     'priv': emp.priv,
            //     'privhistory': { 'effective': emp.privEffective },
            //     'schedhistory': { 'effective': emp.schedEffective,
            //                       'scode': emp.scode,
            //                       'sid': emp.sid },
            //     'schedule': { 'scode': emp.scode, 'sid': emp.sid },
            // };
            var rest = {
                    "method": 'POST',
                    "path": 'employee/nick',
                    "body": protoEmp.sanitize(),
                },
                sc = function (st) {
                    console.log("POST employee/nick returned status", st);
                    // what we do now depends on what targets are on the stack
                    // the target on the top of the stack will be "empProfileEdit"
                    // but the one below that can be either "empProfile" or
                    // "simpleEmployeeBrowser"
                    parentTarget = stack.getTarget(-1);
                    console.log("parentTarget", parentTarget);
                    empObj = Object.create(prototypes.empObject);
                    $.extend(empObj, st.payload);
                    if (parentTarget.name === 'empProfile') {
                        console.log("Employee object is", empObj);
                        currentUser('obj', empObj);
                        appCaches.setProfileCache({"emp": empObj});
                        stack.unwindToTarget(
                            'myProfileAction', undefined,
                            {"resultLine": "Employee profile updated"}
                        );
                    } else if (parentTarget.name === 'simpleEmployeeBrowser') {
                        console.log("Parent target is " + parentTarget.name);
                        console.log("current object in dbrowerState set",
                                    coreLib.dbrowserState.set[coreLib.dbrowserState.pos]);
                        $.extend(
                            coreLib.dbrowserState.set[coreLib.dbrowserState.pos],
                            empObj,
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

        empProfileSetSuperDelete = function () {
            stack.push('empProfileSetSuperChoose', { "eid": null, "nick": null });
        },

        empProfileSetSuperChoose = function (superEmp) {
            var cu = currentUser('obj'),
                obj = {
                    "ePsetsuperofEID": cu.eid,
                    "ePsetsupertoEID": superEmp.eid,
                    "ePsetsuperof": cu.nick,
                    "ePsetsuperto": superEmp.nick,
                };
            console.log("Entering empSetSupervisor() with superEmp", superEmp);
            console.log("Will set superEmp as the supervisor of " + cu.nick);
            console.log("Pushing empProfileSetSuperConfirm onto stack with obj", obj);
            stack.push('empProfileSetSuperConfirm', obj);
        },

        empProfileSetSuperCommit = function (obj) {
            var cu = currentUser('obj'),
                empProfile,
                rest = {
                    "method": 'PUT',
                    "path": 'employee/eid/' + obj.ePsetsuperofEID,
                    "body": {
                        "supervisor": obj.ePsetsupertoEID,
                    }
                },
                sc = function (st) {
                    if (st.code === 'DOCHAZKA_CUD_OK' || st.code === 'DISPATCH_UPDATE_NO_CHANGE_OK' ) {
                        cu.supervisor = obj.ePsetsupertoEID;
                        empProfile = appCaches.getProfileByEID(obj.ePsetsuperofEID);
                        if (empProfile) {
                             empProfile.supervisor = obj.ePsetsupertoEID;
                             appCaches.setProfileCache(empProfile);
                        }
                        stack.unwindToType('dmenu', {
                            "_start": false
                        });
                        stack.push('myProfileAction', {
                            "resultLine": "Commit OK"
                        });
                    } else {
                        coreLib.displayError("CRITICAL ERROR THIS IS A BUG: " + st.code);
                        throw st.code;
                    }
                };
            console.log("Entered empProfileSetSuperCommit() with obj", obj);
            ajax(rest, sc);
        },

        empProfileSetSuperSearch = function (superEmp) {
            empProfileEmp = superEmp;
            stack.push('searchEmployee', {}, {
                "supervisor": true,
            });
        },

        myProfileActionNewOpts,
        myProfileActionPopulate = function (populateArray) {
            var cu = currentUser('obj'),
                obj = {},
                populateContinue = populate.shift(populateArray),
                profileObj = appCaches.getProfileByEID(cu.eid);
            if (profileObj.privhistory) {
                obj['priv'] = profileObj.privhistory.priv;
                obj['privEffective'] = datetime.readableDate(
                    profileObj.privhistory.effective
                );
            } else {
                obj['priv'] = '(none)';
                obj['privEffective'] = '(none)';
            }
            if (profileObj.schedhistory) {
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
            obj['sec_id'] = profileObj.emp.sec_id;
            obj['has_reports'] = ( profileObj.has_reports === 0 || profileObj.has_reports === undefined ) ? null : profileObj.has_reports;
            stack.push('empProfile', obj, myProfileActionNewOpts);
            populateContinue(populateArray);
        },
        myProfileAction = function (obj, opts) {
            myProfileActionNewOpts = {
                'resultLine': (typeof opts === 'object') ? opts.resultLine : null,
                'xtarget': 'mainEmpl',
            };
            populate.bootstrap([
                appCaches.populateFullEmployeeProfileCache,
                appCaches.populateScheduleBySID,
                myProfileActionPopulate,
            ]);
        }
        ;

    return {
        actionEmplSearch: actionEmplSearch,
        currentEmpHasReports: currentEmpHasReports,
        empProfileEditSave: empProfileEditSave,
        empProfileSetSuperChoose: empProfileSetSuperChoose,
        empProfileSetSuperCommit: empProfileSetSuperCommit,
        empProfileSetSuperDelete: empProfileSetSuperDelete,
        empProfileSetSuperSearch: empProfileSetSuperSearch,
        myProfileAction: myProfileAction,
    };

});
