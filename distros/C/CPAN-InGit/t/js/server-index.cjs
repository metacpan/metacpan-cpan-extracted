'use strict';
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const vm = require('node:vm');
const script = readFileSync(process.argv[2], 'utf8');
const cveScript = readFileSync(process.argv[3], 'utf8');
assert.ok(script, 'found the delivered JavaScript');

// A small DOM and controllable fetch/timer queues exercise the delivered script
// without a browser or third-party JavaScript dependencies.
class Element {
  constructor() {
    this.children = [];
    this.dataset = {};
    this.listeners = {};
    this.value = '';
    this.hidden = false;
    this.checked = false;
  }
  append(child) { this.children.push(child); }
  replaceChildren(fragment) { this.children = fragment.children; }
  querySelectorAll() { return this.children; }
  addEventListener(name, fn) { this.listeners[name] = fn; }
  fire(name) { this.listeners[name]({preventDefault() {}}); }
}

const row = (name, version = '1.00', path = 'A/AU/AUTHOR/Example-1.00.tar.gz') =>
  ({name, version, path, text: `${name}  ${version}  ${path}`});
const tick = () => new Promise(resolve => setImmediate(resolve));

function setup({modules, complete = false, filter = '', next_after = null, tree = 'tree1'}) {
  const elements = Object.fromEntries(['cpan-index', 'module-filter', 'module-rows',
    'module-status', 'load-more', 'load-all', 'module-filter-form', 'check-cves', 'only-cves',
    'only-cves-label', 'cve-state', 'cve-spinner', 'cve-message', 'cve-column'].map(id => [id, new Element()]));
  for (const id of ['check-cves', 'only-cves-label', 'cve-state', 'cve-column']) elements[id].hidden = true;
  elements['only-cves'].checked = true;
  const root = elements['cpan-index'];
  root.dataset = {filter, tree, complete: String(complete), nextAfter: next_after || '', previousBefore: '',
    jsonUrl: '/pan/test/modules/', authorsUrl: '/pan/test/authors/id/'};
  elements['module-filter'].value = filter;
  elements['module-rows'].children = modules.map(data => {
    const tr = new Element();
    tr.dataset.row = JSON.stringify(data);
    return tr;
  });
  let timerId = 0;
  const timers = new Map();
  const requests = [];
  const context = vm.createContext({
    document: {baseURI: 'https://example.test/pan/test/', getElementById: id => elements[id],
      createElement: () => new Element(), createDocumentFragment: () => new Element()},
    URL, AbortController,
    setTimeout: (fn, delay) => { assert.equal(delay, 150); timers.set(++timerId, fn); return timerId; },
    clearTimeout: id => timers.delete(id),
    fetch: (url, options) => new Promise((resolve, reject) => requests.push({url: new URL(url), options, reject,
      respond: page => resolve({ok: true, json: async () => page}),
      respondText: text => resolve({ok: true, text: async () => text}),
      respondError: () => resolve({ok: false, status: 503})}))
  });
  vm.runInContext(cveScript, context);
  vm.runInContext(script, context);
  return {
    elements, requests,
    type(value) { elements['module-filter'].value = value; elements['module-filter'].fire('input'); },
    async flush() { const callbacks = [...timers.values()]; timers.clear(); callbacks.forEach(fn => fn()); await tick(); },
    names() { return elements['module-rows'].children.filter(tr => !tr.hidden).map(tr => tr.children[0].textContent); },
    more() { elements['load-more'].fire('click'); },
    all() { elements['load-all'].fire('click'); }
  };
}

