window = null;
var trace_name = process.argv[2];
var trace = require('./traces/' + trace_name + '/attributes.js');
console.log("%j", trace);
