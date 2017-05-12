YAHOO.namespace("periapt");

YAHOO.periapt.Editor = function(elementId) {
    YAHOO.widget.Editor.superclass.constructor.call(this, elementId, {
    	width: 450,
		handleSubmit: true,
    	animate: true //Animates the opening, closing and moving of Editor windows
    });
    this._defaultToolbar.titlebar = false;
    this._defaultToolbar.buttons = [
		{ group: 'textstyle', label: 'Font Style',
        	buttons: [
        		{ type: 'push', label: 'Bold CTRL + SHIFT + B', value: 'bold' },
            	{ type: 'push', label: 'Italic CTRL + SHIFT + I', value: 'italic' }
        	]
    	},
		{ type: 'separator' },
	    { group: 'parastyle', label: 'Paragraph Style',
	        buttons: [
		        { type: 'select', label: 'Normal', value: 'heading', disabled: true,
           			menu: [
           				{ text: 'Normal', value: 'none', checked: true },
           				{ text: 'Subheading', value: 'h3' }
           			]
       			}
       		]
    	},
    	{ type: 'separator' },
    	{ group: 'indentlist', label: 'Lists',
       		buttons: [
           		{ type: 'push', label: 'Create an Unordered List', value: 'insertunorderedlist' },
		    ]
    	},
    	{ type: 'separator' },
    	{ group: 'insertitem', label: 'Insert Item',
       		buttons: [
           		{ type: 'push', label: 'HTML Link CTRL + SHIFT + L', value: 'createlink', disabled: true },
           		{ type: 'push', label: 'Insert Image', value: 'insertimage' }
       		]
    	}
	];
	
	this.on('toolbarLoaded', function() {
		this.toolbar.on ('createlinkClick', function(o) {
            try {
                 var Dom=YAHOO.util.Dom;
                 var labels = Dom.getElementsBy(
                 		function(o) {
                			return true;
                   		},
                   		'label',
                   		elementId + '-panel'
                 );
                 for(var l = 0; l < labels.length; l++) {
                 	if (Dom.getElementsBy(
                   		function(o) {
                   			if (o.id == elementId+"_createlink_target") {
                   				return true;
                   		    }
                       		return false;
                      	},
                       	'input',
                       	labels[l]
                     ).length > 0) {
                     	labels[l].className="hide";
                     }
                 }
            }
            catch(l) {
            	alert(l.message);
            }
        });
		this.toolbar.on ('insertimageClick', function(o) {
			try {
               var imgPanel=new YAHOO.util.Element(elementId + '-panel');
               imgPanel.on ( 'contentReady', function() {
               		try {
                       var Dom=YAHOO.util.Dom;
                       if (! Dom.get(elementId + '_insertimage_upload')) {
                       		var label=document.createElement('label');
                       		label.innerHTML='<strong>Upload:</strong><input type="file" id="' +
				  					elementId + '_insertimage_upload" name="file" size="10" style="width: 300px" /><input type="hidden" name="rm" value="ajax_upload_rm"/>';
                       		
                       		var img_elem=Dom.get(elementId + '_insertimage_url');
                       		Dom.getAncestorByTagName(img_elem, 'form').encoding = 'multipart/form-data';
                       		Dom.insertAfter(label, img_elem.parentNode);
                       		
                       		var labels = Dom.getElementsBy(
                       			function(o) {
                       				return true;
                       			},
                       			'label',
                       			elementId + '-panel'
                       		);
                       		for(var l = 0; l < labels.length; l++) {
                       			if (Dom.getElementsBy(
                       				function(o) {
                       					if (o.id == elementId+"_insertimage_link") {
                       						return true;
                       					}
                      					if (o.id == elementId+"_insertimage_target") {
                       						return true;
                       					} 
                       					return false;
                       				},
                       				'input',
                       				labels[l]
                       			).length > 0) {
                       				labels[l].className="hide";
                       			}
                       		}
                       		
                            YAHOO.util.Event.on ( elementId + '_insertimage_upload', 'change', function(ev) {
                            	YAHOO.util.Event.stopEvent(ev); // no default click action
                            	YAHOO.util.Connect.setForm ( img_elem.form, true);
                            	var c=YAHOO.util.Connect.asyncRequest(
                               		'POST',
                               		'/cgi-bin/template.cgi', {
                               			upload: function(o) {
                               				var resp=o.responseText.replace( /<pre>/i, '').replace ( /<\/pre>/i, '');
                               				var data = YAHOO.lang.JSON.parse(resp);
                               				if (data.status == "UPLOADED") {
                               					Dom.get(elementId + '_insertimage_upload').value='';
                               					Dom.get(elementId + '_insertimage_url').value=data.image_url;
                               					// tell the image panel the url changed
                                               // hack instead of fireEvent('blur')
                                               // which for some reason isn't working
                                               Dom.get(elementId + '_insertimage_url').focus();
                                               Dom.get(elementId + '_insertimage_upload').focus();
                               				}
                               				else {
                               					alert(data.status);
                               				}
                               			},
                               		}
                               	);
                            	return false;
                           	});
                           	
                           	
					   }
               		}
               		catch(ee) {
               			alert(ee.message);
               		}
               	});
			}
			catch(e) {
				alert(e.message);
			}
		});
	}, this, true);
	
	
};


YAHOO.lang.extend(YAHOO.periapt.Editor, YAHOO.widget.Editor);

var myEditor = new YAHOO.periapt.Editor('body');
myEditor.render();
