var next_counter;

var opener=Array(' <img src="closed.gif"> ',
                 ' <img src="opening.gif"> ',
                 ' <img src="open.gif"> ');

function get_data( counter ) {
  var d=$('div'+counter);
  var v={ key: decodeURI(d.getAttribute('ADM_KEY')),
	  uri: decodeURI(d.getAttribute('ADM_URI')) };
  return v;
}

function set_data( counter, key, uri ) {
  var d=$('div'+counter);
  d.setAttribute('ADM_KEY', encodeURI(key));
  d.setAttribute('ADM_URI', encodeURI(uri));
}

function find_parent( o, criteria ) {
  while( o ) {
    var found=true;
    for( var i in criteria ) {
      if( criteria[i] instanceof RegExp ) {
	if( !criteria[i].test(o[i]) ) {
	  found=false;
	  break;
	}
      } else if( criteria[i] instanceof String ||
		 typeof(criteria[i])=='string' ||
		 typeof(criteria[i])=='number' ) {
	if( o[i]!=criteria[i] ) {
	  found=false;
	  break;
	}
      } else if( criteria[i] instanceof Function ) {
	if( !criteria[i](o[i]) ) {
	  found=false;
	  break;
	}
      }
    }
    if( found ) return o;
    o=o.parentNode;
  }
  return null;
}

function add_outer_shortcuts() {
  var el=document.getElementsByTagName('body')[0];
  var func;

  func = function(e) {
    e = e || window.event;
			
    //Find Which key is pressed
    if (typeof(e.keyCode)=='number') code = e.keyCode;
    else if (typeof(e.which)=='number') code = e.which;
    var src=e.target!=null?e.target:e.srcElement;

    var propagate=true;
    if(src!=null && e.ctrlKey) {
      var o;
      var c;
      c=find_parent(src, {id: /^form(\d+)$/});
      if( c!=null ) {
	c=c.id.match(/^form(\d+)$/)[1];
      }
      if( !e.shiftKey && !e.altKey && !e.metaKey ) {
	switch(code) {
	case 83:		// ctrl+s: save
	  if( c!=null ) {
	    o=$('save'+c);
	    if( o.style.visibility!='hidden' ) xupdate(c, o, src);
	  }
	  propagate=false;
	  break;
	  
	case 190:		// ctrl+.: insert new action below
	  o=find_parent(src, {tagName: "TABLE", className: "inner_tdc"});
	  if( o ) xinsert( o.parentNode, 1 );
	  propagate=false;
	  break;
	  
	case 188:		// ctrl+,: insert new action above
	  o=find_parent(src, {tagName: "TABLE", className: "inner_tdc"});
	  if( o ) xinsert( o.parentNode, -1 );
	  propagate=false;
	  break;
	}
      } else if( e.shiftKey && !e.altKey && !e.metaKey ) {
	switch(code) {
	case 67:		// ctrl+shift+c: close
	  if( c!=null ) xclose(c, $('a'+c));
	  propagate=false;
	  break;

	case 85:		// ctrl+shift+u: reload
	  if( c!=null ) xreload(c, $('reload'+c), src);
	  propagate=false;
	  break;

	case 190:		// ctrl+shift+.: insert new block below
	  o=find_parent(src, {tagName: "TABLE", className: "inner_tdc"});
	  if( o ) xbinsert( o.parentNode, 1 );
	  propagate=false;
	  break;

	case 188:		// ctrl+shift+,: insert new block above
	  o=find_parent(src, {tagName: "TABLE", className: "inner_tdc"});
	  if( o ) xbinsert( o.parentNode, -1 );
	  propagate=false;
	  break;

	case 68:		// ctrl+shift+d: delete
	  o=find_parent(src, {tagName: "TABLE", className: "inner_tdc"});
	  if( o ) xdelete( o.parentNode, 1 );
	  propagate=false;
	  break;
	}
      }
    }

    if( propagate ) {
      if( !e.stopPropagation ) {
	e.cancelBubble = false;
	e.returnValue = true;
      }
    } else {
      //e.stopPropagation works in Firefox.
      if (e.stopPropagation) {
	e.stopPropagation();
	e.preventDefault();
      } else {
	e.cancelBubble = true;
	e.returnValue = false;
      }
    }

    return propagate;
  };

  //Attach the function with the event
  if(el.addEventListener)
    el.addEventListener('keydown', func, false);
  else if(el.attachEvent)
    el.attachEvent('onkeydown', func);
  else
    el['onkeydown'] = func;

  // now install the onchange handler
  func = function(e) {
    e = e || window.event;

    var src=e.target!=null?e.target:e.srcElement;
    if( src==null ) return false;
    var c;
    c=find_parent(src, {id: /^form(\d+)$/});
    if( c!=null ) {
      c=c.id.match(/^form(\d+)$/)[1];
    } else {
      return false;
    }

    //Find Which key is pressed
    if (typeof(e.keyCode)=='number') code = e.keyCode;
    else if (typeof(e.which)=='number') code = e.which;
    else return xchanged(c);

    if( code==0 ) return false;

    if(!e.ctrlKey && !e.altKey && !e.metaKey || e.type=='change') {
      if( code==Event.KEY_RETURN && e.type!='change' ) {
	if( src.tagName=='INPUT' ) return false;
      }

      if( code==Event.KEY_TAB ||
	  16<=code && code<=20 ||    // ctrl, shift, alt, caps, pause
	  33<=code && code<=40 ||    // left, right, up, down, pageup, pagedown, insert, home, end
	  code==45 ||		     // insert
	  144<=code && code<=145 ||  // scroll, numlock
	  code==91 || code==93 )     // menu, windows
	return false;

      return xchanged(c);
    }
    return false;
  };

  //Attach the function with the event
  if(el.addEventListener) {
    el.addEventListener('keyup', func, false);
    el.addEventListener('change', func, false);
  } else if(el.attachEvent) {
    el.attachEvent('onkeyup', func);
    el.attachEvent('onchange', func);
  } else {
    el['onkeyup'] = func;
    el['onchange'] = func;
  }
}

