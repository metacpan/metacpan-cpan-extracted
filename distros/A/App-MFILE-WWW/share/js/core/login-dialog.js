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
// login-dialog
//
"use strict";

define ([
    'jquery', 
    'ajax', 
    'cf',
    'html', 
    'lib'
], function (
    $, 
    ajax, 
    cf,
    html, 
    lib
) {

    console.log("Entering loginDialog");

    return function () {

        var // submitCallback is called when user submits login dialog form 

            submitCallback = function (event) {
                console.log("Entering submitCallback()");
                event.preventDefault();
                var found,
                    i,
                    rest = {
                        "method": 'LOGIN',
                        "path": 'login',
                        "body": { nam: $('input[name="nam"]').val(),
                                  pwd: $('input[name="pwd"]').val() }
                    },
                    // success callback
                    sc = function (st) {
                        // trigger GET request to the server -- no console.log messages here
                        // because the reload will make them go away
                        location.reload();
                    },
                    // failure callback
                    fc = function (st) {
                        console.log("Login failed", st);
                        $('#result').html('Login failed: code ' + st.payload.code + 
                                          ' (' + st.payload.message + ')');
                        $('input[name="nam"]').focus();
                        $('input[name="pwd"]').val('');
                    };
                console.log("Initiating AJAX call");
                ajax(rest, sc, fc);
            },

            // formHandler processes user input in login dialog form

            formHandler = function () {
                $('input[name="nam"]').val('').focus();
                $('input[name="pwd"]').val('');

                // Set up form submit callback
                $('#loginform').submit(submitCallback);

                // Set up listener for <ENTER> keypresses in "username" field
                $('input[name="nam"]').keydown(function (event) {
                    lib.logKeyPress(event);
                    if (event.keyCode === 13) {
                        event.preventDefault();
                        $('input[name="pwd"]').focus();
                    }
                });

                // Set up listener for <ENTER> and <TAB> keypresses in "password" field
                $('input[name="pwd"]').keydown(function (event) {
                    lib.logKeyPress(event);
                    if (event.keyCode === 13) {
                        // event.preventDefault();
                        submitCallback(event);
                    } else if (event.keyCode === 9) {
                        event.preventDefault();
                        $('input[name="nam"]').focus();
                    }
                });
            }; // end of var list

        $('#mainarea').html(html.loginDialog());
        formHandler();

    }
});
