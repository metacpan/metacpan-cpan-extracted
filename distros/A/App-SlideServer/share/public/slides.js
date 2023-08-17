/** WebSocket Slide System
 *
 * Apply this to an HTML file and call slides.init(websocket_uri, show_user_interface) 
 *
 * This operates on
 *  <div class="slides">
 *    <div class="slide">...</div>
 *    <div class="slide">...</div>
 *    <div class="slide">...</div>
 *  </div>
 *
 * The margin and padding and scale are altered for each slide to make the content fit
 * the aspect ratio of the viewport.
 *
 * Each slide can have a multi-stage animation caused by showing or hiding elements.
 * Each element can be included in one or more frames of animation by giving it data
 * of "data-step", which is either the frame it becomes visible, or a comma/dash
 * notation specifying a list of frames.  An element with class "auto-step" will have
 * its immediate child DOM elements given sequential data-step values.
 *
 * Each step can also have a "data-extern" indicating an external event that should 
 * "go into effect" when that element is shown.  The external event ends when the
 * element is hidden or when the server says it ends.
 */
function Slide(el, num) {
	var self= this;
	this.el= el;
	this.el.dataset.slide= num;
	this.num= num;
	var slide_jq= $(el);
	// Look for .auto-step, and apply step numbers
	var step_num= 1;
	slide_jq.find('.auto-step').each(function(idx, e) {
		// If it has a step number, and only one, then start the count of its children from that
		var start_step= e.dataset.step;
		if (start_step && start_step.match(/^[0-9]+$/))
			step_num= parseInt(start_step);
		$(e).children().each(function(){ this.dataset.step= [[step_num++]] });
	});
	// do a deep search to find any element with 'data-step' and give it the class of
	// 'slide-step' for easier selecting later.
	slide_jq.find('*').each(function(){
		if (this.dataset.step)
			$(this).addClass('slide-step');
	});
	// Parse each "data-step" specification and replace with an array of ranges
	// Also calculate the step count
	var max_step= 0;
	this.steps= slide_jq.find('.slide-step');
	this.steps.each(function() {
		if (this.dataset.step) {
			var show_list= self.parseSteps(this.dataset.step);
			for (var i= 0; i < show_list.length; i++) {
				if (show_list[i][0] > max_step)
					max_step= show_list[i][0];
				// If a step  has both a start frame and an end frame, then it is "temporary".
				if (show_list[i].length > 1) {
					$(this).addClass('temporary-step');
					if (show_list[i][1] > max_step) max_step= show_list[i][1];
				}
			}
		}
	});
	this.notes= slide_jq.find('.notes').text();
	this.max_step= max_step;
	this.cur_step= 0;
}
Slide.prototype.parseSteps= function(spec) {
	var show_list= (""+spec).split(',');
	for (var i= 0; i < show_list.length; i++) {
		show_list[i]= show_list[i].split(/-/);
		show_list[i][0]= parseInt(show_list[i][0]);
		if (show_list[i].length > 1)
			show_list[i][1]= parseInt(show_list[i][1]);
	}
	return show_list;
}
Slide.prototype.scaleTo= function(viewport_w, viewport_h) {
	var el_w= $(this.el).innerWidth();
	var el_h= $(this.el).innerHeight();
	var xscale= viewport_w / el_w;
	var yscale= viewport_h / el_h;
	var ypad= parseInt((viewport_h - el_h)/2)+'px';
	// console.log('xscale',xscale,'yscale',yscale,'viewport_w',viewport_w,'el_w',el_w,'viewport_h',viewport_h,'el_h',el_h,'ypad',ypad);
	// Example:
	// 50x10 inside 100x60, xscale=2, yscale=6, pad h with 40, 20 top 20 bottom 
	var scale= (xscale < yscale)? xscale : yscale;
	$(this.el).css('margin', ypad+' 0').css('transform', 'scale('+scale+','+scale+')');
}
Slide.prototype.top= function() { return $(this.el).offset().top }
Slide.prototype.show= function(show) { show? $(this.el).show() : $(this.el).hide(); return this }
Slide.prototype.hide= function() { return this.show(false) }

