// ************************************************************************* 
// Copyright (c) 2014-2016, SUSE LLC
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
// html.js - functions that generate HTML source code
//
"use strict";

define ([
    'cf',
    'current-user',
    'lib',
    'app/lib',
    'target'
], function (
    cf,
    currentUser,
    lib,
    appLib,
    target
) {
    var 
        //
        // "Your choice" section at the bottom - shared by all target types
        //
        yourChoice = function () {
            return '<br><b>Your choice:</b> <input name="sel" size=3 maxlength=2> ' +
                   '<input id="submitButton" type="submit" value="Submit"><br><br>'
        },
        //
        // miniMenu is shared by dform and dbrowser
        //
        miniMenu = function (mm) {
            // mm is the dbrowser miniMenu object
            var entries = (mm.entries === null) ? [] : mm.entries,
                len = entries.length,
                entry,
                i,
                r;
            console.log("miniMenu is ", mm);
            console.log("miniMenu length is " + len);
            if (len > 0) {
                r = 'Menu:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
                for (i = 0; i < len; i += 1) {
                    //console.log("i === " + i);
                    console.log("Attempting to pull target " + entries[i] + " from miniMenu");
                    entry = target.pull(entries[i]);
                    if (lib.privCheck(entry.aclProfile)) {
                        r += i + '. ' + entry.menuText + '&nbsp;&nbsp;';
                    }
                }
                r += 'X. ' + mm.back[0];
            } else {
                r = mm.back[0];
            }
            return r;
        },        
        valueToDisplay = function (obj, prop) {
            // given an object and a property, return the value to display
            if (! obj.hasOwnProperty(prop)) {
                return '(NO_SUCH_PROP)';
            } else if (obj[prop] === undefined) {
                return '(undefined)';
            } else if (obj[prop] === false) {
                return 'NO';
            } else if (obj[prop] === true) {
                return 'YES';
            } else if (obj[prop] === null) {
                return '(none)';
            } else if (obj[prop] === NaN) {
                return '(NOT_A_NUMBER)';
            }
            return obj[prop];
        },
        maxLength = function (arr) {
            var len, max;
            len = arr ? arr.length : 0;
            console.log("arr has " + len + " members");
            max = arr.reduce(function(prevVal, elem) {
                if (elem.text === null) {
                    elem.text = '';
                }
                if (elem.text.length > prevVal) {
                    prevVal = elem.text.length;
                }
                return prevVal;
            }, arr[0].text.length);
            console.log("The longest entry is " + max + " characters long");
            return max;
        },
        browserNavMenu = function (len, pos) {
            var r = '',
                context = {
                    forward: 0,
                    back: 0,
                    jumpToEnd: 0,
                    jumpToBegin: 0
                };
	    // context-sensitive navigation menu: selections are based on
	    // set length and cursor position:
            //   if set.length <= 1: no navigation menu at all
            //   if 1 < set.length <= 5: forward, back
            //   if set.length > 5: forward, back, jump to end/beginning
            //   if pos == 1 then back and jump to beginning are deactivated
            //   if pos == set.length then forward and jump to end are deactivated
            // here in html.js, we add <span> elements for each context-sensitive
            // selection. Each such element has a unique identifier, so that in 
            // start.js we can check for the presence of each and handle accordingly
            if (len > 1) {
                //
                // there is at least one record to display:
                // (a) determine context
                //
                if (len > 1) {
                    context.forward = 1;
                    context.back = 1;
                }
                if (len > 5) {
                    context.jumpToEnd = 1;
                    context.jumpToBegin = 1;
                }
                if (pos === 0) {
                    context.back = 0;
                    context.jumpToBegin = 0;
                }
                if (pos === len - 1) {
                    context.forward = 0;
                    context.jumpToEnd = 0;
                }
                //
                // (b) construct navigation menu
                //
                r += 'Navigation:&nbsp;&nbsp;';
                if (context.back) {
                    r += '<span id="navBack">[\u2190] Previous </span>';
                }
                if (context.forward) {
                    r += '<span id="navForward">[\u2192] Next </span>';
                }
                if (context.jumpToBegin) {
                    r += '<span id="navJumpToBegin">[\u2303\u2190] Jump to first </span>';
                }
                if (context.jumpToEnd) {
                    r += '<span id="navJumpToEnd">[\u2303\u2192] Jump to last </span>';
                }
                r += '<br>';
            } else {
                r = '';
            }
            return r;
        },
        genericTable = function (tname, tobj, targetType) {
            return function (set) {

                console.log("Generating source code of " + tname);
                // console.log("tobj", tobj);
                // console.log("set", set);
                var r = '<form id="' + tobj.name + '">',
                    entry,
                    column,
                    row,
                    col,
                    headingsentry = {},
                    superset,
                    maxl = [];

                r += '<br><b>' + tobj.title + '</b><br><br>';

                if (tobj.preamble) {
                    r += tobj.preamble + '<br><br>';
                }

                // populate maxl array
                tobj.entries.map(function (e) {
                    headingsentry[e.prop] = e.text;
                })
                superset = set.concat([headingsentry]);
                console.log("superset", superset);
                for (column = 0; column < tobj.entries.length; column += 1) {
                    console.log("Column " + column);
                    entry = tobj.entries[column];
                    var elems = superset.map(function (obj) {
                        return obj[entry.prop];
                    });
                    var elemlengths = elems.map(function (elem) {
                        var ep = ((elem === null) ? '' : elem).toString();
                        return ep.length;
                    });
                    maxl[column] = elemlengths.reduce(function (a, b) {
                        return (a > b) ? a : b;
                    });
                }

                // display table header
                for (column = 0; column < tobj.entries.length; column += 1) {
                    entry = tobj.entries[column];
                    if (lib.privCheck(entry.aclProfileRead)) {
                        r += '<span style="text-decoration: underline">';
                        r += lib.rightPadSpaces(entry.text, maxl[column]);
                        r += '</span>';
                    }
                    if (column !== tobj.entries.length - 1) {
                        r += ' ';
                    }
                }
                r += '<br>';

                // display table rows
                if (set.length === 0) {
                    r += '<br>(empty table, nothing to display)<br><br><br>';
                }
                if (set.length > 0) {
                    for (row = 0; row < set.length; row += 1) {
                        r += '<span id="row' + row + '">';
                        var obj = set[row];
                        for (column = 0; column < tobj.entries.length; column += 1) {
                            entry = tobj.entries[column];
                            console.log("entry", entry);
                            if (lib.privCheck(entry.aclProfileRead)) {
                                var val = obj[entry.prop];
                                console.log("value", val);
                                r += lib.rightPadSpaces(val, maxl[column]);
                            }
                            if (column !== tobj.entries.length - 1) {
                                r += ' ';
                            }
                        }
                        r += '</span>';
                        r += '<br>';
                    }
                    r += '<br>';
                }

                // Navigation menu (drowselect only)
                if (targetType === 'drowselect' && set.length > 1) {
                    r += 'Navigation:&nbsp;&nbsp;';
                    r += '<span id="navBack">[\u2190] Previous </span>';
                    r += '<span id="navForward">[\u2192] Next </span>';
                    r += '<span id="navJumpToBegin">[\u2303\u2190] Jump to first </span>';
                    r += '<span id="navJumpToEnd">[\u2303\u2192] Jump to last </span>';
                    r += '<br>';
                }

		// miniMenu at the bottom: selections are target names defined
		// in the 'miniMenu' property of the dform object
                r += miniMenu(tobj.miniMenu);

                // your choice section
                r += yourChoice();

                r += '</form>';
                console.log("Assembled source code for " + tname + " - it has " + r.length + " characters");
                return r;
            }
        }; // genericTable


    return {

        loginDialog: function () {
            var r = '';
            r += '<form id="loginform">';
            r += '<br><br><br>';
            r += cf('loginDialogChallengeText');
            r += '<br><br>';
            r += 'Username: <input name="nam" size="' + cf('loginDialogMaxLengthUsername') + '"';
            r += 'maxlength="' + cf('loginDialogMaxLengthUsername') + '" /><br>';
            r += 'Password: <input name="pwd" type="password" size="' + cf('loginDialogMaxLengthPassword') + '"';
            r += 'maxlength="' + cf('loginDialogMaxLengthPassword') + '" /><br><br>';
            r += '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
            r += '<input type="submit" value="Submit"><br><br>';
            r += '</form>';
            return r;
        }, // loginDialog

        logout: function () {
            var r = '';
            r += '<br><br><br>';
            r += 'You have been logged out of our humble application<br><br>';
            r += 'Have a lot of fun!<br><br><br>';
            return r;
        }, // logout

        body: function () {
            var r = '';
            r += '<div class="leftright">';

            r += '<p class="alignleft" style="font-size: x-large; font-weight: bold">';
            r += cf('appName');
            r += ' <span style="font-size: normal; font-weight: normal;">';
            r += cf('appVersion');
            r += '</span>';
            r += '</p>';

            r += '<p class="alignright"><span id="userbox">';
            r += appLib.fillUserBox();
            r += '</span></p>';

            r += '</div>';

            r += '<div class="boxtopbot" id="header" style="clear: both;">';
            r += '   <span class="subbox" id="topmesg">If application appears';
            r += '   unresponsive, make sure browser window is active and press \'TAB\'</span>';
            r += '</div>';

            r += '<div class="mainarea" id="mainarea"></div>';

            r += '<div class="boxtopbot" id="result">&nbsp;</div>';

            r += '<div id="noticesline" style="font-size: small">';
            // r += appLib.fillNoticesLine();
            r += '</div>';
            if (cf('displaySessionData') === true) {
                r += 'Plack session ID: ' + cf('sessionID');
                r += ' (last_seen ' + cf('sessionLastSeen') + ')</br>';
            }
            return r;
        }, // body

        dmenu: function (dmn) {
            console.log("Entering html.dmenu with argument " + dmn);
            // dmn is dmenu name
            // dmo is dmenu object
            var dmo = target.pull(dmn),
                r = '',
                len = dmo.entries.length,
                i,
                back = target.pull(dmo.back),
                entry;
        
            r += '<form id="' + dmn + '"><br><b>' + dmo.title + '</b><br><br>';

            for (i = 0; i < len; i += 1) {
                // the entries are names of targets
                entry = target.pull(dmo.entries[i]);
                console.log("Pulled target " + dmo.entries[i] + " with result ", entry);
                if (lib.privCheck(entry.aclProfile)) {
                    r += i + '. ' + entry.menuText + '<br>';
                }
            }
            r += 'X. ' + back.menuText + '<br>';

            r += yourChoice();

            r += '</form>';
            return r;
        }, // dmenu

        dform: function (dfn) {
            // dfn is dform name
            // dfo is dform object
            var dfo = target.pull(dfn);
            return function (obj) {
        
                console.log("Generating source code of dform " + dfn);
                var r = '<form id="' + dfo.name + '">',
                    len,
                    i,
                    allEntries,
                    needed,
                    entry;
        
                r += '<br><b>' + dfo.title + '</b><br><br>';
        
                if (dfo.preamble) {
                    r += dfo.preamble + '<br><br>';
                }
        
                // determine characters needed for padding (based on longest
                // entry)
                if (dfo.entriesRead !== undefined) {
                    console.log("entriesRead", dfo.entriesRead);
                    allEntries = lib.forceArray(dfo.entriesRead);
                }
                if (dfo.entriesWrite !== undefined) {
                    console.log("entriesWrite", dfo.entriesWrite);
                    allEntries = allEntries.concat(
                        dfo.entriesWrite === null ? [] : dfo.entriesWrite
                    );
                }
                console.log("About to call maxLength() on allEntries", allEntries);
                needed = maxLength(allEntries) + 2;

                // READ-ONLY entries first
                len = dfo.entriesRead ? dfo.entriesRead.length : 0;
                console.log("Processing " + len + "read-only dform entries");
                for (i = 0; i < len; i += 1) {
                    entry = dfo.entriesRead[i];
                    if (entry.name === 'divider') {
                        r += Array(entry.maxlen).join(entry.text) + '<br>';
                    } else if (entry.name === 'emptyLine') {
                        r += '<br>';
                    } else if (lib.privCheck(entry.aclProfileRead)) {
                        r += lib.rightPadSpaces(entry.text.concat(':'), needed);
                        r += '<span id="' + entry.name + '">';
                        r += valueToDisplay(obj, entry.prop);
                        r += '</span><br>';
                    }
                }
                r += '<br>';
        
                // READ-WRITE entries second
                len = dfo.entriesWrite ? dfo.entriesWrite.length : 0;
                console.log("Processing " + len + "read-write dform entries");
                for (i = 0; i < len; i += 1) {
                    entry = dfo.entriesWrite[i];
                    if (lib.privCheck(entry.aclProfileWrite)) {
                        r += lib.rightPadSpaces(entry.text.concat(':'), needed);
                        r += '<input id="' + entry.name + '" ';
                        r += 'name="entry' + i + '" ';
                        r += 'value="' + (obj[entry.prop] || '') + '" ';
                        r += 'size="' + entry.maxlen + '" ';
                        r += 'maxlength="' + entry.maxlen + '"><br>';
                    }
                }
                r += '<br>';
        
                // miniMenu at the bottom
                r += miniMenu(dfo.miniMenu);

                // your choice section
                r += yourChoice();

                r += '</form>';
                //console.log("Assembled source code for " + dfn + " - it has " + r.length + " characters");
                return r;
            };
        }, // dform

        dbrowser: function (dbn) {
            // dfn is dform name
            // dfo is dform object
            var dbo = target.pull(dbn);
            return function (set, pos) {
        
                // console.log("Generating source code of dbrowser " + dbn);
                var r = '<form id="' + dbo.name + '">',
                    len,
                    i,
                    obj,
                    entry,
                    allEntries,
                    needed;
        
                r += '<br><b>' + dbo.title + '</b><br><br>';
        
                if (dbo.preamble) {
                    r += dbo.preamble + '<br><br>';
                }
        
                // determine characters needed for padding (based on longest
                // entry)
                allEntries = lib.forceArray(dbo.entries);
                needed = maxLength(allEntries) + 2;

                // display entries
                len = dbo.entries ? dbo.entries.length : 0;
                obj = set[pos];
                console.log('Browsing object', obj);
                if (len > 0) {
                    for (i = 0; i < len; i += 1) {
                        entry = dbo.entries[i];
                        if (entry.name === 'divider') {
                            r += Array(entry.maxlen).join(entry.text) + '<br>';
                        } else if (entry.name === 'emptyLine') {
                            r += '<br>';
                        } else if (lib.privCheck(entry.aclProfileRead)) {
                            r += lib.rightPadSpaces(entry.text.concat(':'), needed);
                            r += '<span id="' + entry.name + '">';
                            r += valueToDisplay(obj, entry.prop);
                            r += '</span><br>';
                        }
                    }
                    r += '<br>';
                }

		// context-sensitive navigation menu: selections are based on
		// set length and cursor position
                r += browserNavMenu(set.length, pos);
                
		// miniMenu at the bottom: selections are target names defined
		// in the 'miniMenu' property of the dform object
                r += miniMenu(dbo.miniMenu);

                // your choice section
                r += yourChoice();

                r += '</form>';
                console.log("Assembled source code for " + dbn + " - it has " + r.length + " characters");
                return r;
            };
        }, // dbrowser

        dnotice: function (dnn) {
            console.log("Entering html.dnotice with argument " + dnn);
            // dnn is dnotice name
            // dno is dnotice object
            var dno = target.pull(dnn);
            return function () {
                var r = '';
                r += '<div id="' + dnn + '"><br><b>' + dno.title + '</b><br><br>';
                r += dno.preamble + '<br>';
                r += '<div id="noticeText"></div><br>';
                r += "To leave this page, press ENTER or click the Submit button";
                r += yourChoice();
                r += '</div>';
                return r;
            };
        }, // dnotice

        dtable: function (dtn) {
            var dto = target.pull(dtn);
            return genericTable(dtn, dto, 'dtable');
        }, // dtable

        drowselect: function (drsn) {
            var drso = target.pull(drsn);
            return genericTable(drsn, drso, 'drowselect');
        } // dtable

    };
});
