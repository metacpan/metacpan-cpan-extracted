/* global require, process */
[% IF global -%]
var opt = require('node-getopt-long').options([
        ['out|o', 'Output'],
    ],
    {
        name          : '[% module %]',
        commandVersion: '0.0.1'
    }
);
[% END -%]

[% INCLUDE js/class.js class = module -%]
var exports;
exports.[% module %] = [% module %];
