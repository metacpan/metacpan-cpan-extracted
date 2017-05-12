[% INCLUDE includes/header.tpl %]

<div class="container">

<h1>[% "Adding Service for Group #[_1]" | l10n(group_id) %]</h1>

    <div class="forms">
	<form method="POST" action="">
	    <input type="hidden" name="rm" value="insert_service" />
	    
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
	    
	    <label for="name">
		[% "Name" | l10n %]:
		<span class="small">Use lowercase alphanumerics only. Used as config prefix.</span>
	    </label>
	    <input type="text" name="name" value="[% name %]" />
	    
	    <div class="spacer"></div>
	    
	    <label for="desc">
		[% "Description" | l10n %]:
		<span class="small"></span>
	    </label>
	    <input type="text" name="desc" value="[% desc %]" />
	    
	    <div class="spacer"></div>
	    
	    <label for="class">
		[% "Class" | l10n %]:
		<span class="small"></span>
	    </label>
	    <select name="class">
	    [% FOREACH service IN services %]
		<option>[% service %]</option>
	    [% END %]
	    </select>
	    
	    <div class="spacer"></div>
	    
	    <label for="group_key">
		[% "Group Password" | l10n %]:
		<span class="small"></span>
	    </label>
	    <input type="text" name="group_key" value="" />
	    
	    <div class="spacer"></div>
	    
	    <button class="button" type="submit" name="submit">
		<img src="/icons/fffsilk/add.png" border="0" />
		[% "Add Service" | l10n %]
	    </button>
	</form>
    </div>
</div>

[% INCLUDE includes/footer.tpl %]
