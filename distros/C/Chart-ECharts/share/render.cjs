#!/usr/bin/env node

'use strict';

const { createCanvas } = require('canvas');
const echarts = require('echarts');

const { writeFile } = require('node:fs');
const { parseArgs } = require('node:util');

const args = parseArgs({
    options: {
        format: {
            type: "string",
            default: 'svg',
        },
        width: {
            type: 'string',
            default: '400'
        },
        height: {
            type: 'string',
            default: '300'
        },
        option: {
            type: 'string',
            default: '{}'
        },
        output: {
            type: 'string'
        }
    }
});

const format = args.values.format;
const option = args.values.option;
const width = args.values.width;
const height = args.values.height;
const output = args.values.output;

if (format !== 'svg' && format !== 'png') {
    console.error('Unknown output format');
    process.exit(1);
}

if (!output) {
    console.error('Missing output file');
    process.exit(1);
}

const default_option = {
    animation: false,
    tooltip: {},
    series: {}
};

let chart_option = JSON.parse(option);

let canvas = null;
let theme = null;
let opts = {};

if (format == 'svg') {
    opts = {
        renderer: 'svg',
        ssr: true,
        width: width,
        height: height
    };
} else {
    canvas = createCanvas(parseInt(width), parseInt(height), format);
}

let chart = echarts.init(canvas, theme, opts);
chart.setOption({ ...default_option, ...chart_option });

if (format !== 'svg') {
    echarts.setPlatformAPI(canvas);
}

let buffer = (format == 'svg') ? chart.renderToSVGString() : canvas.toBuffer();

if (!buffer) {
    console.warn('Empty buffer');
}

chart.dispose();
chart = null;

writeFile(output, buffer, (err) => {
    if (err) throw err;
});
