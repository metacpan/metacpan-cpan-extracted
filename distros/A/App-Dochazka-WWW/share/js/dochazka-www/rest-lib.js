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
// app/rest-lib.js
//
"use strict";

define ([
    'jquery',
    'ajax',
    'cf',
    'lib'
], function (
    $,
    ajax,
    cf,
    lib
) {

    var restServerDetails = function () {
            var ver = '...LOADING...',
                rest = {
                    "method": 'GET',
                    "path": 'version'
                },
                // success callback
                sc = function (st) {
                    if (st.code === 'DISPATCH_VERSION') {
                        // $("#mainarea").find("#rSDversion").text(st.payload.version);
                        $("#rSDversion").text(st.payload.version);
                        lib.clearResult();
                    }
                },
                // failure callback
                fc = null;
            ajax(rest, sc, fc);
            return {
                url: cf('restURI'),
                version: ver
            };
        };

    return {
        restServerDetails: restServerDetails
    };

});

