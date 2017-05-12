// online.order.page.js.

var online_order_failure_fn;
var online_order_success_fn;

function change_country(country_id)
{
	YUI().use
	(
		"datasource", "io-base", "json", "node", function(Y)
		{
			var success_fn = function(ioId, o)
			{
				var result_div;

				if (o.responseText !== undefined)
				{
					Y.JSON.useNativeParse = false;
					var data = Y.JSON.parse(o.responseText);
					result_div = Y.one("#zone_menu");
					result_div.set("innerHTML", data.menu);
				}
				else
				{
					result_div = Y.one("#order_message_div");
					result_div.set("innerHTML", "The server's response is incomprehensible");
				}
			};
			var failure_fn = function(ioId, o)
			{
				var result_div = Y.one("#order_message_div");
				result_div.set("innerHTML", "The server failed to respond");
			};

			var cfg =
			{
				method: "POST",
				on:
				{
					success: success_fn,
					failure: failure_fn
				},
				sync: true
			};

			var request = Y.io("/Order/change_country?country_id=" + country_id, cfg);
		}
	);
}

function prepare_order_form()
{
	YUI().use
	(
		"datasource-get", "datatable", "event-key", "gallery-formmgr", "io-base", "io-form", "json", "node", function(Y)
		{
			var f = new Y.FormManager("order_form",
			  {
			  });

			f.prepareForm();

			var handle = Y.on("key", function(e)
			  {
				  e.halt();
				  // The YUI docs for Event say to use this, but it stops the effect I want.
				  //handle.detach();
			  }, "#quantity", "press:13");

			online_order_success_fn = function(ioId, o)
			{
				var result_div;

				if (o.responseText !== undefined)
				{
					Y.JSON.useNativeParse = false;
					var data = Y.JSON.parse(o.responseText);

					switch (data.div_name)
					{
					case "order_result_div":
						// Warning: This 'var result_div' line does not work if placed outside the function,
						// in the sense that the 'result_div.set' line stops working in that case.

						result_div = Y.one("#order_result_div");
						result_div.set("innerHTML", "");

						var cols =
							[
								{key: "name",        label: "Name"},
								{key: "price",       label: "Unit price"},
								{key: "quantity",    label: "Quantity"},
								{key: "total_price", label: "Cost"},
								{key: "action",      label: "Action"}
							];
						var table = new Y.DataTable.Base
						({
							columnset: cols,
							recordset: data.content
						}).render("#order_result_div");

						result_div = Y.one("#order_message_div");

						if (data.order_count > 0)
						{
							result_div.set("innerHTML", "<span class=\"red\">Starting a new order...</span>");
						}
						else
						{
							result_div.set("innerHTML", "");
						}

						break;
					case "order_message_div":
						result_div = Y.one("#order_message_div");
						result_div.set("innerHTML", data.content);

						if (data.clear_cart === "Yes")
						{
							result_div = Y.one("#order_result_div");
							result_div.set("innerHTML", "");
						}
					}
				}
				else
				{
					result_div = Y.one("#order_message_div");
					result_div.set("innerHTML", "The server's response is incomprehensible");
				}
			};
			online_order_failure_fn = function(ioId, o)
			{
				var result_div = Y.one("#order_message_div");
				result_div.set("innerHTML", "The server failed to respond");
			};

			Y.one("#reset").on("click", function()
			{
				f.populateForm();
			});

			var online_order_ajax_cfg =
			{
				form:
				{
					id: "order_form"
				},
				method: "POST",
				on:
				{
					success: online_order_success_fn,
					failure: online_order_failure_fn
				},
				sync: true
			};

			Y.one("#add_to_cart").on('click', function(e)
			{
				if (FIC_checkForm("order_form") == false)
				{
					return false;
				}

				var request = Y.io("/Order/add_to_cart", online_order_ajax_cfg);
			});

			Y.one("#cancel_order").on('click', function(e)
			{
				var request = Y.io("/Order/cancel_order", online_order_ajax_cfg);
			});

			Y.one("#checkout").on('click', function(e)
			{
				var request = Y.io("/Order/checkout", online_order_ajax_cfg);
			});
		}
	);
}

function remove_item(order_id, item_id)
{
	YUI().use
	(
		"io-base", "io-form", function(Y)
		{
			var online_order_ajax_cfg =
				{
					method: "POST",
					on:
					{
						success: online_order_success_fn,
						failure: online_order_failure_fn
					},
					sync: true
				};

			var request = Y.io("/Order/remove_from_cart?order_id=" + order_id + ";item_id=" + item_id, online_order_ajax_cfg);
		}
	);
}
