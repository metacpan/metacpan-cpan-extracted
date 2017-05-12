function setDisplayedVersion() {
  for(var d=0; d<versions.length; d++) {

    var myrows  = 0;
    var rows    = document.createElement('tbody');
    rows.setAttribute('id','data-'+versions[d]);

    var row;
    var reports = results[versions[d]];
    if(reports) {
      for(var i=0; i<reports.length; i++) {
        var report = reports[i];

        if(report) {

          var re_patch = new RegExp('\\bpatch\\b');
          var re_perl  = new RegExp('\\b'+prefs.perlver+'\\b');

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
      para.appendChild(document.createTextNode('No reports found. you may need to alter your preferences to see reports'));

      // Create a <td> for the report status and set class name
      var cell = document.createElement('td');
      cell.setAttribute('colspan',6);
      cell.appendChild(para);
      row.appendChild(cell);
      rows.appendChild(row);
    }

    var tbody = document.getElementById('data-'+versions[d]);
    if(tbody) { tbody.parentNode.replaceChild(rows,tbody); }

  }
}

function callSummary() {
  OpenThought.CallUrl('/cgi-bin/reports-summary.cgi', [ 'author_pref', 'perlmat_pref', 'patches_pref', 'oncpan_pref', 'distmat_pref', 'perlver_pref', 'osname_pref' ] );
}

function reloadReports() {
  setDisplayedVersion();
  callSummary();
}

function displayReports() {
  setDisplayedVersion();
  callSummary();
}

function init() {
  readCookies();
  setDisplayedVersion();
  callSummary();
}

