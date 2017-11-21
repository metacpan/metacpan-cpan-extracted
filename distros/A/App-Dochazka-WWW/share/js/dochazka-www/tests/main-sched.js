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
// app/tests/main-sched.js
//
// Tests exercising the "mainSched" dmenu and targets under it
//
"use strict";

define ([
  'QUnit',
  'jquery',
  'app/canned-tests',
  'lib',
  'login',
  'loggout',
  'stack',
  'start',
], function (
  QUnit,
  $,
  ct,
  coreLib,
  login,
  loggout,
  stack,
  start,
) {

    var prefix = "dochazka-www: ",
        test_desc;

    return function () {

        test_desc = 'schedule menu appears';
        QUnit.test(test_desc, function (assert) {
            console.log('***TEST*** ' + prefix + test_desc);
            var done = assert.async(3);
            login({"nam": "root", "pwd": "immutable"});
            setTimeout(function () {
                ct.login(assert, "root", "admin");
                done();
            }, 1000);
            setTimeout(function () {
                ct.mainMenu(assert);
                ct.mainMenuToMainSched(assert);
                loggout();
                done();
            }, 1500);
            setTimeout(function () {
                ct.loggout(assert);
                done();
            }, 2200);
        });

        test_desc = 'schedule lookup - bogus ID';
        QUnit.test(test_desc, function (assert) {
            console.log('***TEST*** ' + prefix + test_desc);
            var done = assert.async(4);
            login({"nam": "root", "pwd": "immutable"});
            setTimeout(function () {
                ct.login(assert, "root", "admin");
                done();
            }, 1000);
            setTimeout(function () {
                var entry1;
                ct.mainMenu(assert);
                ct.mainMenuToMainSched(assert);
                ct.mainSchedToSchedLookup(assert);
                entry1 = $('form#schedLookup input[name="entry1"]');
                entry1.val('BOGOSITYWHELP');
                assert.strictEqual(entry1.val(), 'BOGOSITYWHELP', "Form filled out with bogus data");
                $('input[name="sel"]').val('1');
                $('input[name="sel"]').focus();
                start.mmKeyListener($.Event("keydown", {keyCode: 13}));
                assert.ok(true, "*** REACHED schedLookup form submitted");
                ct.ajaxCallInitiated(assert);
                done();
            }, 1500);
            setTimeout(function () {
                var htmlbuf = $("#result").html();
                ct.stack(assert, 3, 'submitting bogus schedLookup form', 'dform', 'schedLookup');
                assert.ok(htmlbuf, "#result html: " + htmlbuf);
                ct.contains(assert, htmlbuf, "#result", 'URI does not match a known resource');
                $('input[name="sel"]').val('x');
                $('input[name="sel"]').focus();
                start.mmKeyListener($.Event("keydown", {keyCode: 13}));
                ct.stack(assert, 2, 'selecting "x" in schedLookup form', 'dmenu', 'mainSched');
                loggout();
                done();
            }, 2500);
            setTimeout(function () {
                ct.loggout(assert);
                done();
            }, 3000);
        });

    };
});

