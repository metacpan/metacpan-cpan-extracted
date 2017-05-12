var search_callback =
{
	success: function(o)
	{
		var e = document.getElementById("search_result");

		if (o.responseText !== undefined)
		{
			var column_defs =
			[
			 {key: "role", label: "Role"},
			 {key: "name", label: "Name"},
			 {key: "email", label: "Email address"},
			 {key: "email_type", label: "Email type"},
			 {key: "phone", label: "Phone"},
			 {key: "phone_type", label: "Phone type"}
			];
			var json_data = new YAHOO.util.LocalDataSource(YAHOO.lang.JSON.parse(o.responseText) );
			json_data.responseSchema =
			{
			resultsList: "results",
			fields:
			[
			{key: "email"},
			{key: "email_type"},
			{key: "id"},
			{key: "name"},
			{key: "phone"},
			{key: "phone_type"},
			{key: "role"}
			]
			};
			var data_table = new YAHOO.widget.DataTable("search_result", column_defs, json_data);
		}
		else
		{
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("search_result");
		e.innerHTML = 'The server failed to respond';
	}
};

function search_onsubmit()
{
// Leave the old data visible in case the user wants to
// compare it with the results of another search.
//
//	if (organization_tab !== undefined)
//	{
//		tab_set.removeTab(organization_tab);
//	}
//
//	if (person_tab !== undefined)
//	{
//		tab_set.removeTab(person_tab);
//	}

	var e = document.getElementById("target");
	var s = "target=" + e.value + "&sid=<tmpl_var name=sid>";
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/search', search_callback, s);

	e.focus();

	return false;
}
