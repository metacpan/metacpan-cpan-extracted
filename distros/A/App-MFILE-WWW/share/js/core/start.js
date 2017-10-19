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
// start.js
//
// 'start' (i.e. HTML display and event handling) methods for menus, forms,
// browsers
//
define ([
    'jquery',
    'app/entries',
    'lib',
    'stack',
    'target'
], function (
    $,
    entryDefs,
    coreLib,
    stack,
    target
) {
    var 
        currentTarget,

        //
        // generalized handlers
        //

        // used to suppress submit events when we don't need them
        suppressSubmitEvent = function (event) {
            event.preventDefault();
            console.log("Suppressed submit event");
        },

        //
        // dmenu handlers
        //
        dmenuSubmit = function (dmn) {
            // dmn is dmenu name
            // dmo is dmenu object
            var dmo = target.pull(dmn),
                sel = $('input[name="sel"]').val(),
                len = dmo.entries.length,
                entry,
                selection;
        
            if ($.isNumeric(sel) && sel >= 0 && sel <= len) {
                // we can only select the entry if we have sufficient priv level
                selection = target.pull(dmo.entries[sel]);
                if (coreLib.privCheck(selection.aclProfile)) {
                    //console.log('Selection ' + sel + ' passed priv check');
                    entry = selection;
                }
            } else if (sel === 'X' || sel === 'x') {
                stack.pop();
                return;
            } else if (sel === '') {
                // user hit 'enter'
                return;
            }
            if (entry !== undefined) {
                console.log("Selected " + dmn + " menu entry: " + entry.name);
                stack.push(entry, {});
            }
        },
        dmenuSubmitEvent = function (dmn) {
            return function (event) {
                console.log(dmn + " form submission event");
                event.preventDefault();
                dmenuSubmit(dmn);
            };
        },
        dmenuKeyListener = function (dmn) {
            return function (event) {
                coreLib.logKeyPress(event);
                if (event.keyCode === 13) {
                    console.log("Detected ENTER keypress; submitting " + dmn + " form");
                    event.preventDefault();
                    dmenuSubmit(dmn);
                } else if (event.keyCode === 9) {
                    event.preventDefault();
                }
            };
        },

        //
        // miniMenu handlers
        //
        mmKeyListenerVetEntry = function (evt, n, eid) {
            var input = $("input[id='" + eid + "']"),
                vetted = true,
                vettedVal,
                vetter;
            console.log("In writable entry " + eid);
            vetter = currentTarget.getVetter(eid);
            console.log("vetter", vetter);
            if (typeof vetter === 'function') {
                console.log("Current entry ->" + eid +"<- has a vetter function!");
                vettedVal = vetter(input.val());
                if (vettedVal) {
                    input.val(vettedVal);
                } else {
                    vetted = false;
                }
            }
            if (vetted) {
                if (evt.keyCode !== 9) {
                    $("input:text")[n + 1].focus();
                }
            } else {
                coreLib.displayError("Bad " + entryDefs[eid].text.toLowerCase() + " value!");
                if (evt.keyCode === 9) {
                    evt.preventDefault();
                }
                $("input:text")[n].focus();
            }
        },
        mmKeyListener = function (evt) {

            var 
                elid = $(document.activeElement).attr("id"),
                elnam = $(document.activeElement).attr("name"),
                len = $("input:text").length,
                n = $("input:text").index($(document.activeElement)),
                i;

            coreLib.logKeyPress(evt);
            coreLib.clearResult();
    
            if (evt.keyCode === 13) {
                // ENTER key in form
                // console.log("This form has writable entries 0 through " + (len - 1));
                // console.log("Entry " + n + " is active.");
                evt.preventDefault();
                if ( n === len - 1 ) {
                    console.log("Triggering submit button click");
                    for (i=0; i<len; i++) {
                        console.log("Entry " + i, $("input:text")[i]);
                    }
                    // FIXME: iterate over writable entries and vet all the values
                    $('#submitButton').click();
                } else {
                    mmKeyListenerVetEntry(evt, n, elid);
                }
            } else if (evt.keyCode === 9) {
                // TAB key in form
                vetter = function () { return true; };
                if (
                        (elnam === 'entry0' && evt.shiftKey) ||
                        (elnam === 'sel' && len === 1) ||
                        (elnam === 'sel' && !evt.shiftKey)
                   ) {
                    // prevent TAB keypress from navigating out of the form
                    evt.preventDefault();
                }
                mmKeyListenerVetEntry(evt, n, elid);
            }

        },
        mmSubmit = function (obj) {
            console.log("Entering mmSubmit with object", obj);
            console.log("Target is", currentTarget);

            coreLib.clearResult();
        
            var sel = $('input[name="sel"]').val(),
                len,
                i,
                newObj,
                selection,
                entry,
                item,
                wlen,
                entries = currentTarget.miniMenu.entries;

            // if miniMenu has zero or one entries, 'Back' is the only option
            console.log("entries", entries);
            if (entries === null || entries === undefined || entries.length === 0) {
                console.log("Setting sel to 'X' by default because miniMenu has no entries");
                sel = 'X';
                len = 0;
            } else {
                len = entries.length;
            }
            if (len > 0 && sel === '') {
                console.log("User hit ENTER ambiguously; doing nothing");
                return;
            }

            if (obj !== undefined) {
                newObj = $.extend({}, obj);
        
                // replace the writable properties with the values from the form
                if (currentTarget.entriesWrite) {
                    wlen = currentTarget.entriesWrite.length;
                    for (i = 0; i < wlen; i += 1) {
                        entry = currentTarget.entriesWrite[i];
                        newObj[entry.prop] = $('#' + entry.name).val();
                    }
                    //console.log("Modified object based on form contents", newObj);
                }
            } else {
                newObj = {};
            }
        
            console.log("sel === " + sel + " and len === " + len);
            if (sel >= 0 && sel <= len) {
                //console.log("sel " + sel + " is within range");
                // we can only select the item if we have sufficient priv level
                selection = target.pull(currentTarget.miniMenu.entries[sel]);
                if (coreLib.privCheck(selection.aclProfile)) {
                    //console.log('Selection ' + sel + ' passed priv check');
                    item = selection;
                }
            } else if (sel === 'X' || sel === 'x') {
                var xtgt = stack.getXTarget();
                if (typeof xtgt === "string") {
                    stack.unwindToTarget(xtgt);
                } else {
                    stack.pop();
                }
                return;
            } else {
                console.log('Selection is ' + sel + ' (invalid) -- doing nothing');
            }
            if (item !== undefined) {
                //console.log("Selected " + dfn + " menu item: " + item.name);
                newObj.mm = true;
                if (currentTarget.type === 'dform' && currentTarget.rememberState) {
                    console.log("Changing stack state to", newObj);
                    stack.setState(newObj);
                }
                stack.push(item, newObj);
            }
        },

        //
        // dform handlers
        //
        dformListen = function (dfn, obj, focusId) {
            console.log("Listening in form " + dfn);
            currentTarget = target.pull(dfn);
            $('#' + dfn).submit( suppressSubmitEvent );
            $('input[name="sel"]').val('');
            if (focusId) {
                $('input[id="' + focusId + '"]').focus();
            } else if (stack.getPush() === true && $('input[name="entry0"]').length) {
                $('input[name="entry0"]').focus();
            } else {
                $('input[name="sel"]').focus();
            }
            $('#submitButton').on("click", function (event) {
                event.preventDefault;
                console.log("Submitting form " + dfn);
                mmSubmit(obj);
            });
            $('#' + dfn).on("keypress", mmKeyListener);
        },

        //
        // dbrowser handlers
        //
        dbrowserSubmit = function () {
            var dbo = coreLib.dbrowserState.obj,
                set = coreLib.dbrowserState.set,
                pos = coreLib.dbrowserState.pos;
            mmSubmit(set[pos]);
        },
        dbrowserKeyListener = function () {
            var set = coreLib.dbrowserState.set,
                pos = coreLib.dbrowserState.pos;
            
            return function (evt) {
        
                coreLib.logKeyPress(evt);
        
                // since the dbrowser has (may have) a navigation menu, we
                // check first for those keys before moving to miniMenu handler
                if (evt.keyCode === 37) { // <-
                    if (evt.ctrlKey) {
                        console.log('Listener detected CTRL-\u2190 keypress');
                        if ($("#navJumpToBegin").length) {
                            coreLib.dbrowserState.pos = 0;
                            dbrowserListen();
                        }
                    } else {
                        console.log('Listener detected \u2190 keypress');
                        if ($("#navBack").length) {
                            coreLib.dbrowserState.pos -= 1;
                            dbrowserListen();
                        }
                    }
                } else if (evt.keyCode === 39) { // ->
                    if (evt.ctrlKey) {
                        console.log('Listener detected CTRL-\u2192 keypress');
                        if ($("#navJumpToEnd").length) {
                            coreLib.dbrowserState.pos = set.length - 1;
                            dbrowserListen();
                        }
                    } else {
                        console.log('Listener detected \u2192 keypress');
                        if ($("#navForward").length) {
                            coreLib.dbrowserState.pos += 1;
                            dbrowserListen();
                        }
                    }
                } else {
                    mmKeyListener(evt);
                }
            };
        },
        dbrowserListen = function (resultLine) {
            var dbo = coreLib.dbrowserState.obj,
                set = coreLib.dbrowserState.set,
                pos = coreLib.dbrowserState.pos;
            
            console.log("Listening in browser " + dbo.name);
            currentTarget = dbo;
            console.log("Browser set is", set, "cursor position is " + pos);
            $('#mainarea').html(dbo.source(set, pos));
            if (resultLine) {
                coreLib.displayResult(resultLine);
            } else {
                coreLib.displayResult("Displaying no. " + (pos + 1) + " of " + 
                                  coreLib.genObjStr(set.length) + " in result set");
            }
            $('#' + dbo.name).submit(suppressSubmitEvent);
            $('input[name="sel"]').val('').focus();
            $('#submitButton').on("click", function (event) {
                event.preventDefault;
                //console.log("Submitting browser " + dbo.name);
                stack.getState().pos = pos;
                dbrowserSubmit();
            });
            $('#' + dbo.name).on("keypress", dbrowserKeyListener());
        },

        //
        // dnotice handlers
        // 
        dnoticeListen = function (dno) {
            $('#submitButton').on("click", function (event) {
                event.preventDefault;
                //console.log("Submitting form " + dno.name);
                stack.pop();
                return;
            });
            $('#' + dno.name).on("keypress", mmKeyListener);
        },

        //
        // dtable handlers
        // 
        dtableSubmit = function (dto) {
            mmSubmit();
        },
        dtableListen = function (dto) {
            console.log("Listening in table " + dto.name);
            currentTarget = dto;
            $('#' + dto.name).submit(suppressSubmitEvent);
            $('input[name="sel"]').val('').focus();
            $('#submitButton').on("click", function (event) {
                event.preventDefault;
                //console.log("Submitting table " + dto.name);
                dtableSubmit(dto);
            });
            $('#' + dto.name).on("keypress", mmKeyListener);
        },

        //
        // drowselect handlers
        //
        drowselectSubmit = function () {
            var drso = coreLib.drowselectState.obj,
                set = coreLib.drowselectState.set,
                pos = coreLib.drowselectState.pos,
                xtgt;
            if (drso.hasOwnProperty('miniMenu')) {
                if (drso.miniMenu.hasOwnProperty('entries')) {
                    if (drso.miniMenu.entries.length > 0) {
                        mmSubmit(set[pos]);
                        return;
                    }
                }
            }
            if (drso.hasOwnProperty('submitAction')) {
                stack.push(drso.submitAction, set[pos]);
            } else {
                // no miniMenu, no submitAction - just go back
                xtgt = stack.getXTarget();
                if (typeof xtgt === "string") {
                    stack.unwindToTarget(xtgt);
                } else {
                    stack.pop();
                }
            }
        },
        drowselectKeyListener = function () {
            var set = coreLib.drowselectState.set,
                pos = coreLib.drowselectState.pos;

            return function (evt) {

                console.log("Entering drowselectKeyListener");
                coreLib.logKeyPress(evt);

                if (evt.keyCode === 37) { // up arrow
                    if (evt.ctrlKey) {
                        console.log('Listener detected CTRL-up arrow keypress');
                        coreLib.reverseVideo(coreLib.drowselectState.pos, false);
                        coreLib.drowselectState.pos = 0;
                        drowselectListen();
                    } else {
                        console.log('Listener detected up arrow keypress');
                        if (coreLib.drowselectState.pos > 0) {
                            coreLib.reverseVideo(coreLib.drowselectState.pos, false);
                            coreLib.drowselectState.pos -= 1;
                            drowselectListen();
                        }
                    }
                } else if (evt.keyCode === 39) { // down arrow
                    if (evt.ctrlKey) {
                        console.log('Listener detected CTRL-down arrow keypress');
                        coreLib.reverseVideo(coreLib.drowselectState.pos, false);
                        coreLib.drowselectState.pos = set.length - 1;
                        drowselectListen();
                    } else {
                        console.log('Listener detected down arrow keypress');
                        if (coreLib.drowselectState.pos < set.length - 1) {
                            coreLib.reverseVideo(coreLib.drowselectState.pos, false);
                            coreLib.drowselectState.pos += 1;
                            drowselectListen();
                        }
                    }
                } else {
                    mmKeyListener(evt);
                }
            };
        },
        drowselectListen = function () {
            var drso = coreLib.drowselectState.obj,
                set = coreLib.drowselectState.set,
                pos = coreLib.drowselectState.pos;
            currentTarget = drso;
            $('#result').text("Displaying rowselect with " + coreLib.genObjStr(set.length));
            $('#mainarea').html(drso.source(set));
            coreLib.reverseVideo(pos, true);
            console.log("Listening in rowselect " + drso.name);
            $('#' + drso.name).submit(suppressSubmitEvent);
            $('input[name="sel"]').val('').focus();
            $('#submitButton').on("click", function (event) {
                event.preventDefault;
                //console.log("Submitting rowselect " + drso.name);
                drowselectSubmit();
            });
            $('#' + drso.name).on("keypress", drowselectKeyListener());
        };

    return {

        dmenu: function (dmn) {
            // dmn is dmenu name
            // dmo is dmenu object
            var dmo = target.pull(dmn);
            return function (state, opts) {
                console.log('Entering start.dmenu with argument: ' + dmn);
                // coreLib.clearResult();
                stack.setFlag();
                $('#mainarea').html(dmo.source);
                $('input[name="sel"]').val('').focus();
                $('#' + dmn).submit(dmenuSubmitEvent(dmn));
                $('input[name="sel"]').keydown(dmenuKeyListener(dmn));
            };
        }, // dmenu

        dform: function (dfn) {
            var dfo = target.pull(dfn);
            return function (state, opts) {
                console.log('Entering start method of target ' + dfn);
                if (typeof opts !== 'object') {
                    opts = {};
                }
                opts.resultLine = ('resultLine' in opts) ? opts.resultLine : "&nbsp";
                opts.inputId = ('inputId' in opts) ? opts.inputId : null;
                coreLib.displayResult(opts.resultLine);
                if (! state) {
                    state = stack.getState();
                }
                console.log('The object we are working with is:', state);
                $('#mainarea').html(dfo.source(state));
                dformListen(dfn, state, opts.inputId);
            };
        }, // dform

        dbrowser: function (dbn) {
            if (dbn) {
                // when called with dbn (dbrowser name) argument, we assume
                // that we are being called from the second stage of dbrowser
                // initialization (i.e., one-time event) -- generate and
                // return the start function for this dbrowser
                return function (state, opts) {
                    console.log('Starting new ' + dbn + ' dbrowser with state', state);
                    if (! state) {
                        state = stack.getState();
                    }
                    console.log('dbrowser state', state);
                    // (re)initialize dbrowser state
                    if (coreLib.dbrowserStateOverride) {
                        coreLib.dbrowserStateOverride = false;
                    } else {
                        coreLib.dbrowserState.obj = target.pull(dbn);
                        coreLib.dbrowserState.set = state.set;
                        coreLib.dbrowserState.pos = state.pos;
                    }
                    // start browsing
                    dbrowserListen(stack.getResultLine());
                };
            }
        }, // dbrowser

        dbrowserListen: dbrowserListen,

        dnotice: function (dnn) {
            var dno = target.pull(dnn);
            return function (state, opts) {
                // state is a string to be displayed on the screen
                console.log("Entering start.dnotice with argument: " + dnn);
                if (! state) {
                    state = stack.getState();
                }
                coreLib.clearResult();
                $('#mainarea').html(dno.source()); // write HTML to screen
                $("#noticeText").html(state);
                $('input[name="sel"]').focus();
                dnoticeListen(dno);
            };
        }, // dnotice

        dtable: function (dtn) {
            var dto = target.pull(dtn);
            return function (state, opts) {
                // state is a array of objects to be displayed as a table
                coreLib.clearResult();
                console.log('Starting new ' + dtn + ' dtable');
                if (! state) {
                    state = stack.getState();
                }
                console.log('The dataset is', state);
                $('#mainarea').html(dto.source(state));
                $('#result').text('Displaying table with ' + coreLib.genObjStr(state.length));
                dtableListen(dto);
            };
        }, // dtable

        drowselect: function (drsn) {
            var drso = target.pull(drsn);
            if (drsn) {
                // when called with drsn (drowselect name) argument, we assume
                // that we are being called from the second stage of drowselect
                // initialization (i.e., one-time event) -- generate and
                // return the start function for this drowselect
                return function (state, opts) {
                    coreLib.clearResult();
                    console.log('Starting new ' + drsn + ' drowselect');
                    if (! state) {
                        state = stack.getState();
                    }
                    console.log('rowselect state', state);
                    // (re)initialize drowselect state
                    if (coreLib.drowselectStateOverride) {
                        coreLib.drowselectStateOverride = false;
                    } else {
                        coreLib.drowselectState.obj = target.pull(drsn);
                        coreLib.drowselectState.set = state.set;
                        coreLib.drowselectState.pos = state.pos;
                    }
                    // start browsing
                    drowselectListen();
                };
            }
        }, // drowselect

        drowselectListen: drowselectListen,

        mmKeyListener: mmKeyListener,

    }
});
