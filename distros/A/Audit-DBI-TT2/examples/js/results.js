/**
 * Audit::DBI::TT2 v2.3.0
 * https://metacpan.org/release/Audit-DBI
 *
 * Copyright 2010-2017 Guillaume Aubert
 *
 * This code is free software; you can redistribute it and/or modify it under the
 * same terms as Perl 5 itself.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the LICENSE file for more details.
 */
$(document).ready(
	function()
	{
		// Search all the links in code columns.
		$('#results .code a').each(
			function()
			{
				// Activate toggling.
				$(this).click(
					function()
					{
						$(this).parent().find('div').toggle();
						return false;
					}
				);
			}
		);

		// Activate toggling all
		$('#toggle_all').click(
			function()
			{
				$('#results .code div').each(
					function()
					{
						$(this).toggle();
					}
				);
				return false;
			}
		);
	}
);