function add_inner_shortcuts( counter ) {
}

function add_resizer( counter ) {
  var resizer;

  if( typeof(counter)=="string" || typeof(counter)=="number" ) {
    resizer=$('div'+counter);
  } else {
    resizer=$(counter);
  }
  resizer=resizer.getElementsByTagName('table');

  for( var i=0; i<resizer.length; i++ ) {
    if( resizer[i].className=='inner_tdc' ) {
      new Resizeable( resizer[i], 
		      {top: 0, left: 0, bottom: 8, right: 0} );
    }
  }
}

function set_focus_to_first_input(counter, where) {
  var focus;

  if( typeof(counter)=="string" || typeof(counter)=="number" ) {
    focus=$('div'+counter);
  } else {
    focus=$(counter);
  }

  if( where==null ) {
    focus=focus.getElementsByTagName('input');

    for( var i=0; i<focus.length; i++ ) {
      if( focus[i].type=='text' ) {
	focus[i].focus();
	return;
      }
    }
    return;
  } else {
    var trs=focus.getElementsByTagName('tr');
    var n=0;
    for( var i=0; i<trs.length; i++ ) {
      if( trs[i].className=='tdc' && n==where ) {
	trs[i].getElementsByTagName('textarea')[0].focus();
	return;
      } else if( trs[i].className=='tdc' ) n++;
    }
    // not found so far. Set focus to the last textarea
    trs[trs.length-1].getElementsByTagName('textarea')[0].focus();
    return;
  }
}

function focus2index(o) {
  if( !o ) return null;
  o=find_parent(o, {tagName: 'TR', className: 'tdc'});
  if( !o ) return null;
  var trs=o.parentNode.getElementsByTagName('TR');
  var n=0;
  for( var i=0; i<trs.length; i++ ) {
    if( trs[i]==o ) return n;
    if( trs[i].className=='tdc' ) n++;
  }
  return null;
}

