<div class="gallery-info">
    { $MENU }
</div>
<div class="gallery-nav">
{ $BACK } - <a href="./" accesskey="u" rel="up" title="Accesskey U"><u>u</u>p</a> - { $NEXT }
</div>

<div class="clr" />
<div class="img-info">
		IMG { $NUMBER } of { $TOTAL }
		| { $EXIF_DATETIMEORIGINAL }
		| { $EXIF_EXPOSURETIME }s
		| { $EXIF_ISOSPEEDRATINGS }iso
		| { $EXIF_FOCALLENGTH }
		| { $EXIF_APERTUREVALUE }
</div>
<table>
	<tr>
		<td>
			<div class="img-shadow">
				<div class="img-white">
					<div class="img-border">
          <img src="{ $SRC }" alt="* Image { $NUMBER }" />
              { $PICTUREINFO }
					</div>
				</div>
			</div>
		</td>
	</tr>
</table>
<div class="clr" />
<div class="img-options">
[ Size: { $SIZES } | Slideshow: { $SLIDESHOW } ]
</div>

<div class="aginfo">
		  <a href="http://apachegallery.dk/">Apache::Gallery</a> &copy; 2001-2008 Michael Legart, <a href="http://www.hestdesign.com/">Hest Design</a>!
</div>
