[% INCLUDE includes/header.tpl %]

<div class="container">

<h1>[% "Adding User" | l10n %]</h1>

    <div class="forms">
	<form method="POST" action="">
	    <input type="hidden" name="rm" value="insert_contact" />
	    <input type="hidden" name="group_id" value="[% group_id %]" />
	    
	    <label for="name">
		[% "Name" | l10n %]:
		<span class="small"></span>
	    </label>
	    <input type="text" name="name" value="" />
	    
	    <div class="spacer"></div>
	    
	    <label for="cellphone">
		[% "Cellphone" | l10n %]
		<span class="small"></span>
	    </label>
	    <input type="text" name="cellphone" value="" />
	    
	    <div class="spacer"></div>
	    
	    <label for="group_id">
		[% "Group ID" | l10n %]:
		<span class="small"></span>
	    </label>
	    <select name="group_id">
	    [% FOREACH group IN groups %]
		<option value="[% group.id %]"[% IF group_id == group.id %] selected[% END %]>[% group.name %] ([% group.id %])</option>
	    [% END %]
	    </select>
	    
	    <div class="spacer"></div>
	    
	    <label for="group_key">
		[% "Group Key" | l10n %]:
		<span class="small"></span>
	    </label>
	    <input type="text" name="group_key" value="" />
	    
	    <div class="spacer"></div>
	    
	    <button class="button" type="submit" name="submit">
		<img src="/icons/fffsilk/add.png" border="0" />
		[% "Add Contact" | l10n %]
	    </button>
	</form>
    </div>
</div>

[% INCLUDE includes/footer.tpl %]
