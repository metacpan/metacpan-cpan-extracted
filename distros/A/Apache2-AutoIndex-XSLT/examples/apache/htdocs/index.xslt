<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
	<xsl:output encoding="iso-8859-1" method="html" indent="yes" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"/>
	<xsl:variable name="mycomputer_root" select="'true'"/>
	<xsl:variable name="sortorder_href">
		<xsl:choose>
			<xsl:when test="/index/options/option[@name='O']/@value = 'D'"><xsl:text>A</xsl:text></xsl:when>
			<xsl:otherwise><xsl:text>D</xsl:text></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="sortorder">
		<xsl:choose>
			<xsl:when test="/index/options/option[@name='O']/@value = 'D'"><xsl:text>descending</xsl:text></xsl:when>
			<xsl:otherwise><xsl:text>ascending</xsl:text></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="sortnode">
		<xsl:choose>
			<xsl:when test="/index/options/option[@name='C']/@value = 'S'"><xsl:text>size</xsl:text></xsl:when>
			<xsl:when test="/index/options/option[@name='C']/@value = 'D'"><xsl:text>desc</xsl:text></xsl:when>
			<xsl:when test="/index/options/option[@name='C']/@value = 'M'"><xsl:text>mtime</xsl:text></xsl:when>
			<xsl:otherwise><xsl:text>title</xsl:text></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:template match="/">
		<html xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" xsl:version="2.0">
			<head>
				<title>
					<xsl:choose>
						<xsl:when test="/index/@path='/'">My Computer</xsl:when>
						<xsl:when test="/index/@path='/Logitech Webcam/'">My Computer: [Logitech Webcam]</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="substring(/index/@path,2)"/>
						</xsl:otherwise>
					</xsl:choose>
				</title>
				<meta name="robots" content="noarchive,nosnippet"/>
				<meta name="googlebot" content="noarchive,nosnippet"/>
				<meta name="author" content="Nicola Worthington, nicolaw@cpan.org"/>
				<link rel="icon" href="/favicon.ico" type="image/x-icon"/>
				<link rel="shortcut icon" href="/favicon.ico" type="image/x-icon"/>
				<base>
					<xsl:attribute name="href"><xsl:value-of select="/index/@href"/></xsl:attribute>
				</base>
				<script type="text/javascript">
			// <![CDATA[
			function toggle(element) {
				if (element.style.display == 'none') {
					element.style.display = 'block';
				} else {
					element.style.display = 'none';
				}
			}
			// ]]></script>
				<style type="text/css">
			// <![CDATA[
			body {
				background-color: #ffffff;
				margin: 0px 0px 0px 0px;
			}
			table.dhIndex {
				font-family: Tahoma, sans-serif;
				font-size: 8pt;
				white-space: nowrap;
				height: 100%;
			}
			table.dhIndex th {
				white-space: nowrap;
			}
			table.dhIndex td {
				white-space: nowrap;
				background: #ffffff;
				padding-left: 4px;
				padding-right: 4px;
				padding-bottom: 1px;
			}
			table.dhIndex td, table.dhIndex div.inUp, table.dhIndex div.inDown {
				font-weight: normal;
				font-family: Tahoma, sans-serif;
				font-size: 8pt;
				text-align: left;
			}
			table.dhIndex td.filecol {
				background: #F7F7F7;
			}
			table.dhIndex th.sizecol, table.dhIndex td.sizecol {
				text-align: right;
			}
			table.dhIndex img {
				margin-right: 2px;
				vertical-align: bottom;
				border: 0px;
				width: 16px;
				height: 16px;
			}
			table.dhIndex a {
				position: relative;
			}
			table.dhIndex tbody a span, table.dhIndex tbody a div {
				display: none;
			}
			table.dhIndex a, table.dhIndex a:visited {
				color: #000000;
				text-decoration: none;
				white-space: nowrap;
			}
			table.dhIndex td a:hover {
				text-decoration: underline;
			}
			table.dhIndex tbody td a:hover span {
				background: #ffffe1;
				border: 1px #000000 solid;
				padding: 7px 7px 7px 7px;
				position: absolute;
				top: 7px;
				left: 30px;
				width: 210px;
				filter:alpha(opacity=50);
				display: block;
				z-index: 1;
				-moz-opacity:0.5;
				opacity: 0.5;
			}
			table.dhIndex tbody td a:hover div {
				background: #ffffe1;
				border: 1px #000000 solid;
				padding: 7px 7px 7px 7px;
				position: absolute;
				top: 7px;
				left: 30px;
				display: block;
				z-index: 1;
			}
			table.dhIndex img.denied {
				filter:alpha(opacity=50);
				-moz-opacity:0.5;
				opacity: 0.5;
			}
			table.dhIndex div.outDown {
				height: 15px;
				border: 1px #848284 solid;
			}
			table.dhIndex div.inDown {
				height: 13px;
				padding-left: 4px;
				padding-right: 4px;
				color: #000000;
				background: #D6D3CE;
				border: 1px #D6D3CE solid; 
			}
			table.dhIndex div.outUp {
				height: 15px;
				border-bottom: 1px #424142 solid;
				border-right: 1px #424142 solid;
				border-left: 1px #ffffff solid;
				border-top: 1px #ffffff solid;
			}
			table.dhIndex div.inUp {
				height: 13px;
				padding-left: 4px;
				padding-right: 4px;
				color: #000000;
				background: #D6D3CE;
				border-bottom: 1px #848284 solid;
				border-right: 1px #848284 solid;
				border-left: 1px #D6D3CE solid;
				border-top: 1px #D6D3CE solid; 
			}
			// ]]></style>
			</head>
			<body style="margin: 0px 0px 0px 0px;">
				<table cellspacing="0" cellpadding="0" border="0" width="100%" height="100%" class="dhIndex" id="unique_id" summary="Directory listing">
					<thead>
						<tr>
							<xsl:choose>
								<xsl:when test="$mycomputer_root = 'true' and /index/@path = '/'">
									<th scope="col" width="180" abbr="Name">
										<a href="?C=N;O=A">
											<div class="outUp">
												<div class="inUp">Name</div>
											</div>
										</a>
									</th>
									<th scope="col" width="150" abbr="Type">
										<a href="?C=D;O=A">
											<div class="outUp">
												<div class="inUp">Type</div>
											</div>
										</a>
									</th>
									<th scope="col" width="100" abbr="Free Space">
										<a href="?C=S;O=A">
											<div class="outUp">
												<div class="inUp" style="text-align: right;">Free Space</div>
											</div>
										</a>
									</th>
									<th scope="col" width="100" abbr="Total Size">
										<a href="?C=S;O=A">
											<div class="outUp">
												<div class="inUp" style="text-align: right;">Total Size</div>
											</div>
										</a>
									</th>
									<th scope="col" width="120" abbr="Comments">
										<a href="?C=C;O=A">
											<div class="outUp">
												<div class="inUp">Comments</div>
											</div>
										</a>
									</th>
									<th scope="col">
										<div class="outUp">
											<div class="inUp"/>
										</div>
									</th>
								</xsl:when>
								<xsl:otherwise>
									<th scope="col" width="200" abbr="Name">
										<a href="?C=N;O=A">
											<div class="outUp">
												<div class="inUp">Name</div>
											</div>
										</a>
									</th>
									<th scope="col" width="80" abbr="Size">
										<a href="?C=S;O=A">
											<div class="outUp">
												<div class="inUp" style="text-align: right;">Size</div>
											</div>
										</a>
									</th>
									<th scope="col" width="150" abbr="Type">
										<a href="?C=D;O=A">
											<div class="outUp">
												<div class="inUp">Type</div>
											</div>
										</a>
									</th>
									<th scope="col" width="150" abbr="Date Modified">
										<a href="?C=M;O=A">
											<div class="outUp">
												<div class="inUp">Date Modified</div>
											</div>
										</a>
									</th>
									<th scope="col">
										<div class="outUp">
											<div class="inUp"/>
										</div>
									</th>
								</xsl:otherwise>
							</xsl:choose>
						</tr>
					</thead>
					<tbody>
						<xsl:if test="$mycomputer_root != 'true' or /index/@path != '/'">
							<xsl:for-each select="/index/updir">
								<tr>
									<td class="filecol">
										<a href="../">
											<img width="16" height="16" alt="..">
												<xsl:attribute name="src"><xsl:value-of select="@icon"/></xsl:attribute>
											</img>
										</a>
										<a href="../" onmouseover="window.status='Type: Directory'; return true" onmouseout="window.status='';return true">..<span>Type: Directory</span>
										</a>
									</td>
									<td class="sizecol"/>
									<td>File Folder</td>
									<td/>
									<td/>
								</tr>
							</xsl:for-each>
						</xsl:if>
						<xsl:apply-templates select="/index/dir">
							<xsl:sort select="./attribute::*[name()=$sortnode]" order="{$sortorder}"/>
						</xsl:apply-templates>
						<xsl:if test="$mycomputer_root != 'true' or /index/@path != '/'">
							<xsl:apply-templates select="/index/file">
								<xsl:sort select="./attribute::*[name()=$sortnode]" order="{$sortorder}"/>
							</xsl:apply-templates>
						</xsl:if>
						<!--
				<tr>
					<td height="100%" style="100%;" class="filecol"></td>
					<td class="sizecol"></td>
					<td></td>
					<td></td>
					<td></td>
				</tr>
