YAHOO.util.Event.onAvailable('authen_loginfield', function(o) {
	YAHOO.util.Dom.get('authen_loginfield').focus();
}, this);
YAHOO.util.Event.onAvailable('authen_rememberuserfield', function(o) {
	YAHOO.util.Dom.get('authen_loginfield').select();
}, this);