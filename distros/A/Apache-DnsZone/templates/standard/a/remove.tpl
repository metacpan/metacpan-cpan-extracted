<br><center>
<form action="/admin" method="post">
<input type="hidden" name="type" value="A">
<input type="hidden" name="record_id" value="$RECORD_ID">
<input type="hidden" name="dom_id" value="$DOM_ID">
<input type="hidden" name="action" value="delete">
<table bgcolor="#CCCCCC" border="0" cellpadding="1" cellspacing="1">
  <tr><td colspan="2">$EXPLANATION</td></tr>
  <tr><td>$HOST</td><td>$HOST_VALUE</td></tr>
  <tr><td>$IP_ADDRESS</td><td>$IP_ADDRESS_VALUE</td></tr>
  <tr><td>$TTL</td><td>$TTL_VALUE</td></tr>
  <tr><td colspan="2" align="right"><input type="submit" name="button" value="$SUBMIT">&nbsp;<input type="submit" name="button" value="$CANCEL"><!--&nbsp;<input type="submit" name="button" value="$HELP">--></td></tr>
</table>
</form>
</center>
