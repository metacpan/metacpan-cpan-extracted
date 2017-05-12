var search_callback =
{
	success: function(o)
	{
		if (o.responseText !== undefined)
		{
			var json_data = new YAHOO.util.LocalDataSource(YAHOO.lang.JSON.parse(o.responseText) );

			json_data.responseSchema =
			{
			resultsList: "results",
			fields:
			[
			{key: "name"},
			{key: "role"}
			]
			};

			var column_defs =
			[
			 {key: "name", label: "Name"},
			 {key: "role", label: "Role"}
			];

			var data_table = new YAHOO.widget.DataTable("search_result", column_defs, json_data);
		}
		else
		{
			var e       = document.getElementById("search_result");
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e       = document.getElementById("search_result");
		e.innerHTML = 'The server failed to respond';
	}
};

function search_onsubmit()
{
	var e = document.getElementById("target");

	// Note: The &rm=search is only in the next line for cgi-bin/ajax.cgi.
	// local/ajax does not need it, due to the /search in the next line plus 1,
	// which is converted into a run mode by CGI::Application::Dispatch.

	var s = "target=" + e.value + "&rm=search&sid=<tmpl_var name=sid>";
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/search', search_callback, s);

	e.focus();

	return false;
}
