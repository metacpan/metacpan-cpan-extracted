<html>
<body>

  <form action="/handlers/dev.validate" method="post">
    <p>
      <label>Enter the code you see below:</label>
      <input type="text" name="security_code" />
    </p>
    <p>
      <label>&nbsp;</label>
      <img id="captcha" src="/handlers/dev.captcha?r=<%= rand() %>" alt="Security Code" />
      <br/>
      <a href="" onclick="document.getElementById('captcha').src = '/handlers/dev.captcha?r=' + Math.random(); return false">
        (Click for a new Image)
      </a>
    </p>
    <p>
      <label>&nbsp;</label>
      <input type="submit" value="Submit" />
    </p>
  </form>

</body>
</html>

