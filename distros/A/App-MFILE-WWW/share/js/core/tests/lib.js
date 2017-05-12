// ************************************************************************* 
// Copyright (c) 2014, SUSE LLC
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
    'cf',
    'current-user',
    'lib'
], function (
    cf,
    currentUser,
    lib 
) {
    return function () {
        //
        // hairCut
        //
        test('internal library functions: hairCut', function () {
            var obj = Object.create(null);
            obj = { a: 1, b: 2, c: 3, bogusProp: "bogus" };
            ok(obj.hasOwnProperty("a"), "a");
            ok(obj.hasOwnProperty("b"), "b");
            ok(obj.hasOwnProperty("c"), "c");
            ok(obj.hasOwnProperty("bogusProp"), "bogusProp present");
            lib.hairCut(obj, ['a', 'b', 'c']);
            ok(obj.hasOwnProperty("a"), "a still there");
            ok(obj.hasOwnProperty("b"), "b still there");
            ok(obj.hasOwnProperty("c"), "c still there");
            equal(obj.hasOwnProperty("bogusProp"), false, "no bogus property anymore");
        });
        //
        // privCheck
        //
        test('internal library functions: privCheck', function () {
            currentUser('priv', 'passerby');
            strictEqual(currentUser('priv'), 'passerby', "currentUserPriv override");
            equal(lib.privCheck('passerby'), true, "user passerby, ACL passerby");
            equal(lib.privCheck('inactive'), false, "user passerby, ACL inactive");
            equal(lib.privCheck('active'), false, "user passerby, ACL active");
            equal(lib.privCheck('admin'), false, "user passerby, ACL admin");
            currentUser('priv', 'inactive');
            strictEqual(currentUser('priv'), 'inactive', "currentUserPriv override");
            equal(lib.privCheck('passerby'), true, "user inactive, ACL passerby");
            equal(lib.privCheck('inactive'), true, "user inactive, ACL inactive");
            equal(lib.privCheck('active'), false, "user inactive, ACL active");
            equal(lib.privCheck('admin'), false, "user inactive, ACL admin");
            currentUser('priv', 'active');
            strictEqual(currentUser('priv'), 'active', "currentUserPriv override");
            equal(lib.privCheck('passerby'), true, "user active, ACL passerby");
            equal(lib.privCheck('inactive'), true, "user active, ACL inactive");
            equal(lib.privCheck('active'), true, "user active, ACL active");
            equal(lib.privCheck('admin'), false, "user active, ACL admin");
            currentUser('priv', 'admin');
            strictEqual(currentUser('priv'), 'admin', "currentUserPriv override");
            equal(lib.privCheck('passerby'), true, "user admin, ACL passerby");
            equal(lib.privCheck('inactive'), true, "user admin, ACL inactive");
            equal(lib.privCheck('active'), true, "user admin, ACL active");
            equal(lib.privCheck('admin'), true, "user admin, ACL admin");
        });
    };
});

