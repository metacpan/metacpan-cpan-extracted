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
// cf.js
//
// provides a function that makes configuration parameters passed in from Perl
// side available to JavaScript modules that need them. Also provides a way to
// override these parameters with new values. Note, however, that overrides
// will survive only until the next page reload, which can happen at any time.
//
// The 'cf' function takes two parameters:
// - parameter name (as defined in 'module.config' - see Resource.pm->gen_html)
// - optionally, a new value for the parameter, which will override the
//   old value until the next page reload
//
"use strict";

var state = {};

define ([
    'module'
], function (
    module
) {

    // the 'cf' module exports a function, 'cf' that takes two 
    // parameters. The first parameter is the name of the config
    // parameter we are interested in. If the second parameter is
    // undefined or null, the function returns the value of the 
    // parameter. Otherwise, it sets the parameter to a new value
    // and returns that value.

    return function (param, override) {
        var r;
        if (override || override === null) {
            state[param] = override;
            console.log("cf() override: config param '" + param + "' reset to", state[param]);
            return override;
        }
        r = (state.hasOwnProperty(param))
            ? state[param]
            : module.config()[param];
        console.log("cf(): config param '" + param + "' is", r);
        return r;
    };

});

