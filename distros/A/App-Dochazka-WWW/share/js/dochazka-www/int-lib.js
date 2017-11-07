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
    'app/caches',
    'current-user',
    'datetime',
    'lib',
    'stack',
], function (
    $,
    ajax,
    appCaches,
    currentUser,
    dt,
    coreLib,
    stack,
) {

    var
        createMultipleIntSave = function (obj) {
            var cu = currentUser('obj'),
                daylist = $('input[id="iNdaylist"]').val(),
                month = $('input[id="iNmonth"]').val(),
                year = $('input[id="iNyear"]').val(),
                dl = daylist.split(','),
                i, rest, sc, fc;
            // validate activity
            if (obj.iNact) {
                console.log("Looking up activity " + obj.iNact + " in cache");
                i = appCaches.getActivityByCode(obj.iNact);
                if (! i) {
                    coreLib.displayError('Activity ' + obj.iNact + ' not found');
                    return null;
                }
                obj.acTaid = i.aid;
            } else {
                coreLib.displayError("Interval activity code missing");
                return null;
            }
            // validate day list
            if (! coreLib.isArray(dl) || dl.length === 0) {
                coreLib.displayError("Invalid day list");
                return null;
            }
            for (i = 0; i < dl.length; i += 1) {
                dl[i] = year + '-' + dt.monthToInt(month) + '-' + dl[i];
            }
            console.log("Date list", dl);
            rest = {
                "method": "POST",
                "path": "interval/fillup",
                "body": {
                    'date_list': dl,
                    'dry_run': '0',
                    'eid': String(cu.eid),
                    'aid': obj.acTaid,
                },
            };
            sc = function (st) {
                if (st.code === "DISPATCH_FILLUP_INTERVALS_CREATED") {
                    coreLib.displayResult(
                        st.payload.success.intervals.length + " intervals created; " +
                        st.payload.failure.intervals.length + " intervals failed"
                    );
                } else if (st.code === "DISPATCH_FILLUP_NO_INTERVALS_CREATED") {
                    coreLib.displayResult("The dates in question already have 100% schedule fulfillment");
                } else {
                    coreLib.displayError(st.text);
                }
            };
            ajax(rest, sc);
        },

        createSingleIntSave = function (obj) {
            var caller = stack.getTarget().name,
                cu = currentUser('obj'),
                m,
                sc = function (st) {
                    stack.unwindToTarget(
                        'createSingleInt',
                        emptyObj,
                        {
                            "resultLine": "Interval " + st.payload.iid + " created",
                            "inputId": "iNdate",
                        }
                    );
                },
                fc = function (st) {
                    // stack.restart(undefined, {
                    //     "resultLine": st.payload.message,
                    // });
                    coreLib.displayError(st.payload.message);
                };
            if (caller === 'createSingleInt') {
                // obj is scraped by start.js from the form inputs and will look
                // like this:
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
            } else if (caller === 'createLastPlusOffset' || caller === 'createNextScheduled') {
                // Scrape time range from form
                // (The "createLastPlusOffset" dform has no inputs (writable
                // entries); instead, it has spans (read-only entries) that are
                // populated asynchronously and obj does not contain any of
                // the new values. In this case, the time range is residing
                // in one of the spans.)
                // Scrape time range from form
                obj.iNdate = $('input[id="iNdate"]').val();
                obj.iNtimerange = $('input[id="iNtimerange"]').val();
                obj.iNact = $('input[id="iNact"]').val();
                obj.iNdesc = $('input[id="iNdesc"]').val();
            } else {
                console.log("CRITICAL ERROR: unexpected caller", caller);
                return null;
            }
            console.log("Entering createSingleIntSave() with obj", obj);

            // check that all mandatory properties are present
            if (! obj.iNdate) {
                stack.restart(undefined, {
                    "resultLine": "Interval date missing"
                });
                return null;
            }
            if (! obj.iNact) {
                stack.restart(undefined, {
                    "resultLine": "Interval activity code missing"
                });
                return null;
            }
            if (! obj.acTaid) {
                console.log("Looking up activity " + obj.iNact + " in cache");
                m = appCaches.getActivityByCode(obj.iNact);
                if (! m) {
                    stack.restart(undefined, {
                        "resultLine": 'Activity ' + obj.iNact + ' not found'
                    });
                    return null;
                }
                obj.acTaid = m.aid;
            }
            if (! obj.iNtimerange) {
                stack.restart(undefined, {
                    "resultLine": "Interval time range missing"
                });
                return null;
            }

            intervalNewREST.body = {
                "eid": cu.eid,
                "aid": obj.acTaid,
                "long_desc": obj.iNdesc,
                "remark": null,
            }
            if (obj.iNtimerange === '+') {
                stack.push('createNextScheduled', obj);
                return null;
            } else if (obj.iNtimerange.match(/\+/)) {
                obj.iNoffset = obj.iNtimerange;
                stack.push('createLastPlusOffset', obj);
                return null;
            } else if (obj.iNtimerange) {
                intervalNewREST.body["intvl"] = genIntvl(obj.iNdate, obj.iNtimerange);
                if (! intervalNewREST.body["intvl"]) {
                    return null;
                }
            } else {
                console.log("CRITICAL ERROR in createSingleIntSave: nothing to save!"); 
                return null;
            }
            ajax(intervalNewREST, sc, fc);
        },

        emptyObj = {
            "iNdate": "",
            "iNtimerange": "",
            "iNact": "",
            "iNdesc": ""
        },

        genIntvl = function (date, timerange) {
            var ctr = dt.canonicalizeTimeRange(timerange),
                m;
            if (ctr === null) {
                m = 'Time range ->' + timerange + '<- is invalid';
                console.log(m);
                stack.restart(undefined, {
                    "resultLine": m
                });
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
        },

        vetDayList = function (dl, testing) {
            var buf, daylist,
                month = $('input[id="iNmonth"]').val(),
                year = $('input[id="iNyear"]').val(),
                tokens = String(dl).trim().replace(/\s/g, '').split(',');
            console.log("Entering vetDayList() with tokens", tokens, month);
            if (! coreLib.isInteger(year)) {
                year = dt.currentYear();
                $('input[id="iNyear"]').val(year);
            }
            if (! month) {
                month = dt.currentMonth();
                $('input[id="iNmonth"]').val(month);
            }
            if (! coreLib.isArray(tokens) || (tokens.length === 1 && tokens[0] === "")) {
                tokens = ["1-" + dt.daysInMonth(year, month)];
            }
            daylist = dt.vetDayList(tokens);
            if (daylist.length > 0) {
                // populate hidden entries with begin and end of date range
                $('#iNdaterangeBegin').html(year + "-" + dt.monthToInt(month) + "-" + daylist[0]);
                $('#iNdaterangeEnd').html(year + "-" + dt.monthToInt(month) + "-" + daylist[daylist.length - 1]);
                buf = daylist.join(',');
                $('input[id=iNdaylist]').val(buf);
                return buf;
            } else {
                return null;
            }
        },

        vetDayRange = function (dl, testing) {
            var buf, dayrange,
                month = $('input[id="iNmonth"]').val(),
                year = $('input[id="iNyear"]').val(),
                rangeBegin, rangeEnd,
                tokens = String(dl).trim().replace(/\s/g, '').split(','),
                t;
            console.log("Entering vetDayRange() with tokens", tokens, month);
            if (! coreLib.isInteger(year)) {
                year = dt.currentYear();
                $('input[id="iNyear"]').val(year);
            }
            if (! month) {
                month = dt.currentMonth();
                $('input[id="iNmonth"]').val(month);
            }
            if (! coreLib.isArray(tokens) || (tokens.length === 1 && tokens[0] === "")) {
                tokens = ["1-" + dt.daysInMonth(year, month)];
            }
            if (tokens.length === 1) {
                t = tokens[0];
                // t is either a number or a range: if it's a number, push it 
                // to daylist. If it's a range, push each range member.
                if (t.indexOf('-') === -1) {
                    if (! coreLib.isInteger(t) || t < 1 || t > 31) {
                        console.log("Ignoring non-numeric dayspec " + t);
                        return null;
                    }
                    $('#iNdaterangeBegin').html(year + "-" + dt.monthToInt(month) + "-" + t);
                    $('#iNdaterangeEnd').html(year + "-" + dt.monthToInt(month) + "-" + t);
                } else {
                    [rangeBegin, rangeEnd] = t.split('-');
                    rangeBegin = parseInt(rangeBegin, 10);
                    rangeEnd = parseInt(rangeEnd, 10);
                    if (! coreLib.isInteger(rangeBegin) || ! coreLib.isInteger(rangeEnd) ||
                        rangeBegin < 1 || rangeBegin > 31 ||
                        rangeEnd < 1 || rangeEnd > 31 ||
                        rangeBegin > rangeEnd) {
                        console.log("Ignoring invalid day range ->" + t + "<-");
                        return null;
                    }
                    // console.log("Encountered range from " + rangeBegin + " to " + rangeEnd);
                    $('#iNdaterangeBegin').html(year + "-" + dt.monthToInt(month) + "-" + rangeBegin);
                    $('#iNdaterangeEnd').html(year + "-" + dt.monthToInt(month) + "-" + rangeEnd);
                }
                return t;
            }
            return null;
        },

        viewIntervalsAction = function () {
            // scrape begin and end dates from form
            // call GET interval/eid/:eid/:tsrange
            // viewIntervalsDtable on the resulting object
            var begin = $("#iNdaterangeBegin").text(),
                arr, obj,
                cu = currentUser('obj'),
                end = $("#iNdaterangeEnd").text(),
                firstDate,
                i,
                multipleDates,
                opts,
                tsr = "[ " + begin + " 00:00, " + end + " 24:00 )",
                rest = {
                    "method": 'GET',
                    "path": 'interval/eid/' + cu.eid + "/" + tsr,
                },
                sc = function (st) {
                    if (st.code === 'DISPATCH_RECORDS_FOUND' ) {
                        opts = { "resultLine": st.count + " intervals found" };
                        // convert intvl to iNdate and iNtimerange
                        multipleDates = false;
                        for (i = 0; i < st.payload.length; i += 1) {
                            arr = dt.tsrangeToDateAndTimeRange(st.payload[i].intvl);
                            st.payload[i].iNdate = arr[0];
                            if (i === 0) {
                                firstDate = arr[0];  // first date in result set
                            }
                            if (arr[0] !== firstDate) {
                                multipleDates = true; // multiple dates in result set
                            }
                            st.payload[i].iNtimerange = arr[1];
                        }
                        if (multipleDates) {
                            obj = {
                                "beginDate": begin,
                                "endDate": end,
                                "intervals": st.payload,
                            };
                            stack.push('multiDayViewer', obj, opts);
                        } else {
                            stack.push('viewIntervalsDtable', st.payload, opts);
                        }
                    } else if (st.code === 'DISPATCH_NO_RECORDS_FOUND' ) {
                        coreLib.displayError(st.code + ": " + st.text);
                    } else {
                        coreLib.displayError(st.code + ": " + st.text);
                    }
                };
            ajax(rest, sc);
        },

        viewIntervalsMultiDayCallback = function (obj, title, preamble) {
            var i, r = '';
            preamble = preamble
                         .replace(/\[BEGIN\]/, obj.beginDate)
                         .replace(/\[END\]/, obj.endDate);
            r += "<b>" + title + "</b><br><br>";
            r += preamble + "<br><br>";
            return r;
        },

        viewIntervalsMultiDayCallbackRaw = function (obj) {
            var r = '';
            r += "<pre>";
            if (typeof obj === 'object') {
                r += JSON.stringify(obj, null, 2);
            } else if (typeof obj === 'string') {
                r += obj;
            } else {
                console.log("viewIntervalsMultiDayCallbackRaw(): CRITICAL ERROR: bad object", obj);
                r += 'ERROR<br>';
            }
            r += "</pre><br>";
            return r;
        }
        ;

    // here is where we define methods implementing the various
    // interval-related actions (see daction-start.js)
    return {
        createMultipleIntSave: createMultipleIntSave,
        createSingleIntSave: createSingleIntSave,
        vetDayList: vetDayList,
        vetDayRange: vetDayRange,
        viewIntervalsAction: viewIntervalsAction,
        viewIntervalsMultiDayCallback: viewIntervalsMultiDayCallback,
        viewIntervalsMultiDayCallbackRaw: viewIntervalsMultiDayCallbackRaw,
    };

});
