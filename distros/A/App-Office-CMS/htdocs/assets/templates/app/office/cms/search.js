// search.js.

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
			{key: "design_name"},
			{key: "match"},
			{key: "page_name"},
			{key: "site_name"}
			]
			};
			var column_defs =
			[
			 {key: "match",       label: "Match",   sortable: true},
			 {key: "site_name",   label: "Site",    sortable: true},
			 {key: "design_name", label: "Design",    sortable: true},
			 {key: "page_name",   label: "Page",    sortable: true}
			];
			var data_table = new YAHOO.widget.DataTable("search_result_div", column_defs, json_data);
		}
		else
		{
			var e = document.getElementById("search_result_div");
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("search_result_div");
		e.innerHTML = "The server failed to respond";
	}
};

var search_onsubmit = function ()
{
	if (FIC_checkForm("search_form") == false)
	{
		return false;
	}

	YAHOO.util.Connect.setForm("search_form");
	var r = YAHOO.util.Connect.asyncRequest("POST", "<: $form_action :>/search", search_callback);

	return false;
}
