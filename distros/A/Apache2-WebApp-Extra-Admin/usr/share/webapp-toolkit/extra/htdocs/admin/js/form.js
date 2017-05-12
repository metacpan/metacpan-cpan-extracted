/*
 *  Apache2::WebApp::Toolkit - Admin Control Panel (form.js)
 *  Copyright (C) 2010 Marc S. Brooks <mbrooks@cpan.org>
 *
 *  Licensed under the terms of the BSD License
 *  http://www.opensource.org/licenses/bsd-license.php
 */

var args = [];
var form;

function requireFields() {
	form = countForms();	// form position

	if (arguments.length) {
		args = arguments;
		document.onkeyup = function() { allowSubmit() }
		document.onclick = function() { allowSubmit() }
		allowSubmit();
	}

	eventFieldError();
}

function allowSubmit() {
	if ( fieldCheck() ) {
		document.getElementById("allow").disabled = false;
	}
	else {
		document.getElementById("allow").disabled = true;
	}
}

function fieldCheck() {
	for (var i = 0; i < args.length; i++) {
		var elm = document.forms[form].elements[args[i]];

		if (!elm.value) { return false }

		if (elm.type == "checkbox" || elm.type == "radio") {
			if (!elm.checked) {
				return false;
			}
		}
	}
	return true;
}

function countForms() {
	var total = 0;
	for (var i = 0; i < document.forms.length; i++) {
		total++;
	}

	if (total > 0) {
		return total - 1;	// array always begins with a 0
	}
	else {
		return 0;
	}
}

function eventFieldError() {
	var elm = document.getElementsByTagName("*");
	var obj = document.getElementById("alert");

	var error;

	for (var i = 0; i < elm.length; i++) {
		if (elm[i].className.match(/error/) ) {
			elm[i].onmouseover = function() {
				error = obj.innerHTML;
				obj.innerHTML = this.title;
				this.style.backgroundColor = "#FF0000";
				this.style.color           = "#FFFFFF";
			}
			elm[i].onmouseout = function() {
				obj.innerHTML = error;
				this.style.backgroundColor = "#FFFFFF";
				this.style.color           = "#FF0000";
			}
		}
	}
}

function eventSubmit() {
	document.getElementById("allow").onclick = function() {
		disableSubmit()
	};
}

function disableSubmit() {
	document.getElementById("allow").disabled = true;
	document.forms[form].submit();	// i.e. is lame, fix
}

function focusFirstField(name) {
	if (!name) { name = 0 }

	for(var i = 0; i < document.forms[name].length; i++) {
		if (document.forms[name][i].type == "text" ||
		    document.forms[name][i].type == "password") {
			if (document.forms[name][i].disabled != true) {
				document.forms[name][i].focus();
				break;
			}
		}
	}
}