-->
					</tbody>
				</table>
			</body>
		</html>
	</xsl:template>
	<xsl:template match="dir">
		<xsl:choose>
			<xsl:when test="$mycomputer_root = 'true' and /index/@path = '/'">
				<xsl:variable name="title">
					<xsl:choose>
						<xsl:when test="@title = 'A:'">
							<xsl:text>3&#189; Floppy (A:)</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'C:'">
							<xsl:text>IBM_PRELOAD (C:)</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'D:'">
							<xsl:text>Data (D:)</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'E:'">
							<xsl:text>MSOFFICE11 (E:)</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'H:'">
							<xsl:text>nworthin on 'Anatar' (H:)</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'J:'">
							<xsl:text>XXX on 'Anatar' (J:)</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="@title"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="icon">
					<xsl:choose>
						<xsl:when test="@title = 'A:' or @title = 'B:'">
							<xsl:text>/icons/__floppy_disk_drive.png</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'C:' or @title = 'D:'">
							<xsl:text>/icons/__hard_disk_drive.png</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'E:'">
							<xsl:text>/icons/__dvd_drive.png</xsl:text>
						</xsl:when>
						<xsl:when test="string-length(@title) = 2 and substring(@title,2,1) = ':'">
							<xsl:text>/icons/__network_drive.png</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'Logitech Webcam'">
							<xsl:text>/icons/__webcam.png</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="@icon"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="desc">
					<xsl:choose>
						<xsl:when test="@title = 'A:' or @title = 'B:'">
							<xsl:text>3 1/2-Inch Floppy Disk</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'C:' or @title = 'D:'">
							<xsl:text>Local Disk</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'E:'">
							<xsl:text>DVD-RW Drive</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'Logitech Webcam'">
							<xsl:text>Camera</xsl:text>
						</xsl:when>
						<xsl:when test="string-length(@title) = 2 and substring(@title,2,1) = ':'">
							<xsl:text>Network Drive</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="@desc"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="nicesize">
					<xsl:choose>
						<xsl:when test="@title = 'C:'">
							<xsl:text>39.2 GB</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'D:'">
							<xsl:text>142 GB</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'E:'">
							<xsl:text>401 MB</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'H:'">
							<xsl:text>1.36 TB</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'J:'">
							<xsl:text>1.36 TB</xsl:text>
						</xsl:when>
						<xsl:otherwise/>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="nicefree">
					<xsl:choose>
						<xsl:when test="@title = 'C:'">
							<xsl:text>8.65 GB</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'D:'">
							<xsl:text>38.2 GB</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'E:'">
							<xsl:text>0 B</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'H:'">
							<xsl:text>448 GB</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'J:'">
							<xsl:text>448 GB</xsl:text>
						</xsl:when>
						<xsl:otherwise/>
					</xsl:choose>
				</xsl:variable>
				<tr>
					<td class="filecol">
						<a>
							<xsl:attribute name="href"><xsl:value-of select="@href"/></xsl:attribute>
							<img width="16" height="16">
								<xsl:attribute name="src"><xsl:value-of select="$icon"/></xsl:attribute>
								<xsl:attribute name="alt">[<xsl:value-of select="@ext"/>]</xsl:attribute>
							</img>
						</a>
						<a onmouseout="window.status='';return true">
							<xsl:attribute name="href"><xsl:value-of select="@href"/></xsl:attribute>
							<xsl:attribute name="onmouseover">window.status='Free Space: <xsl:value-of select="$nicefree"/> Total Size: <xsl:value-of select="$nicesize"/>'; return true</xsl:attribute>
							<xsl:value-of select="$title"/>
							<span>Free Space: <xsl:value-of select="$nicefree"/>
								<br/>Total Size: <xsl:value-of select="$nicesize"/>
							</span>
						</a>
					</td>
					<td>
						<xsl:value-of select="$desc"/>
					</td>
					<td class="sizecol">
						<xsl:value-of select="$nicefree"/>
					</td>
					<td class="sizecol">
						<xsl:value-of select="$nicesize"/>
					</td>
					<td/>
					<td/>
				</tr>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="title">
					<xsl:choose>
						<xsl:when test="@title = 'recyclebin' or @title = 'RecycleBin'">
							<xsl:text>Recycle Bin</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'documents' or @title = 'Documents' or @title = 'MyDocuments'">
							<xsl:text>My Documents</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'pictures' or @title = 'Pictures' or @title = 'MyPictures'">
							<xsl:text>My Pictures</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'videos' or @title = 'Videos' or @title = 'MyVideos'">
							<xsl:text>My Videos</xsl:text>
						</xsl:when>
						<xsl:when test="@title = 'music' or @title = 'Music' or @title = 'MyMusic'">
							<xsl:text>My Music</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="@title"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="icon">
					<xsl:choose>
						<xsl:when test="$title = 'Recycle Bin'">
							<xsl:text>/icons/__recycle_bin.png</xsl:text>
						</xsl:when>
						<xsl:when test="$title = 'My Documents'">
							<xsl:text>/icons/__my_documents.png</xsl:text>
						</xsl:when>
						<xsl:when test="$title = 'My Pictures'">
							<xsl:text>/icons/__my_pictures.png</xsl:text>
						</xsl:when>
						<xsl:when test="$title = 'My Videos'">
							<xsl:text>/icons/__my_videos.png</xsl:text>
						</xsl:when>
						<xsl:when test="$title = 'My Music'">
							<xsl:text>/icons/__my_music.png</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="@icon"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<tr>
					<td class="filecol">
						<a>
							<xsl:attribute name="href"><xsl:value-of select="@href"/></xsl:attribute>
							<img width="16" height="16">
								<xsl:attribute name="src"><xsl:value-of select="$icon"/></xsl:attribute>
								<xsl:attribute name="alt">[<xsl:value-of select="@ext"/>]</xsl:attribute>
							</img>
						</a>
						<a onmouseout="window.status='';return true">
							<xsl:attribute name="href"><xsl:value-of select="@href"/></xsl:attribute>
							<xsl:attribute name="onmouseover">window.status='Type: <xsl:value-of select="@desc"/> Date Modified: <xsl:value-of select="@nicemtime"/> Size: <xsl:value-of select="@nicesize"/>'; return true</xsl:attribute>
							<xsl:value-of select="$title"/>
							<span>Type: <xsl:value-of select="@desc"/>
								<br/>Date Modified: <xsl:value-of select="@nicemtime"/>
								<br/>Size: <xsl:value-of select="@nicesize"/>
							</span>
						</a>
					</td>
					<td class="sizecol"></td>
					<td>
						<xsl:value-of select="@desc"/>
					</td>
					<td>
						<xsl:value-of select="@nicemtime"/>
					</td>
					<td/>
				</tr>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="file">
		<tr>
			<td class="filecol">
				<a>
					<xsl:attribute name="href"><xsl:value-of select="@href"/></xsl:attribute>
					<img width="16" height="16">
						<xsl:attribute name="src"><xsl:value-of select="@icon"/></xsl:attribute>
						<xsl:attribute name="alt">[<xsl:value-of select="@ext"/>]</xsl:attribute>
					</img>
				</a>
				<a onmouseout="window.status='';return true">
					<xsl:attribute name="href"><xsl:value-of select="@href"/></xsl:attribute>
					<xsl:attribute name="onmouseover">window.status='Type: <xsl:value-of select="@desc"/> Size: <xsl:value-of select="@nicesize"/>'; return true</xsl:attribute>
					<xsl:value-of select="@title"/>
					<div>Type: <xsl:value-of select="@desc"/>
						<br/>Size: <xsl:value-of select="@nicesize"/>
					</div>
				</a>
			</td>
			<td class="sizecol">
				<xsl:value-of select="@nicesize"/>
			</td>
			<td>
				<xsl:value-of select="@desc"/>
			</td>
			<td>
				<xsl:value-of select="@nicemtime"/>
			</td>
			<td/>
		</tr>
	</xsl:template>
</xsl:stylesheet>
