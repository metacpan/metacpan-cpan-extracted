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
// app/lib.js
//
// application-specific routines
//
"use strict";

define ([
    'current-user'
], function (
    currentUser
) {

    return {

        //
        // function returns string that will be displayed at the very
        // bottom of the screen (directly under the frame)
        //
        fillNoticesLine: function () {
            var r = '';
            r += 'Copyright \u00A9 SUSE LLC, 2014-2016. All rights reserved. ';
            r += 'Report bugs at ';
            r += '<a href="https://github.com/smithfarm/dochazka/issues">';
            r += 'https://github.com/smithfarm/dochazka/issues</a>';
            return r;
        },

        //
        // function returns string to be displayed in the 'userbox'
        // <span> element at the top right of the "screen" (i.e. browser
        // window) -- called from html.js
        //
        fillUserBox: function () {

            var r = '', 
                cu = currentUser(),
                cunick,
                cupriv,
                cumasq;

            if (cu) {
                cunick = cu.obj.nick || null;
                cupriv = cu.priv || 'passerby';
                cumasq = cu.flag1; // use flag1 as masquerade state
            } else {
                cunick = null;
                cupriv = 'passerby';
                cumasq = undefined;
            }

            if (cumasq) {
                r += '<b>!!! ';
            }

            r += 'Employee: ';
            r += cunick ? cu.obj.nick : '&lt;NONE&gt;';
            if (cumasq) {
                r += ' (MASQUERADE)';
            } else {
                if (cupriv === 'admin') {
                    r += '&nbsp;ADMIN';
                }
            }

            if (cumasq) {
                r += ' !!!</b>';
            }

            return r;

        },

    };

});
