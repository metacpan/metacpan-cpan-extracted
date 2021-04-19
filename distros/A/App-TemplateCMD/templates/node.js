[% IF not file %][% file     =  out     %][% END -%]
[% IF not file %][% file     = '<Name>' %][% END -%]
#!/usr/bin/env node

'use strict';
const fs = require('fs');
const package = require(`${process.cwd()}/package.json`);
const ngl = require('node-getopt-long');

const options = ngl.options([
  ['output|o=s', 'Format the output either text or json (Default text)'],
  ['good-or-bad|g=s', {
    description: 'The name of the component to create',
    paramName: 'ux-foo-bar',
    test: value => {
      if (value === 'bad') {
        throw 'value must be good';
      }
      return value;
    }
  }]
], {
  name: '[% file %]',
  command: package.version,
  helpPrefix: `
    before text
  `,
  defaults: {
      output: 'text'
  }
});