function _num_is_in_ranges(num, ranges) {
	if (ranges)
		for (var i= 0; i < ranges.length; i++)
			if (num >= ranges[i][0] && (ranges[i].length == 1 || num <= ranges[i][1]))
				return true;
	return false;
}
Slide.prototype.showStep= function(step_num, view_mode) {
	var self= this;
	if (step_num < 0) step_num= this.max_step + 1 + step_num;
	if (step_num < 0) step_num= 0;
	this.steps.each(function() {
		var step= $(this);
		// If a step is not visible, behavior depends on whether we are the presenter
		// and whether the element is temporary.  Non-temporary elements need to remain
		// in the document flow so that the layout of the rest doesn't jump around.
		// But temporary have to be removed from the layout so that they don't occupy
		// space.  Meanwhile the presenter gets to see all hidden elements.
		if (_num_is_in_ranges(step_num, self.parseSteps(this.dataset.step)))
			step.css('visibility','visible').css('position','relative').css('opacity',1);
		else {
			if (view_mode == 'presenter')
				step.css('visibility','visible').css('opacity', .3);
			else
				step.css('visibility','hidden');
			if (step.hasClass('temporary-step'))
				step.css('position','absolute');
		}
	});
	this.cur_step= step_num;
}

function escape_html(unsafe) {
  return (''+unsafe)
    .replaceAll('&', "&amp;")
    .replaceAll('<', "&lt;")
    .replaceAll('>', "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

window.slides= {
	config: {},
	slides: [],
	cur_slide: null,
	roles: {},
	sharedState: {},
	
	init: function(config) {
		var self= this
		if (!config)
			config= self.config
		if (!config.websocket_url)
			config.websocket_url= 'slidelink.io'
		if (!config.mode)
			config.mode= 'obs';
		if (config.code_highlight === undefined && window.hljs)
			config.code_highlight= function(el){ window.hljs.highlightElement(el) }
		if (config.mode == 'presenter' && (config.key == null || config.key.length == 0))
			config.key= null;//TODO: getCookieVal('access_key');
		self.config= config
		// Generic button and checkbox handlers
		this._button_dispatch= function(ev) {
			try {
				self[this.dataset.method].call(self, ev);
			} catch (e) {
				console.log('Calling slides.'+this.dataset.method+': ', e);
			}
		};
		this._enter_dispatch= function(ev) {
			if (ev.keyCode == 13) // Enter
				try {
					self[this.dataset.enter_method].call(self, ev);
				} catch (e) {
					console.log('Calling slides.'+this.dataset.enter_method+': ', e);
				}
		};
		this._ckbox_dispatch= function(ev) {
			try {
				self[this.dataset.method].call(self, this.checked, ev);
			} catch(e) {
				console.log('Calling slides.'+this.dataset.method+' : ', e);
			}
		};
		this.slides= this.buildSlidesArray();
		this.resizeSlides();
		window.addEventListener('resize', function(event) { self.resizeSlides() }, true);
		self._build_ui()
		this._show_slide(1,1);
		// The presenter needs a chance to enter the key before connecting
		if (config.mode == 'presenter' && config.key == null) {
			self.togglemenu();
			self.root.find('.status-actions .login').show();
			self.root.find('.status-actions .reconnect-btn').show();
		} else {
			self.reconnect()
		}
	},
	// Perform alterations to the HTML structure of the page to allow
	// less-strict hand-edited content to be automatically upgraded.
	buildSlidesArray: function(root_el) {
		var self= this;
		if (!root_el) {
			if (!self.root) {
				if (self.config.root) self.root= self.config.root;
				else if ($('div.slides').length) self.root= $($('div.slides')[0]);
				else {
					// TODO: upgrade body to div.slides
					throw "Can't find div.slides element in document";
				}
			}
			root_el= self.root;
		}
		// Wrap each slide with a Slide object, which initializes its steps
		var slides= [];
		var slides_jq= root_el.find('.slide');
		for (var i=0; i < slides_jq.length; i++)
			slides.push(self.wrapSlideEl(slides_jq[i], i+1))
		return slides;
	},
	wrapSlideEl: function(slide_el, num) {
		var self= this;
		$(slide_el).find('code').each(function() { self._fixup_code_block(this) })
		return new Slide(slide_el, num);
	},
	replaceSlide: function(num, new_slide_el) {
		var self= this;
		// insert it into the page, invisible, so that it sizes properly.
		new_slide_el.style.visibility= 'hidden';
		self.root.append(new_slide_el);
		var slide= self.wrapSlideEl(new_slide_el, num);
		console.log('created slide and appended', slide);
		var viewport_w= $(window).width();
		var viewport_h= $(window).height();
		slide.showStep(slide.max_step)
		slide.scaleTo(viewport_w, viewport_h);
		
		if (num <= self.slides.length) {
			var old_slide= self.slides[num-1];
			self.slides[num-1]= slide;
			$(old_slide.el).replaceWith(new_slide_el);
			if (self.cur_slide == num)
				self._show_slide(num, old_slide.cur_step);
			else
				self.slides[num-1].hide();
		} else {
			// Should never happen, but will prevent even more bizarre errors...
			while (this.slides.length -1 < num) {
				var placeholder= self.wrapSlideEl($('<div class="slide">Slide Missing?</div>')[0], this.slides.length+1);
				self.root.append(placeholder.el)
				self.slides.push(placeholder);
			}
			self.root.append(new_slide_el);
			self.slides.push(slide);
		}
		new_slide_el.style.visibility= '';
	},
	resizeSlides: function() {
		var viewport_w= $(window).width();
		var viewport_h= $(window).height();
		for (var i= 0; i < this.slides.length; i++) {
			var slide= this.slides[i];
			slide.showStep(slide.max_step)
			slide.scaleTo(viewport_w, viewport_h);
		}
	},
	// Remove leading whitespace, and convert tabs to spaces, and remove
	// the largest common indent of all lines.
	_fixup_code_block: function(code_el) {
		var text= $(code_el).text();
		text= text.replace(/\t/g, '   '); // tabs to spaces
		text= text.replace(/^\s*\n/g, ''); // remove leading blank line
		text= text.replace(/\n\s*$/g, ''); // remove blank trailing line
		// find the shortest match of whitespace at the start of any line
		var lead_ws_re= new RegExp('^( *)','mg');
		var indent= null;
		while ((matches= lead_ws_re.exec(text)) !== null)
			if (indent === null || matches[1].length < indent) {
				indent= matches[1].length;
				if (indent == 0) break;
			}
		if (indent > 0)
			text= text.replace(new RegExp('^'+(' '.repeat(indent)), 'mg'), '');
		$(code_el).text(text);
		// Apply syntax highlighting if available
		if (this.config.code_highlight)
			this.config.code_highlight(code_el);
	},
	_build_ui: function() {
		var self= this;
		self.root.prepend(this._public_ui_html);
		self.root.find('button').each(function(){ this.onclick= self._button_dispatch });
		self.root.find('input[type="checkbox"]').each(function(){ this.oninput= self._ckbox_dispatch });
		self.root.find('.status-actions input[name="key"]').each(function(){ this.onkeydown= self._enter_dispatch });
		self.root.find('.status-actions button').hide();
		$(document).on('keydown', function(e) { return self._handle_key(e.originalEvent); });
		self.root.find('.slide').on('click', function(e) { return self._handle_click(e) });
	},
	_public_ui_html: (
		'<div class="slides-sidebar">'+
		'  <div class="slides-corner">'+
		'    <button class="slides-sidebar-btn" type="button" data-method="togglemenu" title="Menu">'+
		'      <div class="bar bar1"></div><div class="bar bar2"></div><div class="bar bar3"></div>'+
		'    </button>'+
		'    <div class="slides-notify"></div>'+
		'  </div>'+
		'  <div class="ui"><div class="ui-inner">'+
		'    <h5>Status</h5>'+
		'    <ul class="status"></ul>'+
		'    <div class="status-actions">'+
		'      <label class="login">Key : <input type="password" name="key" data-enter_method="reconnect"></label>'+
		'      <button class="reconnect-btn" type="button" data-method="reconnect">Reconnect</button>'+
		'      <label class="cb follow"><input type="checkbox" name="follow" checked data-method="enableFollow"> Follow</label>'+
		'      <label class="cb lead"><input type="checkbox" name="lead" data-method="enableLead"> Lead</label>'+
		'      <label class="cb navigate"><input type="checkbox" name="navigate" data-method="enableNavigate"> Show Nav Buttons</label>'+
		'      <label class="cb notes"><input type="checkbox" name="notes" data-method="enableNotes"> Show Notes</label>'+
		'    </div>'+
		'  </div></div>'+
		'</div>'
	),
	_build_nav_ui: function() {
		var self= this;
		if (!self.nav_ui) {
			self.root.prepend(this._nav_ui_html);
			self.nav_ui= self.root.find('.navbuttons');
			self.nav_ui.find('button').each(function(){ this.onclick= self._button_dispatch });
		}
	},
	_nav_ui_html: (
		'<div class="navbuttons">'+
		'  <button class="prev" type="button" data-method="navPrev">Prev</button>'+
		'  <button class="step" type="button" data-method="navStep">Step</button>'+
		'  <button class="next" type="button" data-method="navNext">Next</button>'+
		'</div>'
	),
	_build_presenternotes_ui: function() {
		var self= this;
		if (!self.presenternotes_ui) {
			self.root.prepend(this._presenternotes_ui_html);
			self.presenternotes_ui= self.root.find('.presenternotes');
		}
	},
	_presenternotes_ui_html: (
		'<div class="presenternotes">'+
		'  <pre></pre>'+
		'</div>'
	),
	togglemenu: function(next_slide) {
		this.root.find('.slides-sidebar').toggleClass('open');
		var root_top= this.root.offset().top;
		if (this.root.find('.slides-sidebar').hasClass('open')) {
			// if allowed to navigate, show all slides
			if (this.roles.navigate) {
				this.root.find('.slide').show();
				// and scroll to the one we were just on
				if (this.cur_slide) {
					var slide= this.slides[this.cur_slide-1];
					document.documentElement.scrollTop= slide.top();
				}
			}
		} else {
			if (this.following)
				this.goToLeaderSlide();
			// If allowed to navigate, choose the first slide starting after the current scroll pos
			else if (this.roles.navigate) {
				if (!next_slide) { // next_slide might be chosen by click event
					var next_slide= this.cur_slide;
					for (var i= 0; i < this.slides.length; i++) {
						if (this.slides[i].top() >= document.documentElement.scrollTop) {
							next_slide= i+1;
							break;
						}
					}
				}
				this.goToSlide(next_slide, null);
				// ensure other slides get hidden even if cur_slide didn't change
				this._show_slide(this.cur_slide, null);
			}
		}
	},
	reconnect: function() {
		var self= this;
		var url= this.config.websocket_url;
		if (!url.startsWith('ws')) {
			var loc= window.location;
			// Not an absolute URL.
			// First, resolve the path if it was relative.
			if (!url.startsWith('/'))
				url= loc.pathname + (loc.pathname.endsWith('/')? '' : '/') + url;
			url= (loc.protocol == 'https:'? 'wss://' : 'ws://') + window.location.host + url;
		}
		var mode= this.config.mode;
		url += '?mode='+mode;
		if (mode == 'presenter') {
			if (this.config.key == null)
				this.config.key= this.root.find('input[name="key"]').val();
			url += '&key='+encodeURIComponent(this.config.key);
			this.root.find('.status-actions > .login').hide();
		}
		// Connect WebSocket to local event server
		this._set_conn_note('<p>Connecting...</p>')
		this.ws= new WebSocket(url);
		this.ws.onmessage= function(event) { self._handle_ws_event(JSON.parse(event.data)) }
		this.ws.onopen= function(event) { self._handle_connect(event, url, mode) }
		this.ws.onclose= function(event) { self._handle_disconnect(event) }
	},
	enableLead: function(enable, ev) {
		if (enable) {
			if (this.roles.lead) {
				this.leading= true;
				this.enableFollow(false);
			}
		} else {
			this.leading= false;
		}
		this.root.find('.status-actions .lead input').prop('checked', enable);
		this._update_status();
	},
	enableFollow: function(enable, ev) {
		if (enable) {
			this.following= true;
			this.enableLead(false);
			this.goToLeaderSlide();
		} else {
			this.following= false;
		}
		this.root.find('.status-actions .follow input').prop('checked', enable);
		this._update_status();
	},
	enableNavigate: function(enable, ev) {
		if (enable) {
			this._build_nav_ui();
			this.nav_ui.show();
		} else {
			if (this.nav_ui)
				this.nav_ui.hide();
		}
		this.root.find('.status-actions .navigate input').prop('checked', enable);
	},
	enableNotes: function(enable, ev) {
		if (enable) {
			this._build_presenternotes_ui();
			this.presenternotes_ui.show();
		} else {
			if (this._presenternotes_ui)
				this.presenternotes_ui.hide();
		}
		// re-render current slide
		this.showNotes= !!enable;
		this._show_slide(this.cur_slide, this.getSlide(this.cur_slide).cur_step);
	},
	_set_conn_note: function(content, duration) {
		var self= this;
		if (this._conn_note) {
			var prev= this._conn_note
			delete this._conn_note
			prev.fadeOut(500, function(){ prev.remove() })
		}
		var next= $(content);
		this.root.find('.slides-notify').append(next);
		this._conn_note= next;
		if (duration)
			window.setTimeout(function(){
				if (self._conn_note == next) this._conn_note= null
				next.fadeOut(500, function(){ next.remove() });
			}, duration);
		this._update_status();
	},
	_update_status: function() {
		var status= this.root.find('.status');
		status.empty();
		if (this.ws) {
			var server= ''+this.ws.url;
			server= server.replace(/^wss?:\/\/([^:\/]+).*/, '$1');
			if (this.ws.readyState == 0)
				status.append('<li class="connecting">Connecting to <span class="host">'+escape_html(server)+'</span></li>');
			else if (this.ws.readyState == 1)
				status.append('<li class="connected">Connected to <span class="host">'+escape_html(server)+'</span></li>');
			else
				status.append('<li class="disconnected">Not connected</li>');
		}
		if (this.following)
			status.append('<li class="follow">Following presenter</li>');
		else if (this.leading)
			status.append('<li class="broadcast">Broadcasting</li>');
		if (this.cur_slide && this.slides && this.slides.length)
			status.append('<li class="pos">Slide <b>'+this.cur_slide+'</b> of <b>'+this.slides.length+'</b></li>');
	},
	_handle_connect: function(event, url, mode) {
		this.root.find('.reconnect-btn').hide()
		this._set_conn_note('<p>Connected</p>', 1500)
		if (this.config.mode == 'obs')
			this.enableFollow(true);
	},
	_handle_disconnect: function(event) {
		this.root.find('.reconnect-btn').show()
		this._set_conn_note('<p>Lost connection</p>')
		delete this.ws;
	},
	_handle_ws_event: function(event) {
		//console.log('ws event: ', event);
		if (event.state) {
			this.sharedState= event.state;
			if (this.following)
				this.goToLeaderSlide();
		}
		if (event.roles) {
			this.roles= {};
			for (var i=0; i < event.roles.length; i++)
				this.roles[event.roles[i]]= 1;
			if (this.roles.lead) {
				this.enableFollow(false);
				this.root.find('.status-actions .follow').show();
				this.root.find('.status-actions .lead').show();
				this.root.find('.status-actions .notes').show();
			} else {
				// initial state for non-lead is to follow
				this.enableFollow(true);
			}
			if (this.roles.navigate || this.roles.lead) {
				this.root.find('.status-actions .navigate').show();
			}
		}
		if (event.key_incorrect) {
			// TODO: create a password entry form on the sidebar and a login sequence
			// that happens over the websocket.
			this._set_conn_note('<p>Incorrect Key</p>');
			this.config.key= null;
			this.root.find('.status-actions > .login').show();
			this.root.find('.reconnect-btn').show()
		}
		if (event.page_changed) {
			window.location.reload();
		}
		if (event.slides_changed) {
			console.log('slides_changed', event.slides_changed);
			for (var i=0; i < event.slides_changed.length; i++)
				this.replaceSlide(event.slides_changed[i].idx+1, $(event.slides_changed[i].html)[0]);
		}
	},
	send_ws_message: function(obj) {
		if (this.ws)
			this.ws.send( JSON.stringify(obj) );
		else
			console.log("Can't send: ", obj);
	},
	// Return true if the input event is destined for a DOM node that takes input
	_event_is_for_input: function(e) {
		return (e.target.tagName == "INPUT"
			|| (e.target.tagName == "BUTTON" && e.type == 'click')
			|| e.target.tagName == "TEXTAREA"
			) || (e.originalEvent && this._event_is_for_input(e.originalEvent));
	},
	_handle_key: function(e) {
		// Ignore navigation unless granted navigate role
		if (!this.roles.navigate)
			return true;
		// Ignore keys for input elements within the slides
		else if (this._event_is_for_input(e))
			return true;
		else if (e.keyCode == 39) // ArrowRight
			this.navNext();
		else if (e.keyCode == 37) // ArrowLeft
			this.navPrev();
		else if (e.keyCode == 40 || e.keyCode == 32) // ArrowDown, Space
			this.step(1);
		else if (e.keyCode == 38) // ArrowUp
			this.step(-1);
		else
			return true;
		return false;
	},
	_handle_click: function(e) {
		// Ignore clicks for input elements within the slides
		if (!this._event_is_for_input(e)) {
			// Did they click a slide?
			var slide= e.currentTarget.dataset.slide;
			if (slide && this.root.find('.slides-sidebar').hasClass('open')) {
				// The menu is open. close it.
				// If allowed to navigate, change the current slide to the one clicked
				this.togglemenu(this.roles.navigate? slide : null);
				return false;
			}
		}
		return true;
	},
	getSlide: function(slide_num) {
		//console.log('getSlide', slide_num);
		if (slide_num < 0)
			slide_num= this.slides.length + 1 + slide_num;
		if (slide_num < 1)
			slide_num= 1;
		else if (slide_num > this.slides.length)
			slide_num= this.slides.length;
		return this.slides[slide_num-1];
	},
	goToSlide: function(slide_num, step_num) {
		var slide= this.getSlide(slide_num);
		slide_num= slide.num;
		if (step_num == null)
			step_num= slide.cur_step;
		else {
			if (step_num < 0)
				step_num= slide.max_step + 1 + step_num;
			if (step_num < 1)
				step_num= 1;
			else if (step_num > slide.max_step)
				step_num= slide.max_step;
		}
		if (slide_num != this.cur_slide || step_num != slide.cur_step) {
			this._show_slide(slide_num, step_num);
			this._update_status();
			if (this.leading)
				this.send_ws_message({ slide_num: slide_num, step_num: step_num });
		}
	},
	navPrev: function() {
		this.enableFollow(false);
		this.goToSlide(this.cur_slide-1);
	},
	navNext: function() {
		this.enableFollow(false);
		this.goToSlide(this.cur_slide+1);
	},
	navStep: function() {
		this.enableFollow(false);
		this.step(1);
	},
	step: function(ofs) {
		let slide= this.getSlide(this.cur_slide);
		if (ofs > 0) {
			if (slide.cur_step + ofs <= slide.max_step)
				this.goToSlide(slide.num, slide.cur_step + ofs);
			else
				this.goToSlide(slide.num+1, 1);
		}
		else if (ofs < 0) {
			if (slide.cur_step + ofs > 0)
				this.goToSlide(this.cur_slide, slide.cur_step + ofs);
			else
				this.goToSlide(this.cur_slide-1, -1);
		}
	},
	goToLeaderSlide: function() {
		if (this.sharedState.slide_num)
			this.goToSlide(this.sharedState.slide_num||1, this.sharedState.step_num||0);
	},
	_show_slide: function(slide_num, step_num) {
		var slide= this.slides[slide_num-1];
		for (var i= 0; i < this.slides.length; i++)
			this.slides[i].show(i == slide_num-1);
		this.cur_slide= slide_num;
		if (step_num != null)
			slide.showStep(step_num, this.showNotes? 'presenter' : null);
		// Update notes for the presenter
		if (this.showNotes)
			this.root.find('.presenternotes pre').text(slide.notes || '');
	}
};