function xopen( counter ) {
  var data=get_data(counter);
  if( $('div'+counter).innerHTML.length>0 ) {
    Element.show( 'div'+counter );
    if( $('form'+counter).getAttribute('new_element') ) {
      $('reload'+counter).style.visibility='hidden';
      //Element.hide( 'reload'+counter );
    } else {
      $('reload'+counter).style.visibility='';
      //Element.show( 'reload'+counter );
    }
    Element.update( 'a'+counter, opener[2] );
    set_focus_to_first_input( counter );
  } else {
    Element.update( 'a'+counter, opener[1] );
    Element.show( 'progress' );
    new Ajax.Updater( { success: 'div'+counter },
	  	      'index.html',
		      { method: 'post',
			asynchronous: 1,
			parameters: {
			  a: 'fetch',
			  key: data.key,
			  uri: data.uri,
			  counter: counter
			},
		        onComplete: function(req) {
			  if( 200<=req.status && req.status<300 ) {
			    add_resizer( counter );
			    Element.show( 'div'+counter );
			    $('save'+counter).style.visibility='hidden';
			    //Element.hide( 'save'+counter );
			    $('reload'+counter).style.visibility='';
			    //Element.show( 'reload'+counter );
			    Element.update( 'a'+counter, opener[2] );
			    add_inner_shortcuts( counter );
			    set_focus_to_first_input( counter );
			  } else {
			    Element.update( 'a'+counter, opener[0] );
			    var err;
			    var errcode;
			    try {
			      err=req.getResponseHeader("X-Error");
			      errcode=req.getResponseHeader("X-ErrorCode");
			    } catch(e) {}
			    if( err != null && err.length > 0 ) {
			      alert("Sorry, an error has occured.\n"+
				    "The server says: "+err);
			      if( errcode=="1" ) xbdelete(counter);
			    } else {
			      alert("Sorry, an error has occured.\n"+
				    "The server says: "+req.statusText+" ("+
				    req.status+")");
			    }
			  }
			  Element.hide( 'progress' );
			}
		      } );
  }
}

function xreload( counter, o, focus ) {
  if(o) o.blur();
  focus=focus2index(focus);
  var data=get_data(counter);
  Element.update( 'a'+counter, opener[1] );
  Element.show( 'progress' );
  new Ajax.Updater( { success: 'div'+counter },
	  	      'index.html',
		    { method: 'post',
		      asynchronous: 1,
		      parameters: {
		        a: 'fetch',
			key: data.key,
			uri: data.uri,
			counter: counter
		      },
		      onComplete: function(req) {
		        if( 200<=req.status && req.status<300 ) {
			  add_resizer( counter );
		          //Element.show( 'div'+counter );
			  $('save'+counter).style.visibility='hidden';
		          //Element.hide( 'save'+counter );
			  $('reload'+counter).style.visibility='';
		          //Element.show( 'reload'+counter );
		          Element.update( 'a'+counter, opener[2] );
			  var f=$('form'+counter);
			  update_header(counter, f.newkey.value, f.newuri.value);
			  add_inner_shortcuts( counter );
			  set_focus_to_first_input( counter, focus );
		        } else {
		          Element.update( 'a'+counter, opener[2] );
			  var err;
			  var errcode;
			  try {
			    err=req.getResponseHeader("X-Error");
			    errcode=req.getResponseHeader("X-ErrorCode");
			  } catch(e) {}
			  if( err != null && err.length > 0 ) {
			    alert("Sorry, an error has occured.\n"+
				  "The server says: "+err);
			    if( errcode=="1" ) xbdelete(counter);
			  } else {
			    alert("Sorry, an error has occured.\n"+
				  "The server says: "+req.statusText+" ("+
				  req.status+")");
			  }
		        }
			Element.hide( 'progress' );
		      }
		    } );
  return false;
}

function xclose( counter ) {
  Element.hide( 'div'+counter );
  $('reload'+counter).style.visibility='hidden';
  //Element.hide( 'reload'+counter );
  Element.update( 'a'+counter, opener[0] );
  $('a'+counter).focus();
}

function xtoggle( counter, o ) {
  if(o) o.blur();
  if( Element.visible( 'div'+counter ) ) {
    xclose( counter );
  } else {
    if( $('a'+counter).innerHTML == opener[1] ) {
      return false;
    }
    xopen( counter );
  }

  return false;
}

