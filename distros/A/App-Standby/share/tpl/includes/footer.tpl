  <script src="js/jquery-2.0.1.min.js"></script>
  <script src="js/bootstrap.min.js"></script>
  <!-- end concatenated and minified scripts-->
	[% FOREACH message IN messages %]
	[% IF loop.first %]
	<div id="dialog-message" title="Notifications">
	[% END %]
		<div class="ui-widget">
			[% IF message.severity == "error" %]
			<div class="ui-state-error ui-corner-all" style="padding: 0 .7em;"> 
				<p><span class="ui-icon ui-icon-alert" style="float: left; margin-right: .3em;"></span>
			[% ELSE %]
			<div class="ui-state-highlight ui-corner-all" style="margin-top: 20px; padding: 0 .7em;"> 
				<p><span class="ui-icon ui-icon-info" style="float: left; margin-right: .3em;"></span>
			[% END %] 
				<strong>[% message.severity | ucfirst %]:</strong> [% message.loc %].</p>
			</div>
		</div>
	[% IF loop.last %]
	</div>
	<script type="text/javascript">
		$(function() {
			$("#dialog-message").dialog({
				modal: true,
				width: 600,
				position: 'center',
				buttons: {
					Ok: function() {
						$(this).dialog("close");
					}
				}
			});
		});
	</script>
	[% END %]
	[% END %]
  
  <!--[if lt IE 7 ]>
    <script src="[% media_prefix %]/js/libs/dd_belatedpng.js"></script>
    <script type="text/javascript"> DD_belatedPNG.fix('img, .png_bg'); //fix any <img> or .png_bg background-images</script>
  <![endif]-->
  
</body>
</html>
