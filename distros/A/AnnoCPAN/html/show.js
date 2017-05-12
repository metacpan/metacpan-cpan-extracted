window.onload = init;

var Req;
var Form;
var Please_Wait;
var Hidden_Note;
var Edit_Buttons;
var Note_Links = [];
var Move_Msg;

function init() {
    Form = document.getElementById('noteform');
    Edit_Buttons = document.getElementById('edit_buttons');
    Form.save_button.onclick = save_note;
    Form.del_button.onclick  = delete_note;
    Form.hide_button.onclick = hide_note;

    Move_Msg = document.createElement('div');
    Move_Msg.innerHTML = "Moving note... please select destination";

    Please_Wait = document.getElementById('plswait');
    init_buttons(document);
}

function init_buttons(node) {
    var links = node.getElementsByTagName('a'); 
    for (var i = 0; i < links.length; i++) {
        var link    = links[i];
        var mode    = '';
        var note    = '';
        var notepos = '';
        var section = '';
        if (link.className == "cb") { // create
            mode = 'create';
            note = link;
            Note_Links.push(link);
            section = link.href.match(/section=(\d+)/)[1];
        } else if (link.className.match(/button/) 
            && (link.href.match(/mode=edit/))) 
        { // edit
            mode = 'edit';
            note = link.parentNode.parentNode.parentNode;
            notepos = link.href.match(/notepos=(\d+)/)[1];
        } else if (link.className.match(/button/) 
            && (link.href.match(/mode=move/))) 
        { // move
            note    = link.parentNode.parentNode.parentNode;
            notepos = link.href.match(/notepos=(\d+)/)[1];
            link.onclick = move_link_onclick('move', note, notepos);
        }

        if (mode) {
            link.onclick = edit_link_onclick(mode, note, notepos, section);
        } 
    }
    var help_link = document.getElementById('note_help_link');
    help_link.onclick = function () {
        window.open('/note_help', 'ac_help', 'width=500,height=450,resizable=yes,scrollbars=yes').focus();
        return false;
    }
}

// Shows the form when user clicks on edit or create note button
function edit_link_onclick (mode, note, notepos, section) {
    return function () {
        // move form here and show it
        if (Hidden_Note) {
            Hidden_Note.style.display = mode == 'create' ? 'inline' : 'block';
        }
        // alert('note='+note); return false;
        Hidden_Note = note;
        note.parentNode.insertBefore(Form, note);
        note.parentNode.insertBefore(Please_Wait, note);
        Form.notepos.value = notepos; 
        Form.section.value = section;
        if (mode == 'create') {
            Hidden_Note.style.display = "none";
            Form.style.display = "block";
            Form.note_text.value = ''; // XXX - may cause lost text
            Edit_Buttons.style.display = 'none';
            Form.note_text.focus();
        } else if (mode == 'edit') {
            set_note_plaintext(notepos);
            Edit_Buttons.style.display = 'inline';
        } else {
            alert('there is a mysterious bug');
        }
        return false;
    }
}

function move_link_onclick(mode, note, notepos) {
    return function() {
        if (Hidden_Note) {
            Hidden_Note.style.display = mode == 'create' ? 'inline' : 'block';
        }
        Hidden_Note = note;
        Hidden_Note.style.display = "none";
        // XXX
        note.parentNode.insertBefore(Move_Msg, note);

        for (var i = 0; i < Note_Links.length; i++) {
            var link = Note_Links[i];
            if (link.parentNode == note.parentNode) {  
                // hide
            }
            link.firstChild.src="/img/move_to.gif";
            link.firstChild.title="Move note here";
            link.onclick_create = link.onclick; // XXX
            link.onclick = move_note(notepos);
        }
        return false;
    }
}

function post_xml(url, data, on_success) {
    Req = getXMLHTTP();
    if (!Req) {
        Form.mode.value = 'save';
        return true;
    }
    Req.onreadystatechange = processReqChange(on_success);
    Req.open("POST", url, true);
    Req.send(data);
    Form.style.display = 'none';
    Please_Wait.style.display = 'block';
    return false;
}

function getXMLHTTP(){
  var A=null;
  try{
    A=new ActiveXObject("Msxml2.XMLHTTP")
  }catch(e){
    try{
      A=new ActiveXObject("Microsoft.XMLHTTP")
    } catch(oc){
      A=null
    }
  }
  if(!A && typeof XMLHttpRequest != "undefined") {
    A=new XMLHttpRequest()
  }
  return A
}

