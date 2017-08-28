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
// stack.js -- stack enabling targets (dialogs) to be "push"ed and "pop"ped
//
// To initiate a new target (dialog), call stack.push(target)
//
// To return to the previous target (dialog), call stack.pop()
//
// Each target type (dmenu, dform, etc.) needs to have methods for saving
// and restoring the target state. These can range from very simple (dmenu)
// to complicated (dbrowser).
//
"use strict";

define ([
    "jquery",
    "lib",
    "prototypes",
    "target"
], function (
    $,
    lib,
    prototypes,
    target
) {

    var
        // object for storing the stack
        _stack = [],

        // pop a target and its state off the stack
        // ARG1 (optional) - object to be merged into stateObj
        // ARG2 (optional) - boolean, whether to call start() (default: true)
        pop = function (mo, start) {
            start = (start === false) ? false : true;
            console.log("Entering stack.pop() with stack", _stack);
            var stackObj,
                type;
            _stack.pop(); 
            if (_stack.length === 0) {
                console.log("Stack empty - logging out");
                target.pull('logout').start();
                return;
            }
            stackObj = _stack[_stack.length - 1];
            if (typeof mo === 'object') {
                console.log("pop() was passed an object", mo);
                $.extend(stackObj.state, mo);
            }
            stackObj.pushed = false;
            console.log("Popped " + stackObj.target.name);
            type = stackObj.target.type;
            if (start) {
                lib.clearResult();
                stackObj.target.start();
            }
        },

        popWithoutStart = function (mo) {
            pop(mo, false);
        },

        // push a target and its state onto the stack
        push = function (tgt, obj, opts) {
            console.log("Entering stack.push() with target", tgt, "object", obj, "and opts", opts);
            // console.log("and stack", _stack);
            var flag,
                xtarget;
            if (obj === undefined || obj === null) {
                obj = {};
            }
            if (typeof tgt === "string") {
                tgt = target.pull(tgt);
            }
            if (typeof tgt !== "object") {
                console.log("ERROR in stack.push() - found no target object");
                return;
            }
            if (typeof opts === "object") {
                flag = opts.hasOwnProperty('flag') ? opts.flag : false;
                xtarget = opts.hasOwnProperty('xtarget') ? opts.xtarget : null;
                console.log("In stack.push(), setting flag", flag, "and xtarget", xtarget);
            }
            if (tgt.pushable) {
                _stack.push({
                    "flag": flag,
                    "push": true,
                    "state": obj,
                    "target": tgt,
                    "xtarget": xtarget
                });
            }
            lib.clearResult();
            tgt.start(obj);
        },

        getFlag = function () {
            return _stack[_stack.length - 1].flag;
        },
        getPush = function () {
            return _stack[_stack.length - 1].push;
        },
        getState = function () {
            return _stack[_stack.length - 1].state;
        },
        getTarget = function () {
            return _stack[_stack.length - 1].target;
        },
        getXTarget = function () {
            return _stack[_stack.length - 1].xtarget;
        },


        setFlag = function () {
            _stack[_stack.length - 1].flag = true;
        },
        setPush = function (newPush) {
            _stack[_stack.length - 1].push = newPush;
        },
        setState = function (newState) {
            _stack[_stack.length - 1].state = newState;
        },
        setTarget = function (newTarget) {
            _stack[_stack.length - 1].target = newTarget;
        },
        setXTarget = function (newXTarget) {
            _stack[_stack.length - 1].xtarget = newXTarget;
        },

        unsetFlag = function () {
            _stack[_stack.length - 1].flag = false;
        },
        unsetPush = function () {
            _stack[_stack.length - 1].push = undefined;
        },
        unsetState = function () {
            _stack[_stack.length - 1].state = undefined;
        },
        unsetTarget = function () {
            _stack[_stack.length - 1].target = undefined;
        },
        unsetXTarget = function () {
            _stack[_stack.length - 1].xtarget = undefined;
        },

        // unwind stack until given target is reached
        // optional object to pass to start()
        unwindToTarget = function (tname, obj) {
            console.log("Unwinding the stack to target " + tname);
            var tgt;
            for (var i = _stack.length; i > 0; i--) {
                tgt = _stack[i - 1].target;
                if (tgt.name === tname) {
                   break;
                }
                popWithoutStart();
            }
            tgt.start(obj);
        },
        
        unwindToFlag = function () {
            console.log("Unwinding the stack to flag");
            var flag;
            for (var i = _stack.length; i > 0; i--) {
                flag = _stack[i - 1].flag;
                if (flag) {
                   break;
                }
                popWithoutStart();
            }
            _stack[_stack.length - 1].target.start();
        },

        // grep stack for a target name (exact match)
        grep = function (tname) {
            var retval = false;
            for (var i=0; i<_stack.length; i++) {
                if (_stack[i].target.name === tname) {
                    return true;
                }
            }
            return false;
        };

    return {
        "getFlag": getFlag,
        "getPush": getPush,
        "getState": getState,
        "getTarget": getTarget,
        "getXTarget": getXTarget,
        "grep": grep,
        "pop": pop,
        "popWithoutStart": popWithoutStart,
        "push": push,
        "setFlag": setFlag,
        "setPush": setPush,
        "setState": setState,
        "setTarget": setTarget,
        "setXTarget": setXTarget,
        "unsetFlag": unsetFlag,
        "unsetPush": unsetPush,
        "unsetState": unsetState,
        "unsetTarget": unsetTarget,
        "unsetXTarget": unsetXTarget,
        "unwindToFlag": unwindToFlag,
        "unwindToTarget": unwindToTarget
    };

});
