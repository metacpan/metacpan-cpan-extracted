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
// tests/prototypes.js
//
"use strict";

define ([
    'prototypes'
], function (
    prototypes 
) {
    return function () {
        var t = Object.create(prototypes.target),
            u = Object.create(prototypes.user);
        test('prototypes prototyping?', function () {

            // target
            strictEqual(typeof t, 'object', 't is an object');
            strictEqual(typeof t.name, 'string', 'target.name OK');
            strictEqual(t.name, 'targetPrototype', 't.name OK');
            strictEqual(typeof t.get_name, 'function', 'target.get_name OK');
            strictEqual(typeof t.menuText, 'string', 'target.menuText OK');
            strictEqual(t.menuText, 'Target prototype', 't.menuText OK');
            strictEqual(typeof t.get_menuText, 'function', 'target.get_menuText OK');
            strictEqual(typeof t.aclProfile, 'string', 'target.aclProfile OK');
            strictEqual(t.aclProfile, 'passerby', 't.aclProfile OK');
            strictEqual(typeof t.get_aclProfile, 'function', 'target.get_aclProfile OK');
            strictEqual(typeof t.source, 'string', 'target.source OK');
            strictEqual(t.source, '', 't.source OK');
            strictEqual(typeof t.get_source, 'function', 'target.get_source OK');
            strictEqual(typeof t.start, 'function', 'target.start OK');
            strictEqual(typeof t.get_start, 'function', 'target.get_start OK');

            // user
            strictEqual(typeof u, 'object', 'u is an object');
            strictEqual(typeof u.nick, 'string', 'user.nick OK');
            strictEqual(u.nick, '', 'user.nick OK');
            strictEqual(typeof u.passhash, 'string', 'user.passhash OK');
            strictEqual(u.passhash, '', 'user.nick OK');
            strictEqual(typeof u.salt, 'string', 'user.salt OK');
            strictEqual(u.salt, '', 'user.nick OK');

        });

    };
});