function xchanged( counter ) {
  $('save'+counter).style.visibility='';
  //Element.show( 'save'+counter );
  var f=$('form'+counter);
  update_header(counter, f.newkey.value, f.newuri.value);
  return false;
}

function xreorder( counter ) {
  var f=$('form'+counter);
  var tds=f.getElementsByTagName("td");
  var block=0;
  var oldblock;
  var order;

  for (var i=0; i<tds.length; i++) {
    if( tds[i].className.match(/^tdc\d+$/) ) {
      if( oldblock==null ) {
	oldblock=tds[i].getAttribute("ADM_BLOCK");
	order=-1;
      }
      var hi=tds[i].getElementsByTagName("input")[0];
      var ta=tds[i].getElementsByTagName("textarea");
      var tc;
      if( ta && ta.length>1 ) tc=ta[1];
      ta=ta[0];
      var blk=tds[i].getAttribute("ADM_BLOCK");
      var ord=tds[i].getAttribute("ADM_ORDER");
      var id =tds[i].getAttribute("ADM_ID");

      if( blk!=oldblock ) {
	oldblock=blk;
	block++;
	order=0;
      } else {
	order++;
      }
      //debug("oldblock="+oldblock+" block="+block+" oldord="+ord+" ord="+
      //    order+" id="+id+"\n");
      ta.name="action_"+oldblock+"_"+block+"_"+ord+"_"+order+"_"+id;
      if( tc ) tc.name="note_"+block+"_"+order;
      hi.name="ysize_"+block+"_"+order;
      hi.value=Element.getHeight(tds[i])-(Prototype.Browser.IE ? 4 : 0);
    }
  }
}

function update_header( counter, key, uri ) {
  if( uri==":PRE:" || uri==":LOOKUPFILE:" ) {
    Element.update( 'header'+counter, key.escapeHTML() );
  } else {
    Element.update( 'header'+counter,
		    key.escapeHTML()+" <img class=\"pfeil\" src=\"pfeil.gif\"> "+ uri.escapeHTML() );
  }
}

function xupdate( counter, o, focus ) {
  if(o) o.blur();
  focus=focus2index(focus);
  xreorder( counter );
  var params=$('form'+counter).getElements().inject
    ({}, function(hash, element) {
       element = $(element);
       if (element.disabled) return hash;
       var method = element.tagName.toLowerCase();
       var parameter = Form.Element.Serializers[method](element);

       if (parameter && parameter.length) {
	 var key = element.name;
	 if (key.length == 0) return hash;

	 hash[key]=parameter;
       }
       return hash;
     });
  params["a"]="update";
  params["counter"]=counter;
  var d=get_data(counter);
  params["key"]=d.key;
  params["uri"]=d.uri;
  Element.update( 'a'+counter, opener[1] );
  Element.show( 'progress' );
  new Ajax.Updater( { success: 'div'+counter },
		    'index.html',
                    { method: 'post',
                      asynchronous: 1,
		      parameters: params,
		      onComplete: function(req) {
			if( 200<=req.status && req.status<300 ) {
			  add_resizer( counter );
			  $('save'+counter).style.visibility='hidden';
			  $('reload'+counter).style.visibility='';
			  var f=$('form'+counter);
			  set_data( counter, f.newkey.value, f.newuri.value );
			  update_header(counter, f.newkey.value, f.newuri.value);
			  add_inner_shortcuts( counter );
			} else {
			  var err;
			  var errcode;
			  try {
			    err=req.getResponseHeader("X-Error");
			    errcode=req.getResponseHeader("X-ErrorCode");
			  } catch(e) {}
			  if( err != null && err.length > 0 ) {
			    if( errcode=='1' ) {
			      xbdelete(counter);
			    } else {
			      alert("Sorry, an error has occured.\n"+
				    "The server says: "+err);
			    }
			  } else {
			    alert("Sorry, an error has occured.\n"+
				  "The server says: "+req.statusText+" ("+
				  req.status+")");
			  }
			}
			var el=$('a'+counter);
			if( el ) {
			  Element.update( el, opener[2] );
			  set_focus_to_first_input( counter, focus );
			}
			Element.hide( 'progress' );
		      }
                    } );
  return false;
}

