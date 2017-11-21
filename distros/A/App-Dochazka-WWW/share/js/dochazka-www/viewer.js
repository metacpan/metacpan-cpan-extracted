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
// app/viewer.js
//
// =========================
// Multi-day interval viewer
// =========================
//
// Given a multi-day interval object, trigger AJAX call "GET holiday/:tsrange"
// where tsrange is [ "beginDate 00:00", "endDate 23:59" ) - which will include
// all dates in the interval range and allow us to determine which ones are
// weekends/holidays and which are not.
//
// In the success function of that AJAX call, populate the haw ("holidays and
// weekends") object from the AJAX payload. A function "isHolidayOrWeekend()"
// will be implemented, which will take a date string, canonicalize it, and
// look it up in the "haw" lookup object, and return true or false as
// appropriate.
//
// Next, the intervals-to-be-viewed array will be processed. First, to each
// date in haw, add an "intervals" array that will be empty at first. Second,
// iterate over all the intervals-to-be-viewed and push them into the respective
// "intervals" array in haw. At the same time, convert the time range string
// (e.g. "08:00-08:10") into a startTime-duration object (e.g. { "startTime":
// "08:00", "duration": "10" } where "duration" is always in minutes.
//
// Now, haw contains all information needed to draw the canvases.
//
// Iterate over haw, creating canvases. The first and last canvases created
// should be scale canvases.  When a non-holiday/weekend date is detected
// immediately following a holiday/weekend date (that means Monday), insert a
// scale canvas unless it is the first or last date in haw. Populate the 
// scale canvases with scales.
//
// Iterate over haw again, populating the date canvases with attendance
// intervals. For each interval, get the full activity object using
// appCaches.getActivityByAID() and obtain the color from the "color" property.
// 
// Iterate over haw one last time, to draw dates.  Draw holiday/weekend dates
// using strokeText, and the rest using fillText.
//
// At the end, draw a legend linking the colors to activity codes and writing
// the total number of hours associated with each activity code.
//
//

"use strict";

define ([
    "jquery",
    "app/caches",
    "app/svg-lib",
    "ajax",
    "current-user",
    "datetime",
], function (
    $,
    appCaches,
    svgLib,
    ajax,
    currentUser,
    dt,
)
{

    var haw,
        sortedDates,

        entryPoint = function (obj) {
            // generate viewer HTML
            var cu = currentUser('obj'),
                date,
                i,
                r = '',
                lwhow = false;
            console.log("currentUserObject", cu);
            if (cu.fullname) {
                r += '<b>' + cu.fullname + '</b>';
            } else {
                r += '<b>' + cu.nick + '</b>';
            }
            r += '<br><br>';
            r += "Intervals (scheduled and clocked) during period from " + obj.beginDate + " to " + obj.endDate;
            r += '<br><br>';
            r += svgLib.dayViewerScale();
            for (i = 0; i < sortedDates.length; i += 1) {
                // draw a new scale, if needed, for each week, more or less
                date = sortedDates[i];
                if (lwhow && ! holidayOrWeekend(date) && i !== sortedDates.length - 1) {
                    r += svgLib.dayViewerScale();
                }
                lwhow = holidayOrWeekend(date);
                r += svgLib.dayViewerIntervals(date, haw[date], lwhow);
            }
            r += svgLib.dayViewerScale();
            return r;
        },

        addScheduledIntervals = function (obj) {
            var cu = currentUser('obj'),
                i,
                tsr = '[ ' + obj.beginDate + ' 00:00, ' + obj.endDate + ' 24:00 )',
                date, tr,
                scheduledIntervals,
                rest = {
                    "method": "POST",
                    "path": "interval/scheduled",
                    "body": {
                        "eid": cu.eid,
                        "tsrange": tsr,
                    },
                },
                sc = function (st) {
                    if (st.code === 'DISPATCH_SCHEDULED_INTERVALS_IDENTIFIED') {
                        scheduledIntervals = st.payload.success.intervals;
                        for (i = 0; i < scheduledIntervals.length; i += 1) {
                            [date, tr] = dt.tsrangeToDateAndTimeRange(scheduledIntervals[i].intvl);
                            haw[date].scheduled.push(tr);
                        }
                    } else if (st.code === 'DISPATCH_NO_SCHEDULED_INTERVALS_IDENTIFIED') {
                        // do nothing, for the time being
                    } else {
                        console.log("CRITICAL ERROR: unexpected \"interval/scheduled\" status code " + st.code);
                    }
                    $('#dcallback').html(entryPoint(obj));
                };
            ajax(rest, sc);
            return null;
        },

        holidayOrWeekend = function (d) {
            var rv = false;
            // returns true if a given date is a holiday or weekend
            if (haw.hasOwnProperty(d)) {
                if (haw[d].hasOwnProperty('holiday') && haw[d].holiday) {
                    rv = true;
                }
                if (haw[d].hasOwnProperty('weekend') && haw[d].weekend) {
                    rv = true;
                }
            } else {
                console.log("CRITICAL ERROR: haw lookup failed (unexpectedly) for key " + d);
            }
            return rv;
        },

        initializeStore = function (pl) {
            // by "Store" here, I mean "haw" and "sortedDates"
            var date, i;
            haw = $.extend({}, pl);
            sortedDates = Object.keys(haw).sort();
            for (i = 0; i < sortedDates.length; i += 1) {
                date = sortedDates[i];
                if (! haw[date].hasOwnProperty('scheduled')) {
                    haw[date].scheduled = [];
                }
                if (! haw[date].hasOwnProperty('clocked')) {
                    haw[date].clocked = [];
                }
            }
        }
        ;

    return {

        'multiDayViewer': function (obj) {
            var i,
                tsr = '[ ' + obj.beginDate + ' 00:00, ' + obj.endDate + ' 23:59 )',
                date, tr, aid,
                rest = {
                    "method": "GET",
                    "path": "holiday/" + tsr,
                },
                sc = function (st) {
                    if (st.code === 'DOCHAZKA_HOLIDAYS_AND_WEEKENDS_IN_TSRANGE') {
                        initializeStore(st.payload);
                        for (i = 0; i < obj.intervals.length; i += 1) {
                            aid = obj.intervals[i].aid;
                            [date, tr] = [obj.intervals[i].iNdate, obj.intervals[i].iNtimerange];
                            haw[date].clocked.push({"iNtimerange": tr, "aid": aid});
                        }
                        addScheduledIntervals(obj);
                    } else {
                        console.log("CRITICAL ERROR: unexpected holidays status code " + st.code);
                    }
                };
            ajax(rest, sc);
            return null;
        },

    };
    
});
