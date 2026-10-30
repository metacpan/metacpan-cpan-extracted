'use strict';
(() => {
  const root = document.getElementById('cpan-index');
  if (!root) return;
  const input = document.getElementById('module-filter');
  const body = document.getElementById('module-rows');
  const status = document.getElementById('module-status');
  const more = document.getElementById('load-more');
  const all = document.getElementById('load-all');
  const checkCves = document.getElementById('check-cves');
  const onlyCves = document.getElementById('only-cves');
  const onlyCvesLabel = document.getElementById('only-cves-label');
  const cveState = document.getElementById('cve-state');
  const cveSpinner = document.getElementById('cve-spinner');
  const cveMessage = document.getElementById('cve-message');
  const cveColumn = document.getElementById('cve-column');
  let cveIndex = null;
  let checkingCves = false;
  let source = {
    filter: root.dataset.filter,
    tree: root.dataset.tree,
    modules: Array.from(body.querySelectorAll('tr'), row => JSON.parse(row.dataset.row)),
    complete: root.dataset.complete === 'true',
    next_after: root.dataset.nextAfter || null,
    previous_before: root.dataset.previousBefore || null
  };
  let completeCache = source.complete ? source : null;
  let revision = 0;
  let timer;
  let controller;
  let loading = false;
  let loadingAll = false;

  function updatePagination() {
    const filterChanged = input.value !== source.filter;
    more.hidden = !source.next_after;
    more.disabled = loading || loadingAll || filterChanged;
    all.hidden = source.complete && !loadingAll;
    all.disabled = !loadingAll && (loading || filterChanged);
    all.textContent = loadingAll ? 'Stop' : 'Load all';
  }

  function render() {
    cveColumn.hidden = !cveIndex;
    const fragment = document.createDocumentFragment();
    let affected = 0;
    for (const row of source.modules) {
      const tr = document.createElement('tr');
      const advisories = cveIndex ? CPANInGitCves.findAdvisories(cveIndex, row) : [];
      if (advisories.length) {
        ++affected;
        tr.className = 'cve-affected';
      }
      tr.hidden = !!cveIndex && onlyCves.checked && !advisories.length;
      for (const value of [row.name, row.version]) {
        const td = document.createElement('td');
        td.textContent = value;
        tr.append(td);
      }
      if (advisories.length) tr.children[1].title = advisories.flatMap(advisory => advisory.ids).join(', ');
      const reports = document.createElement('td');
      reports.className = 'cve-reports';
      reports.hidden = !cveIndex;
      const ids = [...new Set(advisories.flatMap(advisory => advisory.ids))];
      for (const id of ids.filter(id => /^CVE-\d{4}-\d{4,}$/.test(id))) {
        const report = document.createElement('a');
        report.className = 'cve-report';
        report.textContent = id;
        report.href = 'https://www.cve.org/CVERecord?id=' + encodeURIComponent(id);
        reports.append(report);
      }
      // Some CPANSA advisories have no assigned CVE number.
      if (advisories.length && !reports.children.length) reports.textContent = ids.join(', ');
      tr.append(reports);
      const td = document.createElement('td');
      const link = document.createElement('a');
      link.textContent = row.path;
      link.href = root.dataset.authorsUrl + row.path.split('/').map(encodeURIComponent).join('/');
      td.append(link);
      tr.append(td);
      fragment.append(tr);
    }
    body.replaceChildren(fragment);
    status.textContent = cveIndex
      ? `${affected} affected of ${source.modules.length} loaded modules.${source.next_after ? ' Load more to check additional modules.' : ''}`
      : `Showing ${source.modules.length} modules${source.complete ? ' (all matches).' : '.'}`;
    updatePagination();
  }

  async function requestPage(append, token) {
    controller = new AbortController();
    loading = true;
    updatePagination();
    status.textContent = `Loading modules… (${source.modules.length} loaded)`;
    const url = new URL(root.dataset.jsonUrl, document.baseURI);
    url.searchParams.set('filter', input.value);
    if (append) url.searchParams.set('after', source.next_after);
    try {
      const response = await fetch(url, {signal: controller.signal, headers: {Accept: 'application/json'}});
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const page = await response.json();
      if (token !== revision) return false;
      // A branch may advance between pages. Restart rather than combine different trees.
      if (append && page.tree !== source.tree) {
        completeCache = null;
        return requestPage(false, token);
      }
      if (append) {
        page.modules = source.modules.concat(page.modules);
        page.previous_before = source.previous_before;
        page.complete = !page.previous_before && !page.next_after;
      }
      source = page;
      if (completeCache && completeCache.tree !== page.tree) completeCache = null;
      if (page.complete) completeCache = page;
      loading = false;
      render();
      return true;
    } catch (error) {
      if (token !== revision || error.name === 'AbortError') return false;
      loading = false;
      updatePagination();
      status.textContent = 'Could not load modules. Please try again.';
      return false;
    }
  }

  function applyFilter(token) {
    const needle = input.value.toLowerCase();
    if (completeCache && needle.includes(completeCache.filter.toLowerCase())) {
      source = {...completeCache, filter: input.value,
        modules: completeCache.modules.filter(row => row.text.toLowerCase().includes(needle)),
        next_after: null, previous_before: null, complete: true};
      loading = false;
      render();
    } else {
      requestPage(false, token);
    }
  }

  function scheduleFilter() {
    const token = ++revision;
    clearTimeout(timer);
    if (controller) controller.abort();
    loadingAll = false;
    more.disabled = true;
    all.disabled = true;
    all.textContent = 'Load all';
    timer = setTimeout(() => applyFilter(token), 150);
  }
  input.addEventListener('input', scheduleFilter);
  document.getElementById('module-filter-form').addEventListener('submit', event => {
    event.preventDefault();
    scheduleFilter();
  });
  more.addEventListener('click', () => {
    if (!loading && !loadingAll && source.next_after && input.value === source.filter) requestPage(true, ++revision);
  });
  all.addEventListener('click', async () => {
    if (loadingAll) {
      ++revision;
      loadingAll = false;
      loading = false;
      if (controller) controller.abort();
      render();
      return;
    }
    if (loading || source.complete || input.value !== source.filter) return;
    const token = ++revision;
    loadingAll = true;
    updatePagination();
    try {
      // If the initial view started at a boundary, restart to include earlier matches.
      if (source.previous_before || !source.next_after) {
        if (!await requestPage(false, token)) return;
      }
      while (token === revision && !source.complete && source.next_after) {
        if (!await requestPage(true, token)) break;
      }
    } finally {
      if (token === revision) {
        loadingAll = false;
        updatePagination();
      }
    }
  });
  onlyCves.addEventListener('change', render);
  checkCves.hidden = false;
  checkCves.addEventListener('click', async () => {
    if (checkingCves || cveIndex) return;
    checkingCves = true;
    checkCves.hidden = true;
    cveState.hidden = false;
    cveSpinner.hidden = false;
    try {
      cveIndex = await CPANInGitCves.download(message => { cveMessage.textContent = message; });
      onlyCves.checked = true;
      onlyCvesLabel.hidden = false;
      cveState.hidden = true;
      render();
    } catch (error) {
      checkCves.hidden = false;
      cveSpinner.hidden = true;
      cveMessage.textContent = 'Could not load the CVE list. Please try again.';
    } finally {
      checkingCves = false;
    }
  });
})();
