'use strict';
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const vm = require('node:vm');
const context = vm.createContext({});
vm.runInContext(readFileSync(process.argv[2], 'utf8'), context);
const cves = context.CPANInGitCves;
const compare = (a, b) => cves.compareVersions(cves.parseVersion(a), cves.parseVersion(b));

for (const [a, b, expected] of [
  ['1.002003', 'v1.2.3', 0], ['1.23', 'v1.23.0', 1], ['1.23', 'v1.230.0', 0],
  ['1.002_003', '1.002003', 0], ['1.00_01', '1.0001', 0], ['1.00_01', '1.001', -1],
  ['1.2', '1.10', 1], ['v1.2', 'v1.10', -1], ['1.2.0.0', 'v1.2', 0],
  ['1.999999999999', '2.0', -1], ['0.000001', '0.00001', -1],
  ['v1.99999999999999999999', 'v1.99999999999999999998', 1], ['1.', '1.0', 0]
]) {
  assert.equal(compare(a, b), expected, `${a} compared with ${b} using Perl rules`);
}
assert.throws(() => cves.parseVersion('undef'));
assert.throws(() => cves.parseVersion('1_01'));
assert.throws(() => cves.parseVersion('v1_01'));
assert.throws(() => cves.parseVersion('1.2;alert(1)'));

const row = (version, moduleVersion = '99', distribution = 'Example', extension = 'tar.gz') =>
  ({name: 'A::Bundled::Module', version: moduleVersion, path: `L/LO/LOCAL/${distribution}-${version}.${extension}`});
const feed = ranges => cves.parseFeed(JSON.stringify({Example: [{cpansa_id: 'CPANSA-Example-Test',
  cves: ['CVE-2026-0001'], affected_versions: ranges}]}));
for (const [range, version, affected] of [
  ['<1.20', '1.19', true], ['<1.20', '1.20', false], ['<=1.20', '1.20', true],
  ['>1.20', '1.20', false], ['>1.20', '1.21', true], ['>=1.20', '1.20', true],
  ['=1.20', '1.200', true], ['==1.20', '1.21', false], ['!=1.20', '1.21', true],
  [' >= 1.00, < 2.00 ', '1.50', true], ['>=1.00,<2.00', '2.00', false],
  ['>=1.00,<2.00', '0.99', false], ['=v1.2.3', '1.002003', true],
  ['<=1.00_01', '1.00_02', false]
]) {
  assert.equal(cves.findAdvisories(feed([range]), row(version)).length > 0, affected, `${version}: ${range}`);
}
assert.equal(cves.findAdvisories(feed(['<1.00', '>=2.00,<3.00']), row('2.50')).length, 1, 'alternatives are ORed');
assert.equal(cves.findAdvisories(feed(['<1.00', '>=2.00,<3.00']), row('1.50')).length, 0);
assert.equal(cves.findAdvisories(feed([]), row('99')).length, 1, 'no ranges means all releases, as in Test::CVE');
assert.equal(cves.findAdvisories(feed(['<2']), row('1', '99')).length, 1, 'compares distribution release, not module version');
assert.equal(cves.findAdvisories(feed(['<2']), row('3', '0.01')).length, 0);
assert.equal(cves.findAdvisories(feed(['<2']), row('1', '1', 'Different')).length, 0, 'does not match an unrelated distribution');
assert.equal(cves.findAdvisories(feed(['<2']), row('1.01_01-TRIAL', '1', 'Example', 'zip')).length, 1);
const prefixed = cves.parseFeed('Warning: example\n' + JSON.stringify({Example: [{version_range: ['<2'], cve_id: 'CVE-2026-0002'}]}));
assert.equal(cves.findAdvisories(prefixed, row('1')).length, 1, 'reads warning prefixes and alternate range fields');
assert.throws(() => cves.parseFeed('Not JSON'));
assert.throws(() => cves.parseFeed('{"error":"Not a feed"}'));
assert.throws(() => feed(['<2; process.exit(0)']), 'range syntax is parsed without eval');
