<div id="page">
  <div id="menu">
{ $MENU }
  </div>
  <div>
    <table>
      <tr>
        <td colspan="3" id="picture">
						<center class="nav">
						Viewing picture { $NUMBER } of { $TOTAL } at { $RESOLUTION } pixels<br>
            <img src="{ $SRC }"><br>
            Size [ { $SIZES } ]<br>
						Slideshow [ { $SLIDESHOW } ]
          </center>
        </td>
      </tr>
      <tr>
        <td align="left" width="20%">{ $BACK }</td>

				{ $PICTUREINFO }

        <td align="right" width="20%">{ $NEXT }</td>
      </tr>
	  <tr>
	  	<td colspan="3">
		  <div id="gallery">
		    Indexed by <a href="http://apachegallery.dk">Apache::Gallery</a> - Copyright &copy; 2001-2005 Michael Legart - <a href="http://www.hestdesign.com/">Hest Design!</a>
		  </div>
		</td>
	  </tr>
    </table>
  </div>
</div>
