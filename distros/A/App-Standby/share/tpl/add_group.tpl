[% INCLUDE includes/header.tpl %]

<div class="container">

<h1>[% "Adding Group" | l10n %]</h1>

    <div class="forms">
	<form method="POST" action="">
	    <input type="hidden" name="rm" value="insert_group" />
	    
	    <div class="spacer"></div>
	    
	    <label for="name">
		[% "Name" | l10n %]:
		<span class="small"></span>
	    </label>
	    <input type="text" name="name" value="[% name %]" />
	    
	    <div class="spacer"></div>
	    
	    <label for="key">
		[% "Group Password" | l10n %]:
		<span class="small"></span>
	    </label>
	    <input type="text" name="key" value="" />
	    
	    <div class="spacer"></div>
	    
	    <button class="button" type="submit" name="submit">
		<img src="/icons/fffsilk/add.png" border="0" />
		[% "Add Group" | l10n %]
	    </button>
	</form>
    </div>
</div>

[% INCLUDE includes/footer.tpl %]
