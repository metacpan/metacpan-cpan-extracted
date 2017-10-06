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
// tests/lib.js
//
"use strict";

define ([
    'QUnit',
    'cf',
    'current-user',
    'lib'
], function (
    QUnit,
    cf,
    currentUser,
    lib 
) {
    return function () {

        // hairCut
        QUnit.test('internal library functions: hairCut', function (assert) {
            var obj = Object.create(null);
            obj = { a: 1, b: 2, c: 3, bogusProp: "bogus" };
            assert.ok(obj.hasOwnProperty("a"), "a");
            assert.ok(obj.hasOwnProperty("b"), "b");
            assert.ok(obj.hasOwnProperty("c"), "c");
            assert.ok(obj.hasOwnProperty("bogusProp"), "bogusProp present");
            lib.hairCut(obj, ['a', 'b', 'c']);
            assert.ok(obj.hasOwnProperty("a"), "a still there");
            assert.ok(obj.hasOwnProperty("b"), "b still there");
            assert.ok(obj.hasOwnProperty("c"), "c still there");
            assert.strictEqual(obj.hasOwnProperty("bogusProp"), false, "no bogus property anymore");
        });

        // privCheck
        QUnit.test('internal library functions: privCheck', function (assert) {
            assert.strictEqual(currentUser('priv'), null, "starting currentUserPriv is null");
            currentUser('priv', 'passerby');
            assert.strictEqual(currentUser('priv'), 'passerby', "set currentUserPriv to passerby");
            assert.strictEqual(lib.privCheck('passerby'), true, "user passerby, ACL passerby");
            assert.strictEqual(lib.privCheck('inactive'), false, "user passerby, ACL inactive");
            assert.strictEqual(lib.privCheck('active'), false, "user passerby, ACL active");
            assert.strictEqual(lib.privCheck('admin'), false, "user passerby, ACL admin");
            currentUser('priv', 'inactive');
            assert.strictEqual(currentUser('priv'), 'inactive', "set currentUserPriv to inactive");
            assert.strictEqual(lib.privCheck('passerby'), true, "user inactive, ACL passerby");
            assert.strictEqual(lib.privCheck('inactive'), true, "user inactive, ACL inactive");
            assert.strictEqual(lib.privCheck('active'), false, "user inactive, ACL active");
            assert.strictEqual(lib.privCheck('admin'), false, "user inactive, ACL admin");
            currentUser('priv', 'active');
            assert.strictEqual(currentUser('priv'), 'active', "set currentUserPriv to active");
            assert.strictEqual(lib.privCheck('passerby'), true, "user active, ACL passerby");
            assert.strictEqual(lib.privCheck('inactive'), true, "user active, ACL inactive");
            assert.strictEqual(lib.privCheck('active'), true, "user active, ACL active");
            assert.strictEqual(lib.privCheck('admin'), false, "user active, ACL admin");
            currentUser('priv', 'admin');
            assert.strictEqual(currentUser('priv'), 'admin', "set currentUserPriv to admin");
            assert.strictEqual(lib.privCheck('passerby'), true, "user admin, ACL passerby");
            assert.strictEqual(lib.privCheck('inactive'), true, "user admin, ACL inactive");
            assert.strictEqual(lib.privCheck('active'), true, "user admin, ACL active");
            assert.strictEqual(lib.privCheck('admin'), true, "user admin, ACL admin");
            currentUser('priv', null);
        });

    };
});

