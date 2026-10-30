'use strict';
// CPANSA source and range semantics follow Test::CVE:
// https://github.com/CPAN-Security/Test-CVE/blob/main/lib/Test/CVE.pm
// Range alternatives are ORed; comma-separated comparisons are ANDed.
globalThis.CPANInGitCves = (() => {
  const feedUrl = 'https://cpan-security.github.io/cpansa-feed/cpansa.json';

  function parseVersion(value) {
    const original = String(value).trim();
    if (!/^(?:v?\d+(?:\.\d+)+(?:_\d+)?|v?\d+|\.\d+(?:_\d+)?|\d+\.)$/.test(original)) {
      throw new Error(`Unsupported Perl version: ${original}`);
    }
    const text = original.replace(/_/g, '');
    // Perl decimal versions group fractional digits in threes; dotted versions
    // use literal components. Thus 1.002003 == v1.2.3, but 1.23 != v1.23.
    if (text.startsWith('v') || (text.match(/\./g) || []).length > 1) {
      return text.replace(/^v/, '').split('.').map(part => BigInt(part));
    }
    const [major, fraction = ''] = text.split('.');
    const parts = [BigInt(major || '0')];
    for (let i = 0; i < fraction.length; i += 3) {
      parts.push(BigInt(fraction.slice(i, i + 3).padEnd(3, '0')));
    }
    return parts;
  }

  function compareVersions(left, right) {
    for (let i = 0; i < Math.max(left.length, right.length); i++) {
      const a = left[i] || 0n;
      const b = right[i] || 0n;
      if (a !== b) return a < b ? -1 : 1;
    }
    return 0;
  }

  function compileRange(range) {
    if (range === '*') return () => true;
    if (typeof range !== 'string' || !range.trim()) throw new Error('Invalid affected-version range');
    const conditions = range.split(',').map(condition => {
      const match = condition.trim().match(/^(<=|>=|==|!=|=|<|>)\s*(\S+)$/);
      if (!match) throw new Error(`Unsupported affected-version range: ${range}`);
      return {operator: match[1], version: parseVersion(match[2])};
    });
    return version => conditions.every(condition => {
      const order = compareVersions(version, condition.version);
      switch (condition.operator) {
        case '<': return order < 0;
        case '<=': return order <= 0;
        case '>': return order > 0;
        case '>=': return order >= 0;
        case '!=': return order !== 0;
        default: return order === 0;
      }
    });
  }

  function parseFeed(text) {
    // Some feed revisions prefix their JSON with a plaintext warning.
    const start = text.indexOf('{');
    if (start < 0) throw new Error('Missing CPANSA JSON');
    const data = JSON.parse(text.slice(start));
    if (!data || Array.isArray(data) || typeof data !== 'object') throw new Error('Invalid CPANSA database');
    const index = new Map();
    for (const [distribution, entries] of Object.entries(data)) {
      if (!Array.isArray(entries)) throw new Error('Invalid CPANSA advisory list');
      const advisories = entries.map(entry => {
        if (!entry || typeof entry !== 'object') throw new Error('Invalid CPANSA advisory');
        const ranges = entry.affected_versions ?? entry.version_range ?? [];
        if (!Array.isArray(ranges)) throw new Error('Invalid affected-version list');
        const alternatives = ranges.map(compileRange);
        const ids = Array.isArray(entry.cves) ? entry.cves.filter(id => typeof id === 'string') : [];
        if (typeof entry.cve_id === 'string') ids.push(entry.cve_id);
        if (typeof entry.cpansa_id === 'string') ids.push(entry.cpansa_id);
        return {ids: [...new Set(ids)], affects: version =>
          alternatives.length === 0 || alternatives.some(matches => matches(version))};
      });
      index.set(distribution, advisories);
    }
    return index;
  }

  function findAdvisories(index, row) {
    // Advisories apply to distribution releases, not a bundled module's $VERSION.
    const filename = row.path.split('/').pop();
    const release = filename.match(/^(.+)-(v?\d[\d._]*)(?:-TRIAL)?\.(?:tar\.(?:gz|bz2|xz|zst|Z)|tgz|tbz2|zip|tar)$/i);
    if (!release) return [];
    const advisories = index.get(release[1]);
    if (!advisories) return [];
    let version;
    try { version = parseVersion(release[2]); } catch { return []; }
    return advisories.filter(advisory => advisory.affects(version));
  }

  async function download(onStatus) {
    onStatus('Downloading CVE list…');
    const response = await fetch(feedUrl, {credentials: 'omit', mode: 'cors'});
    if (!response.ok) throw new Error(`CVE download: HTTP ${response.status}`);
    const text = await response.text();
    onStatus('Reading CVE list…');
    return parseFeed(text);
  }

  return Object.freeze({feedUrl, parseVersion, compareVersions, parseFeed, findAdvisories, download});
})();
