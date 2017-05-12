// page.js.

// Global variables.

var page_tree = null;

function click_on_tree(node)
{
	var label     = node.label;
	var e         = document.getElementById("current_page_div");
	e.innerHTML   = label;
	document.update_page_form.action.value = 7;
	document.update_page_form.name.value   = label;

	var p = YAHOO.util.Connect.setForm("update_page_form");
	var r = YAHOO.util.Connect.asyncRequest("POST", "<: $form_action :>/page/click_on_tree", update_page_callback);

	document.update_page_form.action.value = 0; // Reset for next time!
}

function build_menu(item_data)
{
	if (page_tree != null)
	{
		page_tree.destroy();
	}

	page_tree = new YAHOO.widget.TreeView("page_tree_div", item_data);

	page_tree.render();
	page_tree.subscribe("labelClick", click_on_tree);
}

var update_page_callback =
{
	success: function(o)
	{
		if (o.responseText !== undefined)
		{
			var data = YAHOO.lang.JSON.parse(o.responseText);
			var div  = data.results.target_div;
			var e    = document.getElementById(div);
			e.innerHTML = data.results.message;

			if (div == "update_site_message_div")
			{
				// An error was just displayed.
			}
			else
			{
				// Clean up any error message on the Edit Site tab.

				e = document.getElementById("update_site_message_div");
				e.innerHTML = "";

				if (data.results.current_page != "")
				{
					e = document.getElementById("current_page_div");
					e.innerHTML = data.results.current_page;
					document.update_page_form.name.value = data.results.current_page;
				}

				if (data.results.menu.length > 0)
				{
					build_menu(data.results.menu);
				}

				if (data.results.homepage == "Yes")
				{
					document.update_page_form.homepage.checked = true;
				}
				else
				{
					document.update_page_form.homepage.checked = false;
				}

				tab_view.set('activeIndex', 2); // Edit Pages tab.
				make_update_page_name_focus();
			}
		}
		else
		{
			var e = document.getElementById("update_site_message_div");
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("update_site_message_div");
		e.innerHTML = "The server failed to respond";
	}
};

var update_page_onsubmit = function ()
{
	if (FIC_checkForm("update_page_form") == false)
	{
		return false;
	}

	var action = document.update_page_form.action.value;
	var url    = "<: $form_action :>/page/";

	switch (action)
	{
	case "1":
		url = url + "add_sibling_above";
		break;

	case "2":
		url = url + "add_sibling_below";
		break;

	case "3":
		url = url + "add_child";
		break;

	case "4":
		url = url + "delete";
		break;

	case "5": // Edit content.
		url = "<: $form_action :>/content/display";
		break;

	case "6": // Save.
		url = url + "update";
		break;

	//case "7": Click on page tree. See function click_on_tree() above.
	}

	// Confirm delete.

	if (action == 4)
	{
		var page = document.update_page_form.name.value;
		var s    = "Do you really want to delete '" + page + "'?";
		var ok   = confirm(s);

		if (ok == false)
		{
			document.update_page_form.action.value = 0; // Reset for next time!

			return false;
		}
	}

	var p = YAHOO.util.Connect.setForm("update_page_form");

	if (action == 5)
	{
		var r = YAHOO.util.Connect.asyncRequest("POST", url, update_content_callback);
	}
	else
	{
		var r = YAHOO.util.Connect.asyncRequest("POST", url, update_page_callback);
	}

	document.update_page_form.action.value = 0; // Reset for next time!

	return false;
}
