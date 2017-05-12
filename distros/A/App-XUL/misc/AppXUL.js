function $ (id)
{
	return document.getElementById(id);
}

function dbg (string)
{
	Components.classes['@mozilla.org/consoleservice;1']
            .getService(Components.interfaces.nsIConsoleService)
            .logStringMessage(string);
}

function sleep (milliSeconds)
{
	var startTime = new Date().getTime(); // get the current time
	while (new Date().getTime() < startTime + milliSeconds); // hog cpu
}

function getRootNode (elem)
{ 
 	var objparent = elem.parentNode;
 	while (objparent) {
    elem = objparent;
    objparent = elem.parentNode; 
  }
  return elem;
}

function quit (aForceQuit)
{
	var appStartup = 
		Components.classes['@mozilla.org/toolkit/app-startup;1']
			.getService(Components.interfaces.nsIAppStartup);

	// send server the quit signal
	AppXUL.send("quit");
	
	// stop client server
	//AppXUL.serverWorker.terminate();
	
	// eAttemptQuit will try to close each XUL window, but the XUL window can cancel the quit
	// process if there is unsaved data. eForceQuit will quit no matter what.
	var quitSeverity = aForceQuit ? Components.interfaces.nsIAppStartup.eForceQuit :
																	Components.interfaces.nsIAppStartup.eAttemptQuit;
	
	appStartup.quit(quitSeverity);
}

