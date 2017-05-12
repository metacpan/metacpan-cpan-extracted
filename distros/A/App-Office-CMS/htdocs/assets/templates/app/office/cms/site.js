// site.js.

var display_site_callback =
{
	success: function(o)
	{
		if (o.responseText !== undefined)
		{
			var data = YAHOO.lang.JSON.parse(o.responseText);
			var div  = data.results.target_div;
			var e    = document.getElementById(div);

			e.innerHTML = data.results.message;

			// If the db search failed, the server did not send a form.
			// So, we can't make the site's name the focus.

			if (div == "update_site_div")
			{
				make_update_site_name_focus();
			}
			else
			{
				e = document.getElementById("update_site_div");
				e.innerHTML = "";
			}
		}
		else
		{
			var e = document.getElementById("update_site_div");
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("update_site_div");

		e.innerHTML = "The server failed to respond";
	}
};

function display_site(id_pair)
{
	var s = "id_pair=" + id_pair + ";sid=" + document.search_form.sid.value;
	var r = YAHOO.util.Connect.asyncRequest("POST", "<: $form_action :>/site/display", display_site_callback, s);

	return false;
}

var new_site_callback =
{
	success: function(o)
	{
		var e = document.getElementById("new_site_message_div");

		if (o.responseText !== undefined)
		{
			e.innerHTML = o.responseText;
		}
		else
		{
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("new_site_message_div");
		e.innerHTML = "The server failed to respond";
	}
};

var new_site_onsubmit = function ()
{
	if (FIC_checkForm("new_site_form") == false)
	{
		return false;
	}

	YAHOO.util.Connect.setForm("new_site_form");
	var r = YAHOO.util.Connect.asyncRequest("POST", "<: $form_action :>/site/add", new_site_callback);

	return false;
}

var update_site_callback =
{
	success: function(o)
	{
		if (o.responseText !== undefined)
		{
			var data = YAHOO.lang.JSON.parse(o.responseText);
			var div  = data.results.target_div;
			var e    = document.getElementById(div);
			e.innerHTML = data.results.message;

			// If the db search failed, the server did not send a form.
			// So, we can't make the site's name the focus.

			if (div == "update_site_div")
			{
				make_update_site_name_focus();
			}
			else
			{
				// With Delete design and Delete site, the displayed
				// site data is obsolete. We zap it since we're forcing
				// the user to do another search, to update the ip_pair
				// info which identifies site/design combinations.
				// With Save, the displayed site data is up-to-date.

				if (div == "search_result_div")
				{
					e = document.getElementById("update_site_div");
					e.innerHTML = "";
				}
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

var update_site_onsubmit = function ()
{
	if (FIC_checkForm("update_site_form") == false)
	{
		return false;
	}

	var action = document.update_site_form.action.value;
	var site   = document.update_site_form.name.value;
	var design = document.update_site_form.design_name.value;
	var s      = "Do you really want to delete ";
	var s_len  = s.length;
	var url    = "<: $form_action :>/";

	switch (action)
	{
	case "1": // Delete design.
		s   = s + "design '" + design + "' for site '" + site + "'?";
		url = url + "design/delete";
		break;

	case "2": // Delete site.
		s   = s + "site '" + site + "' and all its designs?";
		url = url + "site/delete";
		break;

	case "3": // Edit pages.
		url = url + "page/display";
		break;

	case "4": // Save (Update site).
		url = url + "site/update";
		break;

	case "5": // Duplicate design.
		url = url + "design/duplicate";
		break;

	case "6": // Duplicate site.
		url = url + "site/duplicate";
		break;
	}

	YAHOO.util.Connect.setForm("update_site_form");

	// Get edit page out of the way. It uses a different callback.

	if (action == 3)
	{
		var r = YAHOO.util.Connect.asyncRequest("POST", url, update_page_callback);

		document.update_site_form.action.value = 0; // Reset for next time!

		return false;
	}

	if (action <= 2)
	{
		var ok = confirm(s);

		if (ok == false)
		{
			document.update_site_form.action.value = 0; // Reset for next time!

			return false;
		}
	}

	var r = YAHOO.util.Connect.asyncRequest("POST", url, update_site_callback);

	document.update_site_form.action.value = 0; // Reset for next time!

	return false;
}
