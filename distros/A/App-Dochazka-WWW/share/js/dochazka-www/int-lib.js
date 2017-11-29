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
        createIntervalCheckMandatoryProps = function (obj) {
            var actObj;
            // check that all mandatory properties are present
            if (! obj.iNdate) {
                stack.restart(undefined, {
                    "resultLine": "Interval date missing"
                });
                return false;
            }
            if (! obj.code) {
                stack.restart(undefined, {
                    "resultLine": "Interval activity code missing"
                });
                return false;
            }
            if (! obj.aid) {
                console.log("Looking up activity " + obj.code + " in cache");
                actObj = appCaches.getActivityByCode(obj.code);
                if (! actObj) {
                    stack.restart(undefined, {
                        "resultLine": 'Activity ' + obj.code + ' not found'
                    });
                    return false;
                }
                obj.aid = actObj.aid;
            }
            if (! obj.iNtimerange) {
                stack.restart(undefined, {
                    "resultLine": "Interval time range missing"
                });
                return false;
            }
            return true;
        },

        createMultipleIntSave = function (obj) {
            var cu = currentUser('obj'),
                daylist = $('input[id="iNdaylist"]').val(),
                month = $('input[id="iNmonth"]').val(),
                year = $('input[id="iNyear"]').val(),
                dl = daylist.split(','),
                i, rest, sc, fc;
            // validate activity
            if (obj.code) {
                console.log("Looking up activity " + obj.code + " in cache");
                i = appCaches.getActivityByCode(obj.code);
                if (! i) {
                    coreLib.displayError('Activity ' + obj.code + ' not found');
                    return null;
                }
                obj.aid = i.aid;
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

        createSingleIntMenuItem = function (obj) {
            stack.push('createSingleInt');
        },

        createSingleIntSave = function (obj) {
            var caller = stack.getTarget().name,
                cu = currentUser('obj'),
                rest,
                sc = function (st) {
                    if (caller === 'createSingleIntFixedDay') {
                        stack.unwindToTarget('viewIntervalsAction');
                    } else {
                        stack.unwindToTarget(
                            'createSingleInt',
                            emptyObj,
                            {
                                "resultLine": "Interval " + st.payload.iid + " created",
                                "inputId": "iNdate",
                            }
                        );
                    }
                };
            console.log("Entering createSingleIntSave() from caller " + caller + " with obj", obj);
            if (caller === 'createSingleInt' || caller === 'createSingleIntFixedDay') {
                // obj already populated
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
                obj.code = $('input[id="iNact"]').val();
                obj.long_desc = $('input[id="iNdesc"]').val();
            } else {
                console.log("CRITICAL ERROR: unexpected caller", caller);
                return null;
            }
            if (obj.iNtimerange === '+') {
                stack.push('createNextScheduled', obj);
                return null;
            }
            if (obj.iNtimerange.match(/\+/)) {
                obj.iNoffset = obj.iNtimerange;
                stack.push('createLastPlusOffset', obj);
                return null;
            }
            if (! createIntervalCheckMandatoryProps(obj)) {
                return null;
            }
            obj["intvl"] = genIntvl(obj.iNdate, obj.iNtimerange);
            if (! obj.intvl) {
                return null;
            }
            rest = {
                "method": 'POST',
                "path": 'interval/new',
                "body": {
                    "eid": cu.eid,
                    "aid": obj.aid,
                    "intvl": obj.intvl,
                    "long_desc": obj.long_desc,
                    "remark": null,
                },
            }
            ajax(rest, sc);
        },

        deleteSingleInt = function (obj) {
            var rest = {
                    "method": "DELETE",
                    "path": "interval/iid/" + obj.iid,
                },
                sc = function (st) {
                    if (st.code === 'DOCHAZKA_CUD_OK') {
                        stack.unwindToTarget('viewIntervalsAction');
                    } else {
                        coreLib.displayError(st.text);
                    }
                };
            console.log("Entering deleteSingleInt() with obj", obj);
            ajax(rest, sc);
        },

        emptyObj = {
            "iNdate": "",
            "iNtimerange": "",
            "code": "",
            "long_desc": ""
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

        updateSingleIntSave = function (obj) {
            var caller = stack.getTarget().name,
                cu = currentUser('obj'),
                rest,
                sc = function (st) {
                    // FIXME: update the interval inside the drowselect state
                    // var pos = coreLib.drowselectState.pos,
                    //     set = coreLib.drowselectState.set.slice();
                    // set[pos] = st.payload;
                    stack.unwindToTarget('viewIntervalsAction');
                };
            console.log("Entering updateSingleIntSave() from caller " + caller + " with obj", obj);
            if (caller === 'updateSingleInt') {
                // obj is scraped by start.js from the form inputs and will look
                // like this:
                // {
                //     iNdate: "foo bar in a box",
                //     iNtimerange: "25:00-27:00",
                //     code: "LOITERING",
                //     iid: 148
                //     long_desc: "none",
                // }
                // any of the above properties may be present or missing
                // also, there may or may not be an acTaid property with the AID of
                // the chosen activity
            } else {
                console.log("CRITICAL ERROR: unexpected caller", caller);
                return null;
            }
            if (! createIntervalCheckMandatoryProps(obj)) {
                return null;
            }
            obj["intvl"] = genIntvl(obj.iNdate, obj.iNtimerange);
            if (! obj.intvl) {
                return null;
            }
            rest = {
                "method": 'PUT',
                "path": 'interval/iid/' + obj.iid,
                "body": {
                    "eid": cu.eid,
                    "aid": obj.acTaid,
                    "intvl": obj.intvl,
                    "long_desc": obj.long_desc,
                },
            }
            ajax(rest, sc);
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

        viewIntervalsActionCache = function () {
            // 0 == begin; 1 == end
            var i, frm = [], res;
            frm[0] = coreLib.nullify($("#iNdaterangeBegin").text()); 
            frm[1] = coreLib.nullify($("#iNdaterangeEnd").text()); 
            for (i = 0; i < 2; i += 1) {
                if (frm[i]) {
                    viewIntervalsCache[i] = frm[i];
                } else {
                    frm[i] = viewIntervalsCache[i];
                }
            }
            // console.log("viewIntervalsActionCache() returning", frm);
            return frm;
        },
        viewIntervalsAction = function () {
            // scrape begin and end dates from form
            // call GET interval/eid/:eid/:tsrange
            // viewIntervalsDrowselect on the resulting object
            var arr, 
                begin,
                cu = currentUser('obj'),
                end,
                firstDate,
                i,
                multipleDates,
                obj,
                opts,
                rest,
                sc = function (st) {
                    var ld;
                    if (st.code === 'DISPATCH_RECORDS_FOUND' ) {
                        opts = { "resultLine": st.count + " intervals found" };
                        // convert intvl to iNdate and iNtimerange
                        for (i = 0; i < st.payload.length; i += 1) {
                            arr = dt.tsrangeToDateAndTimeRange(st.payload[i].intvl);
                            st.payload[i].iNdate = arr[0];
                            if (i === 0) {
                                firstDate = arr[0];  // first date in result set
                            }
                            st.payload[i].iNtimerange = arr[1];
                        }
                        opts['xtarget'] = 'viewIntervalsPrep'; // so we don't land in viewIntervalsAction
                        if (multipleDates) {
                            obj = {
                                "beginDate": begin,
                                "endDate": end,
                                "intervals": st.payload,
                            };
                            stack.push('multiDayViewer', obj, opts);
                        } else {
                            for (i = 0; i < st.payload.length; i += 1) {
                                ld = st.payload[i].long_desc ? st.payload[i].long_desc : "";
                                st.payload[i].long_desc = ld.slice(0, 30);
                            }
                            stack.push('viewIntervalsDrowselect', {
                                'pos': 0,
                                'set': st.payload
                            }, opts);
                        }
                    } else {
                        coreLib.displayError(st.code + ": " + st.text);
                    }
                },
                fc = function (st) {
                    var opts = { "resultLine": st.payload.message };
                    if (st.code === 'DISPATCH_NOTHING_IN_TSRANGE' ) {
                        if (multipleDates) {
                            opts['xtarget'] = 'viewIntervalsPrep'; // so we don't land in viewIntervalsAction
                            obj = {
                                "beginDate": begin,
                                "endDate": end,
                                "intervals": [],
                            };
                            stack.push('multiDayViewer', obj, opts);
                        } else {
                            stack.pop(undefined, opts);
                        }
                    } else {
                        opts.resultLine += ' (unexpected status code ' + st.code + ')';
                        stack.pop(undefined, opts);
                    }
                };
            [begin, end] = viewIntervalsActionCache();
            multipleDates = (begin === end) ? false : true;
            rest = {
                "method": 'GET',
                "path": 'interval/eid/' + cu.eid + "/[" + String(begin) + " 00:00, " + String(end) + " 24:00 )",
            };
            ajax(rest, sc, fc);
        },
        viewIntervalsCache = [],

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
        createSingleIntMenuItem: createSingleIntMenuItem,
        createSingleIntSave: createSingleIntSave,
        deleteSingleInt: deleteSingleInt,
        vetDayList: vetDayList,
        vetDayRange: vetDayRange,
        updateSingleIntSave: updateSingleIntSave,
        viewIntervalsAction: viewIntervalsAction,
        viewIntervalsMultiDayCallback: viewIntervalsMultiDayCallback,
        viewIntervalsMultiDayCallbackRaw: viewIntervalsMultiDayCallbackRaw,
    };

});
