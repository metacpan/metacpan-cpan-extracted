/*
 *  Apache2::WebApp::Toolkit - Admin Control Panel (cookie.js)
 *  Copyright (C) 2010 Marc S. Brooks <mbrooks@cpan.org>
 *
 *  Licensed under the terms of the BSD License
 *  http://www.opensource.org/licenses/bsd-license.php
 */

function getCookie(name) {
	var obj = document.cookie;
	var arg = name + "=";
	var beg = obj.indexOf("; " + arg);

	if (beg == -1) {
		beg = obj.indexOf(arg);

		if (beg != 0) { return null };
	}
	else {
		beg += 2;
	}

	var end = document.cookie.indexOf(";", beg);

	if (end == -1) {
		end = obj.length;
	}

	return unescape(obj.substring(beg + arg.length, end));
}

function setCookie(name, value, expires, path, domain, secure) {
	document.cookie = name + "="  + escape(value) +
		((expires) ? "; expires=" + expires.toGMTString() : "") +
		((path)    ? "; path="    + path                  : "") +
		((domain)  ? "; domain="  + domain                : "") +
		((secure)  ? "; secure"                           : "");
}

function delCookie(name) {
	var val = getCookie(name);
	var exp = new Date();

	exp.setTime (exp.getTime() - 1);

	document.cookie = name + "=" + val + "; expires=" + exp.toGMTString();
}
