[% INCLUDE includes/header.tpl %]

<div class="container">

	<h1>[% "Groups configured" | l10n %]</h1>
	[% FOREACH group IN groups %]
		[% IF loop.first %]
		<table class="table table-striped">
			<thead>
			<tr>
				<th>[% "Name" | l10n %]</th>
				<th>[% "del" | l10n %]</th>
			</tr>
			</thead>
			<tbody>
		[% END %]
			<tr>
				<td><a href="?rm=edit_group&group_id=[% group.id %]">[% group.name %]</a></td>
				<td><a class="btn btn-danger" href="?rm=delete_group_ask&group_id=[% group.id %]">del</a></td>
			</tr>
		[% IF loop.last %]
		</tbody>
		<tfoot>
		</tfoot>
		</table>
		[% END %]
	[% END %]
	<a class="btn" href="?rm=add_group">[% "New Group" | l10n %]</a><br />
	<hr />

</div>
	
[% INCLUDE includes/footer.tpl %]
