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
// loggout.js
//
// function to log out the user
//
// N.B.: The extra "g" in "loggout" is just for kicks.
//
"use strict";

define([
    'jquery', 
    'app/lib',
    'ajax',
    'cf',
    'current-user',
    'html',
    'lib',
], function (
    $, 
    appLib,
    ajax,
    cf,
    currentUser,
    html,
    coreLib,
) {

    return function (msg) {

        var logoutPostAJAX = function (msg) {
                currentUser('obj', null);
                currentUser('priv', null);
                $('#userbox').html(appLib.fillUserBox()); // reset userbox
                $('#mainarea').html(html.logout());
                // automated page reloads are a source of woe
                // if (! cf('testing')) {
                //     setTimeout(function() {
                //         location.reload();
                //     }, 2000);
                // }
            },
            rest = {
                method: 'LOGIN',
                path: 'logout',
                body: null
            },
            sc = function (st) {
                if (! msg) {
                    msg = st.text;
                }
                logoutPostAJAX(msg);
            },
            fc = function (st) {
                logoutPostAJAX(st.text);
            };
        ajax(rest, sc, fc);

    };

});
