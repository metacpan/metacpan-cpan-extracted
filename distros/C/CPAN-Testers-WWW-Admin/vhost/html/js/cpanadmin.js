/* ** DEFAULTS ** */

var prefs = {
  "status":  "ALL",
  "oncpan":  1,
  "distmat": 1,
  "perlmat": 1,
  "patch":   1,
  "osname":  'ALL',
  "perlver": 'ALL'
};

/* ** PREFERENCES ** */

function makeVis(theStyle,show) {
  //alert("style="+theStyle+", show="+show);

  var myclass = new RegExp('\\b'+theStyle+'\\b');
    var elem = document.getElementsByTagName('*');
    for (var i = 0; i < elem.length; i++) {
    if (myclass.test(elem[i].className)){
      elem[i].style.display = show;
    } else if (elem[i].className.search('number') != -1){
      elem[i].style.display = show;
    }
  }
}

/* CSS/JS code for grades, perl and patch preferences */

var NEWPREFS1 = 250;  // all grades, no devs or patches
var OLDPREFS1 = 255;  // all on

function checkCSS1(val,css) {
       if((NEWPREFS1 & val) == val)   { makeVis(css, 'table-row'); }
  else if((OLDPREFS1 & val) == val)   { makeVis(css, 'none');  }
}

function checkCSS2(val,css) {
       if((NEWPREFS1 & val) == val)   { makeVis(css, 'block'); }
  else if((OLDPREFS1 & val) == val)   { makeVis(css, 'none');  }
}

function checkVis1() {
  checkCSS1(133,'gPASSdevpat');
  checkCSS1(134,'gPASSdevunp');
  checkCSS1(137,'gPASSrelpat');
  checkCSS1(138,'gPASSrelunp');

  checkCSS1(69,'gFAILdevpat');
  checkCSS1(70,'gFAILdevunp');
  checkCSS1(73,'gFAILrelpat');
  checkCSS1(74,'gFAILrelunp');

  checkCSS1(37,'gNAdevpat');
  checkCSS1(38,'gNAdevunp');
  checkCSS1(41,'gNArelpat');
  checkCSS1(42,'gNArelunp');

  checkCSS1(21,'gUNKNOWNdevpat');
  checkCSS1(22,'gUNKNOWNdevunp');
  checkCSS1(25,'gUNKNOWNrelpat');
  checkCSS1(26,'gUNKNOWNrelunp');

  checkCSS2(133,'cbPASSdevpat');
  checkCSS2(134,'cbPASSdevunp');
  checkCSS2(137,'cbPASSrelpat');
  checkCSS2(138,'cbPASSrelunp');

  checkCSS2(69,'cbFAILdevpat');
  checkCSS2(70,'cbFAILdevunp');
  checkCSS2(73,'cbFAILrelpat');
  checkCSS2(74,'cbFAILrelunp');

  checkCSS2(37,'cbNAdevpat');
  checkCSS2(38,'cbNAdevunp');
  checkCSS2(41,'cbNArelpat');
  checkCSS2(42,'cbNArelunp');

  checkCSS2(21,'cbUNKNOWNdevpat');
  checkCSS2(22,'cbUNKNOWNdevunp');
  checkCSS2(25,'cbUNKNOWNrelpat');
  checkCSS2(26,'cbUNKNOWNrelunp');

  OLDPREFS1 = NEWPREFS1;
}

function reset_grade(item)   {       if (item[0].selected) { NEWPREFS1 = (NEWPREFS1 & 15) + 240; prefs.status = 'ALL';     } // ALL
                                else if (item[1].selected) { NEWPREFS1 = (NEWPREFS1 & 15) + 128; prefs.status = 'PASS';    } // PASS
                                else if (item[2].selected) { NEWPREFS1 = (NEWPREFS1 & 15) +  64; prefs.status = 'FAIL';    } // FAIL
                                else if (item[3].selected) { NEWPREFS1 = (NEWPREFS1 & 15) +  32; prefs.status = 'NA';      } // NA
                                else if (item[4].selected) { NEWPREFS1 = (NEWPREFS1 & 15) +  16; prefs.status = 'UNKNOWN'; } // UNKNOWN
}
function reset_perlmat(item) {       if (item[0].selected) { NEWPREFS1 = (NEWPREFS1 & 243) + 12; prefs.perlmat = 0; } // All
                                else if (item[1].selected) { NEWPREFS1 = (NEWPREFS1 & 243) +  8; prefs.perlmat = 1; } // Offical Only
                                else if (item[2].selected) { NEWPREFS1 = (NEWPREFS1 & 243) +  4; prefs.perlmat = 2; } // Development Only
}
function reset_patches(item) {       if (item[0].selected) { NEWPREFS1 = (NEWPREFS1 & 252) + 3; prefs.patch = 0; }  // All
                                else if (item[1].selected) { NEWPREFS1 = (NEWPREFS1 & 252) + 2; prefs.patch = 1; }  // Exclude Patches
                                else if (item[2].selected) { NEWPREFS1 = (NEWPREFS1 & 252) + 1; prefs.patch = 2; }  // Patches Only
}

