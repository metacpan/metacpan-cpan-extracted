[% INCLUDE includes/header.tpl %]
<div class="container">
   <div class="hero-unit">
	   <h1>Current order</h1>
      <p>This is the current notification order for the Group [% group_name %].</p>
	
	   [% FOREACH line IN ordered_contacts %]
	   [% IF loop.first %]
	   <table class="table table-striped">
	   	<thead>
	   		<tr>
	   			<th>[% "Slot" | l10n %]</th>
	   			<th>[% "Name" | l10n %]</th>
	   			<th>[% "Cellphone" | l10n %]</th>
	   		</tr>
	   	</thead>
	   	<tbody>
	   [% END %]
	   <tr[% IF loop.first %] class="success"[% END %]>
	   	<td[% IF loop.first %] class="green"[% END %]>[% line.ordinal %]</td>
	   	<td[% IF loop.first %] class="green"[% END %]>[% line.name %]</td>
	   	<td[% IF loop.first %] class="green"[% END %]>[% line.cellphone %]</td>
	   </tr>
	   [% IF loop.last %]
	   	</tbody>
	   	<tfoot></tfoot>
	   </table>
	   [% END %]
	   [% END %]
   </div>
	
   <div class="row">

      <div class="span4">
      	<h2>[% "Change Order" | l10n(group_name) %]</h2>
      	[% FOREACH line IN random_contacts %]
      		[% IF loop.first %]
      		<div class="forms">
      			<form method="POST" action="">
      				<input type="hidden" name="rm" value="update_janitor" />
      				<input type="hidden" name="group_id" value="[% group_id %]" />
      		
      				<label for="janitor">
      					[% "Janitor" | l10n %]:
      					<span class="small"></span>
      				</label>
      				<select name="janitor">
      		[% END %]
      					<option value="[% line.id %]">[% line.name %]</option>
      		[% IF loop.last %]
      				</select>
      		
      				<div class="spacer"></div>
      		
      				<label for="group_key">
      					[% "Group password" | l10n %]:
      					<span class="small"></span>
      				</label>
      				<input type="text" name="group_key" value="" />
      		
      				<div class="spacer"></div>
      		
      				<button class="btn btn-danger" type="submit" name="submit">
      					[% "Update Queue" | l10n %]
      				</button>
      			</form>
      		</div>
      		[% END %]
      	[% END %]
      	
      	<small><b>[% "Notice" | l10n %]:</b> [% "Disabled contacts won't be listed here!" | l10n %]</small>
      	
      </div>

      <div class="span4">
      	<h2>Services</h2>
         <p>These are the services currently configured for this group.</p>
      	<ul>
      	[% FOREACH name IN services.keys %]
      		<li>[% services.$name.description %] ([% name %])</li>
      	[% END %]
      	</ul>
      </div>

      <div clasS="span4">
      	<h2>[% "Important remarks" | l10n %]</h2>
      	<ul>
      		<li>[% "The pingdom service can't handle escalations. Only the primary contact is notified." | l10n %]</li>
      	   <li>[% "The selected contact will be set as the primary contact in all configured services." | l10n %]</li>
      	   <li>[% "This means that he will receive text messages and will be called first." | l10n %]</li>
      	   <li>[% "The contact which on duty before will be placed at the end of the notification list." | l10n %]</li>
      	</ul>
      </div>
   
   </div><!-- /class:row -->
</div>
[% INCLUDE includes/footer.tpl %]
