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
// lib.js
//
"use strict";

define ([
    'jquery',
    'cf',
    'current-user',
    'prototypes'
], function (
    $,
    cf,
    currentUser,
    prototypes
) {

    var heldObject = null,
        dbrowserStateOverride = false,
        dbrowserState = {
            "obj": null,  // the dbrowser object itself
            "set": null,  // the dataset (array) we are browsing
            "pos": null   // the current position within that array
        },
        drowselectState = {
            "obj": null,  // the drowselect object itself
            "set": null,  // the dataset (array) we are selecting from
            "pos": null   // the current position within that array
        };

    return {

        // special entries
        dividerEntry: {
            name: 'divider',
            aclProfileRead: 'passerby',
            aclProfileWrite: null,
            text: '-',
            prop: null,
            maxlen: 20
        },

        emptyLineEntry: {
            name: 'emptyLine',
            aclProfileRead: 'passerby',
            aclProfileWrite: null,
            text: "&nbsp",
            prop: null,
            maxlen: 20
        },

        clearResult: function () {
            $('#result').css('text-align', 'left');
            $('#result').html('&nbsp;');
        },

        // dbrowser states
        // FIXME: move this into stack.js
        dbrowserState: dbrowserState,

        // display error message
        displayError: function (buf, id) {
            console.log("ERROR: " + buf);
            $('#result').css('text-align', 'center');
            $("#result").html(buf);
            $('input[name="sel"]').val('');
            if (id) {
                $('input[name="' + id + '"]').focus();
            } else {
                $('input[name="entry0"]').focus();
            }
        },

        displayResult: function (buf) {
            console.log("RESULT: " + buf);
            $('#result').css('text-align', 'center');
            $('#result').html(buf);
        },

        // drowselect state
        // FIXME: move this into stack.js
        drowselectState: drowselectState,

        focusedItem: function () {
            return {
                "id": $(document.activeElement).attr('id'),
                "name": $(document.activeElement).attr('name'),
            };
        },

        // convert null to empty array
        forceArray: function (arr) {
            return (arr === null) ? [] : arr;
        },

        // generate string "n objects" based on array length
        genObjStr: function (len) {
            return (len === 1) ?
                '1 object' :
                len + " objects";
        },

        // give object a "haircut" by throwing out all properties
        // that do not appear in proplist
        hairCut: function (obj, proplist) {
            for (var prop in obj) {
                if (obj.hasOwnProperty(prop)) {
                    if (proplist.indexOf(prop) !== -1) {
                        continue;
                    }
                    delete obj[prop];
                }
            }
            return obj;
        },

        isInteger: function (value) {
            var pival = parseInt(value, 10),
                cond1 = pival == value,
                cond2 = typeof pival === 'number',
                cond3 = isFinite(pival),
                res = cond1 && cond2 && cond3;
            //console.log("isInteger() called with", value);
            //console.log("parseInt says", pival);
            //console.log("typeof says", typeof pival === 'number');
            //console.log("isFinite says", isFinite(pival));
            //console.log("isInteger says", res);
            return res;
        },

        isObjEmpty: function (obj) {
            if (Object.getOwnPropertyNames(obj).length > 0) return false;
            return true;
        },

        // boolean function for existing, non-empty string, from
        // https://www.safaribooksonline.com/library/view/javascript-cookbook/9781449390211/ch01s07.html
        // true if variable exists, is a string, and has a length greater than zero
        isStringNotEmpty: function (unknownVariable) {
            if (((typeof unknownVariable !== "undefined") &&
                 (typeof unknownVariable.valueOf() === "string")) &&
                 (unknownVariable.length > 0)) {
                return true;
            }
            return false;
        },

        // log events to browser JavaScript console
        logKeyPress: function (evt) {
            // console.log("WHICH: " + evt.which + ", KEYCODE: " + evt.keyCode);
        },

        objectify: function (st) {
            // if st ("something") is not a traditional object
            // like { "foo": "bar" }, turn it into {}
            if (st === undefined || st === null || typeof st !== 'object') {
                return {};
            }
            return st;
        },

        // check current employee's privilege against a given ACL profile
        privCheck: function (p) {

            var cep = currentUser('priv'),
                r,
                yesno;

            if ( cf('testing') && ! cep ) {
                cep = 'passerby';
            }
            if ( ! cep ) {
                console.log("Cannot determine priv level of current user! Falling back to sane value \"passerby\"");
                currentUser('priv', 'passerby');
                cep = currentUser('priv');
            }

            if (p === 'passerby' && cep) {
                r = true;
                yesno = "Yes.";
            } else if (p === 'inactive' && (cep === 'inactive' || cep === 'active' || cep === 'admin')) {
                r = true;
                yesno = "Yes.";
            } else if (p === 'active' && (cep === 'active' || cep === 'admin')) {
                r = true;
                yesno = "Yes.";
            } else if (p === 'admin' && cep === 'admin') {
                r = true;
                yesno = "Yes.";
            } else {
                r = false;
                yesno = "No.";
            }

            console.log("Does " + cep + " user satisfy ACL " + p + "? " + yesno);
            return r;
        }, // privCheck

        // reverse-video a row (on/off)
        reverseVideo: function (row, onoff) {
            if (onoff === true) {
                $('#row' + row).css('background-color','#000000');
                $('#row' + row).css('color','#ffffff');
            }
            if (onoff === false) {
                $('#row' + row).css('background-color','#d0e4fe');
                $('#row' + row).css('color','#000000');
            }
        },

        // right pad a string with spaces
        rightPadSpaces: function (toPad, padto) {
            var strToPad = ((toPad === null) ? '' : toPad).toString();
            // console.log("Padding " + strToPad + " to " + padto + " spaces.");
            var sp = '&nbsp;',
                padSpaces = sp.repeat(padto - String(strToPad).length);
            return strToPad.concat(padSpaces);
        },

        // shallow object copy, from
        // http://blog.soulserv.net/understanding-object-cloning-in-javascript-part-i/
        shallowCopy: function (original) {
            // First create an empty object with
            // same prototype of our original source
            var clone = Object.create(Object.getPrototypeOf(original)),
                i, keys = Object.getOwnPropertyNames(original);
            for (i = 0; i < keys.length; i++) {
                // copy each property into the clone
                Object.defineProperty(clone, keys[i],
                    Object.getOwnPropertyDescriptor(original, keys[i])
                );
            }
            return clone;
        },

        // pause main thread for n milliseconds
        //wait: function (ms) {
        //    var start = new Date().getTime();
        //    var end = start;
        //    while(end < start + ms) {
        //        end = new Date().getTime();
        //    }
        //},

    };

});

