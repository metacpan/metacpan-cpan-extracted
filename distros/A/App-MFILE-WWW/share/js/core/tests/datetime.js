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
// tests/datetime.js
//
"use strict";

define ([
    'QUnit',
    'datetime',
], function (
    QUnit,
    dt,
) {

    var date_valid = function (assert, d) {
            console.log("Entering date_valid() with argument", d);
            var r = dt.vetDate(d);
            assert.ok(r, "valid: " + d + " -> " + r);
        },
        date_invalid = function (assert, d) {
            console.log("Entering date_invalid() with argument", d);
            var r = dt.vetDate(d);
            assert.strictEqual(r, null, "invalid: " + d);
        },
        time_valid = function (assert, t) {
            console.log("Entering time_valid() with argument", t);
            var r = dt.canonicalizeTime(t);
            assert.ok(r, "valid: " + t + " -> " + r);
        },
        time_invalid = function (assert, t) {
            console.log("Entering time_invalid() with argument", t);
            var r = dt.canonicalizeTime(t);
            assert.strictEqual(r, null, "invalid: " + t);
        },
        timerange_valid = function (assert, tr) {
            console.log("Entering timerange_valid() with argument", tr);
            var r = dt.vetTimeRange(tr);
            assert.ok(r, "valid: " + tr + " -> " + r);
        },
        timerange_invalid = function (assert, tr) {
            console.log("Entering timerange_invalid() with argument", tr);
            var r = dt.vetTimeRange(tr);
            assert.strictEqual(r, null, "invalid: " + tr);
        };

    return function () {

        QUnit.test('date vetter function: zero components', function (assert) {
            date_valid(assert, ''); // empty string
            date_valid(assert, ' '); // space
            date_valid(assert, '   '); // several spaces
            date_valid(assert, '	'); // tab
            date_valid(assert, ' 	'); // space + tab
            date_valid(assert, '	  '); // tab + 2 spaces
        });

        QUnit.test('date vetter function: one component', function (assert) {
            date_valid(assert, '31');
            date_valid(assert, 31);
            date_valid(assert, ' 31');
            date_valid(assert, ' 	31');
            date_valid(assert, '31      ');
            date_invalid(assert, '32');
            date_invalid(assert, 32);
            date_valid(assert, "-1");
            date_valid(assert, -1);
            date_valid(assert, "-2");
            date_valid(assert, "+20 ");
            date_valid(assert, "0");
            date_valid(assert, 0);
            date_invalid(assert, "january");
            date_valid(assert, "january 1 ");
            date_valid(assert, "  1 january");
            date_invalid(assert, "foobar");
            date_invalid(assert, "  1 foobar");
            date_invalid(assert, "  foobar 1");
            date_invalid(assert, " *&áb");
            date_invalid(assert, " *&áb  3");
            date_valid(assert, " yesterday ");
            date_valid(assert, " today ");
            date_valid(assert, " TOMORROW ");
            date_valid(assert, " yesterday");
            date_valid(assert, " yestBAMBLATCH");
            date_valid(assert, " YEST****");
        });

        QUnit.test('date vetter function: two components', function (assert) {
            date_valid(assert, '2 31');
            date_valid(assert, '2-31');
            date_valid(assert, '  2 31');
            date_valid(assert, '  2-31');
            date_valid(assert, '2 31	');
            date_valid(assert, '2-31	');
            date_valid(assert, '  2 31	  	');
            date_valid(assert, '  2-31	  	');
            date_valid(assert, 'February 31');
            date_valid(assert, 'February-31');
            date_valid(assert, 'feb 31');
            date_valid(assert, 'feb-31');
            date_valid(assert, '31 feb');
            date_valid(assert, '31-feb');
            date_invalid(assert, '2 foo');
            date_invalid(assert, '2-foo');
            date_invalid(assert, '2 unor');
            date_invalid(assert, '2-unor');
            date_invalid(assert, '2. února');
            date_invalid(assert, 'february 5.5');
            date_valid(assert, 'dec 15');
            date_valid(assert, 'dec-15');
            date_valid(assert, '15    deception ');
            date_invalid(assert, 'dec 155');
            date_invalid(assert, '	-  ');
            date_invalid(assert, '	.  ');
            date_invalid(assert, ' 	/  ');
            date_invalid(assert, '3.1415927');
            date_valid(assert, '31-5');
            date_valid(assert, '5-31');
            date_valid(assert, '5-3');
            date_valid(assert, '5.3');
        });

        QUnit.test('date vetter function: three components', function (assert) {
            date_invalid(assert, 'February 31.');
            date_invalid(assert, 'February-31.');
            date_valid(assert, "2017 oct 15");
            date_valid(assert, "15 oct 2017");
            date_valid(assert, "2017 octopus 15");
            date_valid(assert, "15 octopus 2017");
            date_valid(assert, "2017 October 15");
            date_valid(assert, "15 October 2017");
            date_invalid(assert, "15 oct 20177");
            date_invalid(assert, "20177 oct 15");
            date_invalid(assert, "2017 octopus 0");
            date_invalid(assert, "0 octopus 1999");
            date_invalid(assert, "155 oct 2017");
            date_invalid(assert, 'Pi 3.1415927');
            date_valid(assert, '2017-SEP-30ll');
            date_valid(assert, '2017asdf*-SEP-30ll');
            date_valid(assert, '2017***-SEP-30ll');
        });

        QUnit.test('date vetter function: 4+ components', function (assert) {
            date_invalid(assert, "2017 oct 15 b");
            date_invalid(assert, "15 oct 2017 c");
            date_invalid(assert, '-	-  ');
            date_invalid(assert, '.	-  ');
            date_invalid(assert, ' .	/  ');
            date_invalid(assert, '15  -  deception ');
            date_invalid(assert, 'Pi is approximately 3.1415927');
        });

        QUnit.test('canonicalizeTime', function (assert) {
            time_valid(assert, "7:00");
            time_valid(assert, "7:0");
            time_valid(assert, "7:");
            time_valid(assert, "0:00");
            time_valid(assert, "0:0");
            time_valid(assert, ":0");
            time_valid(assert, ":");
            time_valid(assert, "7");
            time_invalid(assert, "foobar");
            time_invalid(assert, "foo:bar");
            time_invalid(assert, "foo:10");
            time_invalid(assert, "10:bar");
            time_invalid(assert, "10:K§Ň");
            time_invalid(assert, "-1:");
            time_invalid(assert, "5:-434");
            time_invalid(assert, "5:-43");
            time_invalid(assert, "5:60");
            time_invalid(assert, "24:60");
            time_invalid(assert, "245:600");
            time_invalid(assert, "25:50");
            time_valid(assert, "02:50");
            time_invalid(assert, "02:60");
            time_valid(assert, "02:03");
            time_valid(assert, "12:00");
            time_valid(assert, "2:1");
            time_valid(assert, "1:2");
            time_valid(assert, "1:9");
            time_valid(assert, "10:10");
            time_invalid(assert, "25:10");
            time_invalid(assert, "10::10");
            time_valid(assert, "10: 10");
            time_valid(assert, "10 :10");
        });

        QUnit.test('time range vetter function', function (assert) {
            timerange_valid(assert, "12:00-12:30");
            timerange_valid(assert, "12:00 -12:30");
            timerange_valid(assert, "12:00 - 12:30");
            timerange_invalid(assert, "12:00 -- 12:30");
            timerange_invalid(assert, "12:60-12:00");
            timerange_invalid(assert, "12:00-12:60");
            timerange_valid(assert, "12:0-12:6");
            timerange_valid(assert, "12:6-12:0");
            timerange_invalid(assert, "12::6-12:0");
            timerange_valid(assert, "8-12");
        });

        QUnit.test('time range vetter function - offset', function (assert) {
            timerange_valid(assert, "8+1");
            timerange_invalid(assert, "16+10");
            timerange_valid(assert, "8:00+1");
            timerange_valid(assert, "8:00+1:45");
            timerange_valid(assert, "8:45+1:45");
            timerange_valid(assert, "8:45+1:55");
            timerange_valid(assert, "23:45+0:15");
            timerange_invalid(assert, "23:45+0:16");
            timerange_valid(assert, "0+0");
        });

    };

});

