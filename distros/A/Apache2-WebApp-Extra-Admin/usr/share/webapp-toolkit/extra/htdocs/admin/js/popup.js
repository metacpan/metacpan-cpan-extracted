/*
 *  Apache2::WebApp::Toolkit - Admin Control Panel (popup.js)
 *  Copyright (C) 2010 Marc S. Brooks <mbrooks@cpan.org>
 *
 *  Licensed under the terms of the BSD License
 *  http://www.opensource.org/licenses/bsd-license.php
 */

function openWindow(url, win, h, w, resize, scroll) {
	resize = (resize) ? "yes" : "no";
	scroll = (scroll) ? "yes" : "no";
	window.open(url, win, "height=" + h + ",width=" + w + ",resizable=" + resize + ", scrollbars=" + scroll + ", toolbar=no");
}

function reloadParent() {
	window.opener.location.reload();
}

function closeWindow() {
	self.close();
}
