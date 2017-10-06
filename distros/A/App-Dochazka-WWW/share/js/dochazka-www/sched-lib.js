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
// app/sched-lib.js
//
"use strict";

define ([
    'jquery',
    'ajax',
    'current-user',
    'lib',
    'app/prototypes',
    'stack',
    'start',
    'target'
], function (
    $,
    ajax,
    currentUser,
    coreLib,
    prototypes,
    stack,
    start,
    target
) {

    var 
        actionDisplaySchedule = function (obj) {
            stack.push(
                'schedDisplay',
                mungeScheduleForDisplay(obj),
            );
        },

        actionSchedLookup = function (obj) {
            console.log("Entering target 'actionSchedLookup' with argument", obj);
            browsing = false;
            var rest = {
                    "method": 'GET',
                },
                scheduleObj,
                // success callback
                sc = function (st) {
                    if (st.code === 'DISPATCH_SCHEDULE_FOUND') {
                        console.log("Payload is", st.payload);
                        scheduleObj = $.extend(
                            Object.create(prototypes.schedObjectForDisplay), {
                                'sid': st.payload.sid,
                                'scode': st.payload.scode,
                                'schedule': st.payload.schedule,
                                'disabled': st.payload.disabled,
                                'remark': st.payload.remark
                            }
                        );
                        stack.push('schedDisplay', mungeScheduleForDisplay(scheduleObj), {
                            "xtarget": "schedLookup"
                        });
                    }
                },
                // failure callback
                fc = function (st) {
                    console.log("AJAX: " + rest["path"] + " failed with", st);
                    coreLib.displayError(st.payload.message);
                };
            if (obj.searchKeySchedID) {
                rest["path"] = 'schedule/sid/' + encodeURIComponent(obj.searchKeySchedID);
            } else if (obj.searchKeySchedCode) {
                rest["path"] = 'schedule/scode/' + encodeURIComponent(obj.searchKeySchedCode);
            } else {
                coreLib.displayError("Please enter a schedule code or ID to search for");
                return;
            }
            ajax(rest, sc, fc);
        },

        browsing,
        browseAllSchedules = function () {
            console.log("Entering target 'browseAllSchedules'");
            browsing = true;
            var rest = {
                    "method": 'GET',
                    "path": 'schedule/all'
                },
                // success callback
                sc = function (st) {
                    if (st.code === 'DISPATCH_RECORDS_FOUND') {
                        // if only one record is returned, it might be in a result_set
                        // or it might be alone in the payload
                        var rs = st.payload.result_set || st.payload,
                            count = rs.length,
                            mungedRS = [];

                        console.log("Found " + count + " schedules");
                        for (var i=0; i<count; i++) {
                            mungedRS.push(mungeScheduleForDisplay(rs[i]));
                        }
                        stack.push('simpleScheduleBrowser', {
                            'pos': 0,
                            'set': mungedRS
                        });
                    }
                },
                // failure callback
                fc = function (st) {
                    console.log("AJAX: schedule/all failed with", st);
                    coreLib.displayError(st.payload.message);
                };
            ajax(rest, sc, fc);
        },

        mungeScheduleForDisplay = function (obj) {
            var schedule = JSON.parse(obj.schedule),
                slen = schedule.length,
                daysOfWeek = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'],
                mungedObj = Object.create(prototypes.schedObjectForDisplay);
            console.log("mungeScheduleForDisplay: schedule has " + slen + " intervals");
            mungedObj['sid'] = obj.sid;
            mungedObj['scode'] = obj.scode;
            mungedObj['remark'] = obj.remark;
            mungedObj['disabled'] = obj.disabled;
            mungedObj['mon'] = null;
            mungedObj['tue'] = null;
            mungedObj['wed'] = null;
            mungedObj['thu'] = null;
            mungedObj['fri'] = null;
            mungedObj['sat'] = null;
            mungedObj['sun'] = null;
            for (var i = 0; i < slen; i++) {  // loop over schedule intervals
                var dow = schedule[i]['low_dow'].toLowerCase();
                // console.log("Schedule interval #" + i + " starts on " + dow);
                if (mungedObj[dow] === null) {
                    mungedObj[dow] = '';
                } else {
                    mungedObj[dow] += '; ';
                }
                mungedObj[dow] += schedule[i]['low_time'] + '-' + schedule[i]['high_time'];
            }
            // console.log("mungemungedObjectForDisplay: mungedObj", mungedObj);
            return mungedObj;
        },

        prepSchedIntvl = function (dow, uint) {
            // given schedule interval entered by user (e.g. "8-12:30"),
            // convert it into a string suitable for passing to the
            // 'schedule/new' REST API resource
            var dow_map = {
                    'mon': '2015-03-23',
                    'tue': '2015-03-24',
                    'wed': '2015-03-25',
                    'thu': '2015-03-26',
                    'fri': '2015-03-27',
                    'sat': '2015-03-28',
                    'sun': '2015-03-29',
                },
                tsr = uint.split('-');
            return "["  + dow_map[dow.toLowerCase()] + " " + tsr[0] +
                   ", " + dow_map[dow.toLowerCase()] + " " + tsr[1] + ")";
        },

        createScheduleAjax = function (obj) {
            console.log("Entering target 'createScheduleAjax' with argument", obj);
            var rest = {
                    "method": 'POST',
                    "path": 'schedule/new',
                    "body": obj
                },
                scheduleObj,
                // success callback
                sc = function (st) {
                    if (st.code === 'DISPATCH_SCHEDULE_INSERT_OK' ||
                        st.code === 'DISPATCH_SCHEDULE_EXISTS') {
                        console.log("Payload is", st.payload);
                        scheduleObj = $.extend(
                            Object.create(prototypes.schedObjectForDisplay), {
                                'sid': st.payload.sid,
                                'scode': st.payload.scode,
                                'schedule': st.payload.schedule,
                                'disabled': st.payload.disabled,
                                'remark': st.payload.remark
                            }
                        );
                        stack.push(
                            'actionDisplaySchedule',
                            scheduleObj,
                            {'resultLine': st.text},
                        );
                    }
                },
                // failure callback
                fc = function (st) {
                    console.log("AJAX: " + rest["path"] + " failed with", st);
                    coreLib.displayError(st.payload.message);
                };
            ajax(rest, sc, fc);
        },

        createSchedule = function (schedFormObj) {
            console.log("Entering createSchedule() with", schedFormObj);

            var obj = Object.create(prototypes.schedObjectForCreate),
                weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'],
                intervals;

            if (coreLib.isStringNotEmpty(schedFormObj.scode)) {
                obj.scode = schedFormObj.scode;
            }
            obj.schedule = [];

            if (schedFormObj.hasOwnProperty('boilerplate')) {
                // Create a new schedule - boilerplate
                if (coreLib.isStringNotEmpty(schedFormObj.boilerplate)) {
                    intervals = schedFormObj.boilerplate.split(';');
                    for (var day = 0; day < 5; day++) {
                        for (var i = 0; i < intervals.length; i++) {
                            obj.schedule.push(prepSchedIntvl(weekdays[day], intervals[i]));
                        }
                    }
                }
            } else {
                // Create a new schedule - custom
                for (var day = 0; day < 7; day++) {
                    var weekday = weekdays[day];
                    if (coreLib.isStringNotEmpty(schedFormObj[weekday])) {
                        intervals = schedFormObj[weekday].split(';');
                        for (var i = 0; i < intervals.length; i++) {
                            obj.schedule.push(prepSchedIntvl(weekday, intervals[i]));
                        }
                    }
                }
            }
            console.log("Ready to call schedule/new with body", obj);
            createScheduleAjax(obj);
        },

        schedGen = function (mode, schedObj) {
            var rest = {
                    "path": 'schedule/sid/' + schedObj.sid,
                    "body": schedObj
                },
                dispMsg,
                sc = function (st) {
                    if (mode === "edit") {
                        dispMsg = "Edited schedule saved";
                        if (stack.grep('schedLookup')) {
                            stack.unwindToTarget('actionSchedLookup', {
                                "searchKeySchedID": schedObj.sid
                            });
                        } else if (stack.grep('simpleScheduleBrowser')) {
                            var obj = coreLib.dbrowserState.set[coreLib.dbrowserState.pos];
                            $.extend(coreLib.dbrowserState.obj, schedObj);
                            $.extend(obj, schedObj);
                            stack.unwindToTarget('simpleScheduleBrowser');
                        } else if (stack.grep('schedDisplay')) {
                            stack.unwindToTarget('schedDisplay', schedObj);
                        } else {
                            dispMsg = "Don't know what to do here";
                        }
                    } else if (mode === "delete") {
                        dispMsg = "Schedule deleted";
                        if (browsing) {
                            var set = coreLib.dbrowserState.set,
                                pos = coreLib.dbrowserState.pos,
                                len = set.length;
                            set.splice(pos, 1);
                            if (pos > 0) {
                                coreLib.dbrowserState.pos -= 1;
                            }
                        }
                        stack.unwindToFlag();
                    }
                    coreLib.displayResult(dispMsg);
                },
                fc = function (st) {
                    console.log("AJAX: " + rest["path"] + " failed with", st);
                    coreLib.displayError(st.payload.message);
                };
            if (mode === 'edit') {
                rest.method = 'PUT';
            } else if (mode === 'delete') {
                rest.method = 'DELETE';
            }
            ajax(rest, sc, fc);
        };

    // here is where we define methods implementing the various
    // schedule-related actions (see daction-start.js)
    return {
        actionDisplaySchedule: actionDisplaySchedule,
        actionSchedLookup: actionSchedLookup,
        browseAllSchedules: browseAllSchedules,
        createSchedule: createSchedule,
        schedEditSave: function (obj) {
            schedGen('edit', obj);
        },
        schedReallyDelete: function (obj) {
            schedGen('delete', obj);
        }
    };

});

