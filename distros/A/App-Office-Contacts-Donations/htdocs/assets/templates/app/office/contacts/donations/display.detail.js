// For organizations...

var display_organization_callback =
{
	success: function(o)
	{
		if (o.responseText !== undefined)
		{
			// Warning: Can't use if (organization_tab !== undefined) when it's null.

			if (organization_tab == undefined)
			{
			}
			else
			{
				tab_set.removeTab(organization_tab);
			}

			organization_tab = new YAHOO.widget.Tab
			({
				label: "Organization",
				content: o.responseText,
				active: true
			});
			tab_set.addTab(organization_tab, (tab_set.get('tabs').length - 1) );
			organization_tab.addListener('click', make_update_name_focus);
			make_update_name_focus();
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("search_result");
		e.innerHTML = "The server failed to respond";
	}
};

function display_organization(id)
{
	var s = "target_id=" + id + "&sid=<tmpl_var name=sid>";
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/organization', display_organization_callback, s);

	return false;
}

// For people...

var display_person_callback =
{
	success: function(o)
	{
		if (o.responseText !== undefined)
		{
			// Warning: Can't use if (person_tab !== undefined) when it's null.

			if (person_tab == undefined)
			{
			}
			else
			{
				tab_set.removeTab(person_tab);
			}

			person_tab = new YAHOO.widget.Tab
			({
				label: "Person",
				content: o.responseText,
				active: true
			});
			tab_set.addTab(person_tab, (tab_set.get('tabs').length - 1) );
			person_tab.addListener('click', make_update_given_names_focus);
			make_update_given_names_focus();
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("search_result");
		e.innerHTML = "The server failed to respond";
	}
};

function display_person(id)
{
	var s = "target_id=" + id + "&sid=<tmpl_var name=sid>";
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/person', display_person_callback, s);

	return false;
}
