/*
 *  Apache2::WebApp::Toolkit - Admin Control Panel (prompt.js)
 *  Copyright (C) 2010 Marc S. Brooks <mbrooks@cpan.org>
 *
 *  Licensed under the terms of the BSD License
 *  http://www.opensource.org/licenses/bsd-license.php
 */

function confirmDelete(name, url) {
	var answer = confirm("Are you sure you want to delete '" + name + "'");
	if (answer) {
		window.open(url, "_self");
	}
}

function changeOrder(mesg, url ) {
	var answer = prompt(mesg, "");
	if (answer) {
		window.open(url + "&new_value=" + answer, "_self");
	}
}
 
function sendEmail(url) {
	var answer = prompt("Please enter a valid e-mail address", "");
	if (answer) {
		window.open(url + "&email=" + answer, "_self");
	}
}
