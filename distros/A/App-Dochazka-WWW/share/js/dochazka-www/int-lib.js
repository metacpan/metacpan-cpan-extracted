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
// app/int-lib.js
//
"use strict";

define ([
    'jquery',
    'ajax',
    'app/act-lib',
    'current-user',
    'datetime',
    'lib',
    'stack',
], function (
    $,
    ajax,
    actLib,
    currentUser,
    datetime,
    coreLib,
    stack,
) {

    var
        emptyObj = {
            "iNdate": "",
            "iNtimerange": "",
            "iNact": "",
            "iNdesc": ""
        },

        genIntvl = function (date, timerange) {
            var ctr = datetime.canonicalizeTimeRange(timerange);
            if (ctr === null) {
                coreLib.displayError('Time range ->' + timerange + '<- is invalid');
                stack.restart();
            } else {
                return '[ "' +
                       date +
                       ' ' +
                       ctr[0] +
                       '", "' +
                       date +
                       ' ' +
                       ctr[1] +
                       '" )';
            }
        },

        intervalNewREST = {
            "method": 'POST',
            "path": 'interval/new'
        };

    // here is where we define methods implementing the various
    // interval-related actions (see daction-start.js)
    return {

        createLastPlusOffsetSave: function (obj) {
        },

        createNextScheduledSave: function (obj) {
        },

        createSingleIntSave: function (obj) {
            // obj will look like this:
            // {
            //     iNdate: "foo bar in a box",
            //     iNtimerange: "25:00-27:00",
            //     iNact: "LOITERING",
            //     iNdesc: "none",
            //     mm: true
            // }
            // any of the above properties may be present or missing
            // also, there may or may not be an acTaid property with the AID of
            // the chosen activity
            console.log("createSingleIntSave called with obj", obj);
            var cu = currentUser('obj'),
                sc = function (st) {
                    console.log("AJAX: " + rest["method"] + " " + rest["path"] + " returned", st);
                    stack.restart(
                        emptyObj,
                        {
                            "resultLine": "Interval " + st.payload.iid + " created",
                            "inputId": "iNdate",
                        }
                    );
                },
                fc = function (st) {
                    console.log("AJAX: " + rest["method"] + " " + rest["path"] + " failed", st);
                    stack.restart(undefined, { "resultLine": st.payload.message });
                };

            // check that all mandatory properties are present
            if (! obj.hasOwnProperty('iNdate')) {
                stack.restart(undefined, { "resultLine": "Interval date missing" });
            }
            if (obj.iNdate.length === 0) {
                stack.restart(undefined, { "resultLine": "Interval date missing" });
            }

            if (! obj.hasOwnProperty('iNtimerange')) {
                stack.restart(undefined, { "resultLine": "Interval time range missing" });
            }
            if (obj.iNtimerange.length === 0) {
                stack.restart(undefined, { "resultLine": "Interval time range missing" });
            }

            if (! obj.hasOwnProperty('iNact')) {
                stack.restart(undefined, { "resultLine": "Interval activity code missing" });
            }
            if (obj.iNact.length === 0) {
                stack.restart(undefined, { "resultLine": "Interval activity code missing" });
            }
            if (! obj.hasOwnProperty('acTaid')) {
                console.log("Looking up activity " + obj.iNact + " in cache");
                obj.acTaid = actLib.getActByCode(obj.iNact).aid;
                if (! obj.acTaid) {
                    stack.restart(undefined, { "resultLine": 'Activity ' + obj.iNact + ' not found' });
                }
            }

            intervalNewREST.body = {
                "eid": cu.eid,
                "aid": obj.acTaid,
                "long_desc": obj.iNdesc,
                "remark": null,
            }
            if (obj.iNtimerange === '+') {
                stack.push('createNextScheduled', obj);
            } else if (obj.iNtimerange.match(/\+/)) {
                stack.push('createLastPlusOffset', obj);
            } else {
                intervalNewREST.body["intvl"] = genIntvl(obj.iNdate, obj.iNtimerange);
                ajax(intervalNewREST, sc, fc);
            }
        },

    };

});
