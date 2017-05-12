[% INCLUDE includes/header.tpl %]

<div class="container">

<h1>[% "Adding Config for User #[_1]" | l10n(contact_id) %]</h1>

    <div class="forms">
	<form method="POST" action="">
	    <input type="hidden" name="rm" value="insert_config_contacts" />

	    <label for="contact_id">
		[% "Contact ID" | l10n %]:
		<span class="small"></span>
	    </label>
	    <select name="contact_id">
	    [% FOREACH contact IN contacts %]
		<option value="[% contact.id %]"[% IF contact_id == contact.id %] selected[% END %]>[% contact.name %] ([% contact.id %])</option>
	    [% END %]
	    </select>
	    
	    <div class="spacer"></div>
	    
	    <label for="key">
		[% "Key" | l10n %]:
		<span class="small"></span>
	    </label>
	    <input type="text" name="key" value="[% key %]" />
	    
	    <div class="spacer"></div>
	    
	    <label for="value">
		[% "Value" | l10n %]:
		<span class="small"></span>
	    </label>
	    <input type="text" name="value" value="[% value %]" />
	    
	    <div class="spacer"></div>
	    
	    <label for="group_key">
		[% "Group password" | l10n %]:
		<span class="small"></span>
	    </label>
	    <input type="text" name="group_key" value="" />
	    
	    <div class="spacer"></div>
	    
	    <button class="button" type="submit" name="submit">
		<img src="/icons/fffsilk/add.png" border="0" />
		[% "Add Config Item" | l10n %]
	    </button>
	</form>
    </div>
</div>

[% INCLUDE includes/footer.tpl %]
