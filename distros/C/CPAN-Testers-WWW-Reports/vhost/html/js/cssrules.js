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

function check_grade(item)   {  reset_grade(item);   checkVis1(); permlink(); displayReports(); }
function check_perlmat(item) {  reset_perlmat(item); checkVis1(); permlink(); displayReports(); }
function check_patches(item) {  reset_patches(item); checkVis1(); permlink(); displayReports(); }


/* CSS/JS code for CPAN/BACKPAN availability and distribution release type */

var NEWPREFS2 = 10; // On CPAN and Offical releases only
var OLDPREFS2 = 15; // all

function checkCSS2(val,css) {
       if((NEWPREFS2 & val) == val)   { makeVis(css, 'block'); }
  else if((OLDPREFS2 & val) == val)   { makeVis(css, 'none');  }
}


function checkVis2() {
  checkCSS2( 5,'backdev');
  checkCSS2( 6,'backoff');
  checkCSS2( 9,'cpandev');
  checkCSS2(10,'cpanoff');

  OLDPREFS2 = NEWPREFS2;
}

function reset_oncpan(item)   {      if (item[0].selected) { NEWPREFS2 = (NEWPREFS2 & 3) + 12; prefs.oncpan = 0; } // All
                                else if (item[1].selected) { NEWPREFS2 = (NEWPREFS2 & 3) +  8; prefs.oncpan = 1; } // CPAN
                                else if (item[2].selected) { NEWPREFS2 = (NEWPREFS2 & 3) +  4; prefs.oncpan = 2; } // Backpan
}
function reset_distmat(item)  {      if (item[0].selected) { NEWPREFS2 = (NEWPREFS2 & 12) + 3; prefs.distmat = 0; } // All
                                else if (item[1].selected) { NEWPREFS2 = (NEWPREFS2 & 12) + 2; prefs.distmat = 1; } // Official Only
                                else if (item[2].selected) { NEWPREFS2 = (NEWPREFS2 & 12) + 1; prefs.distmat = 2; } // Development Only
}

function check_oncpan(item)  {  reset_oncpan(item);  checkVis2(); permlink(); reloadReports(); }
function check_distmat(item) {  reset_distmat(item); checkVis2(); permlink(); reloadReports(); }



/* CSS/JS code for OS and Perl version filtering */

function reset_perlver(item) {  prefs.perlver = item[item.selectedIndex].value; }
function reset_osname(item)  {  prefs.osname  = item[item.selectedIndex].value; }

function check_perlver(item) { reset_perlver(item); permlink(); displayReports(); }
function check_osname(item)  { reset_osname(item);  permlink(); displayReports(); }



/* ** COOKIE CONTROL ** */

function createCookie(name,value,days) {
  var expires = "";
  if (days) {
    var date = new Date();
    date.setTime(date.getTime()+(days*24*60*60*1000));
    expires = "; expires="+date.toGMTString();
  }
  document.cookie = name+"="+value+expires+"; path=/";
}

function readCookie(name) {
  var nameEQ = name + "=";
  var ca = document.cookie.split(';');
  for(var i=0;i < ca.length;i++) {
    var c = ca[i];
    while (c.charAt(0)==' ') { c = c.substring(1,c.length); }
    if (c.indexOf(nameEQ) == 0) { return c.substring(nameEQ.length,c.length); }
  }
  return null;
}

function eraseCookie(name) {
  createCookie(name,"",-1);
}

function readCookies() {
  var rs = getparam('grade');
  if(!rs) { rs = readCookie('grade'); }
  if(!rs) { rs = 1; }
  var elem = document.getElementById('grade_pref');
  elem.selectedIndex = rs-1;
  reset_grade(elem);

       if(rs == 1) { prefs.status = 'ALL';     }
  else if(rs == 2) { prefs.status = 'PASS';    }
  else if(rs == 3) { prefs.status = 'FAIL';    }
  else if(rs == 4) { prefs.status = 'NA';      }
  else if(rs == 5) { prefs.status = 'UNKNOWN'; }

  rs = getparam('perlmat');
  if(!rs) { rs = readCookie('perlmat'); }
  if(!rs) { rs = 2; }
  elem = document.getElementById('perlmat_pref');
  elem.selectedIndex = rs-1;
  reset_perlmat(elem);

  prefs.perlmat = rs-1;

  rs = getparam('patches');
  if(!rs) { rs = readCookie('patches'); }
  if(!rs) { rs = 2; }
  elem = document.getElementById('patches_pref');
  elem.selectedIndex = rs-1;
  reset_patches(elem);

  prefs.patch = rs-1;

  rs = getparam('oncpan');
  if(!rs) { rs = readCookie('oncpan'); }
  if(!rs) { rs = 2; }
  elem = document.getElementById('oncpan_pref');
  elem.selectedIndex = rs-1;
  reset_oncpan(elem);

  prefs.oncpan = rs-1;

  rs = getparam('distmat');
  if(!rs) { rs = readCookie('distmat'); }
  if(!rs) { rs = 2; }
  elem = document.getElementById('distmat_pref');
  elem.selectedIndex = rs-1;
  reset_distmat(elem);

  prefs.distmat = rs-1;

  rs = getparam('perlver');
  if(!rs) { rs = readCookie('perlver'); }
  if(!rs) { rs = 'ALL'; }
  elem = document.getElementById('perlver_pref');
  for(var i =0;i<elem.options.length;i++) {
    if(elem[i].value == rs) {
      elem.selectedIndex = i;
    }
  }
  reset_perlver(elem);

  prefs.perlver = rs;

  rs = getparam('osname');
  if(!rs) { rs = readCookie('osname'); }
  if(!rs) { rs = 'ALL'; }
  elem = document.getElementById('osname_pref');
  for(var i =0;i<elem.options.length;i++) {
    if(elem[i].value == rs) {
      elem.selectedIndex = i;
    }
  }
  reset_osname(elem);

  prefs.osname = rs;

  checkVis1();
  checkVis2();
  permlink();
}



