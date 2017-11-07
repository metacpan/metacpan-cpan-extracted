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
// svg-lib.js
//
// area for developing Scalabable Vector Graphics (SVG) content
//

"use strict";

define ([
    "app/caches",
    "datetime",
], function (
    appCaches,
    dt,
)
{

    var 
        absWidth = 870,

        dayViewerIntervals = function (date, obj, how) {
            // returns an SVG document for date, reflecting clocked and
            // scheduled intervals in obj; how is a boolean value "holiday or
            // weekend"
            var r = '',
                fill, i, intvl, begin, bo, end, eo, color;
            if (how) {
                fill = 'font-weight="bold" fill="transparent"';
            } else {
                fill = 'fill="black"';
            }
            r += '<svg width="' + absWidth + '" height="30" ' + svgBoilerPlate + '>';
            // draw base rectangle
            r += '<rect x="5" y="0" width="' + absWidth + '" height="30" fill="gray" stroke="transparent"/>';
            // draw attendance intervals
            for (i = 0; i < obj.clocked.length; i += 1) {
                intvl = obj.clocked[i];
                [begin, end] = intvl.iNtimerange.split('-');
                [bo, eo] = [timeToOffset(begin), timeToOffset(end)];
                color = appCaches.getActivityByAID(intvl.aid).color;
                r += '<rect x="' + bo + '" y="0" width="' + (eo - bo) + '" height="30" ' +
                     'fill="' + color + '" stroke="transparent"/>';
            }
            // draw schedule intervals
            for (i = 0; i < obj.scheduled.length; i += 1) {
                intvl = obj.scheduled[i];
                [begin, end] = intvl.split('-');
                [bo, eo] = [timeToOffset(begin), timeToOffset(end)];
                r += '<rect x="' + bo + '" y="0" width="' + (eo - bo) + '" height="15" ' +
                     'fill="black" fill-opacity="0.4" stroke="transparent"/>';
            }
            // draw date
            r += '<text font-size="24px" ' + fill + ' ' +
                 'stroke="black" stroke-width="1" x="7" y="26">' + date + ' ' + dt.dateToDay(date) + '</text>';
            r += '</svg>';
            return r;
        },

        dayViewerScale = function () {
            // returns svg document that draws a scale for the multi-day interval viewer
            var r = '',
                i, h, w;
            r += '<svg width="' + (absWidth + 1) + '" height="20" ' + svgBoilerPlate + '>';
            for (i = 0; i < 25; i += 1) {
                if (i < 10) {
                    h = String("0" + i);
                } else {
                    h = i;
                }
                w = timeToOffset(h + ":00");
                r += '<path d="M' + (w + 1) + ' 10 V 20" stroke="black" stroke-width=1 fill="transparent"/>';
                if (i < 24) {
                    r += '<text font-size="10px" x="' + w + '" y=8>' + String(h + "h") + '</text>';
                    r += '<path d="M' + (w + 19) + ' 15 V 20" stroke="black" stroke-width="1" fill="transparent"/>';
                }
            }
            r += '</svg>';
            return r;
        },

        svgBoilerPlate = 'version="1.1" xmlns="http://www.w3.org/2000/svg"',

        timeToOffset = function (t) {
            // given a time, return width offset for drawing
            var [hours, minutes] = t.split(':'),
                hourOffset = hours * 36,
                minuteOffset = minutes / 5 * 3;
            return 5 + hourOffset + minuteOffset;
        }
        ;

    return {
        "absWidth": absWidth,
        "dayViewerIntervals": dayViewerIntervals,
        "dayViewerScale": dayViewerScale,
        "svgBoilerPlate": svgBoilerPlate,
        "timeToOffset": timeToOffset,
    };
    
});
