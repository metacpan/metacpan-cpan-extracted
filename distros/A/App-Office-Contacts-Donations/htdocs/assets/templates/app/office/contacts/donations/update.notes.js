var <tmpl_var name=context>_add_notes_callback =
{
	success: function(o)
	{
		var e = document.getElementById("<tmpl_var name=context>_notes_result");

		if (o.responseText !== undefined)
		{
			new_<tmpl_var name=context>_notes_tab(o.responseText);
		}
		else
		{
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("<tmpl_var name=context>_notes_result");
		e.innerHTML = 'The server failed to respond';
	}
};

function <tmpl_var name=context>_update_notes_onsubmit()
{
	var action = document.<tmpl_var name=context>_update_notes_form.action.value;

	if (action == 2) // Delete.
	{
		var s = "target_id=" + document.<tmpl_var name=context>_update_notes_form.target_id.value + "&notes_id=" + document.<tmpl_var name=context>_update_notes_form.notes_id.value + "&sid=" + document.<tmpl_var name=context>_update_notes_form.sid.value;
		var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/notes/delete/<tmpl_var name=context>', <tmpl_var name=context>_delete_notes_callback, s);

		return false;
	}

	var p = YAHOO.util.Connect.setForm("<tmpl_var name=context>_update_notes_form");
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/notes/add/<tmpl_var name=context>', <tmpl_var name=context>_add_notes_callback);

	return false;
}

function new_<tmpl_var name=context>_notes_tab(s)
{
	// Warning: Can't use if (person_notes_tab !== undefined) when it's null.

	if (<tmpl_var name=context>_notes_tab == undefined)
	{
	}
	else
	{
		tab_set.removeTab(<tmpl_var name=context>_notes_tab);
	}

	var title = ("<tmpl_var name=context>" == "organization") ? "Org notes" : "Personal notes";

	<tmpl_var name=context>_notes_tab = new YAHOO.widget.Tab
	({
		label: title,
		content: s,
		active: true
	});
	tab_set.addTab(<tmpl_var name=context>_notes_tab, (tab_set.get('tabs').length - 1) );
	<tmpl_var name=context>_notes_tab.addListener('click', make_<tmpl_var name=context>_notes_focus);
	make_<tmpl_var name=context>_notes_focus();
}

var <tmpl_var name=context>_update_delete_notes_callback =
{
	success: function(o)
	{
		var e = document.getElementById("<tmpl_var name=context>_notes_result");

		if (o.responseText !== undefined)
		{
			new_<tmpl_var name=context>_notes_tab(o.responseText);
		}
		else
		{
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("notes_result");
		e.innerHTML = 'The server failed to respond';
	}
};

function <tmpl_var name=context>_update_notes_list_onsubmit()
{
	var s = "0";
	var i;

	for (i = 0; i < document.<tmpl_var name=context>_update_notes_list_form.elements.length; i++)
	{
		if (document.<tmpl_var name=context>_update_notes_list_form.elements[i].name.search("^notes_id") >= 0)
		{
			if (document.<tmpl_var name=context>_update_notes_list_form.elements[i].checked)
			{
				s = s + "," + document.<tmpl_var name=context>_update_notes_list_form.elements[i].value;
			}
		}
	}

	if (s == "0")
	{
		return false;
	}

	var action = document.<tmpl_var name=context>_update_notes_list_form.action.value;

	if (action == 2) // Delete.
	{
		var ok = confirm("Do you really want to delete these notes?");

		if (ok == false)
		{
			return false;
		}
	}

	// Warning: We get vars from the other form...

	s = "target_id=" + document.<tmpl_var name=context>_update_notes_form.target_id.value + "&notes_id=" + s + "&sid=" + document.<tmpl_var name=context>_update_notes_form.sid.value;
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/notes/delete/<tmpl_var name=context>', <tmpl_var name=context>_update_delete_notes_callback, s);

		return false;
}
