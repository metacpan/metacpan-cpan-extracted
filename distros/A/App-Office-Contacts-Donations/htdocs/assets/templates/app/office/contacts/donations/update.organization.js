var <tmpl_var name=context>_organization_callback =
{
	success: function(o)
	{
		var e = document.getElementById("<tmpl_var name=context>_organization_result");

		if (o.responseText !== undefined)
		{
			var s = o.responseText;
			e.innerHTML = s;

			if (s.search("Added") >= 0)
			{
				// Stop the user adding the same one twice.
				// But Firebug says reset() is not a function.
				// document.<tmpl_var name=context>_organization.reset();
			}
			else
			{
				if (s.search("Deleted") >= 0)
				{
					document.<tmpl_var name=context>_organization_form.target_id.value = 0;
				}
			}
		}
		else
		{
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("<tmpl_var name=context>_organization_result");
		e.innerHTML = 'The server failed to respond';
	}
};

var <tmpl_var name=context>_organization_donations_callback =
{
	success: function(o)
	{
		if (o.responseText !== undefined)
		{
			new_organization_donations_tab(o.responseText);
		}
		else
		{
			var e = document.getElementById("<tmpl_var name=context>_organization_result");

			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("<tmpl_var name=context>_organization_result");
		e.innerHTML = 'The server failed to respond';
	}
};

var <tmpl_var name=context>_organization_notes_callback =
{
	success: function(o)
	{
		if (o.responseText !== undefined)
		{
			new_organization_notes_tab(o.responseText);
		}
		else
		{
			var e = document.getElementById("<tmpl_var name=context>_organization_result");

			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("<tmpl_var name=context>_organization_result");
		e.innerHTML = 'The server failed to respond';
	}
};

function <tmpl_var name=context>_organization_onsubmit()
{
	var action = document.<tmpl_var name=context>_organization_form.action.value;
	var id     = document.<tmpl_var name=context>_organization_form.target_id.value;

	if (action > 201) // Delete (202), Donations (203), Notes (204), Update (205), Sites (206).
	{
		if (id == 0)
		{
			return false;
		}
	}

	// 201 => Add.

	if (action == 202) // Delete.
	{
		var e  = document.getElementById("update_organization_result");
		var s  = 'Do you really want to delete ' + e.innerHTML + "'s record and notes?";
		var ok = confirm(s);

		if (ok == false)
		{
			return false;
		}
	}

	if (action == 203) // Donations.
	{
		var s = "target_id=" + id + "&sid=" + document.<tmpl_var name=context>_organization_form.sid.value;
		var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/donations/display/organization', <tmpl_var name=context>_organization_donations_callback, s);

		return false;
	}

	if (action == 204) // Notes.
	{
		var s = "action=" + action + "&target_id=" + id + "&sid=" + document.<tmpl_var name=context>_organization_form.sid.value;
		var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/notes/display/organization', <tmpl_var name=context>_organization_notes_callback, s);

		return false;
	}

	// 205 => Update.
	// 206 => Sites.

	var p = YAHOO.util.Connect.setForm("<tmpl_var name=context>_organization_form");
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/organization/<tmpl_var name=context>', <tmpl_var name=context>_organization_callback);

	return false;
}

var <tmpl_var name=context>_delete_orgs_occupation_callback =
{
	success: function(o)
	{
		var e = document.getElementById("<tmpl_var name=context>_organization_result");

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
		var e = document.getElementById("<tmpl_var name=context>_organization_result");
		e.innerHTML = 'The server failed to respond';
	}
};

function <tmpl_var name=context>_organization_staff_onsubmit()
{
	// Warning: This code means the string sent to the server starts with '0,', which must be discarded.
	// See sub App::Office::Contacts::Controller::Organization.delete_occupation_via_organization().

	var s = "0";
	var i;

	for (i = 0; i < document.<tmpl_var name=context>_organization_staff_form.elements.length; i++)
	{
		if (document.<tmpl_var name=context>_organization_staff_form.elements[i].name.search("^occupation_id") >= 0)
		{
			if (document.<tmpl_var name=context>_organization_staff_form.elements[i].checked)
			{
				s = s + "," + document.<tmpl_var name=context>_organization_staff_form.elements[i].value;
			}
		}
	}

	// Nothing was checked, so do nothing.

	if (s == "0")
	{
		return false;
	}

	var action = document.<tmpl_var name=context>_organization_staff_form.action.value;

	if (action == 2) // Delete.
	{
		var ok = confirm("Do you really want to delete occupations?");

		if (ok == false)
		{
			return false;
		}
	}

	// Warning: We get 2 vars from the other form...

	s = "target_id=" + document.<tmpl_var name=context>_organization_form.target_id.value + "&occupation_id=" + s + "&sid=" + document.<tmpl_var name=context>_organization_form.sid.value;
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/delete_occupation_via_organization', <tmpl_var name=context>_delete_orgs_occupation_callback, s);

		return false;
}
