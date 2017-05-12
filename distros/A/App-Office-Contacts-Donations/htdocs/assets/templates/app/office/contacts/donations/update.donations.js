var <tmpl_var name=context>_add_donations_callback =
{
	success: function(o)
	{
		var e = document.getElementById("<tmpl_var name=context>_donations_result");

		if (o.responseText !== undefined)
		{
			new_<tmpl_var name=context>_donations_tab(o.responseText);
		}
		else
		{
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("<tmpl_var name=context>_donations_result");
		e.innerHTML = 'The server failed to respond';
	}
};

function <tmpl_var name=context>_update_donations_onsubmit()
{
	var action = document.<tmpl_var name=context>_update_donations_form.action.value;

	if (action == 2) // Delete.
	{
		var s = "target_id=" + document.<tmpl_var name=context>_update_donations_form.target_id.value + "&donations_id=" + document.<tmpl_var name=context>_update_donations_form.donations_id.value + "&sid=<tmpl_var name=sid>";
		var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/donations/delete/<tmpl_var name=context>', <tmpl_var name=context>_delete_donations_callback, s);

		return false;
	}

	var p = YAHOO.util.Connect.setForm("<tmpl_var name=context>_update_donations_form");
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/donations/add/<tmpl_var name=context>', <tmpl_var name=context>_add_donations_callback);

	return false;
}

function new_<tmpl_var name=context>_donations_tab(s)
{
	// Warning: Can't use if (person_donations_tab !== undefined) when it's null.

	if (<tmpl_var name=context>_donations_tab == undefined)
	{
	}
	else
	{
		tab_set.removeTab(<tmpl_var name=context>_donations_tab);
	}

	var title = ("<tmpl_var name=context>" == "organization") ? "Org donations" : "Personal donations";

	<tmpl_var name=context>_donations_tab = new YAHOO.widget.Tab
	({
		label: title,
		content: s,
		active: true
	});
	tab_set.addTab(<tmpl_var name=context>_donations_tab, (tab_set.get('tabs').length - 1) );
	<tmpl_var name=context>_donations_tab.addListener('click', make_<tmpl_var name=context>_donations_focus);
	make_<tmpl_var name=context>_donations_focus();
}

var <tmpl_var name=context>_update_delete_donations_callback =
{
	success: function(o)
	{
		var e = document.getElementById("<tmpl_var name=context>_donations_result");

		if (o.responseText !== undefined)
		{
			new_<tmpl_var name=context>_donations_tab(o.responseText);
		}
		else
		{
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("donations_result");
		e.innerHTML = 'The server failed to respond';
	}
};

function <tmpl_var name=context>_update_donations_list_onsubmit()
{
	var s = "0";
	var i;

	for (i = 0; i < document.<tmpl_var name=context>_update_donations_list_form.elements.length; i++)
	{
		if (document.<tmpl_var name=context>_update_donations_list_form.elements[i].name.search("^donations_id") >= 0)
		{
			if (document.<tmpl_var name=context>_update_donations_list_form.elements[i].checked)
			{
				s = s + "," + document.<tmpl_var name=context>_update_donations_list_form.elements[i].value;
			}
		}
	}

	if (s == "0")
	{
		return false;
	}

	var action = document.<tmpl_var name=context>_update_donations_list_form.action.value;

	if (action == 2) // Delete.
	{
		var ok = confirm("Do you really want to delete these donations?");

		if (ok == false)
		{
			return false;
		}
	}

	// Warning: We get vars from the other form...

	var s = "target_id=" + document.<tmpl_var name=context>_update_donations_form.target_id.value + "&donations_id=" + s + "&sid=" + document.<tmpl_var name=context>_update_donations_form.sid.value;
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/donations/delete/<tmpl_var name=context>', <tmpl_var name=context>_update_delete_donations_callback, s);

		return false;
}
