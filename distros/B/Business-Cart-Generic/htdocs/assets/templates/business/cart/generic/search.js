// search.js.

function prepare_search_form()
{
	YUI().use
	(
		"datasource-get", "gallery-formmgr", "io-base", "io-form", "json", "node", function(Y)
		{
			var f = new Y.FormManager("search_form",
			  {
			  });

			f.prepareForm();

			var div = Y.one("#search_result_div");
			var success_fn = function(ioId, o)
			{
				if (o.responseText !== undefined)
				{
					div.set("innerHTML", o.responseText);
				}
				else
				{
					div.set("innerHTML", "The server's response is incomprehensible");
				}
			};
			var failure_fn = function(ioId, o)
			{
				div.set("innerHTML", "The server failed to respond");
			};

			Y.one("#reset_search").on("click", function()
			{
				f.populateForm();
			});

			Y.one("#submit_search").on("click", function(e)
			{
				if (FIC_checkForm("search_form") == false)
				{
					return false;
				}

				var cfg =
					{
						form:
						{
							id: "search_form"
						},
						method: "POST",
						on:
						{
							success: success_fn,
							failure: failure_fn
						},
						sync: true
					};
				var request = Y.io("/Search/display", cfg);
			});
		}
	);
}
