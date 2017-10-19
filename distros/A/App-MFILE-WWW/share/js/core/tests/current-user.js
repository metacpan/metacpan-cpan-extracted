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
// tests/current-user.js
//
// Test the currentUser object
//
"use strict";

define ([
    'QUnit',
    'cf',
    'current-user'
], function (
    QUnit,
    cf,
    currentUser
) {
    return function () {

        QUnit.test('currentUser object', function (assert) {
            var cu = currentUser();
            assert.ok(cu, "There is a currentUser object with value " +
                QUnit.dump.parse(cu));
            assert.ok(cu.hasOwnProperty('obj'), "currentUser.obj exists with value " +
                QUnit.dump.parse(cu.obj));
            assert.ok(cu.hasOwnProperty('priv'), "currentUser.priv exists with value " +
                QUnit.dump.parse(cu.priv));
            assert.ok(typeof cu.obj, "object", "currentUser.obj is an object");
            assert.ok('nick' in cu.obj, "currentUser.obj has nick property");
            assert.strictEqual(cu.obj.nick, "", "value of nick property is the empty string");
            assert.strictEqual(cu.priv, null, "currentUser.priv is null");
            assert.strictEqual(cu.flag1, undefined, "currentUser.flag1 is undefined");
        });

    };
});

