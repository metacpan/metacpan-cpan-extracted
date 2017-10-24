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
    'ajax',
    'lib',
    'app/prototypes',
    'stack',
    'start',
], function (
    $,
    ajax,
    coreLib,
    prototypes,
    stack,
    start,
) {

    var ldapEmployeeObject,

        displayLdapEmployee = function (emp, xtarget) {
            // The user might cause the LDAP employee to be displayed 
            // several times in a row, e.g. by selecting LDAP sync from
            // ldapDisplayEmployee - make sure we don't push duplicate
            // ldapDisplayEmployee targets onto the stack!
            var topTarget = stack.getTarget().name;
            console.log("In displayLdapEmployee, topTarget is " + topTarget);
            if (topTarget === 'ldapDisplayEmployee') {
                stack.popWithoutStart();
            }
            stack.push('ldapDisplayEmployee', emp);
            stack.setXTarget(xtarget);
        },

        getLdapEmployeeObject = function () { return ldapEmployeeObject; },

        ldapEmployeeLink = function () {
            // we assume the ldapEmployeeObject has already been 
            // partially populated - we just need to determine whether
            // or not the nick already exists in the local database
            if (ldapEmployeeObject.nick === null) {
                return ldapEmployeeObject;
            }
            ldapEmployeeObject.dochazka = false;
            var rest = {
                    "method": 'GET',
                    "path": 'employee/nick/' + ldapEmployeeObject.nick
                },
                // success callback
                sc = function (st) {
                    if (st.code === "DISPATCH_EMPLOYEE_FOUND") {
                        console.log("Payload is", st.payload);
                        ldapEmployeeObject.dochazka = true;
                    }
                    if (document.getElementById('ldapLookup') ||
                        document.getElementById('ldapDisplayEmployee')) {
                        displayLdapEmployee(ldapEmployeeObject, 'ldapLookup');
                    }
                },
                fc = function (st) {
                    if (document.getElementById('ldapLookup') ||
                        document.getElementById('ldapDisplayEmployee')) {
                        displayLdapEmployee(ldapEmployeeObject, 'ldapLookup');
                    }
                }
            ajax(rest, sc, fc);
        },

        ldapLookupSubmit = function (obj) {
            var emp = obj;
            console.log("Entering function ldapLookupSubmit, object", emp);
            // "nick" is the only property of emp that is populated
            if (! emp.nick) {
                return;
            }
            var nick = emp.nick,
                rest = {
                    method: 'GET',
                    path: 'employee/nick/' + nick + "/ldap"
                },
                // success callback -- employee already exists
                sc = function (st) {
                    if (st.code === 'DOCHAZKA_LDAP_LOOKUP') {
                        console.log("Employee exists in LDAP");
                        console.log("Server said", st);
                        resetLdapEmployeeObject();
                        $.extend(ldapEmployeeObject, st.payload);
                    } else {
                        console.log("REST server returned unexpected status", st);
                    }
                    ldapEmployeeLink();
                },
                // failure callback -- employee doesn't exist
                fc = function (st) {
                    coreLib.displayError(st.payload.message);
                };
            ajax(rest, sc, fc);
        },

        ldapSync = function (ldapEmp) {
            if (! ldapEmp) {
                stack.getState();
            }
            console.log("Entered ldapSync with object", ldapEmp);
            if (! ldapEmp.nick) {
                return;
            }
            var bo,
                nick = ldapEmp.nick,
                stackTarget,
                rest = {
                    method: 'PUT',
                    path: 'employee/nick/' + nick + '/ldap'
                },
                // success callback -- employee already exists
                sc = function (st) {
                    console.log("PUT ldap success, st object is", st);
                    if (st.code === 'DOCHAZKA_CUD_OK') {
                        console.log("Payload is", st.payload);
                        ldapEmployeeObject = $.extend(ldapEmployeeObject, st.payload);
                        ldapEmployeeObject.dochazka = true;
                    }
                    stackTarget = stack.getTarget().name;
                    console.log("Detected target ' + stackTarget + ' on top of stack");
                    if (stackTarget === 'ldapDisplayEmployee') {
                        ldapEmployeeLink();
                    } else if (stackTarget === 'simpleEmployeeBrowser') {
                        // FIXME: this code belongs in App::MFILE::WWW
                        bo = coreLib.dbrowserState.set[coreLib.dbrowserState.pos];
                        $.extend(coreLib.dbrowserState.obj, ldapEmployeeObject);
                        $.extend(bo, ldapEmployeeObject);
                        start.dbrowserListen("Employee profile updated from LDAP");
                    } else if (stackTarget === 'empProfile') {
                        stack.restart(
                            ldapEmployeeObject,
                            {"resultLine": "Employee profile updated from LDAP"},
                        );
                    }
                },
                // failure callback -- employee doesn't exist
                fc = function (st) {
                    var err = st.payload.code,
                        msg;
                    if (err === '404') {
                        msg = 'Employee ' + ldapEmp.nick + ' not found in LDAP';
                    } else {
                        msg = st.payload.message;
                    }
                    coreLib.displayError(msg);
                }
            ajax(rest, sc, fc);
        },

        ldapSyncFromBrowser = function (obj) {
            ldapSync(obj);
        },

        resetLdapEmployeeObject = function () {
            ldapEmployeeObject = Object.create(prototypes.ldapEmpObject);
        };

    return {
        ldapLookupSubmit: ldapLookupSubmit,
        ldapSync: ldapSync,
        ldapSyncFromBrowser: ldapSyncFromBrowser,
    };

});