function get_form_counter( o ) {
  return find_parent( o, {tagName: 'FORM'} ).getAttribute("ADM_COUNTER");
}

function xinsert( o, where ) {
  if(o) o.blur();
  var tr=find_parent( o, {tagName: 'TR', className: 'tdc'} );
  var newnode=tr.cloneNode(true);

  var ta=newnode.getElementsByTagName("textarea");
  ta[0].value='';
  if( ta && ta.length>1 ) ta[1].value='';

  var hidden=newnode.getElementsByTagName("td")[0];
  hidden.setAttribute("ADM_ORDER", "");
  hidden.setAttribute("ADM_ID", "");

  add_resizer( newnode );

  if( where<0 ) {
    tr.parentNode.insertBefore(newnode, tr);
  } else {
    if( tr.nextSibling ) {
      tr.parentNode.insertBefore(newnode, tr.nextSibling);
    } else {
      tr.parentNode.appendChild(newnode);
    }
  }

  $('save'+get_form_counter(tr)).style.visibility='';

  newnode.getElementsByTagName('textarea')[0].focus();

  return false;
}

function find_next_free_form_block( o ) {
  var form=find_parent( o, {tagName: 'FORM'} );
  var rc=form.getAttribute("ADM_NBLOCKS");
  form.setAttribute("ADM_NBLOCKS", rc+1);
  return rc;
}

function get_tr_block( o ) {
  //debug(o.inspect()+" class="+o.className+"\n");
  var rc=o.getElementsByTagName("td");
  if( rc && rc.length==0 ) return -1;
  rc=rc[0].getAttribute("ADM_BLOCK");
  if( rc==null ) return -1;
  else return rc;
}

function get_next_sibling( tr, what ) {
  what=what.toUpperCase();
  while( tr=tr.nextSibling ) {
    if( tr.nodeName==what ) return tr;
  }
  return null;
}

function get_prev_sibling( tr, what ) {
  what=what.toUpperCase();
  while( tr=tr.previousSibling ) {
    if( tr.nodeName==what ) return tr;
  }
  return null;
}

function update_bg( o ) {
  var tbl=find_parent( o, {tagName: 'TABLE'} );
  var trs=tbl.getElementsByTagName("tr");
  var style=-1;
  var block=-1;

  for (var i=0; i<trs.length; i++) {
    var td=trs[i].getElementsByTagName("td");
    if( td && td.length && td[0].className.match(/^tdc\d+$/) ) {
      if( get_tr_block(trs[i])!=block ) {
	block=get_tr_block(trs[i]);
	style=(style+1)%3;
      }
      td[0].className='tdc'+(style+1);
    }
  }
}

function xbdelete( counter ) {
  var n=$('header'+counter);
  n=n.parentNode;
  var p=n.parentNode;
  p.removeChild(n);
  n=$('div'+counter);
  p=n.parentNode;
  p.removeChild(n);
}

function xbinsert( o, where ) {
  if(o) o.blur();
  var tr=find_parent( o, {tagName: 'TR', className: 'tdc'} );
  var newnode=tr.cloneNode(true);
  
  var ta=newnode.getElementsByTagName("textarea");
  ta[0].value='';
  if( ta && ta.length>1 ) ta[1].value='';

  var hidden=newnode.getElementsByTagName("td")[0];
  hidden.setAttribute("ADM_BLOCK", find_next_free_form_block( tr ));
  hidden.setAttribute("ADM_ORDER", "");
  hidden.setAttribute("ADM_ID", "");

  add_resizer( newnode );

  var myblock=get_tr_block( tr );

  //debug("myblock="+myblock+"\n");

  if( where<0 ) {
    var insert_before_this=tr;
    for( var x=get_prev_sibling(insert_before_this, 'tr');
	 x && get_tr_block(x)==myblock;
	 insert_before_this=x, x=get_prev_sibling(x, 'tr') );
    tr.parentNode.insertBefore(newnode, insert_before_this);
  } else {
    var insert_before_this;
    for( insert_before_this=get_next_sibling(tr, 'tr');
	 insert_before_this &&
	   get_tr_block(insert_before_this)==myblock;
	 insert_before_this=get_next_sibling(insert_before_this, 'tr') );
    if( insert_before_this ) {
      tr.parentNode.insertBefore(newnode, insert_before_this);
    } else {
      tr.parentNode.appendChild(newnode);
    }
  }

  update_bg( tr );

  $('save'+get_form_counter(tr)).style.visibility='';
  //Element.show( 'save'+get_form_counter(tr) );

  newnode.getElementsByTagName('textarea')[0].focus();

  return false;
}

