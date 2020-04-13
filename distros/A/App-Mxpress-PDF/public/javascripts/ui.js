(function (window, document) {
	var Application = function () {
		return this;
	};

	Application.prototype = {
		session: false,
		layout: document.getElementById('layout'),
		menu: document.getElementById('menu'),
		menuLink: document.getElementById('menuLink'),
		content: document.getElementById('main'),
		notification: document.getElementById('notify'),
		templateStore: [],	
		defaultTemplateStyles: {
			page:{
				padding:15,
			},
			cover:{
				columns:1
			},
			toc:{
				font:{ colour:'#00f' },
			},
			title:{
				margin_bottom:3,
			},
			subtitle:{
				margin_bottom:3,
			},
			subsubtitle:{
				margin_bottom:3,
			},
			text:{
				margin_bottom:3,
			},
		},
		start: function () {
			App.aceEditor('createTemplateAce', "ace/mode/text");
			App.aceEditor('createTemplateStylesAce', "ace/mode/json");
			App.aceEditor('generateParams', 'ace/mode/json');
			App.aceEditor('createPodStylesAce', 'ace/mode/json');
			App.aceEditor('createRawPodAce', 'ace/mode/text');
			App.changeTab(
				window.location.hash || '#templates'
			);

			App.getRequest('/api/templates', {}, function (data) {
				App.templateStore = data;
				App.templatesTable(App.templateStore);
				App.generate();
			});
		},
		toggleClass: function (element, className) {
			var classes = element.className.split(/\s+/),
			length = classes.length,
			i = 0;

			for(; i < length; i++) {
				if (classes[i] === className) {
					classes.splice(i, 1);
					break;
				}
			}
			// The className is not found
			if (length === classes.length) {
				classes.push(className);
			}

			element.className = classes.join(' ');
		},
		toggleAll: function (e) {
			var active = 'active';
			e.preventDefault();
			this.toggleClass(this.layout, active);
			this.toggleClass(this.menu, active);
			this.toggleClass(this.menuLink, active);
		},
		formData: function (form) {
			var data = {};
			var elements = form.elements;
			for (var i = 0; i < elements.length; i++) {
				var element = form.elements[i];
				if (element.name) {
					if (element.tagName === 'SELECT') {
						data[element.getAttribute('name')] = element.options[element.selectedIndex].value 
							|| element.options[element.selectedIndex].innerText;	
					} else if (element.type === 'radio') {
						if (element.checked) data[element.name] = element.value;
					}  else {
						data[element.getAttribute('name')] = element.value;
					}
				}
			}
			return data;
		},
		table: function (selector, columns, tableData, index) {
			var table = new Tabulator(selector, {
				index: index,
				data:tableData,           //load row data from array
				layout:"fitColumns",      //fit columns to width of table
				responsiveLayout:"hide",  //hide columns that dont fit on the table
				tooltips:true,            //show tool tips on cells
				addRowPos:"top",          //when adding a new row, add it to the top of the table
				history:true,             //allow undo and redo actions on the table
				pagination:"local",       //paginate the data
				paginationSize:7,         //allow 7 rows per page of data
				movableColumns:true,      //allow column order to be changed
				resizableRows:true,       //allow row order to be changed
				initialSort:[             //set the initial sort order of the data
					{column:"name", dir:"asc"},
				],
				columns: columns
			});
		},
		aceEditor: function (selector, mode) {
			var editor = ace.edit(selector);
			var textarea = document.querySelector('#' + selector + '-textarea');
			editor.getSession().setMode(mode);
			editor.getSession().on('change', function(){
  				textarea.value = editor.getSession().getValue();
			});
		},

		templatesTable: function (tableData) {
			var tableColumns = [
				{title:"Name", field:"name"},
				{title:"Size", field:"size"},
				{title:"Edit", width: 80, field:"edit", formatter: function () { return '<button>Edit</button>' }, cellClick: this.editTemplate },
				{title:"Delete", width: 80, field:"delete", formatter: function () { return '<button>Delete</button>' }, cellClick: this.deleteTemplate },
				{title:"Clone", width: 80, field:"clone", formatter: function () { return '<button>Clone</button>' }, cellClick: this.cloneTemplate }
			];
			this.table('#example-table', tableColumns, tableData, 'name');
		},
		editTemplate: function (e, cell) {
			var data = cell.getRow().getData();
			document.querySelector('a[href="#manage"]').click();
			App.setTemplateFormData(data);
		},
		deleteTemplate: function (e, cell) {
			var data = cell.getRow().getData();
			App.postRequest('/api/delete/template', { name:data.name, size: data.size }, function (data) {
				var ind = App.templateStore.findIndex(function (d) {
					if (d.name === data.name) return true;
				});
				App.templateStore.splice(ind, 1);
				App.templatesTable(App.templateStore);
			});
		},
		cloneTemplate: function (e, cell) {
			var data = cell.getRow().getData();
			data = JSON.parse(JSON.stringify(data));
			document.querySelector('a[href="#manage"]').click();
			data.name = '';
			App.setTemplateFormData(data);
		},
		setTemplateFormData: function (data) {
			document.querySelector('input[name="name"').value = data.name || '';
			document.querySelector('select[name="size"] option[value="' + data.size + '"]').selected = true;
			var editor = ace.edit('createTemplateAce');
			editor.setValue(data.template, -1);
			editor = ace.edit('createTemplateStylesAce');
			editor.setValue(data.styles, -1);
		},
		changeTab: function (id) {
			var current = document.querySelector('.content.active');
			var currentLink = document.querySelectorAll('.pure-menu-selected');
			var next = document.querySelector(id);
			var nextLink = document.querySelector('a[href="' + id + '"]').parentNode;
				
			App.toggleClass(current, 'active');
			App.toggleClass(next, 'active');

			currentLink.forEach(function (n) {
				App.toggleClass(n, 'pure-menu-selected');
			});

			if (nextLink.parentNode.classList.contains('nested')) {
				nextLink.parentNode.parentNode.classList.add('open');
			} else {
				document.querySelectorAll('.pure-menu-item.open').forEach(function (n) {
					App.toggleClass(n, 'open');
				});
			}
			App.toggleClass(nextLink, 'pure-menu-selected');
			window.scrollTo(0,0);
		},
		getRequest: function (req, data, cb) {
			var xmlhttp = new XMLHttpRequest();   // new HttpRequest instance 
			
			xmlhttp.onreadystatechange = function () {
				{
					try {
						if (xmlhttp.readyState === XMLHttpRequest.DONE) {
							if (xmlhttp.status === 200) {	
								if (xmlhttp.getResponseHeader('Token')) {
									App.csrf_token = xmlhttp.getResponseHeader('Token');
								}
								var data = JSON.parse(xmlhttp.responseText);
								cb(data);
							} else {
								App.notify('error', 'Error', 'There was a problem with the request.');
							}
						}
					}
					catch( e ) {
						console.log(e);
					}
				}
			};
			xmlhttp.open("GET", req);
			xmlhttp.send();
		},
		fileRequest: function (req, data, cb) {
			var xmlhttp = new XMLHttpRequest();
			xmlhttp.open('POST', req, true);
			xmlhttp.responseType = 'blob';
			xmlhttp.onreadystatechange = function () {
				{
					try {
						if (xmlhttp.readyState === XMLHttpRequest.DONE) {
							if (xmlhttp.status === 200) {
								App.getRequest('/api/session', {}, function () { });

								var blob = xmlhttp.response;
			   					App.saveBlob(blob, data.name + '.pdf');		
							} else {
								App.notify('error', 'Error', 'There was a problem with the request.');
							}
						}
					}
					catch( e ) {
						console.log(e);
					}
				}
			};

			xmlhttp.setRequestHeader("Token", App.csrf_token);	
			xmlhttp.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
			xmlhttp.send(JSON.stringify(data));
		},
		saveBlob: function (blob, fileName) {
			console.log(blob);
			var a = document.createElement('a');
			a.href = URL.createObjectURL(blob);
			a.download = fileName;
			a.dispatchEvent(new MouseEvent('click'));
		},
		postRequest: function (req, data, cb) {
			var xmlhttp = new XMLHttpRequest();   // new HttpRequest instance 	
			xmlhttp.onreadystatechange = function () {
				{
					try {
						if (xmlhttp.readyState === XMLHttpRequest.DONE) {
							if (xmlhttp.status === 200) {
								if (xmlhttp.getResponseHeader('Token')) {
									App.csrf_token = xmlhttp.getResponseHeader('Token');
								}
								var data = JSON.parse(xmlhttp.responseText);
								cb(data);
							} else {
								App.notify('error', 'Error', 'There was a problem with the request.');
							}
						}
					}
					catch( e ) {
						console.log(e);
					}
				}
			};

			xmlhttp.open("POST", req);
			xmlhttp.setRequestHeader("Token", App.csrf_token);	
			xmlhttp.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
			xmlhttp.send(JSON.stringify(data));
		},
		notify: function (type, title, content) {
			this.notification.classList.add(type);
			this.notification.querySelector('.title').innerText = title;
			this.notification.querySelector('.description').innerText = content;
			setTimeout(function () {
				console.log('fired');
				App.notification.classList.remove(type);
			}, 3000);
		},
		generate: function () {
			var templates = App.templateStore;
			var select = App.content.querySelector('select[name="template"]');
			select.innerHTML = '';
			var ro = new Option('Select a template');
			select.appendChild(ro);
			templates.forEach(function (t) {
				var o = new Option(t.name, t.name);	
				select.appendChild(o);
			});
		},
		logout: function () {
			App.postRequest('/api/logout', {}, function (res) {
				window.location.hash = '#templates';
				window.location.reload();
			});
		}
	}

	var App = new Application;

	App.menuLink.onclick = function (e) {
		App.toggleAll(e);
	};

/*

*/	
	window.onhashchange = function(e) {
		if (!App.session) return;
		var id = e.target.location.hash;
		var cb = id.replace('#', '');
		if (App[cb]) App[cb]();
		if (cb !== 'logout') App.changeTab(id);	
	};

	App.content.querySelector('select[name="template"]').addEventListener('change', function (e) {
		var templates = App.templateStore;
		var value = e.target.options[e.target.selectedIndex].value;
		var find = templates.find(function (t) {
			return t.name === value;
		});
		var editor = ace.edit('generateParams');
		editor.setValue(JSON.stringify(find.params, null, "\t"), -1);
	});

	App.content.querySelector('#setDefaultStyles').addEventListener('click', function (e) {
		var editor = ace.edit('createTemplateStylesAce');
		editor.setValue(JSON.stringify(App.defaultTemplateStyles, null, '\t'), -1);
	});

	App.content.querySelector('#setDefaultPodStyles').addEventListener('click', function (e) {
		var editor = ace.edit('createPodStylesAce');
		var clone = JSON.parse(JSON.stringify(App.defaultTemplateStyles));
		clone.toc.levels = ["title", "h1", "h2", "h3", "h4", "h5", "h6"];
		editor.setValue(JSON.stringify(clone, null, '\t'), -1);
	});

	App.content.querySelector('#generatePDF').addEventListener('submit', function (e) {
		e.preventDefault();
		var data = App.formData(e.target);
		var find = JSON.parse(JSON.stringify(App.templateStore.find(function (t) {
			return data.template === t.name;
		})));
		find.params = JSON.parse(data.params);		
		App.fileRequest('/api/generate/pdf', find, function (res) {
				
		});
	});

	App.content.querySelector('#generatePODPDF').addEventListener('submit', function (e) {
		e.preventDefault();
		var data = App.formData(e.target);
		if (!data.name) data.name = data.module ? data.module : data.distribution;
		App.fileRequest('/api/generate/pod', data, function (res) {});
	});

	App.content.querySelector('#createTemplate').addEventListener('submit', function (e) {
		e.preventDefault();
		var data = App.formData(e.target);
		App.postRequest('/api/create/template', data, function (res) {
			var find = App.templateStore.find(function (a) {
				return a.name === res.name;
			});
			if (!find) {
				App.templateStore.push(res);
				App.notify('success', 'Create Template', 'Successfully created a new template: ' + res.name)
			} else {
				for (key in res) {
					find[key] = res[key]
				}
				App.notify('success', 'Update Template', 'Successfully updated template: ' + res.name)
			}
			App.templatesTable(App.templateStore);
		});
	});

	App.content.querySelectorAll('input[data-validate="plain-text"]').forEach(function (e) {
		e.addEventListener('keydown', function (n) {
			if (n.key.match('[^a-zA-Z0-9\-\:]')) {
				n.preventDefault();
			}
		});
	});

	App.content.querySelector('#createNewTemplate').addEventListener('click', function () {
		document.querySelector('a[href="#manage"]').click();
		App.setTemplateFormData({
			name: '',
			styles: '',
			template: '',
			size: 'A4'
		});
	});

	App.content.querySelector('#loginForm').addEventListener('submit', function (e) {
		e.preventDefault();
		var data = App.formData(e.target);
		App.postRequest('/api/login', data, function (res) {
			if (res.success) {
				App.notify('success', 'Logged In', res.success);
				App.session = true;
				App.start();
			} else {
				App.notify('error', 'Login Failed', res.error);
			}
		});
	});

	App.getRequest('/api/session', {}, function (res) {
		if (res.session == 1) {
			App.session = true;
			App.start();
		}
	});


}(this, this.document));
