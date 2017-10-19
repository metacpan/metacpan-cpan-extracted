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
// datetime.js
//
// Area for code that works with dates and times
//
"use strict";

define ([
    "lib",
], function (
    coreLib,
) {

    var //today = Object.create(Date.prototype),
        today = new Date(),

        addMinutes = function (date, minutes) {
            return new Date(date.getTime() + minutes*60000);
        },

        canonicalizeTime = function (rt) {
            // assume rt ("raw time") is a string with format "h[:m]" where h and
            // m are integers
            console.log("Entering canonicalizeTime() with argument", rt);

            var h,
                i,
                m,
                ct = [],
                rts = String(rt).split(":");

            if (rts.length < 1 || rts.length > 2) {
                return null;
            }
            if (rts.length === 1) {
                rts.push("0");
            }
            for (i = 0; i < 2; i += 1) {
                if (rts[i] === "") {
                    rts[i] = "0";
                }
            }
            if (!coreLib.isInteger(rts[0]) || !coreLib.isInteger(rts[1])) {
                return null;
            }
            h = parseInt(rts[0], 10);
            m = parseInt(rts[1], 10);
            if (h < 0 || h > 24) {
                return null;
            }
            if (m < 0 || m > 59) {
                return null;
            }
            if (h === 24 && m !== 0) {
                return null;
            }
            // assemble canonicalized time string; left-pad with zero if necessary
            ct[0] = h;
            ct[1] = m;
            for (i = 0; i < 2; i += 1) {
                if (ct[i] < 10) {
                    ct[i] = "0" + String(ct[i]);
                } else {
                    ct[i] = String(ct[i]);
                }
            }
            return ct[0] + ":" + ct[1];
        },

        canonicalizeTimeRange = function (tr) {
            console.log("Entering canonicalizeTimeRange() with argument", tr);
            var ttr = String(tr).trim().replace(/\s/g, '');
            if (ttr.match(/^\d*:{0,1}\d*-\d*:{0,1}\d*$/)) {
                console.log(tr + " is a standard time range");
                return canonicalizeTimeRangeStandard(ttr);
            } else if (ttr.match(/^\d+:{0,1}\d*[+]\d+:{0,1}\d*/)) {
                console.log(tr + " is an offset time range");
                return canonicalizeTimeRangeOffset(ttr);
            }
            return null;
        },

        canonicalizeTimeRangeOffset = function (tr) {
            console.log("Entering canonicalizeTimeRangeOffset() with argument", tr);
            // on success, returns e.g. ["06:00", "07:30"]
            // on failure, returns null
            var i,
                ttrs = tr.split('+'),
                ftr = [],
                buf = [],
                baseMinutes,
                offsetMinutes;

            if (ttrs.length !== 2) {
                return null;
            }
            for (i = 0; i < 2; i += 1) {
                ftr[i] = canonicalizeTime(ttrs[i]);
                if (ftr[i] === null) {
                    return null;
                }
            }
            console.log("Canonicalized base time: " + ftr[0]);
            console.log("Canonicalized offset: " + ftr[1]);
            baseMinutes = timeToMinutes(ftr[0]);
            offsetMinutes = timeToMinutes(ftr[1]);
            console.log("Base minutes: " + baseMinutes);
            console.log("Base minutes: " + offsetMinutes);
            if (baseMinutes === null || offsetMinutes === null) {
                console.log("CRITICAL ERROR: problem with timeToMinutes", ftr);
                return null;
            }
            ftr[1] = minutesToTime(baseMinutes + offsetMinutes);
            if (ftr[1] === null) {
                return null;
            }
            return ftr;
        },

        canonicalizeTimeRangeStandard = function (tr) {
            // on success, returns e.g. ["06:00", "07:30"]
            // on failure, returns null
            var i,
                ttrs = tr.split('-'),
                ftr = [];

            if (ttrs.length !== 2) {
                return null;
            }
            for (i = 0; i < 2; i += 1) {
                ftr[i] = canonicalizeTime(ttrs[i]);
                if (ftr[i] === null) {
                    return null;
                }
            }

            return ftr;
        },

        intToMonth = function (m) {
            // if 1 <= m <= 12, return three-letter string signifying the month
            // otherwise, return null
            console.log("Entering intToMonth() with argument", m);
            var m = parseInt(m, 10),
                month = null;
            if (m === 1) {
                month = "JAN";
            } else if (m === 2) {
                month = "FEB";
            } else if (m === 3) {
                month = "MAR";
            } else if (m === 4) {
                month = "APR";
            } else if (m === 5) {
                month = "MAY";
            } else if (m === 6) {
                month = "JUN";
            } else if (m === 7) {
                month = "JUL";
            } else if (m === 8) {
                month = "AUG";
            } else if (m === 9) {
                month = "SEP";
            } else if (m === 10) {
                month = "OCT";
            } else if (m === 11) {
                month = "NOV";
            } else if (m === 12) {
                month = "DEC";
            }
            return month;
        }, // intToMonth

        minutesToTime = function (m) {
            console.log("Entering minutesToTime() with argument", m);
            var quotient,
                remainder;
            if (m < 0 || m > 1440) {
                return null;
            }
            quotient = String(Math.floor(m/60));
            remainder = String(m % 60);
            console.log("Quotient is", quotient);
            console.log("Remainder is", remainder);
            return canonicalizeTime(quotient + ":" + remainder);
        },

        strToMonth = function (buf) {
            console.log("Entering strToMonth() with argument", buf);
            var m = String(buf).toLowerCase().slice(0, 3),
                month = null;
            if (m.length < 3) {
                return null;
            }
            if (m === 'jan') {
                month = "JAN";
            } else if (m === 'feb') {
                month = "FEB";
            } else if (m === 'mar') {
                month = "MAR";
            } else if (m === 'apr') {
                month = "APR";
            } else if (m === 'may') {
                month = "MAY";
            } else if (m === 'jun') {
                month = "JUN";
            } else if (m === 'jul') {
                month = "JUL";
            } else if (m === 'aug') {
                month = "AUG";
            } else if (m === 'sep') {
                month = "SEP";
            } else if (m === 'oct') {
                month = "OCT";
            } else if (m === 'nov') {
                month = "NOV";
            } else if (m === 'dec') {
                month = "DEC";
            }
            return month;
        }, // strToMonth

        timeToMinutes = function (ts) {
            // convert a canonicalized time string into minutes
            var buf = String(ts).split(':');
            if (buf.length !== 2) {
                return null;
            }
            buf[0] = parseInt(buf[0], 10);
            if (buf[0] > 24) {
                return null;
            }
            buf[1] = parseInt(buf[1], 10);
            if (buf[1] > 59) {
                return null;
            }
            return buf[0] * 60 + buf[1];
        },

        vetDateYYYYMMDD = function (ds) {
            console.log("Entering vetDateYYYYMMDD() with argument", ds);
            var y = parseInt(ds[0], 10),
                m = ds[1],
                d = parseInt(ds[2], 10),
                month;
            if (!coreLib.isInteger(y) || !coreLib.isInteger(d)) {
                console.log("Non-integer year or day-of-month");
                return null;
            }
            if (y < 0 || d < 0) {
                console.log("Negative year or day-of-month");
                return null;
            }
            if (y > 0 && y < 32) {
                d = parseInt(ds[0], 10);
                y = parseInt(ds[2], 10);
            }
            if (y < 1800 || y > 9999) {
                console.log("Year out of range");
                return null;
            }
            if (coreLib.isInteger(m)) {
                if (m < 1 || m > 12) {
                    console.log("Month out of range");
                    return null;
                }
                month = intToMonth(m);
            } else {
                month = strToMonth(String(m));
                if (month === null) {
                    return null;
                }
            }
            if (!coreLib.isInteger(d) || d < 1 || d > 31) {
                console.log("Day-of-month out of range");
                return null;
            }
            return String(y) + 
                   '-' +
                   month +
                   '-' +
                   String(d);
        }, // vetDateYYYYMMDD

        vetDateMMDD = function (ds) {
            console.log("Entering vetDateMMDD() with argument", ds);
            var ds0 = ds[0],
                ds1 = ds[1];
            if (coreLib.isInteger(ds[0]) && coreLib.isInteger(ds[1])) {
                ds0 = parseInt(ds0, 10);
                ds1 = parseInt(ds1, 10);
                if (ds0 > 12 && ds1 < 13) {
                    ds0 = ds[1];
                    ds1 = ds[0];
                }
            }
            return vetDateYYYYMMDD([
                today.getFullYear(), ds0, ds1
            ]);
        }, // vetDateMMDD

        vetDateDDMM = function (ds) {
            return vetDateYYYYMMDD([
                today.getFullYear(), ds[1], ds[0]
            ]);
        }, // vetDateDDMM

        vetDateDD = function (ds) {
            var d4 = String(ds).toLowerCase().slice(0, 4);
            if (d4 == "toda") {
                return vetDateOffset(0);
            }
            if (d4 == "yest") {
                return vetDateOffset(-1);
            }
            if (d4 == "tomo") {
                return vetDateOffset(+1);
            }
            return vetDateYYYYMMDD([
                today.getFullYear(), today.getMonth() + 1, ds[0]
            ]);
        }, // vetDateDD

        vetDateNothing = function () {
            return vetDateYYYYMMDD([
                today.getFullYear(), today.getMonth() + 1, today.getDate()
            ]);
        }, // vetDateNothing

        vetDateOffset = function (dof) {
            console.log("Entering vetDateOffset() with argument", dof);
            var d = new Date();
            d.setDate(d.getDate() + parseInt(dof, 10));
            return vetDateYYYYMMDD([
                d.getFullYear(), d.getMonth() + 1, d.getDate()
            ]);
        } //vetDateOffset
        ;

    return {

        addMinutes: addMinutes,

        canonicalizeTime: canonicalizeTime,

        canonicalizeTimeRange: canonicalizeTimeRange,

        intToMonth: intToMonth,

        minutesToTime: minutesToTime,

        // convert "YYYY-MM-DD HH:DD:SS+TZ" string into YYYY-MMM-DD
        readableDate: function (urd) {
            var ymd = urd.substr(0, urd.indexOf(" ")).split('-'),
                year,
                m,
                day,
                month;
            if (ymd.length !== 3) {
                return urd;
            }
            year = parseInt(ymd[0], 10);
            m =    parseInt(ymd[1], 10);
            day =  parseInt(ymd[2], 10);
            month = intToMonth(m);
            return year.toString() + "-" + month + "-" + day.toString();
        }, // readableDate

        strToMonth: strToMonth,

        timeToMinutes: timeToMinutes,

        vetDateYYYYMMDD: vetDateYYYYMMDD,

        vetDateOffset: vetDateOffset,

        vetDateMMDD: vetDateMMDD,

        vetDateDD: vetDateDD,

        vetDate: function (d) {
            console.log("Entering vetDate() with argument", d);
            var i,
                td = String(d).trim(),
                tda;

            // handle offset date (e.g. "-1", "+2")
            if (td === "0" || td.match(/^[+-]\d+$/)) {
                return vetDateOffset(td);
            }

            tda = td.split(/-|\.|\/|\s+/);
            console.log("Identified " + tda.length + " date components", tda);

            if (tda.length === 1 && String(tda[0]).length === 0) {
                return vetDateNothing();
            } else if (tda.length === 1) {
                return vetDateDD(tda);
            } else if (tda.length === 2) {
                if (coreLib.isInteger(tda[0]) && !coreLib.isInteger(tda[1])) {
                    return vetDateDDMM(tda);
                } else {
                    return vetDateMMDD(tda);
                }
            } else if (tda.length === 3) {
                return vetDateYYYYMMDD(tda);
            }
            return null;
        },

        vetDateRange: function (dr) {
            // should support ranges of dates (using a hyphen)
            // should support whole months (e.g. 2017 AUGUST, August 2017)
            // if year is omitted, assume current year
            // should trim all whitespace (leading, trailing, internal)
            // on success, returns e.g. { "2017-02-01", "2017-02-28" }
            // on failure, returns null
            // TBD
            var tdr = String(dr).trim();
            return "VETTED";
        },

        vetTimeRange: function (tr) {
            var ctr = canonicalizeTimeRange(tr),
                rv = null;
            if (ctr !== null) {
                rv = ctr[0] + '-' + ctr[1];
            }
            return rv;
        },

    };

});