function xdelete( o ) {
  if(o) o.blur();
  var tr=find_parent( o, {tagName: 'TR'} );
  var form=find_parent( tr, {tagName: 'FORM'} );
  var parent=tr.parentNode;

  var newfocus;
  for( newfocus=tr.nextSibling; newfocus; newfocus=newfocus.nextSibling ) {
    if( newfocus.tagName=='TR' ) break;
  }
  if( !newfocus ) {
    for( newfocus=tr.previousSibling; newfocus; newfocus=newfocus.previousSibling ) {
      if( newfocus.tagName=='TR' ) break;
    }
  }
  if( newfocus ) {
    var el=newfocus.getElementsByTagName("textarea");
    if( el && el.length ) {
      newfocus=el[0];
    } else {
      el=form.getElementsByTagName("input");
      for( var i=0; i<el.length; i++ ) {
	if( el[i].type=='text' ) {
	  newfocus=el[i];
	  break;
	}
      }
    }
  }

  var hidden=tr.getElementsByTagName("td")[0];
  var v=hidden.getAttribute("ADM_ID");
  if( v && v.length ) {		// need to delete from database
    var newnode=document.createElement('input');
    newnode.name=("delete_"+hidden.getAttribute("ADM_BLOCK")+"_"+
		  hidden.getAttribute("ADM_ORDER")+"_"+v);
    newnode.value=1;
    newnode.type="hidden";
    form.appendChild(newnode);
  }

  parent.removeChild(tr);

  update_bg( parent );

  $('save'+get_form_counter(parent)).style.visibility='';
  //Element.show( 'save'+get_form_counter(parent) );
  newfocus.focus();

  return false;
}

function check_key( key ) {
  var forms=document.getElementsByTagName('form');
  for( i=0; i<forms.length; i++ ) {
    var k=forms[i].newkey;
    if( k!=null && k.value==key ) return 1;
  }
  var divs=document.getElementsByTagName('div');
  for( i=0; i<divs.length; i++ ) {
    var k=divs[i].getAttribute("ADM_KEY");
    if( k==key ) return 1;
  }
  return 0;
}