// noteform.onsubmit
function save_note() {
    var data;
    // Not very elegant, but works in IE 6 / Mozilla / Opera 8
    data = '<data>'
            + '<mode>save</mode><fast>1</fast>'
            + '<notepos>'   + Form.notepos.value                + '</notepos>'
            + '<section>'   + Form.section.value                + '</section>'
            + '<note_text>' + escape_html(Form.note_text.value) + '</note_text>'
        + '</data>';
    url  = '/save_xml.cgi';
    return post_xml(url, data, on_save);
}

function escape_html(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function unescape_html(s) {
    return s.replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>');
}


// on response
function on_save(response) {
    var el = document.createElement('div');
    el.innerHTML = response.responseText;
    var note = el.getElementsByTagName('div')[0];
    // alert('note='+note+' response='+response+' text='+response.responseText);
    Form.parentNode.insertBefore(note, Form);
    Please_Wait.style.display = 'none';
    if (Hidden_Note) {
        if (Hidden_Note.className == 'cb') {
            Hidden_Note.style.display = 'inline';
        } else {
            Hidden_Note.parentNode.removeChild(Hidden_Note);
        }
        Hidden_Note = false;
    }
    init_buttons(note);
    return false;
}

function processReqChange(on_success) {
    return function () {
        if (Req.readyState == 4) { // complete
            if (Req.status == 200) { // OK
                on_success(Req);
            } else {
                alert("There was a problem connecting to the server:\n" + Req.statusText);
            }
        }
    }
}

// on click
function delete_note() {
    if (confirm('Are you sure you want to delete this note?')) {
        var notepos = this.form.notepos.value;
        return get_xml('/?mode=delete;fast=1;notepos=' + notepos, on_delete);
    }
    return false; 
}

// on response
function on_delete(response) {
    var el = document.createElement('div');
    el.innerHTML = response.responseText;
    var msg = el.getElementsByTagName('div')[0];
    Hidden_Note.parentNode.insertBefore(msg, Hidden_Note);
    if (msg.className == 'message') {
        Hidden_Note.parentNode.removeChild(Hidden_Note);
        Hidden_Note = false;
        Form.style.display = 'none';
        Form.parentNode.removeChild(Form);
    }
    return false;
}

// on click on the arrow to select the destination
function move_note(notepos) {
    return function() {
        var section = this.href.match(/section=(\d+)/)[1];
        return get_xml('/?mode=do_move;fast=1;notepos=' + notepos + ';section=' + section, on_move(this));
    }
}

// on response
function on_move(link) {
    return function(response) {
        var el = document.createElement('div');
        el.innerHTML = response.responseText;
        var msg = el.getElementsByTagName('div')[0];
        Hidden_Note.parentNode.insertBefore(msg, Hidden_Note);
        if (msg.className == 'message') {
            Hidden_Note.parentNode.removeChild(Hidden_Note);
            Hidden_Note.style.display = 'block';
            link.parentNode.insertBefore(Hidden_Note, link);
            Hidden_Note = false;
            Move_Msg.parentNode.removeChild(Move_Msg);
        }
        for (var i = 0; i < Note_Links.length; i++) {
            Note_Links[i].firstChild.src="/img/note.gif";
            Note_Links[i].firstChild.title="Create note";
            Note_Links[i].onclick = Note_Links[i].onclick_create;
        }
        return false;
    }
}

function get_xml(url, on_success) {
    Req = getXMLHTTP();
    if (!Req) {
        return true;
    }
    Req.onreadystatechange = processReqChange(on_success);
    Req.open("GET", url, true);
    Req.send(null);
    return false;
}

function hide_note() {
    var notepos = this.form.notepos.value;
    return get_xml('/?mode=hide;fast=1;notepos=' + notepos, on_delete);
    return false; 
}

function note_plaintext(note) {
    var s = note.getElementsByTagName('div')[3].innerHTML;
    s = s.replace(/\s*<p>/gi, '');
    s = s.replace(/\s*<\/p>/gi, "\n");
    s = s.replace(/^\s+/, '').replace(/\s+$/, '');
    s = unescape_html(s);
    return s;
}

function set_note_plaintext(notepos) {
    document.getElementsByTagName('body')[0].style.cursor = 'wait';
    return get_xml('/?mode=raw_note;notepos=' + notepos, on_raw_note);
}

function on_raw_note(response) {
    var s = response.responseText;
    s = s.replace(/\n$/, '');
    Form.note_text.value = s;
    Hidden_Note.style.display = "none";
    Form.style.display = "block";
    document.getElementsByTagName('body')[0].style.cursor = 'auto';
    Form.note_text.focus();
}


