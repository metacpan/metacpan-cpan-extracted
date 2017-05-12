[% INCLUDE includes/header.tpl %]

<div class="container">

<h1>[% "Editing Service [_1] for Group #[_2]" | l10n(name,group_id) %]</h1>

    <div class="forms">
	<form method="POST" action="">
	    <input type="hidden" name="rm" value="update_group_service" />
	    
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
	    
	    <label for="name">
		[% "Name" | l10n %]:
		<span class="small"></span>
	    </label>
	    <input type="text" name="name" value="[% name %]" />
	    
	    <div class="spacer"></div>
	    
	    <label for="dest">
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
		<option[% IF class == service %] selected[% END %]>[% service %]</option>
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
		[% "Update Service" | l10n %]
	    </button>
	</form>
    </div>
</div>

[% INCLUDE includes/footer.tpl %]
