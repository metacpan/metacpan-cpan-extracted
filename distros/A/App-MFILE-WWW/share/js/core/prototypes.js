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
// prototypes.js
//
//
"use strict";

define(function () {
    return {

    // Simple menus, mini menus, and actions all share certain properties
    // (and methods) like 'name', 'menuText', etc. To streamline the
    // creation and use of these three basic object classes, we create a
    // 'target' object to serve as a prototype.

        target: {
            name: 'targetPrototype',
            get_name: function () {
                return this.name;
            },
            menuText: 'Target prototype',
            get_menuText: function () {
                return this.menuText;
            },
            aclProfile: 'passerby',
            get_aclProfile: function () {
                return this.aclProfile;
            },
            source: '',
            get_source: function () {
                return this.source;
            },
            start: function () {},
            get_start: function () {
                return this.start;
            }
        },

    // MFILE assumes that the application will have a concept of a "user" -
    // perhaps under a different name, like "employee", but sharing certain
    // very basic properties like 'nick', 'passhash', and 'salt' which are
    // defined in this ancestral prototype

        user: {
            nick: '',
            passhash: '',
            salt: ''
        }

    };
});

