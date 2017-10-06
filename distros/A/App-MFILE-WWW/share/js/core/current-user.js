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
// current-user.js - initialize, store, and modify current user object and
//                   priv level setting
//
// This module returns a function. When the module is first loaded, it creates
// an empty 'prototypes.user' object (see prototypes.js) and merges it with
// the value of the 'currentUser' module.config parameter (see Resource.pm), 
// which may be empty. It also gets the value of the 'currentUserPriv' setting,
// which also may be empty.
//
// The function provides a simple API that hinges on the value of the first
// argument:
//
// - first argument === undefined
//   the "full current-user object" is returned, i.e.:
//   {
//       obj: { nick: '...', eid: '...', etc. },
//       priv: 'passerby'
//   }
//
//  - first argument === 'obj'
//    the current user object only is returned. If there is a second argument,
//    the object is set to that argument first.
//
//  - first argument === 'priv'
//    the current user priv string only is returned. If there is a second argument,
//    the priv string is set to that argument first.
//
//
"use strict";

define ([
    'jquery', 
    'cf', 
    'prototypes'
], function (
    $, 
    cf,
    prototypes
) {

    console.log("current-user initialization routine");

    var cu = Object.create(prototypes.user),
        ce = cf('currentUser'),
        priv = cf('currentUserPriv'),
        flag1;

    console.log("current-user: ce is ", ce);
    console.log("current-user: priv is " + priv);

    if (ce) {
        $.extend(cu, ce)
    }

    return function (sw, arg) { 
        var emptyObj = { "nick": null };
        if (sw === 'obj') {
            console.log('current-user function called with "obj"', arg);
            if (arg) {
                console.log('NOTICE: setting current user object to ', arg);
                cu = arg;
                cf('currentUser', cu);
            }
            if (arg === null) {
                console.log('NOTICE: resetting currentUser object');
                cu = emptyObj;
                cf('currentUser', cu);
            }
            return cu;
        }
        if (sw === 'priv') {
            // console.log('current-user function called with "priv"');
            if (arg) {
                console.log('NOTICE: setting current user priv to ' + arg);
                priv = arg;
                cf('currentUserPriv', priv);
            }
            if (arg === null || arg === "") {
                console.log('NOTICE: resetting current user priv');
                priv = null;
                cf('currentUserPriv', priv);
            }
            return priv;
        }
        if (sw === 'flag1') {
            // console.log('current-user function called with "flag1"');
            if (arg || arg === 0 || arg === 'null') {
                console.log('NOTICE: setting current user flag1 to ' + arg);
                flag1 = arg;
            }
            return flag1;
        }
        // console.log('current-user function called with no arguments');
        return {
            'obj': cu,
            'priv': priv,
            'flag1': flag1
        };
    };

});
