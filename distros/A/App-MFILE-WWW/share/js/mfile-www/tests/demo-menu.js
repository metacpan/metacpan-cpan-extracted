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
// app/tests/demo-menu.js
//
// tests exercising the "demoMenu" component of the standalone demo app
//
"use strict";

define ([
  'QUnit',
  'jquery',
  'current-user',
  'login',
  'root',
  'stack',
], function (
  QUnit,
  $,
  currentUser,
  login,
  root,
  stack,
) {
    return function () {

        var prefix = "mfile-www: ",
            test_desc,
            mainareaFormFunc = function (assert, formId) {
                // asserts that #mainarea contains a form and that its form ID is
                // formID
                var mainarea = $('#mainarea'),
                    htmlbuf = mainarea.html();
                assert.ok(htmlbuf, "#mainarea html: " + htmlbuf);
                assert.strictEqual($('form', mainarea).length, 1, "#mainarea contains 1 form");
                assert.strictEqual($('form', mainarea)[0].id, formId, "that form is called " + formId);
            },
            stackFunc = function (assert, stackLen, afterWhat, tgtType, tgtName) {
                // asserts that stack has a certain length (stackLen) after doing
                // some action (afterWhat) and that the target on the top of the
                // stack is of type tgtType and has name tgtName
                var topTarget = stack.getTarget();
                assert.strictEqual(
                    stack.getLength(),
                    stackLen,
                    stackLen + " item(s) on stack after " + afterWhat
                );
                assert.strictEqual(
                    topTarget.type,
                    tgtType,
                    "Target on top of stack is of type \"" + tgtType + "\"",
                );
                assert.strictEqual(
                    topTarget.name,
                    tgtName,
                    "Target on top of stack has name \"" + tgtName + "\"",
                );
            },
            test_desc = 'demo main menu appears';

        QUnit.test(test_desc, function (assert) {
            console.log('***TEST*** ' + prefix + test_desc);
            var done = assert.async(1),
                mainarea,
                nick = "root",
                priv = "admin",
                /*
                currentUserObj = currentUser('obj'),
                currentUserPriv = currentUser('priv'),
                */
                cu;
            login({"nam": "root", "pwd": "root"});
            setTimeout(function () {
                console.log("TEST: post-login tests");
                cu = currentUser();
                assert.ok(cu, "current user object after login: " + QUnit.dump.parse(cu));
                assert.strictEqual(cu.obj.nick, nick, 'we are now ' + nick);
                assert.strictEqual(cu.priv, priv, nick + ' has ' + priv + ' privileges');
                assert.ok(true, "Starting app in fixture");
                root(); // start app in QUnit fixture
                stackFunc(assert, 1, 'starting app', 'dmenu', 'demoMenu');
                mainareaFormFunc(assert, 'demoMenu');
                assert.ok(true, '*** REACHED logged in as ' + nick);
                done();
            }, 500);
        });

        test_desc = 'press 0 in main menu';
        QUnit.test(test_desc, function (assert) {
            console.log('***TEST*** ' + prefix + test_desc);
            var done = assert.async(),
                sel;
            assert.timeout(200);
            root(); // start mfile-www demo app in QUnit fixture
            sel = $('input[name="sel"]').val();
            assert.strictEqual(sel, '', "Selection form field is empty");
            // press '0' key in sel, but value does not change?
            $('input[name="sel"]').trigger($.Event("keydown", {keyCode: 48})); // press '0' key
            sel = $('input[name="sel"]').val();
            assert.strictEqual(sel, '', "Selection form field is empty even after simulating 0 keypress");
            // simulating keypress doesn't work, so just set the value to "0"
            $('input[name="sel"]').val('0');
            // press ENTER -> submit the form
            $('input[name="sel"]').trigger($.Event("keydown", {keyCode: 13}));
            setTimeout(function() {
                var mainarea = $('#mainarea').html();
                assert.ok(mainarea, "#mainarea has non-empty html: " + mainarea);
                assert.notStrictEqual(
                    mainarea.indexOf('SOMETHING IS HAPPENING'),
                    -1,
                    "#mainarea html contains substring \"SOMETHING IS HAPPENING\""
                );
                done();
            });
        });

    };
});

