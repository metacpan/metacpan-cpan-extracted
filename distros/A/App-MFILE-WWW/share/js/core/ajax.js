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
// ajax.js
//
// provides a function that sends AJAX requests to the App::MFILE::WWW server
// (which forwards them to the backend server) and takes action based on the
// HTTP response received.
//
// The 'ajax' function takes three arguments:
// - MFILE AJAX Object (an object)
// - success callback 
// - failure callback
//
// The success and failure callbacks can be null or undefined, in which case App::MFILE::WWW will
// just display the status text in the #result div (i.e., the line at the bottom of the frame).
// If your AJAX calls needs any other handling than this, you need to provide at least a success
// callback.
//
// In all cases except login/logout, the MFILE AJAX Object looks like this:
// {
//     "method": any HTTP method accepted by the backend server
//     "path": valid path to backend server resource
//     "body": content body to be sent to backend server (can be null)
// }
//
// MFILE AJAX Object for _login_ to backend server:
// {
//     "method": "LOGIN",
//     "path": "login",
//     "body": { "nam": $USERNAME, "pas": $PASSWORD }
// }
//
// MFILE AJAX Object for _logout_ from backend server:
// {
//     "method": "LOGIN",
//     "path": "logout",
//     "body": null
// }
//
// For details on how AJAX calls are handled, see lib/App/MFILE/WWW/Resource.pm
//
"use strict";

define ([
    'jquery',
    'cf',
    'lib',
], function (
    $,
    cf,
    lib,
) {

    return function (rest, sc, fc) {
        // console.log("Initiating AJAX call", mfao);
        lib.displayResult('* * * AJAX call * * *');
        $.ajax({
            'url': '/',
            'data': JSON.stringify(rest),
            'method': 'POST',
            'processData': false,
            'contentType': 'application/json'
        })
        .done(function (data) {
            if (data.level === 'OK') {
                console.log("AJAX success", rest, data);
                if (typeof sc === 'function') {
                    lib.clearResult();
                    sc(data);
                } else {
                    lib.displayResult(data.text);
                }
            } else {
                console.log("AJAX failure", rest, data);
                if (typeof fc === 'function') {
                    fc(data);
                } else {
                    lib.displayError(data.payload.message);
                }
            }
        });
    };

});