async function run() {
  const modules = [row('Example::Alpha'), row('Example::Beta', '2.50', 'L/LO/LOCAL/Beta-2.50.tar.gz')];
  const local = setup({modules, complete: true});
  local.type('AL');
  local.type('aLpHa');
  await local.flush();
  assert.equal(local.requests.length, 0, 'debounced narrowing uses the complete cache');
  assert.deepEqual(local.names(), ['Example::Alpha']);
  local.type('LOCAL');
  await local.flush();
  assert.deepEqual(local.names(), ['Example::Beta'], 'matches distribution paths case-insensitively');
  local.type('2.50');
  await local.flush();
  assert.deepEqual(local.names(), ['Example::Beta'], 'matches versions');
  local.type('[.*');
  await local.flush();
  assert.deepEqual(local.names(), [], 'metacharacters are literal');
  local.type('');
  await local.flush();
  assert.deepEqual(local.names(), ['Example::Alpha', 'Example::Beta'], 'broadening within a complete base cache is safe');

  const partial = setup({modules: [row('Example::Alpha')], next_after: 'Example::Alpha'});
  partial.type('EXAMPLE');
  assert.equal(partial.requests.length, 0, 'does not fetch before the delay');
  await partial.flush();
  assert.equal(partial.requests.length, 1, 'incomplete results require a server filter');
  assert.equal(partial.requests[0].url.searchParams.get('filter'), 'EXAMPLE');
  partial.requests[0].respond({modules: [modules[0]], filter: 'EXAMPLE', tree: 'tree1', complete: false,
    next_after: 'Example::Alpha', previous_before: null});
  await tick();
  partial.more();
  assert.equal(partial.requests[1].url.searchParams.get('after'), 'Example::Alpha', 'pages by module boundary');
  partial.requests[1].respond({modules: [modules[1]], filter: 'EXAMPLE', tree: 'tree1', complete: false,
    next_after: null, previous_before: 'Example::Beta'});
  await tick();
  assert.deepEqual(partial.names(), ['Example::Alpha', 'Example::Beta'], 'appends further modules');
  assert.equal(partial.elements['load-more'].hidden, true, 'hides load-more at the end');
  partial.type('example::BETA');
  await partial.flush();
  assert.equal(partial.requests.length, 2, 'all accumulated pages can now be filtered locally');
  assert.deepEqual(partial.names(), ['Example::Beta']);
  partial.type('AUTHOR');
  await partial.flush();
  assert.equal(partial.requests.length, 3, 'an unrelated filter needs fresh results');

  const races = setup({modules: [], complete: false});
  races.type('old');
  await races.flush();
  races.type('new');
  await races.flush();
  assert.equal(races.requests[0].options.signal.aborted, true, 'aborts stale requests');
  races.requests[1].respond({modules: [row('New')], filter: 'new', tree: 'tree1', complete: true,
    next_after: null, previous_before: null});
  await tick();
  races.requests[0].respond({modules: [row('Old')], filter: 'old', tree: 'tree1', complete: true,
    next_after: null, previous_before: null});
  await tick();
  assert.deepEqual(races.names(), ['New'], 'late responses cannot replace the newer filter');

  const advancing = setup({modules: [row('Old')], next_after: 'Old'});
  advancing.more();
  advancing.requests[0].respond({modules: [row('WrongPage')], filter: '', tree: 'tree2', complete: false,
    next_after: null, previous_before: 'WrongPage'});
  await tick();
  assert.equal(advancing.requests.length, 2, 'branch advancement restarts the listing');
  assert.equal(advancing.requests[1].url.searchParams.has('after'), false);
  advancing.requests[1].respond({modules: [row('Fresh')], filter: '', tree: 'tree2', complete: true,
    next_after: null, previous_before: null});
  await tick();
  assert.deepEqual(advancing.names(), ['Fresh'], 'does not mix trees when appending');

  const errors = setup({modules: [], complete: false});
  errors.type('example');
  await errors.flush();
  errors.requests[0].reject(new Error('Offline'));
  await tick();
  assert.match(errors.elements['module-status'].textContent, /Could not load/);
  errors.type('example::alpha');
  await errors.flush();
  assert.equal(errors.requests.length, 2, 'can fetch again after an error');

  const bulk = setup({modules: [row('A')], next_after: 'A'});
  bulk.all();
  assert.equal(bulk.requests.length, 1, 'Load all starts a single request');
  assert.equal(bulk.elements['load-all'].textContent, 'Stop');
  assert.equal(bulk.elements['load-all'].disabled, false, 'Stop stays clickable during fetch');
  assert.equal(bulk.elements['load-more'].disabled, true);
  bulk.more();
  assert.equal(bulk.requests.length, 1, 'Load more cannot start a concurrent request');
  bulk.requests[0].respond({modules: [row('B')], filter: '', tree: 'tree1', complete: false,
    next_after: 'B', previous_before: 'B'});
  await tick();
  assert.equal(bulk.requests.length, 2, 'Load all fetches the next page sequentially');
  assert.equal(bulk.requests[1].url.searchParams.get('after'), 'B');
  assert.match(bulk.elements['module-status'].textContent, /2 loaded/, 'progress reports accumulated rows');
  bulk.requests[1].respond({modules: [row('C')], filter: '', tree: 'tree1', complete: false,
    next_after: null, previous_before: 'C'});
  await tick();
  assert.deepEqual(bulk.names(), ['A', 'B', 'C'], 'Load all accumulates every page');
  assert.equal(bulk.elements['load-all'].hidden, true);
  assert.equal(bulk.elements['load-more'].hidden, true);
  bulk.type('B');
  await bulk.flush();
  assert.equal(bulk.requests.length, 2, 'completed bulk results can be filtered locally');
  assert.deepEqual(bulk.names(), ['B']);

  const stopped = setup({modules: [row('A')], next_after: 'A'});
  stopped.all();
  stopped.all();
  assert.equal(stopped.requests.length, 1, 'two quick clicks start and stop one request');
  assert.equal(stopped.requests[0].options.signal.aborted, true, 'Stop aborts the active fetch');
  assert.equal(stopped.elements['load-all'].textContent, 'Load all');
  assert.deepEqual(stopped.names(), ['A']);
  stopped.requests[0].respond({modules: [row('Ignored')], filter: '', tree: 'tree1', complete: false,
    next_after: 'Ignored', previous_before: 'Ignored'});
  await tick();
  assert.deepEqual(stopped.names(), ['A'], 'a stopped request cannot append late results');
  assert.equal(stopped.requests.length, 1, 'stopped loop does not continue');
  stopped.all();
  assert.equal(stopped.requests[1].url.searchParams.get('after'), 'A', 'can resume from the retained boundary');
  stopped.requests[1].respond({modules: [row('B')], filter: '', tree: 'tree1', complete: false,
    next_after: 'B', previous_before: 'B'});
  await tick();
  assert.equal(stopped.requests.length, 3);
  stopped.all();
  assert.equal(stopped.requests[2].options.signal.aborted, true);
  assert.deepEqual(stopped.names(), ['A', 'B'], 'Stop preserves successfully loaded pages');
  stopped.all();
  assert.equal(stopped.requests[3].url.searchParams.get('after'), 'B');
  stopped.requests[3].respond({modules: [row('C')], filter: '', tree: 'tree1', complete: false,
    next_after: null, previous_before: 'C'});
  await tick();
  assert.deepEqual(stopped.names(), ['A', 'B', 'C'], 'resuming avoids gaps and duplicates');

  const bulkFilter = setup({modules: [row('A')], next_after: 'A'});
  bulkFilter.all();
  bulkFilter.type('different');
  assert.equal(bulkFilter.requests[0].options.signal.aborted, true, 'changing the filter aborts bulk loading');
  await bulkFilter.flush();
  bulkFilter.requests[0].respond({modules: [row('Ignored')], filter: '', tree: 'tree1', complete: false,
    next_after: 'Ignored', previous_before: 'Ignored'});
  bulkFilter.requests[1].respond({modules: [row('Different')], filter: 'different', tree: 'tree1', complete: true,
    next_after: null, previous_before: null});
  await tick();
  assert.equal(bulkFilter.requests.length, 2, 'old bulk loop cannot continue with the new filter');
  assert.deepEqual(bulkFilter.names(), ['Different']);

  const bulkError = setup({modules: [row('A')], next_after: 'A'});
  bulkError.all();
  bulkError.requests[0].respondError();
  await tick();
  assert.equal(bulkError.requests.length, 1, 'an error stops the fetch loop');
  assert.equal(bulkError.elements['load-all'].textContent, 'Load all');
  assert.equal(bulkError.elements['load-all'].disabled, false, 'bulk loading can be retried after an error');
  assert.match(bulkError.elements['module-status'].textContent, /Could not load/);

  const advisoryFeed = JSON.stringify({Example: [{cpansa_id: 'CPANSA-Example-2026-01',
    cves: ['CVE-2026-0001', 'CVE-2026-0002'], affected_versions: ['<2.00']},
    {cpansa_id: 'CPANSA-Example-2026-02', cves: ['CVE-2026-0001'], affected_versions: ['<2.00']}]});
  const cves = setup({modules: [row('Bundled::Affected', '99.00', 'L/LO/LOCAL/Example-1.00.tar.gz'),
    row('Unaffected', '0.01', 'L/LO/LOCAL/Example-2.00.tar.gz')], next_after: 'Unaffected'});
  assert.equal(cves.requests.length, 0, 'no CVE download until requested');
  assert.equal(cves.elements['cve-column'].hidden, true, 'CVE column hidden before checking');
  cves.elements['check-cves'].fire('click');
  assert.match(cves.requests[0].url.href, /^https:\/\/cpan-security\.github\.io\//);
  assert.equal(cves.elements['check-cves'].hidden, true, 'button replaced while downloading');
  assert.equal(cves.elements['cve-state'].hidden, false);
  assert.equal(cves.elements['cve-spinner'].hidden, false);
  assert.match(cves.elements['cve-message'].textContent, /Downloading/);
  assert.equal(cves.elements['only-cves-label'].hidden, true, 'checkbox hidden until success');
  cves.elements['check-cves'].fire('click');
  assert.equal(cves.requests.length, 1, 'duplicate clicks do not duplicate the download');
  cves.requests[0].respondText(advisoryFeed);
  await tick();
  assert.equal(cves.elements['only-cves-label'].hidden, false);
  assert.equal(cves.elements['only-cves'].checked, true, 'Only CVEs checked by default');
  assert.equal(cves.elements['cve-state'].hidden, true, 'spinner removed after success');
  assert.deepEqual(cves.names(), ['Bundled::Affected'], 'only affected rows visible');
  const marked = cves.elements['module-rows'].children[0];
  assert.equal(marked.className, 'cve-affected', 'affected row gets its CSS class');
  assert.match(marked.children[1].title, /CVE-2026-0001/, 'version identifies the advisory');
  assert.equal(cves.elements['cve-column'].hidden, false, 'checking reveals the CVE column');
  assert.equal(marked.children.length, 4, 'report column follows Version and precedes Distribution');
  assert.deepEqual(marked.children[2].children.map(link => [link.textContent, link.href]), [
    ['CVE-2026-0001', 'https://www.cve.org/CVERecord?id=CVE-2026-0001'],
    ['CVE-2026-0002', 'https://www.cve.org/CVERecord?id=CVE-2026-0002']
  ], 'CVE numbers link to reports, with duplicates removed');
  assert.equal(cves.elements['module-rows'].children[1].children[2].children.length, 0, 'unaffected row has no CVE links');
  assert.match(cves.elements['module-status'].textContent, /1 affected of 2 loaded/);
  cves.elements['only-cves'].checked = false;
  cves.elements['only-cves'].fire('change');
  assert.deepEqual(cves.names(), ['Bundled::Affected', 'Unaffected'], 'checkbox can show all rows');
  cves.elements['only-cves'].checked = true;
  cves.elements['only-cves'].fire('change');
  cves.all();
  cves.requests[1].respond({modules: [row('New::Affected'), row('New::Unaffected', '1.00',
    'L/LO/LOCAL/Example-3.00.tar.gz')], filter: '', tree: 'tree1', complete: false,
    next_after: null, previous_before: 'New::Affected'});
  await tick();
  assert.deepEqual(cves.names(), ['Bundled::Affected', 'New::Affected'], 'new pages are checked and filtered');
  assert.equal(cves.elements['module-rows'].children[2].children[2].children[0].textContent,
    'CVE-2026-0001', 'newly loaded affected rows also link to their reports');
  assert.equal(cves.requests.length, 2, 'pagination reuses the CVE data');
  cves.type('new');
  await cves.flush();
  assert.deepEqual(cves.names(), ['New::Affected'], 'text filtering and CVE filtering compose');
  cves.elements['only-cves'].checked = false;
  cves.elements['only-cves'].fire('change');
  assert.deepEqual(cves.names(), ['New::Affected', 'New::Unaffected']);

  const failedCves = setup({modules: [], complete: true});
  failedCves.elements['check-cves'].fire('click');
  failedCves.requests[0].respondError();
  await tick();
  assert.equal(failedCves.elements['check-cves'].hidden, false, 'failed download can be retried');
  assert.equal(failedCves.elements['cve-spinner'].hidden, true);
  assert.equal(failedCves.elements['only-cves-label'].hidden, true);
  failedCves.elements['check-cves'].fire('click');
  failedCves.requests[1].respondText('Not a JSON database');
  await tick();
  assert.equal(failedCves.elements['only-cves-label'].hidden, true, 'invalid data does not enable filtering');
  failedCves.elements['check-cves'].fire('click');
  failedCves.requests[2].respondText('{}');
  await tick();
  assert.equal(failedCves.elements['only-cves-label'].hidden, false, 'successful retry enables CVE filtering');
}

run().catch(error => { console.error(error); process.exitCode = 1; });
