/*
 *  Apache2::WebApp::Toolkit - Admin Control Panel (disable.js)
 *  Copyright (C) 2010 Marc S. Brooks <mbrooks@cpan.org>
 *
 *  Licensed under the terms of the BSD License
 *  http://www.opensource.org/licenses/bsd-license.php
 */

function clickIE4() {
	if (event.button == 2) {
		return false;
	}
}

function clickNS4(e) {
	if (document.layers || document.getElementById && !document.all) {
		if (e.which == 2 || e.which == 3) {
			return false;
		}
	}
}

if (document.layers){
	document.captureEvents(Event.MOUSEDOWN);
	document.onmousedown = clickNS4;
}
else if (document.all && !document.getElementById) {
	document.onmousedown = clickIE4;
}

document.oncontextmenu = new Function("return false");
