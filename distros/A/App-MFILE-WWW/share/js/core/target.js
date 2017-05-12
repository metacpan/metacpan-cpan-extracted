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
// target.js -- target storage and retrieval
//
// A 'target' is an object representing a user-interface element. Targets
// can currently be one of the following types:
// - menu
// - form
// - action
//
// Each target must have a unique name. The object exported by this module
// provides methods for storing and retrieving targets.
//
// The object, referred to as 'target', has the following structure:
// {
//     '_store': { ... target objects ... }
//     'pull': method for retrieving single targets by name
//     'getAll': method for retrieving all targets of a particular type
//     'push': method for 'pushing' properties onto a given target
// }
//
"use strict";

define ([
    "prototypes"
], function (
    prototypes
) {

    var 
        //
        // object for storing targets
        //
        _store = {},
        //
        // function for retrieving a single target by name
        //
        pull = function (tn) {
            if (_store.hasOwnProperty(tn)) {
                return _store[tn];
            }
            return undefined;
        },
        //
        // function for retrieving set of all targets of a given type
        //
        getAll = function (tt) {
            var buffer = {},
                i;
            for (i in _store) {
                if (_store.hasOwnProperty(i)) {
                    // _store[i] is a target
                    if (_store[i].type === tt) {
                        buffer[i] = _store[i];
                    }
                }
            }
            return buffer;
        },
        //
        // function for pushing set of properties onto a target
        //
        push = function (tn, props) {
            var target,
                i;
            if (! _store.hasOwnProperty(tn)) {
                _store[tn] = Object.create(prototypes.target);
            }
            target = _store[tn];
            for (i in props) {
                if (props.hasOwnProperty(i)) {
                    target[i] = props[i];
                }
            }
        };

    //
    // export the 'target' object
    //
    return { 
        "_store": _store, 
        "pull": pull, 
        "getAll": getAll, 
        "push": push 
    };

});