var AppXUL = {

	string2xml: function (string) {
	
			var parser = 
				Components.classes["@mozilla.org/xmlextras/domparser;1"]
	        .createInstance(Components.interfaces.nsIDOMParser);
	         
	    var systemPrincipal = 
	    	Components.classes["@mozilla.org/systemprincipal;1"]
          .createInstance(Components.interfaces.nsIPrincipal);

	    //parser.init(systemPrincipal, null, null);
	                 
	    string = 
	    	//'<?xml version="1.0"?>'+"\n"+
	    	'<html:div xmlns="http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul" '+
					'xmlns:html="http://www.w3.org/1999/xhtml">'+string+'</html:div>';
			//dbg(string);

			var doc = parser.parseFromString(string, 'text/xml');
			if (doc.documentElement.namespaceURI === 'http://www.mozilla.org/newlayout/xml/parsererror.xml' &&
					doc.documentElement.tagName === 'parsererror') {
				//var errorDescription = doc.documentElement.firstChild.nodeValue;
				//dbg(errorDescription);
				return null;
			} else {
				doc = doc.childNodes[0];
				var elems = [];
				for (var i = 0; i < doc.childNodes.length; i++) {
					elems.push(doc.childNodes[i]);
				}
				//doc.setAttribute("xmlns","http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");
				//doc.setAttribute("xmlns:html","http://www.w3.org/1999/xhtml");
				return elems;
			}
		},
		
	xml2string: function (xml) {
	
			var serializer = Components.classes["@mozilla.org/xmlextras/xmlserializer;1"].createInstance(Components.interfaces.nsIDOMSerializer);
 			var string = serializer.serializeToString(xml);
 			return string;
		},

	// sends an ajax request
	ajax: function (url, string, onsuccess, onfailure, onwait) {	

			var xhr = new XMLHttpRequest();
			var success_cb = onsuccess;
			var failure_cb = onfailure;
			var wait_cb    = onwait;
			
			xhr.onreadystatechange = function () {
				if (wait_cb)
					wait_cb();
				if (xhr.readyState == 4) {
					if (xhr.status == 200) { 
						if (success_cb) 
							success_cb(xhr.responseText);
					} else {
						if (failure_cb)
							failure_cb(xhr.status, xhr.statusText);
					} 
				}
			};
			xhr.open("GET", url+"?data="+escape(string), true);
			xhr.send(null);
		},
	
	// updates the DOM based on a change description
	update: function (description) {
		if (description.action == 'update') {
			if ($(description.id)) {
				// update attributes
				for (var attr in description.attributes) {
					//dbg(description.id+"."+attr+" = '"+description.attributes[attr]+"'");
					$(description.id).setAttribute(attr, description.attributes[attr]);
				}
			}
		}
		else if (description.action == 'create') {
			if ($(description.parent)) {
				//dbg(description.content);
				var elems = AppXUL.string2xml(description.content);
				if (elems) {
					for (var i = 0; i < elems.length; i++) {
						try {
							$(description.parent).appendChild(elems[i]);
						} catch (err) {
							//dbg("err: "+err.name+" / "+err.message);
						}
					}
				}
				//dbg(AppXUL.xml2string($(description.parent)));
			}
		}
		else if (description.action == 'remove') {
			if ($(description.id)) {
				var parent = $(description.id).parentNode;
				parent.removeChild($(description.id));
			}
		}
		
		// perform sub-actions
		if (description.subactions) {
			for (var i = 0; i < description.subactions.length; i++) {
				AppXUL.update(description.subactions[i]);
			}
		}
	},
	
	// sends an event to the server
	send: function (eventType, elementId) {
	
			// send event to server	
			AppXUL.ajax(
				"http://localhost:3000/",
				'{"event":"'+eventType+'"'+(elementId ? ', "id":"'+elementId+'"' : '')+'}',
				function (responseText) { // success
					//dbg("Received:"+responseText);
					// integrate answer
					AppXUL.update(eval("("+responseText+')'));
				},
				function (status, statusText) { // failure
					dbg("Error: returned status code "+status+" "+statusText); 
				},
				function () { // wait
					//dbg("Waiting for server...");   
				}
			);
		},
		
	// processess an async message sent from a server
	async: function (string) {
			
			string = string.split(/\r?\n\r?/)[0];
			string = unescape(string.replace(/^GET \/\?data\=(.*) HTTP.*$/, '$1'));
			//dbg("async: "+string);
			
			var result = '{"content":""}';
			try {
				var action;
				eval("action = "+string);
				
				// perform action
				if (action.action == 'child') {
					if (action.id && (""+action.number).match(/^\d+$/)) {
						//dbg("num children "+$(action.id).childNodes.length);
						result = '{"content":"'+$(action.id).childNodes[action.number].id+'"}';
					}
				}
				else if (action.action == 'numchildren') {
					if (action.id) {
						result = '{"content":"'+$(action.id).childNodes.length+'"}';
					}
				}
				else if (action.action == 'insert') {
					if (action.id && action.position && action.content) {
						//dbg("insert xml "+action.content);
						var elems = AppXUL.string2xml(action.content);
						if (elems) {
							for (var i = 0; i < elems.length; i++) {
								try {
									$(action.id).appendChild(elems[i]);
								} catch (err) {
									//dbg("err: "+err.name+" / "+err.message);
								}
							}
						}
						//$(action.id).appendChild(AppXUL.string2xml(action.content));
					}				
				}
				else if (action.action == 'update') {
					if (action.id && action.content) {
						// remove child nodes
						while ($(action.id).childNodes.length > 0) {
							$(action.id).removeChild($(action.id).childNodes[0]);
						}
						// add new child node(s)
						var elems = AppXUL.string2xml(action.content);
						if (elems) {
							for (var i = 0; i < elems.length; i++) {
								try {
									$(action.id).appendChild(elems[i]);
								} catch (err) {
									//dbg("err: "+err.name+" / "+err.message);
								}
							}
						}
					}
				}
				else if (action.action == 'remove') {
					if (action.id && $(action.id).parentNode) {
						$(action.id).parentNode.removeChild($(action.id));
					}
				}
				else if (action.action == 'trigger') {
					if (action.id && action.name) {
						eval($(action.id).setAttribute('on'+action.name));
					}
				}
				else if (action.action == 'register') {
				}
				else if (action.action == 'unregister') {
					if (action.id && action.name) {
						$(action.id).setAttribute('on'+action.name, "");
					}				
				}
				else if (action.action == 'setattr') {
					if (action.id && action.name && action.value) {
						$(action.id).setAttribute(action.name, action.value);
						//dbg($(action.id).getAttribute(action.name));
					}
				}
				else if (action.action == 'getattr') {
					if (action.id && action.name) {
						result = '{"content":"'+$(action.id).getAttribute(action.name)+'"}';
					}				
				}
				else {
					dbg("Error: unknown action "+action.action+" called from backend.");
				}
				
			} catch (err) {
				dbg(err.message);
			}
			
			//dbg("  -> res = "+result);
			return result;
		}
};

var AppXULSocket = 
	Components.classes["@mozilla.org/network/server-socket;1"]
    .createInstance(Components.interfaces.nsIServerSocket);

AppXULSocket.init(3001, false, -1);
AppXULSocket.asyncListen({
	onSocketAccepted: function (socket, transport) {

		var rawInputStream = transport.openInputStream(0, 0, 0);
		var dataStream = 
			Components.classes["@mozilla.org/scriptableinputstream;1"]
				.createInstance(Components.interfaces.nsIScriptableInputStream);
		dataStream.init(rawInputStream);

		var rawOutputStream = transport.openOutputStream(0, 0, 0);
	
		var listener = {
			onDataAvailable:
				function (request, context, stream, offset, count) {
					var result = AppXUL.async(dataStream.read(count));
					//dbg("async result: "+result);
					
					// send result to socket
					rawOutputStream.write(result, result.length);
					
					rawInputStream.close();
					rawOutputStream.close();
				},
			onStartRequest:
				function () {
					//dbg("async request start");
				},
			onStopRequest:
				function () {
					//dbg("async request stop");
				}
			};

		var pump =
			Components.classes["@mozilla.org/network/input-stream-pump;1"]
				.createInstance(Components.interfaces.nsIInputStreamPump);
		pump.init(rawInputStream, -1, -1, 0, 0, false);
		pump.asyncRead(listener, null);
	}
});
