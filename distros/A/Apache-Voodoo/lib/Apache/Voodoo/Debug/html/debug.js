// Ajax handler for Voodoo's native debugging functions.  This contains modified versions
// of Sean Kane's Feather Ajax and the reference JSON parser found at JSON.org.
// The original copyright notices for those components appear below, along with
// comments in the code noting where they begin, end and how they were modified.

//Created by Sean Kane (http://celtickane.com/programming/code/ajax.php)
//Feather Ajax v1.0.1

/*
    http://www.JSON.org/json2.js
    2008-11-19

    Public Domain.

    NO WARRANTY EXPRESSED OR IMPLIED. USE AT YOUR OWN RISK.

    See http://www.JSON.org/js.html

	This is a reference implementation. You are free to copy, modify, or
    redistribute.

    This code should be minified before deployment.
    See http://javascript.crockford.com/jsmin.html

    USE YOUR OWN COPY. IT IS EXTREMELY UNWISE TO LOAD CODE FROM SERVERS YOU DO
    NOT CONTROL.

*/

function voodooJson() {
	//////////////////////////////////////////////////////////////////////////////////
	// JSON library
	//
	// The stringify function and it's supporting functions have been removed
	// since this object only needs the parse function.
	// The comments were extremely verbose and have been removed.
	//////////////////////////////////////////////////////////////////////////////////
	this.f = function (n) {
		return n<10?'0'+n:n;
	};

	if (typeof Date.prototype.toJSON !== 'function') {
		Date.prototype.toJSON = function(key) {
			return this.getUTCFullYear()+'-'+f(this.getUTCMonth()+1)+'-'+f(this.getUTCDate())+'T'+f(this.getUTCHours())+':'+f(this.getUTCMinutes())+':'+f(this.getUTCSeconds())+'Z';
		};
		String.prototype.toJSON = Number.prototype.toJSON = Boolean.prototype.toJSON = function (key) {
			return this.valueOf();
		};
	}
	var cx=/[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,escapeable=/[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,gap,indent,meta={'\b':'\\b','\t':'\\t','\n':'\\n','\f':'\\f','\r':'\\r','"':'\\"','\\':'\\\\'},rep;

	this.parse = function(text,reviver) {
		var j;
		function walk(holder,key) {
			var k,v,value = holder[key];
			if (value&&typeof value==='object') {
				for (k in value) {
					if (Object.hasOwnProperty.call(value,k)) {
						v = walk(value,k);
						if (v!==undefined) {
							value[k]=v;
						}
						else {
							delete value[k];
						}
					}
				}
			}
			return reviver.call(holder,key,value);
		}
		cx.lastIndex=0;
		if (cx.test(text)) {
			text=text.replace(cx,
				function(a) {
					return '\\u'+('0000'+a.charCodeAt(0).toString(16)).slice(-4);
				}
			);
		}
		if (/^[\],:{}\s]*$/.test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g,'@').replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,']').replace(/(?:^|:|,)(?:\s*\[)+/g,''))) {
			j = eval('('+text+')');
			return typeof reviver==='function'?walk({'':j},''):j;
		}
		throw new SyntaxError('voodooDebug.parse');
	};
}

function voodooAjax() {
	//////////////////////////////////////////////////////////////////////////////////
	// Feather Ajax
	//////////////////////////////////////////////////////////////////////////////////

	// reference to the calling object
	this.caller = null;

	// ..and the associated set method
	this.setResponseHandler = function(obj) {
		this.caller = obj;
	};

	this.createRequestObject = function() {
		var ro;
		try {
			ro=new XMLHttpRequest();
		}
		catch(e) {
			ro=new ActiveXObject("Microsoft.XMLHTTP");
		}
		return ro;
	};

	this.http = this.createRequestObject();
	var me = this;
	this.sndReq = function(action,url,data) {
		if (action.toUpperCase()=="POST") {
			this.http.open(action,url,true);
			this.http.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
			this.http.onreadystatechange=this.handleResponse;
			this.http.send(data);
		}
		else {
			this.http.open(action,url+'?'+data,true);
			this.http.onreadystatechange=this.handleResponse;
			this.http.send(null);
		}
	};

	this.handleResponse = function() {
		// Stripped down to only call the response handler passing it the response content
		if (me.http.readyState==4) {
			me.caller.handleResponse(me.http.responseText);
		}
	};
}

