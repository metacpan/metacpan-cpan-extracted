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
                ct.mainMenu(assert);
                // assert.ok(true, "Employee profile cache: " + QUnit.dump.parse(appCaches.profileCache));
                assert.ok(appCaches.profileCacheLength() > 0, "Employee profile cache populated");
                fullProfile = appCaches.getProfileByNick('demo');
                assert.ok("emp" in fullProfile, "Employee profile cache populated with an employee");
                assert.strictEqual(
                    fullProfile.emp.nick,
                    "demo",
                    "Employee profile cache populated with employee \"demo\""
                );
                assert.ok(true, 'select 1 ("Profile") in mainMenu as demo');
                $('input[name="sel"]').val('1');
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
            var done = assert.async(5);
            login({"nam": "root", "pwd": "immutable"});
            setTimeout(function () {
                ct.login(assert, "root", "admin");
                done();
            }, 1500);
            setTimeout(function () {
                var sel;
                ct.mainMenu(assert);
                ct.mainMenuToMainAdmin(assert);
                ct.mainAdminToSearchEmployee(assert);
                // enter search term into form
                $('#searchEmployee input[name="entry0"]').val('inactive');
                sel = ct.getMenuEntry(assert, $('#minimenu').html(), 'Search');
                $('input[name="sel"]').val(sel);
                $('input[name="sel"]').focus();
                start.mmKeyListener($.Event("keydown", {keyCode: 13}));
                ct.log(assert, "*** REACHED initiated search for Dochazka employee inactive");
                done();
            }, 2000);
            setTimeout(function () {
                var htmlbuf = $("#mainarea").html();
                ct.log(assert, htmlbuf);
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
                    $('#minimenu').html(),
                    "#minimenu html",
                    ".&nbsp;LDAP&nbsp;sync",
                );
                assert.ok(true, "*** REACHED miniMenu contains substring '. LDAP sync'");
                // // choose '0' for ldapSync
                // $('input[name="sel"]').val('0');
                // $('input[name="sel"]').focus();
                // start.mmKeyListener($.Event("keydown", {keyCode: 13}));
                // assert.ok(true, "*** REACHED pressed 0 for LDAP sync");
                done();
            }, 3000);
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
                    'mainAdmin'
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

        test_desc = 'Masquerading as active, set inactive as supervisor';
        QUnit.test(test_desc, function (assert) {
            console.log('***TEST*** ' + prefix + test_desc);
            var done = assert.async(10);
            login({"nam": "root", "pwd": "immutable"});
            setTimeout(function () {
                ct.login(assert, "root", "admin");
                done();
            }, 1500);
            setTimeout(function () {
                var mainarea,
                    sel;
                ct.mainMenu(assert);
                assert.strictEqual($('#userbox').text(), 'Employee: root ADMIN');
                ct.mainareaForm(assert, 'mainMenu');
                sel = ct.getMenuEntry(assert, $('#mainarea').html(), 'Masquerade');
                $('input[name="sel"]').val(sel);
                $('input[name="sel"]').focus();
                // press ENTER -> submit the form
                $('input[name="sel"]').trigger($.Event("keydown", {keyCode: 13}));
                ct.stack(assert, 2, 'navigating from mainMenu to searchEmployee', 'dform', 'searchEmployee');
                mainarea = $('#mainarea').html();
                ct.contains(assert, mainarea, "#mainarea", "Search Dochazka employees");
                assert.ok(true, "*** REACHED searchEmployee dform");
                done();
            }, 2000);
            setTimeout(function () {
                var minimenu,
                    sel;
                // enter a search string
                $('input[id="sEnick"]').val('act%');
                assert.strictEqual($('input[id="sEnick"]').val(), 'act%', "Search string entered into form");
                minimenu = $('#minimenu').html();
                ct.contains(assert, minimenu, "searchEmployee miniMenu", ".&nbsp;Search");
                sel = ct.getMenuEntry(assert, minimenu, 'Search')
                ct.log(assert, "searchEmployee miniMenu contains Search as selection " + sel);
                $('input[name="sel"]').val(sel);
                $('input[name="sel"]').focus();
                $('input[name="sel"]').trigger($.Event("keydown", {keyCode: 13}));
                done();
            }, 2500);
            setTimeout(function () {
                var mainarea,
                    minimenu,
                    sel;
                ct.stack(assert, 3, 'browsing results of successful Dochazka employee search',
                         'dbrowser', 'masqueradeCandidatesBrowser');
                assert.ok(true, "*** REACHED masqueradeCandidatesBrowser dform");
                mainarea = $('#mainarea').html();
                minimenu = $('#minimenu').html();
                ct.contains(assert, mainarea, "Masquerade candidates browser", 'Masquerade candidates');
                ct.contains(assert, minimenu, "Masquerade selection in miniMenu", ".&nbsp;Masquerade");
                assert.ok(true, "*** REACHED Masquerade selection in masqueradeCandidatesBrowser miniMenu");
                sel = ct.getMenuEntry(assert, minimenu, 'Masquerade');
                assert.ok(true, "masqueradeCandidatesBrowser miniMenu contains Masquerade as selection " + sel);
                // select Masquerade (first time - begin)
                $('input[name="sel"]').val(sel);
                $('input[name="sel"]').focus();
                // press ENTER -> submit the form
                $('input[name="sel"]').trigger($.Event("keydown", {keyCode: 13}));
                ct.stack(assert, 1, 'selected Masquerade in masqueradeCandidatesBrowser', 'dmenu', 'mainMenu');
                assert.strictEqual($('#userbox').text(), '!!! Employee: active (MASQUERADE) !!!');
                assert.ok(true, "*** REACHED masquerading as employee \"active\"");
                done();
            }, 3000);
            setTimeout(function () {
                ct.mainMenuSelectEmpProfile(assert);
                done();
            }, 3500);
            setTimeout(function () {
                var htmlbuf,
                    sel;
                // mainMenu, myProfileAction, empProfile
                ct.stack(assert, 3, 'navigating from mainMenu to empProfile', 'dform', 'empProfile');
                ct.mainareaForm(assert, 'empProfile');
                ct.contains(assert, $('#mainarea').html(), "#mainarea", "Employee profile");
                ct.log(assert, "*** REACHED empProfile dform");
                // Whatever the supervisor is, delete it
                sel = ct.getMenuEntry(assert, $('#minimenu').html(), "Remove&nbsp;supervisor");
                assert.ok(true, "Selection is " + sel);
                $('input[name="sel"]').val(sel);
                $('input[name="sel"]').focus();
                // press ENTER -> submit the form
                $('input[name="sel"]').trigger($.Event("keydown", {keyCode: 13}));
                // mainMenu, myProfileAction, empProfile, searchEmployee
                ct.stack(
                    assert,
                    4,
                    'selected Delete supervisor in empProfile',
                    'dform',
                    'empProfileSetSuperConfirm'
                );
                htmlbuf = $("#mainarea").html(),
                ct.contains(
                    assert,
                    htmlbuf,
                    "#mainarea html",
                    "Set employee supervisor - confirmation",
                );
                ct.mainareaForm(assert, "empProfileSetSuperConfirm");
                sel = ct.getMenuEntry(assert, $('#minimenu').html(), 'Yes,&nbsp;I&nbsp;really&nbsp;do');
                assert.ok(true, "Selection is " + sel);
                $('input[name="sel"]').val(sel);
                $('input[name="sel"]').focus();
                // press ENTER -> submit the form
                $('input[name="sel"]').trigger($.Event("keydown", {keyCode: 13}));
                done();
            }, 4000);
            setTimeout(function () {
                var sel;
                ct.stack(
                    assert,
                    3,
                    'back in empProfile after confirming deletion of supervisor',
                    'dform',
                    'empProfile'
                );
                ct.log(assert, $('#mainarea').html());
                ct.contains(
                    assert,
                    $('#ePsuperNick').text(),
                    "#ePsuperNick text",
                    "(none)",
                );
                ct.log(assert, "*** REACHED supervisor deleted; no supervisor is set");
                sel = ct.getMenuEntry(assert, $('#minimenu').html(), "Set&nbsp;supervisor");
                assert.ok(true, "Selection is " + sel);
                $('input[name="sel"]').val(sel);
                $('input[name="sel"]').focus();
                // press ENTER -> submit the form
                $('input[name="sel"]').trigger($.Event("keydown", {keyCode: 13}));
                // mainMenu, myProfileAction, empProfile, searchEmployee
                ct.stack(assert, 4, 'selected Set supervisor in empProfile', 'dform', 'searchEmployee');
                // enter search term into form
                $('#searchEmployee input[name="entry0"]').val('inactive');
                sel = ct.getMenuEntry(assert, $('#minimenu').html(), 'Search');
                $('input[name="sel"]').val(sel);
                $('input[name="sel"]').focus();
                start.mmKeyListener($.Event("keydown", {keyCode: 13}));
                assert.ok(true, "*** REACHED initiated search for Dochazka employee inactive");
                done();
            }, 4500);
            setTimeout(function () {
                var htmlbuf,
                    sel;
                ct.stack(
                    assert,
                    5,
                    'Reached simpleEmployeeBrowser dbrowser',
                    'dbrowser',
                    'setSupervisorBrowser'
                );
                htmlbuf = $("#mainarea").html(),
                ct.contains(
                    assert,
                    htmlbuf,
                    "#mainarea html",
                    "Supervisor candidates",
                );
                ct.mainareaForm(assert, "setSupervisorBrowser");
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
                    $('#minimenu').html(),
                    "#minimenu html",
                    ".&nbsp;Set&nbsp;supervisor",
                );
                assert.ok(true, "*** REACHED miniMenu contains substring '.&nbsp;Set&nbsp;supervisor'");
                sel = ct.getMenuEntry(assert, $('#minimenu').html(), 'Set&nbsp;supervisor');
                assert.ok(true, "Selection is " + sel);
                $('input[name="sel"]').val(sel);
                $('input[name="sel"]').focus();
                // press ENTER -> submit the form
                $('input[name="sel"]').trigger($.Event("keydown", {keyCode: 13}));
                ct.stack(
                    assert,
                    6,
                    'selected Set supervisor in setSupervisorBrowser',
                    'dform',
                    'empProfileSetSuperConfirm'
                );
                htmlbuf = $("#mainarea").html(),
                ct.contains(
                    assert,
                    htmlbuf,
                    "#mainarea html",
                    "Set employee supervisor - confirmation",
                );
                ct.mainareaForm(assert, "empProfileSetSuperConfirm");
                sel = ct.getMenuEntry(assert, $('#minimenu').html(), 'Yes,&nbsp;I&nbsp;really&nbsp;do');
                assert.ok(true, "Selection is " + sel);
                $('input[name="sel"]').val(sel);
                $('input[name="sel"]').focus();
                // press ENTER -> submit the form
                $('input[name="sel"]').trigger($.Event("keydown", {keyCode: 13}));
                done();
            }, 5000);
            setTimeout(function () {
                var sel;
                ct.stack(
                    assert,
                    3,
                    'back in empProfile after confirming selection of supervisor',
                    'dform',
                    'empProfile'
                );
                ct.log(assert, $('#mainarea').html());
                ct.contains(
                    assert,
                    $('#ePsuperNick').text(),
                    "#ePsuperNick text",
                    "inactive",
                );
                ct.log(assert, "*** REACHED supervisor set to inactive");
                $('input[name="sel"]').val('x');
                $('input[name="sel"]').focus();
                // press ENTER -> submit the form
                $('input[name="sel"]').trigger($.Event("keydown", {keyCode: 13}));
                ct.stack(
                    assert,
                    1,
                    'back to mainMenu after setting supervisor',
                    'dmenu',
                    'mainMenu'
                );
                // turn off masquerade
                sel = ct.getMenuEntry(assert, $('#mainarea').html(), 'Masquerade');
                $('input[name="sel"]').val(sel);
                $('input[name="sel"]').focus();
                // press ENTER -> submit the form
                $('input[name="sel"]').trigger($.Event("keydown", {keyCode: 13}));
                assert.strictEqual($('#userbox').text(), 'Employee: root ADMIN');
                loggout();
                done();
            }, 5500);
            setTimeout(function () {
                ct.loggout(assert);
                done();
            }, 6000);
        });

    };
});

