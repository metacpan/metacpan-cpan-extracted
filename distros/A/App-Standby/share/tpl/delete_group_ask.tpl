[% INCLUDE includes/header.tpl %]

<div class="container">

    <h1>[% "Deleting Group: [_1]" | l10n(group_id) %]</h1>
    
    [% "If you really want to delete this group enter the group password below and
    submit the form." | l10n %]
    
    <div class="forms">
	<form method="POST" action="">
	    <input type="hidden" name="rm" value="delete_group" />
	    <input type="hidden" name="group_id" value="[% group_id %]" />
	    
	    <label for="group_key">
		[% "Group Key" | l10n %]:
		<span class="small"></span>
	    </label>
	    <input type="text" name="group_key" value="" />
	    
	    <div class="spacer"></div>
	    
	    <button class="button" type="submit" name="submit">
		<img src="/icons/fffsilk/add.png" border="0" />
		[% "Delete Group" | l10n %]
	    </button>
	</form>
    </div>
</div>

[% INCLUDE includes/footer.tpl %]
