var <tmpl_var name=context>_person_callback =
{
	success: function(o)
	{
		var e = document.getElementById("<tmpl_var name=context>_person_result");

		if (o.responseText !== undefined)
		{
			var s = o.responseText;
			e.innerHTML = s;

			if (s.search("Added") >= 0)
			{
				// Stop the user adding the same one twice.
				// But Firebug says reset() is not a function.
				// document.<tmpl_var name=context>_person.reset();
			}
			else
			{
				if (s.search("Deleted") >= 0)
				{
					document.<tmpl_var name=context>_person_form.target_id.value = 0;
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
		var e = document.getElementById("<tmpl_var name=context>_person_result");
		e.innerHTML = 'The server failed to respond';
	}
};

var <tmpl_var name=context>_person_donations_callback =
{
	success: function(o)
	{
		if (o.responseText !== undefined)
		{
			new_person_donations_tab(o.responseText);
		}
		else
		{
			var e = document.getElementById("<tmpl_var name=context>_person_result");

			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("<tmpl_var name=context>_person_result");
		e.innerHTML = 'The server failed to respond';
	}
};

var <tmpl_var name=context>_person_notes_callback =
{
	success: function(o)
	{
		if (o.responseText !== undefined)
		{
			new_person_notes_tab(o.responseText);
		}
		else
		{
			var e = document.getElementById("<tmpl_var name=context>_person_result");

			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("<tmpl_var name=context>_person_result");
		e.innerHTML = 'The server failed to respond';
	}
};

function <tmpl_var name=context>_person_onsubmit()
{
	var action = document.<tmpl_var name=context>_person_form.action.value;
	var id     = document.<tmpl_var name=context>_person_form.target_id.value;

	if (action > 101) // Delete (102), Donations (103), Notes (104), Update (105), Sites (106).
	{
		if (id == 0)
		{
			return false;
		}
	}

	// 101 => Add.

	if (action == 102) // Delete.
	{
		var e  = document.getElementById("update_person_result");
		var s  = 'Do you really want to delete ' + e.innerHTML + "'s record and notes?";
		var ok = confirm(s);

		if (ok == false)
		{
			return false;
		}
	}

	if (action == 103) // Donations.
	{
		var s = "target_id=" + id + "&sid=" + document.<tmpl_var name=context>_person_form.sid.value;
		var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/donations/display/person', <tmpl_var name=context>_person_donations_callback, s);

		return false;
	}

	if (action == 104) // Notes.
	{
		var s = "target_id=" + id + "&sid=" + document.<tmpl_var name=context>_person_form.sid.value;
		var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/notes/display/person', <tmpl_var name=context>_person_notes_callback, s);

		return false;
	}

	// 105 => Update.
	// 106 => Sites.

	var p = YAHOO.util.Connect.setForm("<tmpl_var name=context>_person_form");
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/person/<tmpl_var name=context>', <tmpl_var name=context>_person_callback);

	return false;
}

var <tmpl_var name=context>_delete_occupation_callback =
{
	success: function(o)
	{
		var e = document.getElementById("<tmpl_var name=context>_person_result");

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
		var e = document.getElementById("<tmpl_var name=context>_person_result");
		e.innerHTML = 'The server failed to respond';
	}
};

function <tmpl_var name=context>_person_occupation_onsubmit()
{
	// Warning: This code means the string sent to the server starts with '0,', which must be discarded.
	// See sub App::Office::Contacts::Controller::Person.delete_occupation_via_person().

	var s = "0";
	var i;

	for (i = 0; i < document.<tmpl_var name=context>_person_occupation_form.elements.length; i++)
	{
		if (document.<tmpl_var name=context>_person_occupation_form.elements[i].name.search("^occupation_id") >= 0)
		{
			if (document.<tmpl_var name=context>_person_occupation_form.elements[i].checked)
			{
				s = s + "," + document.<tmpl_var name=context>_person_occupation_form.elements[i].value;
			}
		}
	}

	// Nothing was checked, so do nothing.

	if (s == "0")
	{
		return false;
	}

	var action = document.<tmpl_var name=context>_person_occupation_form.action.value;

	if (action == 2) // Delete.
	{
		var ok = confirm("Do you really want to delete occupations?");

		if (ok == false)
		{
			return false;
		}
	}

	// Warning: We get 2 vars from the other form...

	s = "target_id=" + document.<tmpl_var name=context>_person_form.target_id.value + "&occupation_id=" + s + "&sid=" + document.<tmpl_var name=context>_person_form.sid.value;
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/delete_occupation_via_person', <tmpl_var name=context>_delete_occupation_callback, s);

		return false;
}
