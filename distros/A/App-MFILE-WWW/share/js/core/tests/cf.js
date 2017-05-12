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
// tests/cf.js
//
"use strict";

define ([
    'cf'
], function (
    cf
) {

    return function () {
        var priv = cf('currentUserPriv');
        test('cf sees parameters sent from Perl side', function () {
            strictEqual(typeof cf('appName'), 'string', "appName");
            strictEqual(typeof cf('appVersion'), 'string', "appVersion");
            strictEqual(typeof cf('currentUser'), 'object', "currentUser");

            // currentUser can either be null or a user/employee object
            if (cf('currentUser') === null) {
                strictEqual(cf('currentUser'), null, "currentUser is null");
            } else {
                ok(cf('currentUser').hasOwnProperty('nick'), "currentUser has nick property");
                ok(cf('currentUser').hasOwnProperty('passhash'), "currentUser has passhash property");
                ok(cf('currentUser').hasOwnProperty('salt'), "currentUser has salt property");
                equal(cf('currentUser').hasOwnProperty('priv'), false, "currentUser does NOT have priv property");
            }

            strictEqual(typeof priv, 'string', "currentUserPriv");

            // currentUserPriv must be a valid privlevel
            ok( 
                (priv === 'passerby') ||
                (priv === 'inactive') ||
                (priv === 'active') ||
                (priv === 'admin')
                , "currentUserPriv value is valid (" + priv + ")");

            strictEqual(typeof cf('loginDialogChallengeText'), 'string', "loginDialogChallengeText (1)");
            ok(cf('loginDialogChallengeText').length > 0, "loginDialogChallengeText (2)");
            strictEqual(typeof cf('loginDialogMaxLengthUsername'), 'number', "loginDialogMaxLengthUsername");
            strictEqual(typeof cf('loginDialogMaxLengthPassword'), 'number', "loginDialogMaxLengthPassword");
            strictEqual(typeof cf('dummyParam'), 'object', "dummyParam is an object");
            strictEqual(cf('nonExistentdummyParam'), undefined, "nonExistentDummyParam is undefined");
        });
        test('cf parameter values can be overridden', function () {
            // override dummyParam
            cf('dummyParam', { test: 'test' });
            deepEqual(cf('dummyParam'), { test: 'test' }, 'dummyParam value override');
        });
    };

});