/* ** COMMAND LINE PARAMETER CONTROL ** */

function getparam( name ) {
  name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
  var regexS = "[\\?&;]"+name+"=([^&#]*)";
  var regex = new RegExp( regexS );
  var results = regex.exec( window.location.href );
  if( results == null ) {
    return "";
  } else {
    return results[1];
  }
}

function permlink() {
  var link = parent.location + "";
  if(link.indexOf('?') != -1) {
    link = link.substring(0,link.indexOf('?'));
  }

  var elem = document.getElementById('grade_pref');
  link += '?grade='+(elem.selectedIndex+1);

  elem = document.getElementById('perlmat_pref');
  link += '&perlmat='+(elem.selectedIndex+1);

  elem = document.getElementById('patches_pref');
  link += '&patches='+(elem.selectedIndex+1);

  elem = document.getElementById('oncpan_pref');
  link += '&oncpan='+(elem.selectedIndex+1);

  elem = document.getElementById('distmat_pref');
  link += '&distmat='+(elem.selectedIndex+1);

  elem = document.getElementById('perlver_pref');
  link += '&perlver='+(elem[elem.selectedIndex].value);

  elem = document.getElementById('osname_pref');
  link += '&osname='+(elem[elem.selectedIndex].value);

  elem = document.getElementById('version');
  if(elem && elem.selectedIndex >= 0 && elem[elem.selectedIndex]) {
    vers = elem[elem.selectedIndex].value;
    dist = document.getElementById('dist_pref');
    if(dist) {
      vers = vers.substring(dist.value.length+1);
      link += '&version='+vers;
    }
  }

  elem = document.getElementById('PermLink');
  elem.href = link;
}



/* ** PREFERENCE ADMIN ** */

function savePrefs() {
  var elem = document.getElementById('grade_pref');
  createCookie('grade',elem.selectedIndex+1,1000);

  elem = document.getElementById('perlmat_pref');
  createCookie('perlmat',elem.selectedIndex+1,1000);

  elem = document.getElementById('patches_pref');
  createCookie('patches',elem.selectedIndex+1,1000);

  elem = document.getElementById('oncpan_pref');
  createCookie('oncpan',elem.selectedIndex+1,1000);

  elem = document.getElementById('distmat_pref');
  createCookie('distmat',elem.selectedIndex+1,1000);

  elem = document.getElementById('perlver_pref');
  createCookie('perlver',elem.selectedIndex+1,1000);

  elem = document.getElementById('osname_pref');
  createCookie('osname',elem.selectedIndex+1,1000);
}

function resetPrefs() {
  var rs = readCookie('grade');
  var elem = document.getElementById('grade_pref');
  if(!rs) { rs = 1; }
  elem.selectedIndex = rs-1;

  rs = readCookie('perlmat');
  elem = document.getElementById('perlmat_pref');
  if(!rs) { rs = 2; }
  elem.selectedIndex = rs-1;

  rs = readCookie('patches');
  elem = document.getElementById('patches_pref');
  if(!rs) { rs = 2; }
  elem.selectedIndex = rs-1;

  rs = readCookie('oncpan');
  elem = document.getElementById('oncpan_pref');
  if(!rs) { rs = 2; }
  elem.selectedIndex = rs-1;

  rs = readCookie('distmat');
  elem = document.getElementById('distmat_pref');
  if(!rs) { rs = 2; }
  elem.selectedIndex = rs-1;

  rs = readCookie('perlver');
  elem = document.getElementById('perlver_pref');
  if(!rs) { rs = 'ALL'; }
  for(var i =0;i<elem.options.length;i++) {
    if(elem[i].value == rs) {
      elem.selectedIndex = i;
    }
  }

  rs = readCookie('osname');
  elem = document.getElementById('osname_pref');
  if(!rs) { rs = 'ALL'; }
  for(var i =0;i<elem.options.length;i++) {
    if(elem[i].value == rs) {
      elem.selectedIndex = i;
    }
  }
}

