[% INCLUDE includes/header.tpl %]

<div class="container">

    <h1>[% "Deleting User: [_1] ([_2])" | l10n(name,contact_id) %]</h1>
    
    If you really want to delete this user enter the group password below and
    submit the form.
    
    <div class="forms">
        <form method="POST" action="">
            <input type="hidden" name="rm" value="delete_contact" />
            <input type="hidden" name="contact_id" value="[% contact_id %]" />
            
            <label for="group_key">
                [% "Group Key" | l10n %]:
                <span class="small"></span>
            </label>
            <input type="text" name="group_key" value="" />
            
            <div class="spacer"></div>
            
            <button class="button" type="submit" name="submit">
		<img src="/icons/fffsilk/add.png" border="0" />
		[% "Delete Contact" | l10n %]
	    </button>
        </form>
    </div>
</div>

[% INCLUDE includes/footer.tpl %]