function xnewkey( o, uri ) {
  if(o) o.blur();
  if( next_counter!=null ) {
    var key='newkey';
    for( var i=1; check_key(key); i++ ) key='newkey'+i;
    if( uri==null ) uri="subroutine";
    o=find_parent(o, {tagName: 'H2'});

    var newnode=document.createElement('div');
    var newfocus=newnode;
    newnode.id='div'+next_counter;
    newnode.style.display='';
    newnode.setAttribute("ADM_KEY", key);
    newnode.setAttribute("ADM_URI", uri);

    newnode.innerHTML=
      ( '<div class="fetch">'+
	'<form new_element="1" id="form'+next_counter+'"'+
	'	  onsubmit="return false;"'+
	'	  ADM_COUNTER="'+next_counter+'"'+
	'	  ADM_NBLOCKS="1">'+
	'	<table class="tdc">'+
	'		<tr>'+
	'			<td class="tdcol1">New Key:</td>'+
	'			<td class="tdcol2">'+
	'				<input type="text" name="newkey" id="key'+next_counter+'" value="'+key.escapeHTML()+'">'+
	'			</td>'+
	'		</tr>'+
	(uri==":PRE:" || uri==":LOOKUPFILE:"
	 ? ('		<input type="hidden" name="newuri" id="uri'+next_counter+'" value="'+uri.escapeHTML()+'">')
	 : ('		<tr>'+
	    '			<td class="tdcol1">New Uri:</td>'+
	    '			<td class="tdcol2">'+
	    '				<input type="text" name="newuri" id="uri'+next_counter+'" value="'+uri.escapeHTML()+'">'+
	    '			</td>'+
	    '		</tr>'))+
	'		<tr><th colspan="2"><br>Action</th></tr>'+
	'		<tr class="tdc">'+
	'			<td ADM_BLOCK="0" ADM_ORDER="" ADM_ID=""'+
	'				colspan="2" class="tdc1">'+
	'			    <input type="hidden" name="ysize">'+
	'		            <table class="inner_tdc">'+
	'		                <tr>'+
	'                                   <td class="fetch_ta">'+
	'			                <textarea class="fetch_ta" rows="1" wrap="off"'+
	'			                          title="action field"></textarea>'+
	'			            </td>'+
	(can_notes
	 ? ('                               <td class="comment_ta">'+
	    '			                <textarea class="comment_ta" rows="1" wrap="word"'+
	    '			                          title="comment field"></textarea>'+
	    '                               </td>')
	 : '')+
	'                               </tr>'+
	'                           </table>'+
	'			</td>'+
	'			<td class="control">'+
	'				&nbsp;<a href="#" onclick="return xinsert(this, -1);"'+
	'						 title="new action above"><img src="1uparrow.gif"></a>'+
	'				<br>'+
	'				&nbsp;<a href="#" onclick="return xinsert(this, 1);"'+
	'						 title="new action below"><img src="1downarrow.gif"></a>'+
	'			</td>'+
	'			<td class="control">'+
	'				&nbsp;<a href="#" onclick="return xbinsert(this, -1);"'+
	'						 title="new block above"><img src="2uparrow.gif"></a>'+
	'				<br>'+
	'				&nbsp;<a href="#" onclick="return xbinsert(this, 1);"'+
	'						 title="new block below"><img src="2downarrow.gif"></a>'+
	'			</td>'+
	'			<td class="control">'+
	'				&nbsp;<a href="#" onclick="return xdelete(this, 1);"'+
	'						 title="delete action"><img src="delete.gif"></a>'+
	'			</td>'+
	'		</tr>'+
	'	</table>'+
	'</form>'+
	'</div>' );

    add_resizer( newnode );

    if( o.nextSibling ) {
      o.parentNode.insertBefore( newnode, o.nextSibling );
    } else {
      o.parentNode.appendChild( newnode );
    }

    newnode=document.createElement('h3');
    newnode.innerHTML=
      ( '<a id="a'+next_counter+'" class="opener" href="#"'+
	'   title="open/close this block list"'+
	'   onclick="return xtoggle( '+next_counter+', this )">'+opener[2]+
	'</a>'+
	'<a href="#" class="opener" id="reload'+next_counter+'"'+
	'   title="reload this block list"'+
	'   onclick="return xreload( '+next_counter+', this );"'+
	'   style="visibility: hidden;">'+
	'	<img src="reload.gif">'+
	'</a>'+
	'<a href="#" class="opener" id="save'+next_counter+'"'+
	'   title="save this block list"'+
	'   onclick="return xupdate( '+next_counter+', this );"'+
	'   style="visibility: hidden;">'+
	'	<img src="save.gif">'+
	'</a>'+
	'<span class="header" id="header'+next_counter+'"></span>');

    o.parentNode.insertBefore( newnode, o.nextSibling );
    //add_div_shortcuts(next_counter);
    update_header(next_counter, key, uri);

    newfocus=newfocus.getElementsByTagName("input");
    for( var i=0; i<newfocus.length; i++ ) {
      if( newfocus[i].type=='text' ) {
	newfocus[i].focus();
	break;
      }
    }

    next_counter++;
  }
  return false;
}

function ie_height(o) {
  if( Resizeable.current ) {
    for( var i=o.parentNode; i; i=i.parentNode ) {
      if( i==Resizeable.current.element ) {
        return ((Resizeable.current.currentHeight>47
                 ? Resizeable.current.currentHeight-7
	         : 40)+"px");
      }
    }
  }
  return ((o.parentNode.offsetHeight>47
	   ? o.parentNode.offsetHeight-7
	   : 40)+"px");
}
