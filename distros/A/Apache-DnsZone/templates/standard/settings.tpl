<br><center>
<form action="/admin" method="POST">
<input type="hidden" name="type" value="SETTINGS">
<input type="hidden" name="action" value="settings">
<table bgcolor="#CCCCCC" border="0" cellpadding="1" cellspacing="1">
  <tr><td>$LANGUAGE:</td><td>$LANG_VALUE</td></tr>
  <tr><td>$EMAIL:</td><td><input type="text" name="user_email" value="$EMAIL_VALUE"></td></tr>
  <tr><td colspan="2">$PASSWORD_CHANGE</td></tr>
  <tr><td>$NEW_PASSWORD:</td><td><input type="password" name="password" value="$NEW_PASSWORD_VALUE"></td></tr>
  <tr><td>$CONFIRM_PASSWORD:</td><td><input type="password" name="password_confirm" value="$CONFIRM_PASSWORD_VALUE"></td></tr>
  <tr><td colspan="2" align="right"><input type="submit" name="button" value="$SUBMIT">&nbsp;<input type="submit" name="button" value="$CANCEL"><!--&nbsp;<input type="submit" name="button" value="$HELP">--></td></tr>
</table>
</form>
</center>
