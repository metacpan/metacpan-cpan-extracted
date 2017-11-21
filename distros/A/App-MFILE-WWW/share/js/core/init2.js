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
// init2.js
//
// second round of target initialization: add 'source' property and 'start'
// method to all targets that need them
//
// (first round initialization module is in app/)
//
"use strict";

define([
    'html',
    'lib',
    'prototypes',
    'start',
    'target'
], function (
    html,
    coreLib,
    prototypes,
    start,
    target
) {

    var transformMenu = function (menu, type) {
            // transform array of strings into a menu object

            var entry,
                i,
                newMenu;

            if (! coreLib.isArray(menu)) {
                throw("CRITICAL ERROR: non-array sent to transformMenu");
            }

            newMenu = Object.create(prototypes.menu);
            newMenu.entries = [ null, ]; // 0th menu entry is not used
            for (i = 0; i < menu.length; i += 1) {
                entry = target.pull(menu[i]);
                if (coreLib.privCheck(entry.aclProfile) && entry.onlyWhen()) {
                    newMenu.entries.push(entry);
                }
            }

            newMenu.isEmpty = (menu.length === 0);
            newMenu.isDmenu = (type === 'dmenu');
            newMenu.isMiniMenu = (type === 'miniMenu');

            // return transformed array of target objects
            // console.log("Transformed menu into", newMenu);
            return newMenu;
        };

    return function (wtype) {

        var entry,
            i,
            tgt,
            widgets = target.getAll(wtype);
    
        for (i in widgets ) {
            if (widgets.hasOwnProperty(i)) {
                tgt = widgets[i];
                tgt.start = start[wtype](i);
                // adjust dmenu and miniMenu - the idea here is to remove items
                // for which the current user does not have sufficient privileges
                if (wtype === 'dmenu') {
                    if (! tgt.menuObj) {
                        if ('entries' in tgt && coreLib.isArray(tgt.entries)) {
                            // console.log("Transforming dmenu " + tgt.name);
                            tgt.menuObj = transformMenu(tgt.entries, "dmenu");
                        } else {
                            tgt.menuObj = Object.create(prototypes.menu);
                            tgt.menuObj.isDmenu = true;
                        }
                    }
                    tgt.source = html[wtype](i);
                    continue; // dmenus do not have miniMenus
                }
                // console.log("Considering miniMenu of target", tgt);
                if (   tgt.miniMenu &&
                       'entries' in tgt.miniMenu &&
                       coreLib.isArray(tgt.miniMenu.entries) &&
                       ! tgt.miniMenu.menuObj
                   ) {
                    // console.log("Transforming miniMenu of " + tgt.name);
                    tgt.miniMenu.menuObj = transformMenu(tgt.miniMenu.entries, "miniMenu");
                }
                tgt.source = html[wtype](i);
            }
        }

    };

});
