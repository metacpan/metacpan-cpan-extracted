var select_open = false;
var last_keypress = undefined;
var timer_id = undefined;
var timer_arg = undefined;

function populate_emails( event ) {
	var str = '';
	var evt = (event) ? event : ((window.event) ? window.event : null);
	if (! evt) { 
		if (timer_arg != undefined) {
			str = timer_arg;
		} else {
			return;
		}
	} else {
		var elem = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null);
		if (! elem) { return; }
		var char = isIE ? evt.keyCode : evt.which;
		if (char == 13 || char == 40) {
			// return or downarrow
			var list = $("emaillist");
			if (list) {
				list.focus();
				return;
			}
		} else if (char == 8 || char == 127) {
			str = elem.value.substr( 0, elem.value.length - 1 ); 
		} else if (    (char == 43)
                    || (char == 45)
                    || (char == 46)
                    || (char >= 48 && char <= 57)
                    || (char >= 64 && char <= 90) 
                    || (char == 95)
		            || (char >= 97 && char <= 122) 
                  ) {
			str = elem.value + String.fromCharCode( char );
		}
	}

	if (timer_id != undefined) {
		clearTimeout( timer_id );
		timer_id = undefined;
		timer_arg = undefined;
	}
	if (last_keypress == undefined) {
		last_keypress = new Date();
	} else {
		// if the last keypress was less than half a second ago, 	
		// wait to see if we get any more input
		var now = new Date();
		if (now.getTime() - last_keypress.getTime() < 500) {
			timer_arg = str;
			timer_id = setTimeout( "populate_emails()", 501 );
			return;
		}
	}

	var list = $("emaillist");
	if (list) {
		$("email_list").removeChild( list );
	}
	var url = '';
	if (str.length > 2) {
		url = 'email_search.cgi?str=' + str;
	}
	if (url != '' && select_open == false) {
		clearTimeout( timer_id );
		last_keypress = undefined;
		select_open = true;
		new Ajax.Request( url, {
			method: 'get',
			onSuccess: add_emails_to_list
		} );
	}
}

function select_email( event )
{
	var list = $("emaillist");
	if (! list) { return; }
	var evt = (event) ? event : ((window.event) ? window.event : null);
	if (! evt) { return; }
	var elem = list.selectedIndex > -1 ? list.options[list.selectedIndex] : undefined;
	if (! elem) { return; }

	if (evt.type == 'mouseup' || evt.type == 'change' || evt.type == 'click') {
		add_to_field( elem );
	} else if (evt.type == 'keypress') {
		var char = isIE ? evt.keyCode : evt.which;
		if (char == 13) {
			add_to_field( elem );
		}
	}
}

function add_emails_to_list( req ) {
	var emails = req.responseXML.getElementsByTagName("ITEM");

	if (emails.length > 0) {
		// problem: the select is outside the tab order

		var list = document.createElement("select");
		list.id = 'emaillist';
		list.size = 10;
		list.onchange = select_email;
		list.onkeypress = select_email;
		$("email_list").appendChild( list );

		for (var i = 0; i < emails.length; i++) {
			append_to_select(list , i, emails[i] );
		}
	}
	select_open = false;
}

function append_to_select( select, index, item ) {
	var opt = document.createElement("option");

	var label = item.getAttribute('email');
	var targettext = label;
	opt.id_num = item.getAttribute('id');

	var txt = document.createTextNode(label);
	opt.targettext = targettext;
	opt.value = txt;
	opt.appendChild(txt);
	select.appendChild(opt);
}

function add_to_field( elem )
{
    var email = document.getElementById('email');
    email.value = elem.text;
}

