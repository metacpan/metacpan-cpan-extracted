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
// tests/01-users.js
//
// create "active" and "inactive" users
//
"use strict";

define ([
    'QUnit',
    'ajax',
    'app/canned-tests',
    'login',
    'loggout',
], function (
    QUnit,
    ajax,
    ct,
    login,
    loggout,
) {

    var prefix = "dochazka-www: ",
        test_desc;

    return function () {

        test_desc = 'create "active" and "inactive" users if necessary';
        QUnit.test(test_desc, function (assert) {
            console.log('***TEST*** ' + prefix + test_desc);
            var done = assert.async(5);
            assert.expect(23);
            login({"nam": "root", "pwd": "immutable"});
            setTimeout(function () {
                ct.login(assert, "root", "admin");
                done();
            }, 2000);
            setTimeout(function () {
                // create the employees
                ct.employeeCreate(assert, "active");
                ct.employeeCreate(assert, "inactive");
                done();
            }, 2400);
            setTimeout(function () {
                // add privhistory records
                ct.employeePriv(assert, "active", "active");
                ct.employeePriv(assert, "inactive", "inactive");
                done();
            }, 2800);
            setTimeout(function () {
                // assert that employees have expected privlevels
                ct.employeeHasPriv(assert, "active", "active");
                ct.employeeHasPriv(assert, "inactive", "inactive");
                loggout();
                done();
            }, 3200);
            setTimeout(function () {
                ct.loggout(assert);
                done();
            }, 3600);
        });

    };

});
