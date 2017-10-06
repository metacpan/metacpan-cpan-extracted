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
// tests/cf.js
//
"use strict";

define ([
    'QUnit',
    'cf'
], function (
    QUnit,
    cf
) {
    return function () {

        var priv = cf('currentUserPriv');

        QUnit.test('cf sees parameters sent from Perl side', function (assert) {
            assert.strictEqual(typeof cf('appName'), 'string', "appName");
            assert.strictEqual(typeof cf('appVersion'), 'string', "appVersion");
            assert.strictEqual(typeof cf('currentUser'), 'object', "currentUser");
            //
            // currentUser and currentUserPriv will always be null in testing
            assert.strictEqual(cf('currentUser'), null, "currentUser is null");
            assert.strictEqual(cf('currentUserPriv'), null, "currentUserPriv is null");
            //
            assert.strictEqual(typeof cf('loginDialogChallengeText'), 'string', "loginDialogChallengeText (1)");
            assert.ok(cf('loginDialogChallengeText').length > 0, "loginDialogChallengeText (2)");
            assert.strictEqual(typeof cf('loginDialogMaxLengthUsername'), 'number', "loginDialogMaxLengthUsername");
            assert.strictEqual(typeof cf('loginDialogMaxLengthPassword'), 'number', "loginDialogMaxLengthPassword");
            assert.strictEqual(typeof cf('dummyParam'), 'object', "dummyParam is an object");
            assert.strictEqual(cf('nonExistentdummyParam'), undefined, "nonExistentDummyParam is undefined");
        });

        QUnit.test('cf parameter values can be overridden', function (assert) {
            // override dummyParam
            cf('dummyParam', { test: 'test' });
            assert.deepEqual(cf('dummyParam'), { test: 'test' }, 'dummyParam value override');
        });

        QUnit.test('cf testing is set to true', function (assert) {
            assert.strictEqual(cf('testing'), true, 'cf testing is set to true');
        });

    };
});

