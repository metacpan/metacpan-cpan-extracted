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
// app/tests/main-empl.js
//
// Tests exercising the "mainEmpl" dmenu
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

        test_desc = 'employee menu appears';
        QUnit.test(test_desc, function (assert) {
            console.log('***TEST*** ' + prefix + test_desc);
            var done = assert.async(3);
            login({"nam": "demo", "pwd": "demo"});
            setTimeout(function () {
                ct.login(assert, "demo", "passerby");
                done();
            }, 1000);
            setTimeout(function () {
                ct.mainMenuToMainEmpl(assert);
                loggout();
                done();
            }, 2000);
            setTimeout(function () {
                ct.loggout(assert);
                done();
            }, 2500);
        });

        test_desc = 'employee profile - passerby';
        QUnit.test(test_desc, function (assert) {
            var done = assert.async(4),
                fullProfile;
            console.log("***TEST*** " + prefix + test_desc);
            login({"nam": "demo", "pwd": "demo"});
            setTimeout(function() {
                ct.login(assert, "demo", "passerby");
                done();
            }, 1500);
            setTimeout(function () {
                // assert.ok(true, "Employee profile cache: " + QUnit.dump.parse(appCaches.profileCache));
                assert.ok(appCaches.profileCacheLength() > 0, "Employee profile cache populated");
                fullProfile = appCaches.getProfileByNick('demo');
                assert.ok("emp" in fullProfile, "Employee profile cache populated with an employee");
                assert.strictEqual(
                    fullProfile.emp.nick,
                    "demo",
                    "Employee profile cache populated with employee \"demo\""
                );
                ct.mainMenuToMainEmpl(assert);
                assert.ok(true, 'select 0 ("My profile") in mainEmpl as demo');
                $('input[name="sel"]').val('0');
                $('input[name="sel"]').focus();
                $('input[name="sel"]').trigger($.Event("keydown", {keyCode: 13}));
                // no AJAX call is initiated, because the profile is already in the cache
                // ct.ajaxCallInitiated(assert);
                done();
            }, 2000);
            setTimeout(function() {
                // assert.ok(true, $("#mainarea").html());
                ct.mainareaForm(assert, 'empProfile');
                // FIXME: test for non-existence of entries here, since we are
                // just a "passerby"
                loggout();
                done();
            }, 2500);
            setTimeout(function () {
                ct.loggout(assert);
                done();
            }, 3000);
        });

        test_desc = 'Search Dochazka employees - success no wildcard';
        // searches for an exact match - the resulting dbrowser will
        // contain only one object
        QUnit.test(test_desc, function (assert) {
            console.log('***TEST*** ' + prefix + test_desc);
            var done = assert.async(4);
            login({"nam": "root", "pwd": "immutable"});
            setTimeout(function () {
                ct.login(assert, "root", "admin");
                ct.mainMenuToMainEmpl(assert);
                ct.mainEmplToSearchEmployee(assert);
                // enter search term into form
                $('#searchEmployee input[name="entry0"]').val('inactive');
                // choose '0' to start search
                $('input[name="sel"]').val('0');
                $('input[name="sel"]').focus();
                start.mmKeyListener($.Event("keydown", {keyCode: 13}));
                assert.ok(true, "*** REACHED pressed 0 to initiate search for Dochazka employee inactive");
                done();
            }, 1000);
            setTimeout(function () {
                var htmlbuf = $("#mainarea").html();
                ct.stack(
                    assert,
                    4,
                    'Reached simpleEmployeeBrowser dbrowser',
                    'dbrowser',
                    'simpleEmployeeBrowser'
                );
                ct.contains(
                    assert,
                    htmlbuf,
                    "#mainarea html",
                    "Employee search results",
                );
                ct.mainareaForm(assert, "simpleEmployeeBrowser");
                assert.strictEqual(
                    $('#ePfullname').text(),
                    "inactive user",
                    "Dochazka employee search succeeded - full name \"inactive user\" displayed",
                );
                assert.strictEqual(
                    $('#ePnick').text(),
                    "inactive",
                    "Dochazka employee search succeeded - nick inactive displayed",
                );
                ct.contains(
                    assert,
                    $('#mainarea').html(),
                    "#mainarea html",
                    "0.&nbsp;LDAP sync",
                );
                assert.ok(true, "*** REACHED miniMenu contains 0. LDAP sync");
                // // choose '0' for ldapSync
                // $('input[name="sel"]').val('0');
                // $('input[name="sel"]').focus();
                // start.mmKeyListener($.Event("keydown", {keyCode: 13}));
                // assert.ok(true, "*** REACHED pressed 0 for LDAP sync");
                done();
            }, 2500);
            setTimeout(function () {
                // ct.contains(
                //     assert,
                //     $('#result').html(),
                //     "#result html",
                //     "Employee profile updated from LDAP",
                // );
                ct.stack(
                    assert,
                    4,
                    'in simpleEmployeeBrowser dbrowser',
                    'dbrowser',
                    'simpleEmployeeBrowser'
                );
                $('input[name="sel"]').val('x');
                $('input[name="sel"]').focus();
                start.mmKeyListener($.Event("keydown", {keyCode: 13}));
                ct.stack(
                    assert,
                    3,
                    'After selecting X in simpleEmployeeBrowser',
                    'dform',
                    'searchEmployee',
                );
                assert.ok(true, "*** REACHED searchEmployee dform via X from simpleEmployeeBrowser");
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
            }, 5000);
            setTimeout(function () {
                ct.loggout(assert);
                done();
            }, 5500);
        });

    };
});