function voodooDebug(opts) {
	this.debug_root = opts.debug_root;
	this.app_id     = opts.app_id;
	this.session_id = opts.session_id;
	this.request_id = opts.request_id;

	this.origin_id  = this.request_id;

	this.imgSpinner = new Image(16,16);
	this.imgMinus   = new Image(9,9);
	this.imgPlus    = new Image(9,9);

	this.imgSpinner.src = this.debug_root+"/spinner.gif";
	this.imgMinus.src   = this.debug_root+"/minus.png";
	this.imgPlus.src    = this.debug_root+"/plus.png";

	this.elementid = 1; //counter so we can generate unique element ids.

	this.levels = {
		"debug":     1,
		"info":      1,
		"warn":      1,
		"error":     1,
		"exception": 1,
		"table":     1,
		"trace":     1
	};

	this.openSections = {
		"profile":       false,
		"debug":         false,
		"return_data":   false,
		"session":       false,
		"template_conf": false,
		"parameters":    false
	};

	this.parser = new voodooJson();

	this.imgLevels = {};
	for (var key in this.levels) {
		this.imgLevels[key] = new Image(12,12);
		this.imgLevels[key].src = this.debug_root+"/"+key+".png";
	}

	this.yourBrowserIsBroken = (navigator.userAgent.toLowerCase().indexOf("msie")!=-1);

	////////////////////////////////////////////////////////////////////////////////
	//
	// PUBLIC METHODS
	//
	////////////////////////////////////////////////////////////////////////////////

	// pulls down the list of ajax requests made by the page we're looking at
	this.listRequests = function() {
		var params = 'app_id='     +this.app_id+
		             '&session_id='+this.session_id+
		             '&request_id='+this.origin_id;

		this.sendRequest('request',params);
	};

	// Changes the which request we're looking at; refreshes all the open sections
	this.changeRequest = function(obj) {
		this.request_id = obj.value;
		for (var section in this.openSections) {
			if (this.openSections[section]) {
				this.loadSection(section);
			}
		}
	};

	// Changes the debug block filtering options
	this.filterDebug = function(obj,level) {
		document.getElementById("vd_debug").innerHTML = '<img src="'+this.imgSpinner.src+'">';
		this.levels[level] = (this.levels[level])?0:1;

		var params = 'app_id='     +this.app_id+
		             '&session_id='+this.session_id+
		             '&request_id='+this.request_id;

		for (var i in this.levels) {
			params += '&' + i + '='	+ this.levels[i];
		}
		this.sendRequest('debug',params);
	};

	// Handles the opening or closing of the various debug panels
	this.handleSection = function(obj, section) {
		if (obj.parentNode.className == "vdOpen") {
			obj.parentNode.className = 'vdClosed';
			obj.firstChild.src=this.imgPlus.src;

			if (section != "top") {
				this.openSections[section] = false;
			}
		}
		else {
			obj.parentNode.className = 'vdOpen';
			obj.firstChild.src=this.imgMinus.src;

			if (section != "top") {
				this.openSections[section] = true;
				this.loadSection(section);
			}
			else {
				// make sure the select list of urls has at least the current page listed
				var select = document.getElementById("voodooDebugSelect");
				if (select.length < 1) {
					select.add(new Option(location.pathname,this.origin_id),null);
				}
			}
		}

		if (this.yourBrowserIsBroken) {
			var selectState;
			if (section == "top") {
				selectState = (obj.parentNode.className == "vdOpen") ? 'hidden': 'visible';
			}
			else {
				selectState = 'hidden';
			}
			var selects = document.getElementsByTagName("SELECT");
			for (var i = 0; i < selects.length; i++) {
				selects[i].style.visibility = selectState;
			}
		}
		return false;
	};


	////////////////////////////////////////////////////////////////////////////////
	//
	// Methods associated with making the ajax requests
	//
	////////////////////////////////////////////////////////////////////////////////

	// Replaces the newly opened (or refreshed) sub panel's contents with the spinner
	// image and fires the ajax request pull down the content
	this.loadSection = function(section) {
		document.getElementById("vd_"+section).innerHTML = '<img src="'+this.imgSpinner.src+'">';

		var params = 'app_id='     +this.app_id+
		             '&session_id='+this.session_id+
		             '&request_id='+this.request_id;

		if (section == "debug") {
			for (var i in this.levels) {
				params += '&' + i + '='	+ this.levels[i];
			}
		}
		this.sendRequest(section,params);
	};

	this.sendRequest = function(addr,params) {
		var ajax = new voodooAjax();
		ajax.setResponseHandler(this);
		ajax.sndReq('get',this.debug_root+"/"+addr,params);
	};


	////////////////////////////////////////////////////////////////////////////////
	//
	// Methods for handling the ajax response and creating the display
	//
	////////////////////////////////////////////////////////////////////////////////

	// Main ajax response handler, all ajax responses enter here.
	this.handleResponse = function(rawdata) {
		var data = this.parser.parse(rawdata);

		var h;
		if (data.value === null || data.value.length <= 0 ) {
			h = "<i>(empty)</i>";
		}
		else {
			if (data.constructor == Object) {
				switch (data.key) {
					case 'vd_request':
						this.handleListRequests(data.value);
						return;	// *sigh* this ended up being a special case.
					case 'vd_profile':     h = this.handleTable(     data.value); break;
					case 'vd_debug':       h = this.handleDebug(     data.value); break;
					case 'vd_return_data': h = this.handleReturnData(data.value); break;
					default:               h = this.dumpData(        data.value); break;
				}
			}
			else {
				h = "<span>"+data+"</span>";
			}
		}
		document.getElementById(data.key).innerHTML = h;
	};

	// Updates the select list of requests.
	this.handleListRequests = function(data) {
		var select = document.getElementById("voodooDebugSelect");
		while (select.length > 0) {
			select.remove(0);
		}

		for (var i=0; i < data.length; i++) {
			select.add(new Option(data[i].url,data[i].request_id),null);
			if (data[i].request_id == this.request_id) {
				select.selectedIndex = i;
			}
		}
	};

	this.handleTable = function(data) {
		var h = '<table>';
		h += '<tr><th>'+data[0].join('</th><th>')+'</th></tr>';

		for (j=1; j < data.length; j++) {
			h += '<tr class="vdTableRow';
			h += (j%2)?'Odd':'';
			h += '"><td>';
			h += data[j].join('</td><td>');
			h += '</td></tr>';
		}
		h += "</table>";
		return h;
	};

	this.handleDebug = function(data) {
		var i;

		var stack = [];

		var h = '<ul>';
		for (i=0; i < data.length; i++) {
			var row = data[i];
			var rstack = row.stack.reverse();

			if (rstack.length > 0) {
				var depth;
				for (depth=0; depth < rstack.length || depth < stack.length; depth++) {
					if (rstack[depth]                === undefined ||
						stack[depth]             === undefined ||
						stack[depth]['class']    !== rstack[depth]['class'] ||
						stack[depth]['function'] !== rstack[depth]['function']) {

						while (stack.length > depth) {
							// pop stack up to the point that everything matches
							h += '</li></ul>';
							stack.pop();
						}

						if (rstack[depth] !== undefined) {
							// push new item
							stack.push(rstack[depth]);
							h += '<li class="vdOpen"><span class="vdClick" onClick="vdDebug.toggleUL(this);">'+
								'<img src="'+this.imgMinus.src+'" />'+
								rstack[depth]['class'] +
								rstack[depth]['type'].replace('<','&lt;').replace('>','&gt;') +
								rstack[depth]['function'] + "</span><ul>";
						}
					}
				}
				h += '<li><img src="'+this.imgLevels[row.level].src+'"/> ' + rstack[0]['line'] + ':';
			}

			if (row.level == "table") {
				h += row.data[0];
				h += this.handleTable(data[i].data[1]);
			}
			else if (row.level == "exception" || row.level == "trace") {
				h += row.data;
				h += this.handleTable(this.convertStackToTable(row.stack));
			}
			else {
				h += this.dumpData(row.data);
			}

			h += '</li>';
		}

		// close all the openg dl's.  This will be however deep the stack is.
		for (i=0; i <= stack.length; i++) {
			h += '</li></ul>';
		}

		return h;
	};

	this.convertStackToTable = function(data) {
		var t = [];
		t.push(['Class','Subroutine','Line','Args']);
		for (var i=0; i<data.length; i++) {
			var args = [];
			if (data[i]['args'] instanceof Array) {
				for (var j=0; j<data[i]['args'].length; j++) {
					args.push(this.dumpData(data[i]['args'][j],true));
				}
			}

			t.push([
				data[i]['class'],
				data[i]['function'],
				data[i]['line'],
				args.join(',')
			]);
		}
		return t;
	};

	this.handleReturnData = function(data) {
		var h = '<dl>';
		for (j=0; j < data.length; j++) {
			h += '<dt>'+data[j][0].replace(/>/g,'&gt;') + ': ' + this.dumpData(data[j][1]) + '</dt>';
		}
		h += '</dl>';
		return h;

	};

	// walks a JSON data structure and creates a collapsible view of it.
	this.dumpData = function(data,closed) {
		var a = [];
		if (data === null) {
			return "<i>undefined</i>";
		}
		else if (data.constructor == Object) {
			for (var key in data) {
				a.push('<li>' + key + ' => ' + this.dumpData(data[key]));
			}

			if (a.length > 0) {
				return this._mkblock(a,closed,'{','}');
			}
			else {
				return "{}";
			}
		}
		else if (data.constructor == Array) {
			if (data.length > 0) {
				for (var j=0; j < data.length; j++) {
					a.push('<li>' + this.dumpData(data[j]));
				}
				return this._mkblock(a,closed,'[',']');
			}
			else {
				return "[]";
			}
		}
		else {
			var d = String(data);
			return '"' + d.replace(/"/g,'\\"').replace('<','&lt;').replace('>','&gt;') + '"';
		}
	};

	this._mkblock = function(a,closed,l,r) {
		var o = 'vdVisible';
		var c = 'vdInvisible';
		if (closed) {
			o = 'vdInvisible';
			c = 'vdVisible';
		}

		var id = this.makeId();
		return '<span class="'+c+'" id="' +id+'-c"><span class="vdClick" onClick="vdDebug.toggleData(\''+id+'\')">'+l+'<i>' + a.length + ' elements...</i>'+r+'</span></span>'+
		       '<span class="'+o+'" id="' +id+'-o"><span class="vdClick" onClick="vdDebug.toggleData(\''+id+'\')">'+l+'</span><ul>' + a.join(",</li>") + '</li></ul>'+r+'</span';
	};

	this.toggleUL = function(obj) {
		if (obj.parentNode.className == "vdOpen") {
			obj.parentNode.className = "vdClosed";
			obj.firstChild.src=this.imgPlus.src;
		}
		else {
			obj.parentNode.className = "vdOpen";
			obj.firstChild.src=this.imgMinus.src;
		}
	};

	this.toggleData = function(id) {
		var first  = document.getElementById(id+'-c');
		var second = document.getElementById(id+'-o');
		var tmp = first.className;
		first.className = second.className;
		second.className = tmp;
	};

	this.makeId = function() {
		this.elementid += 1;
		return 'voodooDebug_id_'+this.elementid;
	};
}
