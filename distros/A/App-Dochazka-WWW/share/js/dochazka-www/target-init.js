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
// app/target-init.js
//
// Initialization of targets (round one)
//
"use strict";

define ([
    'target',
    'app/act-lib',
    'app/daction-init',
    'app/dform-init',
    'app/dmenu-init',
    'app/dbrowser-init',
    'app/dnotice-init',
    'app/dtable-init',
    'app/drowselect-init',
    'init2',
    'stack'
], function (
    target,
    actLib,
    dactionInitRoundOne,
    dformInitRoundOne,
    dmenuInitRoundOne,
    dbrowserInitRoundOne,
    dnoticeInitRoundOne,
    dtableInitRoundOne,
    drowselectInitRoundOne,
    initRoundTwo,
    stack
) {

    return function () {

        // round one - set up the targets
        console.log("dochazka-www/target-init.js: round one");
        dactionInitRoundOne();
        dformInitRoundOne();
        dmenuInitRoundOne();
        dbrowserInitRoundOne();
        dnoticeInitRoundOne();
        dtableInitRoundOne();
        drowselectInitRoundOne();

        // round two - add 'source' and 'start' properties
        // (widget targets only)
        console.log("dochazka-www/target-init.js: round two");
        initRoundTwo('dform');
        initRoundTwo('dmenu');
        initRoundTwo('dbrowser');
        initRoundTwo('dnotice');
        initRoundTwo('dtable');
        initRoundTwo('drowselect');

        // populate activities cache
        actLib.populateActivitiesCache();

        // fire up the main menu
        stack.push('mainMenu');

    };

});

