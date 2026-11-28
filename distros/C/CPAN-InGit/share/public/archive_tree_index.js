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
  const groupModules = document.getElementById('group-modules');
  const groupModulesLabel = document.getElementById('group-modules-label');
  const groupPreview = 10;
  const expandedGroups = new Set();
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

  // Presentation only: fold a module under an earlier module of the listed rows when the
  // earlier name is a namespace prefix of it and both rows describe the same distribution.
  // It works on whatever rows the filter left, so filtering still sees every module.
  function groupRows(rows) {
    const groups = [];
    const open = [];
    for (const row of rows) {
      while (open.length && !row.name.startsWith(open[open.length - 1].row.name)) open.pop();
      let head = null;
      if (groupModules.checked) {
        for (let i = open.length - 1; i >= 0 && !head; i--) {
          const candidate = open[i].row;
          // A different review link means the module would move to a different distribution.
          if (row.name.startsWith(candidate.name + '::') && row.path === candidate.path
              && (row.review_url ?? null) === (candidate.review_url ?? null)) head = open[i];
        }
      }
      if (head) {
        head.children.push(row);
      } else {
        const group = {row, children: []};
        groups.push(group);
        open.push(group);
      }
    }
    return groups;
  }

  function moduleCell(group) {
    const {row, children} = group;
    const td = document.createElement('td');
    if (!children.length) {
      td.textContent = row.name;
      return td;
    }
    const name = document.createElement('span');
    name.textContent = row.name;
    td.append(name);
    const expanded = expandedGroups.has(row.name);
    for (const child of expanded ? children : children.slice(0, groupPreview)) {
      const sub = document.createElement('span');
      sub.className = 'submodule';
      sub.textContent = child.name;
      if (child.version !== row.version) {
        const version = document.createElement('span');
        version.className = 'submodule-version';
        version.textContent = ' ' + child.version;
        sub.append(version);
      }
      td.append(sub);
    }
    if (children.length > groupPreview) {
      const toggle = document.createElement('button');
      toggle.type = 'button';
      toggle.className = 'submodule-toggle';
      toggle.textContent = expanded ? 'Show fewer' : `Show ${children.length - groupPreview} more`;
      toggle.addEventListener('click', () => {
        if (expanded) expandedGroups.delete(row.name); else expandedGroups.add(row.name);
        render();
      });
      td.append(toggle);
    }
    return td;
  }

  function render() {
    cveColumn.hidden = !cveIndex;
    const fragment = document.createDocumentFragment();
    let affected = 0;
    const groups = groupRows(source.modules);
    for (const group of groups) {
      const row = group.row;
      const tr = document.createElement('tr');
      const advisories = cveIndex ? CPANInGitCves.findAdvisories(cveIndex, row) : [];
      if (advisories.length) {
        // Advisories belong to the distribution, so the folded modules are affected too
        affected += 1 + group.children.length;
        tr.className = 'cve-affected';
      }
      tr.hidden = !!cveIndex && onlyCves.checked && !advisories.length;
      tr.append(moduleCell(group));
      {
        const td = document.createElement('td');
        td.textContent = row.version;
        tr.append(td);
      }
      if (advisories.length) tr.children[1].title = advisories.flatMap(advisory => advisory.ids).join(', ');
      if (root.dataset.sourceVersions === 'true') {
        const td = document.createElement('td');
        td.className = 'source-version';
        if (row.review_url) {
          const link = document.createElement('a');
          link.textContent = row.source_version;
          link.href = row.review_url;
          link.target = '_blank';
          link.rel = 'noopener';
          td.append(link);
        } else {
          td.textContent = row.source_version ?? '';
        }
        tr.append(td);
      }
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
      : `Showing ${source.modules.length} modules${groups.length < source.modules.length ? ` in ${groups.length} rows` : ''}${source.complete ? ' (all matches).' : '.'}`;
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
  groupModulesLabel.hidden = false;
  groupModules.addEventListener('change', render);
  // A browser may restore the checkbox as checked when the page is reloaded.
  if (groupModules.checked) render();
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
