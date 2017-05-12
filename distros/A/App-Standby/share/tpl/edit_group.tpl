[% INCLUDE includes/header.tpl %]

<div class="container">

<h1>[% "Editing Group [_1] ([_2])" | l10n(group_name,group_id) %]</h1>

    <div class="forms">
        <form method="POST" action="">
            <input type="hidden" name="rm" value="update_group" />
            
            <label for="name">
                [% "Name" | l10n %]:
                <span class="small"></span>
            </label>
            <input type="text" name="name" value="[% name %]" />
            
            <div class="spacer"></div>
            
            <label for="new_group_key">
                [% "New Group Key" | l10n %]:
                <span class="small"></span>
            </label>
            <input type="text" name="new_group_key" value="" />
            
	    <label for="group_key">
		[% "Group Key" | l10n %]:
		<span class="small"></span>
	    </label>
	    <input type="text" name="group_key" value="" />
	    
	    <div class="spacer"></div>
	    
	    <button class="button" type="submit" name="submit">
		<img src="/icons/fffsilk/add.png" border="0" />
		[% "Update Group" | l10n %]
	    </button>
        </form>
    </div>
</div>

[% INCLUDE includes/footer.tpl %]
