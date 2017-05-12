<br><center>
<form action="/admin" method="post">
<input type="hidden" name="type" value="SOA">
<input type="hidden" name="record_id" value="$RECORD_ID">
<input type="hidden" name="dom_id" value="$DOM_ID">
<input type="hidden" name="action" value="edit">
<table bgcolor="#CCCCCC" border="0" cellpadding="1" cellspacing="1">
  <tr><td colspan="2">$EXPLANATION</td></tr>
  <tr><td>$AUTH_NS</td><td>$AUTH_NS_VALUE</td></tr>
  <tr><td>$SERIAL</td><td>$SERIAL_VALUE</td></tr>
  <tr><td>$ADMIN_EMAIL</td><td><input type="text" name="soa_email" value="$ADMIN_EMAIL_VALUE"></td></tr>
  <tr><td>$REFRESH</td><td><input type="text" name="refresh" value="$REFRESH_VALUE"></td></tr>
  <tr><td>$RETRY</td><td><input type="text" name="retry" value="$RETRY_VALUE"></td></tr>
  <tr><td>$EXPIRE</td><td><input type="text" name="expire" value="$EXPIRE_VALUE"></td></tr>
  <tr><td>$TTL</td><td><input type="text" name="default_ttl" value="$TTL_VALUE"></td></tr>
  <tr><td colspan="2" align="right"><input type="submit" name="button" value="$SUBMIT">&nbsp;<input type="submit" name="button" value="$CANCEL"><!--&nbsp;<input type="submit" name="button" value="$HELP">--></td></tr>
</table>
</form>
</center>
