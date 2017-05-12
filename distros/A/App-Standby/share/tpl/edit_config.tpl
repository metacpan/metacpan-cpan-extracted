[% INCLUDE includes/header.tpl %]

<div class="container">

<h1>[% "Editing Config: [_1] for Group #[_2]" | l10n(key,group_id) %]</h1>

    <div class="forms">
        <form method="POST" action="">
            <input type="hidden" name="rm" value="update_config" />
            <input type="hidden" name="config_id" value="[% config_id %]" />
            
            <label for="key">
                [% "Key" | l10n %]:
                <span class="small"></span>
            </label>
            <input type="text" value="[% key %]" readonly=1 />
            
            <div class="spacer"></div>
            
            <label for="value">
                [% "Value" | l10n %]:
                <span class="small"></span>
            </label>
            <input type="text" name="value" value="[% value %]" />
            
            <div class="spacer"></div>
            
            <label for="group_key">
                [% "Group Key" | l10n %]:
                <span class="small"></span>
            </label>
            <input type="text" name="group_key" value="" />
            
            <div class="spacer"></div>
            
            <button class="button" type="submit" name="submit">
		<img src="/icons/fffsilk/add.png" border="0" />
		[% "Update Config" | l10n %]
	    </button>
        </form>
    </div>
</div>

[% INCLUDE includes/footer.tpl %]
