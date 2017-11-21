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
// login-dialog.js
//
"use strict";

define ([
    'jquery', 
    'cf',
    'html', 
    'lib',
    'login'
], function (
    $, 
    cf,
    html, 
    lib,
    login
) {

    return function () {

        var // submitCallback is called when user submits login dialog form 

            submitCallback = function (event) {
                console.log("Entering submitCallback()");
                event.preventDefault();
                login({
                    "nam": $('input[name="nam"]').val(),
                    "pwd": $('input[name="pwd"]').val()
                });
            },

            // formHandler processes user input in login dialog form

            formHandler = function () {
                $('input[name="nam"]').val('').focus();
                $('input[name="pwd"]').val('');

                // Set up form submit callback
                $('#loginform').submit(submitCallback);

                // Set up listener for <ENTER> keydowns in "username" field
                $('input[name="nam"]').keydown(function (evt) {
                    lib.logKeyDown(evt);
                    if (evt.keyCode === 13) {
                        evt.preventDefault();
                        $('input[name="pwd"]').focus();
                    } else if (evt.keyCode === 9 && evt.shiftKey) {
                        evt.preventDefault();
                    }
                });

                // Set up listener for <ENTER> and <TAB> keydowns in "password" field
                $('input[name="pwd"]').keydown(function (evt) {
                    lib.logKeyDown(evt);
                    if (evt.keyCode === 13) {
                        // event.preventDefault();
                        submitCallback(evt);
                    } else if (evt.keyCode === 9) {
                        evt.preventDefault();
                        $('input[name="nam"]').focus();
                    }
                });
            }; // end of var list

        $('#mainarea').html(html.loginDialog());
        formHandler();

    }
});
