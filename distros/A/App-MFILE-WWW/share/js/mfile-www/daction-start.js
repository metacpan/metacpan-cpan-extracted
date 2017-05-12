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
    "logout",
    "start",
    "target",
    "lib"
], function (
    $,
    logout,
    start,
    target,
    lib
) {

    var act = {
            "demoActionFromMenu": function () {
                $('#mainarea').html(
                    '<br><br>SAMPLE ACTION - SOMETHING IS HAPPENING<br><br><br>'
                );
                setTimeout(function () { target.pull('demoMenu').start(); }, 1500);
            },
            "demoActionFromSubmenu": function () {
                $('#mainarea').html(
                    '<br><br>SAMPLE ACTION - foo bar actioning bazness<br><br><br>'
                );
                setTimeout(function () { target.pull('demoSubmenu').start(); }, 1500);
            },
            "saveToBrowser": function () { 
                console.log("Now in saveToBrowser daction");
                lib.dbrowserState.set[lib.dbrowserState.pos] = {
                    "prop1": $("#RWProp1").val(),
                    "prop2": $("#RWProp2").val()
                };
                start.dbrowserListen();
            },
            "returnToBrowser": function () { 
                console.log("Now in returnToBrowser daction");
                start.dbrowserListen(); 
            },
            "saveToRowselect": function () {
                console.log("Now in saveToRowselect daction");
                lib.drowselectState.set[lib.drowselectState.pos] = {
                    "prop1": $("#RWProp1").val(),
                    "prop2": $("#RWProp2").val()
                };
                start.drowselectListen();
            },
            "returnToRowselect": function () {
                console.log("Now in returnToRowselect daction");
                start.drowselectListen();
            },
            "logout": logout
        };
   
    return function (a) {
        if (act.hasOwnProperty(a)) {
            return act[a];
        }
        return undefined;
    };

});
