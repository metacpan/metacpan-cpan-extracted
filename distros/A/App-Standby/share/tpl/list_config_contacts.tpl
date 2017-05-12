[% INCLUDE includes/header.tpl %]

<div class="container">

	<h1>[% "Configuration settings for user #[_1]" | l10n(contact_id) %]</h1>
	[% FOREACH line IN config %]
	    [% IF loop.first %]
	    <table class="table table-striped">
		<thead>
		    <tr>
			<th>[% "Key" | l10n %]</th>
			<th>[% "Value" | l10n %]</th>
			<th>[% "del" | l10n %]</th>
		    </tr>
		</thead>
		<tbody>
	    [% END %]
		<tr>
		    <td><a href="?rm=edit_config_contacts&cconfig_id=[% line.id %]&contact_id=[% contact_id %]">[% line.key %]</a></td>
		    <td>[% line.value %]</td>
		    <td><a href="?rm=delete_config_contacts_ask&cconfig_id=[% line.id %]&contact_id=[% contact_id %]">del</a></td>
		</tr>
	    [% IF loop.last %]
		</tbody>
		<tfoot></tfoot>
	    </table>
	    [% END %]
	[% END %]
	<a class="btn" href="?rm=add_config_contacts&contact_id=[% contact_id %]&group_id=[% group_id %]">[% "Create new config item for this contact" | l10n %]</a><br />

</div>
	
[% INCLUDE includes/footer.tpl %]
