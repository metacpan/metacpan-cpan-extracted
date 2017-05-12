var import_vcards_callback =
{
	// Note: Use upload, not success, with file uploads.

	upload: function(o)
	{
		var e = document.getElementById("import_vcards_result");

		if (o.responseText !== undefined)
		{
			var column_defs =
			[
			 {key: "count", label: "Count"},
			 {key: "name", label: "Name"},
			 {key: "status", label: "Status"},
			];
			var json_data = new YAHOO.util.LocalDataSource(YAHOO.lang.JSON.parse(o.responseText) );
			json_data.responseSchema =
			{
			resultsList: "results",
			fields:
			[
			{key: "count"},
			{key: "name"},
			{key: "status"}
			]
			};
			var data_table = new YAHOO.widget.DataTable("import_vcards_result", column_defs, json_data);
		}
		else
		{
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("import_vcards_result");
		e.innerHTML = 'The server failed to respond';
	}
};

function import_vcards()
{
	// WTF: YUI zaps the path info if it's just in the asyncRequest stmt.

	var f = document.getElementById("import_vcards_form");
	f.action  = "<tmpl_var name=form_action>/import";
	var p = YAHOO.util.Connect.setForm(f, true);
	var r = YAHOO.util.Connect.asyncRequest('POST',
		"<tmpl_var name=form_action>/import", import_vcards_callback);

	return false;
}
