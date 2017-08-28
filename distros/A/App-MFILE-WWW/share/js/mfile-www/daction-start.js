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
// app/daction-start.js
//
// daction 'start' method definitions
//
// shorter daction functions can be included directly (see, e.g.,
// 'demoActionFromMenu' below); longer ones should be placed in their own
// module and brought in as a dependency (see, e.g. 'logout' below)
//
"use strict";

define ([
    "jquery",
    "lib",
    "logout",
    "stack",
    "start",
    "target"
], function (
    $,
    lib,
    logout,
    stack,
    start,
    target
) {

    var act = {
            "demoActionFromMenu": function () {
                // not pushable
                console.log("Entering demoActionFromMenu");
                $('#mainarea').html(
                    '<br><br>SAMPLE ACTION - SOMETHING IS HAPPENING<br><br><br>'
                );
                setTimeout(stack.getTarget().start, 1500);
            },
            "demoNoticeAction": function () {
                stack.push(
                    target.pull('demoNotice'),
                    'Random number of the day ' + Math.random() + ' WOW!'
                );
            },
            "demoBrowserAction": function () {
                stack.push(
                    target.pull('demoBrowser'),
                    {
                        "pos": 0,
                        "set": [
                            { prop1: 'Some information here', prop2: 1234 },
                            { prop1: null, prop2: 'Some other info' },
                            { prop1: 'Mangled crab crackers', prop2: 'Umpteen whizzles' },
                            { prop1: 'Fandango', prop2: 'Professor!' },
                            { prop1: 'Emfeebled whipple weepers', prop2: 'A godg' },
                            { prop1: 'Wuppo wannabe', prop2: 'Jumbo jamb' }
                        ]
                    }
                );
            },
            "demoRowselectAction": function () {
                stack.push(
                    target.pull('demoRowselect'),
                    {
                        "pos": 0,
                        "set": [
                            { prop1: 'Some information here', prop2: 1234 },
                            { prop1: null, prop2: 'Some other info' },
                            { prop1: 'Mangled crab crackers', prop2: 'Umpteen whizzles' },
                            { prop1: 'Fandango', prop2: 'Professor!' },
                            { prop1: 'Emfeebled whipple weepers', prop2: 'A godg' },
                            { prop1: 'Wuppo wannabe', prop2: 'Jumbo jamb' }
                        ]
                    }
                );
            },
            "demoTableAction": function () {
                stack.push(
                    target.pull('demoTable'),
                    [
                        { prop1: 'Some information here', prop2: 1234 },
                        { prop1: null, prop2: 'Some other info' },
                        { prop1: 'Mangled crab crackers', prop2: 'Umpteen whizzles' },
                        { prop1: 'Fandango', prop2: 'Professor!' },
                        { prop1: 'Emfeebled whipple weepers', prop2: 'A godg' },
                        { prop1: 'Wuppo wannabe', prop2: 'Jumbo jamb' }
                    ]
                );
            },
            "demoActionFromSubmenu": function () {
                $('#mainarea').html(
                    '<br><br>SAMPLE ACTION - foo bar actioning bazness<br><br><br>'
                );
                setTimeout(stack.getTarget().start, 1500);
            },
            "saveToBrowser": function () { 
                console.log("Now in saveToBrowser daction");
                lib.dbrowserStateOverride = true;
                lib.dbrowserState.set[lib.dbrowserState.pos] = {
                    "prop1": $("#RWProp1").val(),
                    "prop2": $("#RWProp2").val()
                };
                stack.pop();
                stack.pop();
            },
            "saveToRowselect": function () {
                console.log("Now in saveToRowselect daction");
                lib.drowselectStateOverride = true;
                lib.drowselectState.set[lib.drowselectState.pos] = {
                    "prop1": $("#RWProp1").val(),
                    "prop2": $("#RWProp2").val()
                };
                stack.pop();
                stack.pop();
            },
            "logout": logout
        };
   
    return function (a) {
        console.log("Initializing daction " + a);
        if (act.hasOwnProperty(a)) {
            return act[a];
        }
        console.log("ERROR: daction-start fall-through; should not happen ever!");
    };

});
