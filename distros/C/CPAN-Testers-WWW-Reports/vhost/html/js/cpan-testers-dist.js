function loadVersionDropdown() {
  var ddselect = document.getElementById('version');
  ddselect.options.length=0;

  for(var i=0; i<versions.length; i++) {
    var dist = distros[versions[i]];
    if(dist) {
      distro = dist[0];
      if( prefs.oncpan == 0 ||
         (prefs.oncpan == 1 && distro.oncpan == 'cpan') ||
         (prefs.oncpan == 2 && distro.oncpan == 'back')) {
        if( prefs.distmat == 0 ||
           (prefs.distmat == 1 && distro.distmat == 'off') ||
           (prefs.distmat == 2 && distro.distmat == 'dev')) {
          var ddoption = document.createElement('option');
          ddoption.value = versions[i];
          ddoption.appendChild(document.createTextNode(versions[i]));
          ddselect.appendChild(ddoption);
        }
      }
    }
  }

  // IE hack to force a redraw of the <select> element
  ddselect.parentNode.replaceChild(ddselect,ddselect);
}

function setDisplayedVersion() {
  var myrows  = 0;
  var rows    = document.createElement('tbody');
  rows.setAttribute('id','report_data');
  var select  = document.getElementById('version');
  var svalue  = select.value;
  var reports = results[svalue];
  var header  = distros[svalue][0].header;
  var modhead = document.getElementById('modulehead');
  modhead.innerHTML = header;


  var re_patch = new RegExp('\\bpatch\\b');
  var re_perl  = new RegExp('\\b'+prefs.perlver+'\\b');

  var row;
  if(reports) {
    for(var i=0; i<reports.length; i++) {
      var report = reports[i];

      if(report) {
        if(prefs.status == report.status || prefs.status == 'ALL') {
          if(  prefs.patch == 0 ||
              (prefs.patch == 1 && !re_patch.test(report.perl)) ||
              (prefs.patch == 2 &&  re_patch.test(report.perl))) {
            if( prefs.perlmat == 0 ||
               (prefs.perlmat == 1 && report.perlmat == 'rel') ||
               (prefs.perlmat == 2 && report.perlmat == 'dev')) {
              if(prefs.osname == 'ALL' || prefs.osname == report.osname) {
                if(prefs.perlver == 'ALL' || re_perl.test(report.perl)) {
                  // Create new <tr> table row
                  row = document.createElement('tr');
                
                  // Create a link to the report details
                  var link = document.createElement('a');
                  var href = '/cpan/report/' + (report.guid || report.id);
                  link.setAttribute('href',href);
                  link.appendChild(document.createTextNode(report.status));

                  // Create a <td> for the report status and set class name
                  var status = document.createElement('td');
                  status.appendChild(link);
                  status.className = report.status.toUpperCase();
                  row.appendChild(status);
                
                  var properties = ['perl','ostext','osvers','archname'];
                  for(var p=0; p<properties.length; p++) {
                    var td = document.createElement('td');
                    td.appendChild(document.createTextNode(report[properties[p]]));
                    row.appendChild(td);
                  }
                  rows.appendChild(row);
                  myrows = myrows + 1;
		}
              }
            }
          }
        }
      }
    }
  }

  if(myrows == 0) {
    row = document.createElement('tr');
            
    // Create paragraph text
    var para = document.createElement('span');
    para.setAttribute('class','alert');
    para.appendChild(document.createTextNode('No reports found. select another distribution version, or alter your preferences'));

    // Create a <td> for the report status and set class name
    var cell = document.createElement('td');
    cell.setAttribute('colspan',6);
    cell.appendChild(para);
    row.appendChild(cell);
    rows.appendChild(row);
  }

  var tbody = document.getElementById('report_data');
  tbody.parentNode.replaceChild(rows,tbody);

  var srows = document.createElement('tbody');
  srows.setAttribute('id','stats_data');
  var rowclass = 'row';
  for(var i=0; i<stats.length; i++) {
    var stat = stats[i];
    if(  prefs.patch == 0 ||
        (prefs.patch == 1 && !re_patch.test(stat.perl)) ||
        (prefs.patch == 2 &&  re_patch.test(stat.perl))) {
      if(prefs.perlver == 'ALL' || re_perl.test(stat.perl)) {
        // Create new <tr> table row
        row = document.createElement('tr');
        row.setAttribute('class',rowclass);
              
        var ver = document.createElement('td');
        ver.appendChild(document.createTextNode(stat.perl));
        row.appendChild(ver);

        // Create a <td> for the perl version
        for(var j=0; j<stat.counts.length; j++) {
          var num = document.createElement('td');
          num.appendChild(document.createTextNode(stat.counts[j]));
          row.appendChild(num);
        }
        
        srows.appendChild(row);
        if(rowclass == 'row') { rowclass = 'altrow'; }
        else                  { rowclass = 'row';    }
      }
    }
  }

  var sbody = document.getElementById('stats_data');
  if(sbody) { sbody.parentNode.replaceChild(srows,sbody); }
}

function callSummary() {
  OpenThought.CallUrl('/cgi-bin/reports-summary.cgi', 'dist_pref', 'perlmat_pref', 'patches_pref', 'oncpan_pref', 'distmat_pref', 'perlver_pref', 'osname_pref' );
}

function reloadReports() {
  loadVersionDropdown();
  setDisplayedVersion();
  callSummary();
}

function displayReports() {
  setDisplayedVersion();
  permlink();
  callSummary();
}

function selectReports(vers) {
  var elem = document.getElementById('version');
  for(var i =0;i<elem.options.length;i++) {
    if(elem[i].value == vers) {
      elem.selectedIndex = i;
    }
  }
  setDisplayedVersion();
  permlink();
}

function init() {
  vers = getparam('version');
  if(vers) {
    dist = document.getElementById('dist_pref');
    distvers = dist.value + '-' + vers;
  } else {
    distvers = versions[0];
  }

  readCookies();
  loadVersionDropdown();
  selectReports(distvers);
  callSummary();
}