function check_grade(item)   { reset_grade(item); checkVis1(); }



/* CSS/JS code for OS and Perl version filtering */

function reset_perlver(item) {  prefs.perlver = item[item.selectedIndex].value; }
function reset_osname(item)  {  prefs.osname  = item[item.selectedIndex].value; }

function check_perlver(item) { reset_perlver(item); }
function check_osname(item)  { reset_osname(item);  }


/* More Info Popup */

function more_info(guid,grade,dist,vers,perl,os,tester,author,date) {
  document.getElementById( 'info_guid'   ).innerHTML = guid;
  document.getElementById( 'info_grade'  ).innerHTML = grade;
  document.getElementById( 'info_dist'   ).innerHTML = dist;
  document.getElementById( 'info_vers'   ).innerHTML = vers;
  document.getElementById( 'info_perl'   ).innerHTML = perl;
  document.getElementById( 'info_os'     ).innerHTML = os;
  document.getElementById( 'info_date'   ).innerHTML = date;
  document.getElementById( 'info_tester' ).innerHTML = tester;
  document.getElementById( 'info_author' ).innerHTML = author;
  document.getElementById( 'cell_grade'  ).className = grade;
  showMenu();
}

function edit_tester(id,name,pause,refresh) {
  document.getElementById( 'edit_id'    ).value = id;
  document.getElementById( 'edit_name'  ).value = name;
  document.getElementById( 'edit_pause' ).value = pause;
  document.getElementById( 'refresh'    ).value = refresh;
  showMenu();
}

function less_info() {
  hideMenu();
}


var isNS  = (document.layers) ? 1:0
var isIE  = (document.all) ? 1:0
var isNS6 = (!document.all && document.getElementById) ? true : false;
//var isIE4 = document.all&&navigator.userAgent.indexOf("Opera")==-1
var isIEX = (window.ActiveXObject) ? true : false;


function togglecheckboxes(main) {
	for (i=0; i < document.reports.elements.length; i++) {
    if(document.reports.elements[i].style.display != 'none') {
  		document.reports.elements[i].checked = main.checked;
    }
	}
}

// Admin - Testers

function submit_tester() {
  new Ajax.Request('/tester/edit', {
    method: 'get',
    parameters: { 
      testerid: document.getElementById( 'edit_id'    ).value,
      name:     document.getElementById( 'edit_name'  ).value,
      pause:    document.getElementById( 'edit_pause' ).value
    },
    onSuccess:  SaveSuccess,
    onFailure:  SaveFailure
  });
}

function SaveSuccess(response) {
  hideMenu();
  //document.getElementById( 'listform' ).submit();

  var refresh = document.getElementById( 'refresh' ).value;
  if (refresh) {
    $('listform').submit();
  }
}

function SaveFailure(response) {
  alert("sorry, there was a problem trying to save your changes");
}

// Reports

function MarkReports() {
  $('reports-form').request({
    onSuccess:  MarkSuccess,
    onFailure:  MarkFailure
  });
  return false;
}

function MarkSuccess(response) {
  // loop through and mark rows
  //alert(JSON.stringify(response, null, 4));

  var json = response.responseText.evalJSON();
  json.data.each(function(elt){
    $('mark'+elt).innerHTML = 'marked';
  });
}

function MarkFailure(response) {
  alert("sorry, there was a problem marking those reports");
}

function UnmarkReports() {
  $('reports-form').request({
    onSuccess:  UnmarkSuccess,
    onFailure:  UnmarkFailure
  });
  return false;
}

function UnmarkSuccess(response) {
  // loop through and hide rows
  //alert(JSON.stringify(response, null, 4));

  var json = response.responseText.evalJSON();
  json.data.each(function(elt){
    $('row'+elt).style.display = 'none';
  });
}

function UnmarkFailure(response) {
  alert("sorry, there was a problem unmarking those reports");
}

function DeleteReports() {
  var ans = confirm('Are you sure you wish to delete these reports?');
  if(ans) {
    $('act').value = 'tester-delete';
    $('reports-form').request({
      onSuccess:  UnmarkSuccess,
      onFailure:  UnmarkFailure
    });
  }
  return false;
}
