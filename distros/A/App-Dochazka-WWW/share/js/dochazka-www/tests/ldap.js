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
// app/tests/ldap.js
//
// Tests exercising LDAP functionality
//
"use strict";

define ([
  'QUnit',
  'jquery',
  'app/canned-tests',
  'app/caches',
  'lib',
  'login',
  'loggout',
  'stack',
  'start',
], function (
  QUnit,
  $,
  ct,
  appCaches,
  coreLib,
  login,
  loggout,
  stack,
  start,
) {

    var prefix = "dochazka-www: ",
        test_desc;

    return function () {

        test_desc = 'LDAP lookup - success';
        QUnit.test(test_desc, function (assert) {
            console.log('***TEST*** ' + prefix + test_desc);
            var done = assert.async(4);
            login({"nam": "root", "pwd": "immutable"});
            setTimeout(function () {
                ct.login(assert, "root", "admin");
                ct.mainMenuToMainEmpl(assert);
                ct.mainEmplToLdapLookup(assert);
                ct.submitLdapLookup(assert, 'ncutler');
                done();
            }, 1000);
            setTimeout(function () {
                var ldapDochazka;
                ct.stack(
                    assert,
                    4,
                    'Displaying LDAP employee after successful LDAP lookup',
                    'dform',
                    'ldapDisplayEmployee',
                );
                ct.mainareaForm(assert, 'ldapDisplayEmployee');
                assert.strictEqual(
                    $('#ePfullname').text(),
                    "Nathan Cutler",
                    "Successful LDAP lookup displayed full name Nathan Cutler",
                );
                assert.strictEqual(
                    $('#ePnick').text(),
                    "ncutler",
                    "Successful LDAP lookup displayed nick ncutler",
                );
                ldapDochazka = $('#LDAPdochazka').text();
                assert.ok(ldapDochazka, "ncutler is in Dochazka already? " + ldapDochazka);
                assert.ok(
                    ldapDochazka === "YES" || ldapDochazka === "NO",
                    "Answer to whether ncutler is in Dochazka (" + ldapDochazka + ") makes sense",
                );
                assert.ok(true, "*** REACHED Employee LDAP lookup success");
                ct.contains(
                    assert,
                    $('#mainarea').html(),
                    "#mainarea html",
                    "0. LDAP sync",
                );
                assert.ok(true, "*** REACHED miniMenu contains 0. LDAP sync");
                // choose '0' for ldapSync
                $('input[name="sel"]').val('0');
                $('input[name="sel"]').focus();
                start.mmKeyListener($.Event("keydown", {keyCode: 13}));
                assert.ok(true, "*** REACHED pressed 0 for LDAP sync");
                done();
            }, 3000);
            setTimeout(function () {
                var ldapDochazka = $('#LDAPdochazka').text();
                ct.stack(
                    assert,
                    4,
                    'Displaying LDAP employee after successful LDAP lookup',
                    'dform',
                    'ldapDisplayEmployee',
                );
                ct.mainareaForm(assert, 'ldapDisplayEmployee');
                assert.ok(ldapDochazka, "ncutler is in Dochazka already? " + ldapDochazka);
                assert.ok(
                    ldapDochazka === "YES",
                    "ncutler is now in Dochazka, no question about it",
                );
                $('input[name="sel"]').val('x');
                $('input[name="sel"]').focus();
                start.mmKeyListener($.Event("keydown", {keyCode: 13}));
                ct.stack(
                    assert,
                    3,
                    'After selecting X in ldapDisplayEmployee',
                    'dform',
                    'ldapLookup',
                );
                assert.ok(true, "*** REACHED ldapLookup dform via X from ldapDisplayEmployee");
                assert.strictEqual(
                    coreLib.focusedItem().name,
                    'sel',
                    'Focus is on selection field',
                );
                $('input[name="sel"]').val('x');
                $('input[name="sel"]').focus();
                start.mmKeyListener($.Event("keydown", {keyCode: 13}));
                ct.stack(
                    assert,
                    2,
                    'After selecting X in ldapLookup',
                    'dmenu',
                    'mainEmpl'
                );
                assert.ok(true, "*** REACHED mainEmpl dmenu via X from ldapLookup");
                loggout();
                done();
            }, 4500);
            setTimeout(function () {
                ct.loggout(assert);
                done();
            }, 5500);
        });

        test_desc = 'LDAP lookup - failure';
        QUnit.test(test_desc, function (assert) {
            console.log('***TEST*** ' + prefix + test_desc);
            var done = assert.async(4);
            login({"nam": "root", "pwd": "immutable"});
            setTimeout(function () {
                ct.login(assert, "root", "admin");
                ct.mainMenuToMainEmpl(assert);
                ct.mainEmplToLdapLookup(assert);
                ct.submitLdapLookup(assert, 'NONEXISTENTfoobarbazblatFISHBEAR');
                done();
            }, 1000);
            setTimeout(function () {
                ct.stack(
                    assert,
                    3,
                    'failed LDAP lookup',
                    'dform',
                    'ldapLookup',
                );
                ct.contains(
                    assert,
                    $("#result").html(),
                    "#result html",
                    "Employee not found in LDAP",
                );
                assert.strictEqual(
                    coreLib.focusedItem().name,
                    'entry0',
                    'Focus is on data entry field',
                );
                ct.submitLdapLookup(assert, 'NONEXISTENTpseudoDataEntered');
                done();
            }, 3000);
            setTimeout(function () {
                ct.stack(
                    assert,
                    3,
                    'failed LDAP lookup',
                    'dform',
                    'ldapLookup',
                );
                ct.contains(
                    assert,
                    $("#result").html(),
                    "#result html",
                    "Employee not found in LDAP",
                );
                assert.strictEqual(
                    coreLib.focusedItem().name,
                    'entry0',
                    'Focus is on data entry field',
                );
                loggout();
                done();
            }, 4000);
            setTimeout(function () {
                ct.loggout(assert);
                done();
            }, 5000);
        });

    };
});

