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
        pop = function (newState, opts) {
            console.log("Entering stack.pop() with new state", newState, "and opts", opts);
            var resultLine,
                stackState,
                stackTarget,
                stackLength;

            opts = lib.objectify(opts);
            opts['logout'] = ('logout' in opts) ? opts.logout : false;
            opts['inputId'] = ('inputId' in opts) ? opts.inputId : null;
            opts['resultLine'] = ('resultLine' in opts) ? opts.resultLine : "&nbsp";
            opts['_start'] = ('_start' in opts) ? opts._start : true;
            opts['_restart'] = ('_restart' in opts) ? opts._restart : false;
            opts['_start'] = opts._restart ? true : opts._start;
            console.log("stack.pop() adjusted opts", opts);

            stackLength = getLength();

            if (stackLength === 1) {
                if (opts.logout) {
                    target.pull('logout').start();
                    return;
                } else {
                    console.log("Refusing to pop last remaining item off the stack");
                    return
                }
            }

            // pop item off the stack, unless called by stack.restart()
            if (opts._restart) {
                console.log("Restarting stack top item.");
            } else {
                _stack.pop();
                console.log("Stack top item popped off and discarded.");
            }
            stackTarget = getTarget();
            stackState = getState();
            console.log("Now, the stack length is " + stackLength +
                        " and the top target is " + stackTarget.name +
                        " and its state is", stackState);
            if (newState && typeof newState === 'object') {
                $.extend(stackState, newState);
                setState(stackState);
            }
            setPush(false);
            if (opts._start) {
                delete opts["_start"];
                delete opts["_restart"];
                stackTarget.start(newState, opts);
            }
        },

        popWithoutStart = function (newState, opts) {
            opts = lib.objectify(opts);
            opts['_start'] = false;
            opts['_restart'] = false;
            pop(newState, opts);
        },

        // push a target and its state onto the stack
        push = function (tgt, obj, opts) {
            console.log("Entering stack.push() with target", tgt, "object", obj, "and opts", opts);
            // console.log("and stack", _stack);
            var flag,
                resultLine,
                xtarget;
            obj = lib.objectify(obj);
            opts = lib.objectify(opts);
            if (typeof tgt === "string") {
                tgt = target.pull(tgt);
            }
            if (typeof tgt !== "object") {
                console.log("ERROR in stack.push() - found no target object");
                return;
            }
            opts['flag'] = ('flag' in opts) ? opts.flag : false;
            opts['xtarget'] = ('xtarget' in opts) ? opts.xtarget : null;
            opts['resultLine'] = ('resultLine' in opts) ? opts.resultLine : null;
            opts['_start'] = ('_start' in opts) ? opts._start : true;
            console.log("stack.push() adjusted opts", opts);
            if (tgt.pushable) {
                _stack.push({
                    "flag": opts.flag,
                    "opts": opts,
                    "push": true,
                    "resultLine": opts.resultLine,
                    "state": obj,
                    "target": tgt,
                    "xtarget": opts.xtarget
                });
            }
            if (opts._start) {
                tgt.start(obj);
            }
        },

        pushWithoutStart = function (newState, opts) {
            if (typeof opts !== 'object') {
                opts = {};
            }
            opts['_start'] = false;
            push(newState, opts);
        },

        restart = function (newState, opts) {
            // does the exact same thing as pop, except it leaves the top
            // item on the stack and restarts it with new state and opts
            if (typeof opts !== 'object') {
                opts = {};
            }
            opts["_start"] = true;
            opts["_restart"] = true;
            pop(newState, opts);
        },

        getFlag = function () {
            return _stack[_stack.length - 1].flag;
        },
        getLength = function () {
            return _stack.length;
        },
        getOpts = function () {
            return _stack[_stack.length - 1].opts;
        },
        getPush = function () {
            return _stack[_stack.length - 1].push;
        },
        getResultLine = function () {
            return _stack[_stack.length - 1].resultLine;
        },
        getStack = function () {
            // returns the entire stack
            return _stack;
        },
        getState = function (offset) {
            // offset -1 for target under top target
            // offset -2 for two targets down, etc.
            if (offset === undefined) {
                offset = 0;
            }
            if (_stack.length === 0) {
                console.log("Ignoring attempt to get target from empty stack");
                return null;
            }
            return _stack[_stack.length - 1].state;
        },
        getTarget = function (offset) {
            // offset -1 for target under top target
            // offset -2 for two targets down, etc.
            if (offset === undefined) {
                offset = 0;
            }
            if (_stack.length === 0) {
                console.log("Ignoring attempt to get target from empty stack");
                return null;
            }
            return _stack[_stack.length + offset - 1].target;
        },
        getXTarget = function () {
            return _stack[_stack.length - 1].xtarget;
        },

        resetStack = function () {
            console.log("Resetting the stack");
            _stack = [];
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
        unwindToTarget = function (tname, newObj, opts) {
            var i, tgt;
            console.log("Unwinding the stack to target " + tname);
            for (i = _stack.length; i > 0; i -= 1) {
                tgt = _stack[i - 1].target;
                console.log("Does " + tgt.name + " equal " + tname + " ?");
                if (tgt.name === tname) {
                   break;
                }
                popWithoutStart(newObj, opts);
            }
            tgt.start(newObj, opts);
        },
        
        unwindToFlag = function (newObj, opts) {
            console.log("Unwinding the stack to flag");
            var flag, i;
            if (typeof opts !== 'object' || opts === null) {
                opts = {};
            }
            opts['_start'] = ('_start' in opts) ? opts._start : true;
            for (i = _stack.length; i > 0; i -= 1) {
                flag = _stack[i - 1].flag;
                if (flag) {
                   break;
                }
                popWithoutStart(newObj, opts);
            }
            if (opts._start) {
                _stack[_stack.length - 1].target.start();
            }
        },

        unwindToType = function (targetType, opts) {
            var i, tgt;
            console.log("Unwinding stack to nearest target of type " + targetType);
            if (typeof opts !== 'object' || opts === null) {
                opts = {};
            }
            opts['_start'] = ('_start' in opts) ? opts._start : true;
            for (i = _stack.length; i > 0; i -= 1) {
                tgt = _stack[i - 1].target;
                if (tgt.type === targetType) {
                   break;
                }
                popWithoutStart();
            }
            if (opts._start) {
                tgt.start();
            }
        },

        // grep stack for a target name (exact match)
        grep = function (tname) {
            var i, retval = false;
            console.log("Grepping stack for " + tname);
            for (i = 0; i < _stack.length; i += 1) {
                console.log("Does " + _stack[i].target.name + " equal " + tname + " ?");
                if (_stack[i].target.name === tname) {
                    return true;
                }
            }
            return false;
        };

    return {
        "getFlag": getFlag,
        "getLength": getLength,
        "getOpts": getOpts,
        "getPush": getPush,
        "getResultLine": getResultLine,
        "getStack": getStack,
        "getState": getState,
        "getTarget": getTarget,
        "getXTarget": getXTarget,
        "grep": grep,
        "pop": pop,
        "popWithoutStart": popWithoutStart,
        "push": push,
        "pushWithoutStart": popWithoutStart,
        "resetStack": resetStack,
        "restart" : restart,
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
        "unwindToTarget": unwindToTarget,
        "unwindToType": unwindToType,
    };

});
