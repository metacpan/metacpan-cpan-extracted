[% INCLUDE includes/header.tpl %]

<div class="container">

	<h1>[% "Contacts in group [_1]" | l10n(group_name) %]</h1>
	[% FOREACH line IN contacts %]
	    [% IF loop.first %]
	    <table class="table table-striped">
		 <thead>
		   <tr>
			<th>[% "Name" | l10n %]</th>
			<th>[% "Cellphone" | l10n %]</th>
			<th>[% "act" | l10n %]</th>
			<th>[% "del" | l10n %]</th>
		   </tr>
		 </thead>
		 <tbody>
	    [% END %]
		 <tr[% IF line.is_enabled %] class="success"[% ELSE %] class="error"[% END %]>
		    <td><a href="?rm=edit_contact&contact_id=[% line.id %]&group_id=[% group_id %]">[% line.name %]</a></td>
		    <td>[% line.cellphone %]</td>
		    
		    [% IF line.is_enabled %]
		    <td><a class="btn btn-warning" href="?rm=disable_contact_ask&contact_id=[% line.id %]&group_id=[% group_id %]">dis</a></td>
		    [% ELSE %]
		    <td><a class="btn btn-success" href="?rm=enable_contact_ask&contact_id=[% line.id %]&group_id=[% group_id %]">ena</a></td>
		    [% END %]
		    
		    <td><a class="btn btn-danger" href="?rm=delete_contact_ask&contact_id=[% line.id %]&group_id=[% group_id %]">del</a></td>
		</tr>
	    [% IF loop.last %]
		</tbody>
		<tfoot></tfoot>
	    </table>
	    [% END %]
	[% END %]
	<a class="btn" href="?rm=add_contact&group_id=[% group_id %]">[% "Create new contact" | l10n %]</a>
	<br />
	
	[% "This is the list of contacts configured for this group." | l10n %]

</div>

[% INCLUDE includes/footer.tpl %]

