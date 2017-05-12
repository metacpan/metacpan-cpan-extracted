[% INCLUDE includes/header.tpl %]

<div class="container">

<h1>[% "Editing User: [_1] ([_2])" | l10n(name,contact_id) %]</h1>

    <div class="forms">
	<form method="POST" action="">
	    <input type="hidden" name="rm" value="update_contact" />
	    <input type="hidden" name="contact_id" value="[% contact_id %]" />
	    
	    <label for="name">
		[% "Name" | l10n %]:
		<span class="small"></span>
	    </label>
	    <input type="text" name="name" value="[% name %]" />
	    
	    <div class="spacer"></div>
	    
	    <label for="cellphone">
		[% "Cellphone" | l10n %]
		<span class="small"></span>
	    </label>
	    <input type="text" name="cellphone" value="[% cellphone %]" />
	    
	    <div class="spacer"></div>
	    
	    <label for="group_id">
		[% "Group ID" | l10n %]
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
		[% "Update User" | l10n %]
	    </button>
	</form>
    </div>

    <a href="?rm=list_config_contacts&contact_id=[% contact_id %]&group_id=[% group_id %]">[% "Show per-user config" | l10n %]</a>
</div>

[% INCLUDE includes/footer.tpl %]
