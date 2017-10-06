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
    'lib',
    'stack',
    'target'
], function (
    $,
    lib,
    stack,
    target
) {
    var 
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
                if (lib.privCheck(selection.aclProfile)) {
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
                lib.logKeyPress(event);
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
        mmKeyListener = function (evt) {

            var len = $("input:text").length,
                n = $("input:text").index($(document.activeElement)),
                i;

            lib.logKeyPress(evt);
    
            if (evt.keyCode === 13) {
                console.log('MiniMenu listener detected <ENTER> keypress');
                console.log("This form has elements 0 through " + (len - 1));
                for (i=0; i<len; i++) {
                    console.log("Element " + i, $("input:text")[i]);
                }
                console.log("The current element is no. " + n);
                evt.preventDefault();
                if ( n === len - 1 ) {
                    console.log("Triggering submit button click");
                    $('#submitButton').click();
                } else {
                    $("input:text")[n + 1].focus();
                }
    
            } else if (evt.keyCode === 9) {
                var elnam = $(document.activeElement).attr("name");
                if (
                        (elnam === 'entry0' && evt.shiftKey) ||
                        (elnam === 'sel' && len === 1) ||
                        (elnam === 'sel' && !evt.shiftKey)
                   ) {
                    evt.preventDefault();
                }
            }

        },
        mmSubmit = function (tgt, obj) {
            console.log("Entering mmSubmit with target", tgt, " and object", obj);

            lib.clearResult();
        
            var sel = $('input[name="sel"]').val(),
                len,
                i,
                newObj,
                selection,
                entry,
                item,
                wlen,
                entries = tgt.miniMenu.entries;

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
                if (tgt.entriesWrite) {
                    wlen = tgt.entriesWrite.length;
                    for (i = 0; i < wlen; i += 1) {
                        entry = tgt.entriesWrite[i];
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
                selection = target.pull(tgt.miniMenu.entries[sel]);
                if (lib.privCheck(selection.aclProfile)) {
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
                if (tgt.type === 'dform' && tgt.rememberState) {
                    console.log("Changing stack state to", newObj);
                    stack.setState(newObj);
                }
                stack.push(item, newObj);
            }
        },

        //
        // dform handlers
        //
        dformSubmit = function (dfn, obj) {
            // dfn is dform name
            mmSubmit(target.pull(dfn), obj);
        },
        dformListen = function (dfn, obj) {
            console.log("Listening in form " + dfn);
            var dfo = target.pull(dfn);
            $('#' + dfn).submit( suppressSubmitEvent );
            $('input[name="sel"]').val('');
            if (stack.getPush() === true && $('input[name="entry0"]').length) {
                $('input[name="entry0"]').focus();
            } else {
                $('input[name="sel"]').focus();
            }
            $('#submitButton').on("click", function (event) {
                event.preventDefault;
                console.log("Submitting form " + dfn);
                dformSubmit(dfn, obj);
            });
            $('#' + dfn).on("keypress", mmKeyListener);
        },

        //
        // dbrowser handlers
        //
        dbrowserSubmit = function () {
            var dbo = lib.dbrowserState.obj,
                set = lib.dbrowserState.set,
                pos = lib.dbrowserState.pos;
            mmSubmit(dbo, set[pos]);
        },
        dbrowserKeyListener = function () {
            var set = lib.dbrowserState.set,
                pos = lib.dbrowserState.pos;
            
            return function (evt) {
        
                lib.logKeyPress(evt);
        
                // since the dbrowser has (may have) a navigation menu, we
                // check first for those keys before moving to miniMenu handler
                if (evt.keyCode === 37) { // <-
                    if (evt.ctrlKey) {
                        console.log('Listener detected CTRL-\u2190 keypress');
                        if ($("#navJumpToBegin").length) {
                            lib.dbrowserState.pos = 0;
                            dbrowserListen();
                        }
                    } else {
                        console.log('Listener detected \u2190 keypress');
                        if ($("#navBack").length) {
                            lib.dbrowserState.pos -= 1;
                            dbrowserListen();
                        }
                    }
                } else if (evt.keyCode === 39) { // ->
                    if (evt.ctrlKey) {
                        console.log('Listener detected CTRL-\u2192 keypress');
                        if ($("#navJumpToEnd").length) {
                            lib.dbrowserState.pos = set.length - 1;
                            dbrowserListen();
                        }
                    } else {
                        console.log('Listener detected \u2192 keypress');
                        if ($("#navForward").length) {
                            lib.dbrowserState.pos += 1;
                            dbrowserListen();
                        }
                    }
                } else {
                    mmKeyListener(evt);
                }
            };
        },
        dbrowserListen = function (resultLine) {
            var dbo = lib.dbrowserState.obj,
                set = lib.dbrowserState.set,
                pos = lib.dbrowserState.pos;
            
            console.log("Listening in browser " + dbo.name);
            console.log("Browser set is", set, "cursor position is " + pos);
            $('#mainarea').html(dbo.source(set, pos));
            if (resultLine) {
                lib.displayResult(resultLine);
            } else {
                lib.displayResult("Displaying no. " + (pos + 1) + " of " + 
                                  lib.genObjStr(set.length) + " in result set");
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
            mmSubmit(dto);
        },
        dtableListen = function (dto) {
            console.log("Listening in table " + dto.name);
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
            var drso = lib.drowselectState.obj;
                set = lib.drowselectState.set,
                pos = lib.drowselectState.pos;
            mmSubmit(drso, set[pos]);
        },
        drowselectKeyListener = function () {
            var set = lib.drowselectState.set,
                pos = lib.drowselectState.pos;

            return function (evt) {

                console.log("Entering drowselectKeyListener");
                lib.logKeyPress(evt);

                if (evt.keyCode === 37) { // up arrow
                    if (evt.ctrlKey) {
                        console.log('Listener detected CTRL-up arrow keypress');
                        lib.reverseVideo(lib.drowselectState.pos, false);
                        lib.drowselectState.pos = 0;
                        drowselectListen();
                    } else {
                        console.log('Listener detected up arrow keypress');
                        if (lib.drowselectState.pos > 0) {
                            lib.reverseVideo(lib.drowselectState.pos, false);
                            lib.drowselectState.pos -= 1;
                            drowselectListen();
                        }
                    }
                } else if (evt.keyCode === 39) { // down arrow
                    if (evt.ctrlKey) {
                        console.log('Listener detected CTRL-down arrow keypress');
                        lib.reverseVideo(lib.drowselectState.pos, false);
                        lib.drowselectState.pos = set.length - 1;
                        drowselectListen();
                    } else {
                        console.log('Listener detected down arrow keypress');
                        if (lib.drowselectState.pos < set.length - 1) {
                            lib.reverseVideo(lib.drowselectState.pos, false);
                            lib.drowselectState.pos += 1;
                            drowselectListen();
                        }
                    }
                } else {
                    mmKeyListener(evt);
                }
            };
        },
        drowselectListen = function () {
            var drso = lib.drowselectState.obj,
                set = lib.drowselectState.set,
                pos = lib.drowselectState.pos;
            $('#result').text("Displaying rowselect with " + lib.genObjStr(set.length));
            $('#mainarea').html(drso.source(set));
            lib.reverseVideo(pos, true);
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
                // lib.clearResult();
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
                lib.displayResult(opts.resultLine);
                if (! state) {
                    state = stack.getState();
                }
                console.log('The object we are working with is:', state);
                $('#mainarea').html(dfo.source(state));
                dformListen(dfn, state);
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
                    if (lib.dbrowserStateOverride) {
                        lib.dbrowserStateOverride = false;
                    } else {
                        lib.dbrowserState.obj = target.pull(dbn);
                        lib.dbrowserState.set = state.set;
                        lib.dbrowserState.pos = state.pos;
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
                lib.clearResult();
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
                lib.clearResult();
                console.log('Starting new ' + dtn + ' dtable');
                if (! state) {
                    state = stack.getState();
                }
                console.log('The dataset is', state);
                $('#mainarea').html(dto.source(state));
                $('#result').text('Displaying table with ' + lib.genObjStr(state.length));
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
                    lib.clearResult();
                    console.log('Starting new ' + drsn + ' drowselect');
                    if (! state) {
                        state = stack.getState();
                    }
                    console.log('rowselect state', state);
                    // (re)initialize drowselect state
                    if (lib.drowselectStateOverride) {
                        lib.drowselectStateOverride = false;
                    } else {
                        lib.drowselectState.obj = target.pull(drsn);
                        lib.drowselectState.set = state.set;
                        lib.drowselectState.pos = state.pos;
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
