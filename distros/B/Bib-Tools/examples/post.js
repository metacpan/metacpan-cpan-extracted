function GetCellValues(dataTable) {
    // Generate JSON with details of selected documents
    var table = document.getElementById(dataTable);
    if (table == null) return;
    var i = 0; var Obj = [];
    var names = table.rows[0];
    for (var r = 1; r < table.rows.length; r++) {
        if (table.rows[r].id == 'cite') {
          var row = table.rows[r].cells;
          var check = table.rows[r].getElementsByTagName('Input');
          if (check.length>0){
            Obj[i] = {};
            for (var c = 3; c < row.length; c++){        
              var tag = names.cells[c].textContent;
              Obj[i][tag] =row[c].textContent;
            }
            i = i+1;
          }
        }
    }
    var jsonString = JSON.stringify(Obj);
    document.getElementById('out').innerHTML = document.getElementById('out').innerHTML+jsonString;
}

//--------------------------------------
// Code below creates popup for structured input of author details
//--------------------------------------

function initAuth() {
  // attach popups to every author list cell
  SetAuthEvents('doi');
  SetAuthEvents('nodoi');
}

function SetAuthEvents(dataTable) {
  // attach popups to every author list cell
  var table = document.getElementById(dataTable);
  if (table == null) return;
  var rows = table.rows;
  for (var i = 1; i<rows.length; i++) {
    if (rows[i].id == "cite") {
      var col = rows[i].cells[5];
      col.contentEditable=false;
      col.addEventListener("click",HandleAuth,false);
    }
  }
}

function ShowAuth(el) {
  // get author list
  var s = el.textContent;
  var bits = s.split(/ and /);
  var str = '';
  for (var i = 0; i<bits.length; i++) {
     str += bits[i]+"\n";
  }

  // create popup
  var m = document.createElement("div");
  m.id = "auth";
  m.style.cssText="position:absolute; background:#0E73B9; padding:10px; box-shadow:10px 10px 5px #888888; border:1px solid;";
  // textarea with authors, one per line
  m.innerHTML = '<textarea rows="'+(bits.length+2)+'">'+str+'</textarea><br>';
  // save button
  var save = document.createElement("input");
  save.type="button"; save.value="Save"; save.addEventListener("click", HandleAuth, false);
  // cancel button
  var cancel = document.createElement("input");
  cancel.type="button"; cancel.value="Cancel"; cancel.addEventListener("click", HandleAuth, false);
  m.appendChild(save);m.appendChild(cancel);

  // insert it into cell
  el.insertBefore(m,el.firstChild);

  // display it
  m.style.display="block";
}

function CloseAuth(el) {
  var m = el.parentNode;
  var td = m.parentNode;
  if (td == null) return; // to handle multiple clicks due to bubbling
  if (el.value == "Save") {
    // extract author list info
    var auths = m.firstChild.value;
    auths = auths.replace(/\n+/g,' and ');
    auths = auths.replace(/^ and /,'');
    auths = auths.replace(/ and $/,'');
    // delete popup
    td.removeChild(td.firstChild);
    // update table entry
    td.textContent=auths;
  } else {
    // just delete popup
    td.removeChild(td.firstChild);
  }
}

function HandleAuth(e) {
  var el;
  if (!e) {
      el = event.target || event.srcElement;
  } else {
      el = e.target || e.srcElement;
  }
  if (el.tagName == "INPUT") {
    // save or cancel button
    CloseAuth(el);
  } else if (el.tagName == "TD") {
    ShowAuth(el);
  }
}

// add click event listeners to table cells once page has loaded ...
window.addEventListener("load", initAuth, false);
