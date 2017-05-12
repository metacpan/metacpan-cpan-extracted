<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<HTML>
	<HEAD>
		<title>V: ECHOnline Decline and Error Responses</title>
		<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
		<style> <!-- a:hover{color:#0080FF}
	--></style>
	</HEAD>
	<body bgcolor="#ffffff">
		
<table border="0" width="100%">
    <tr>
      <td rowspan=2 valign=center align=middle height="48" width="50">
      
	  
				<a href="/"><img src="/images/ECHOBall3.jpg" border=0 alt="ECHO Merchant Center"></a>
      
	  </td>
      
      <td align="left" valign="bottom">
		<b><font size=+1>Interface Specification</b></font>
	  </td>
	  
      <td align="right" valign="bottom">
		<font size="-1"><font face="Arial,Verdana,Helvetica"><b><i><font size=+2>ECHOnline </i></b></font></font>
        
        
        <br><b>Document revision date 05/24/2004</b></font>
     </td>
   </tr>
</table>
 
<hr size="3" color="#000080">
		<a href="/ISPGuide-Menu.asp">Return to the <font face="Verdana,Arial,Helvetica" size="-1">
				<b><i>ECHO</b></I></font> <b>Internet Development Tools</b> home page.</a>
		<h1>Part V: Decline and Error Responses</h1>
		<p>
			This document describes the content of an ECHOTYPE1 response containing a 
			decline or error response received from the <font face="Verdana,Arial,Helvetica" size="-1">
				<b><i>ECHO</i></b></font> host computers. For a general description of <b><i><font face="Verdana,Arial,Helvetica" size="-1">
						ECHO<font size="-2">NLINE</font></font></i></b> responses see <a href="ISPGuide-Interface.asp#Responses">
				Response Protocol</a>
		in Part I of this Specification.
		<p>
			Host responses differ depending on the transaction code and whether or not an 
			error or decline was detected by the host. For a description of acknowledgement 
			and approval responses see <a href="ISPGuide-Response.asp"><b>Part IV: <i><font face="Verdana,Arial,Helvetica" size="-1">
							ECHO<font size="-2">NLINE</font></font></i> Host Responses</b></a>
		.
		<p>
			Credit card transactions and electronic check transactions differ slightly in 
			their format. For this reason they are treated separately in the sections 
			below. In the examples, the "·" character is used to indicate a space 
			character.
			<h2>Credit Card Transactions</h2>
		Decline and error responses are very similar in that they both represent 
		situations that prevent a transaction from being authorized. Decline codes can 
		actually represent a system error, and error codes can actually represent an 
		account restriction. The difference between the two is more of a historical 
		artifact than any distinction between an "error" and a "decline."
		<p>
			Decline responses are always preceded by the word "DECLINED," while error 
			responses contain various text messages from <b><i><font face="Verdana,Arial,Helvetica" size="-1">
						ECHO</font></i></b>'s host computer or the issuer's computers. 
			Decline and error responses are described below.
			<h3>Message Formats</h3>
		<p>
		Decline responses are formatted as follows.
		<p>
			<center>
				<table border="1" cellpadding="3" cellspacing="0" width="80%">
					<tr bgcolor="#e0e0e0">
						<td valign="top"><b>Field</b></td>
						<td valign="top"><b>Size</b></td>
						<td valign="top"><b>Description</b></td>
					</tr>
					<tr>
						<td valign="top">tag</td>
						<td valign="top">11</td>
						<td valign="top">"&lt;ECHOTYPE1&gt;"</td>
					</tr>
					<tr>
						<td valign="top">decline</td>
						<td valign="top">9</td>
						<td valign="top">"DECLINED "</td>
					</tr>
					<tr>
						<td valign="top">decline code
						</td>
						<td valign="top">2</td>
						<td valign="top">See Decline Codes table below</td>
					</tr>
					<tr>
						<td valign="top">filler</td>
						<td valign="top">1</td>
						<td valign="top">" " (space)</td>
					</tr>
					<tr>
						<td valign="top">amount</td>
						<td valign="top">20</td>
						<td valign="top">Declined transaction amount. <em><b>Note</b></em>: This field is 
							right-justified with leading zeroes suppressed. Depending on the type of 
							decline, there may or may not be a "$" character in the leftmost position of 
							this field. Examples: "$bbbbbbbbbbbbbbb2.99" and "bbbbbbbbbbbbbbbb2.99"</td>
					</tr>
					<tr>
						<td valign="top">tag</td>
						<td valign="top">12</td>
						<td valign="top">"&lt;/ECHOTYPE1&gt;"</td>
					</tr>
				</table>
			</center>
		<p>
		Error responses are formatted as follows.
		<p>
			<center>
				<table border="1" cellpadding="3" cellspacing="0" width="80%">
					<tr bgcolor="#e0e0e0">
						<td valign="top"><b>Field</b></td>
						<td valign="top"><b>Size</b></td>
						<td valign="top"><b>Description</b></td>
					</tr>
					<tr>
						<td valign="top">tag</td>
						<td valign="top">11</td>
						<td valign="top">"&lt;ECHOTYPE1&gt;"</td>
					</tr>
					<tr>
						<td valign="top">error text</td>
						<td valign="top">20</td>
						<td valign="top">error description</td>
					</tr>
					<tr>
						<td valign="top">error code</td>
						<td valign="top">4</td>
						<td valign="top">See Error Codes table below</td>
					</tr>
					<tr>
						<td valign="top">tag</td>
						<td valign="top">12</td>
						<td valign="top">"&lt;/ECHOTYPE1&gt;"</td>
					</tr>
				</table>
			</center>
			<h3>Decline Codes</h3>
		<p>Decline codes are defined in the following table.</p>
		<center>
			<table border="1" cellpadding="3" cellspacing="0" width="80%">
				<tr bgcolor="#e0e0e0">
					<td valign="top"><b>Decline<br>
							Code</b></td>
					<td valign="top" width="259"><b>Short<br>
							Description</b></td>
					<td valign="top"><b><br>
							Explanation</b></td>
				</tr>
				<tr>
					<td valign="top">01</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Refer 
								to card issuer</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								merchant must call the issuer before the transaction can be approved.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">02</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Refer 
								to card issuer, special condition</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								merchant must call the issuer before the transaction can be approved.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">03</td>
					<td valign="top" width="259">Invalid merchant number</td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								merchant ID is not valid.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">04</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Pick-up 
								card. Capture for reward</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								card is listed on the Warning Bulletin.<SPAN style="mso-spacerun: yes">&nbsp; </SPAN>Merchant 
								may receive reward money by capturing the card.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">05</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Do 
								not honor. The transaction was declined by the issuer without definition or 
								reason</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
									transaction was declined without explanation by the card issuer.</FONT></SPAN>
						</SPAN></td>
				</tr>
				<TR>
					<TD vAlign="top">06</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Error</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								card issuer returned an error without further explanation.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">07</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Pick-up 
								card, special condition</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								card is listed on the Warning Bulletin.<SPAN style="mso-spacerun: yes">&nbsp; </SPAN>Merchant 
								may receive reward money by capturing the card.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">08</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Honor 
								with identification</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Honor 
								with identification.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">09</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Request 
								in progress</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Request 
								in progress.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">10</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Approved 
								for partial amount</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Approved 
								for partial amount.</FONT></SPAN></TD>
				</TR>
				<tr>
					<td valign="top">
						11</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Approved, 
								VIP</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Approved, 
											VIP program.</FONT></SPAN>
								</SPAN></FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">12</td>
					<td valign="top" width="259">Invalid transaction</td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								requested transaction is not supported or is not valid for the card number 
								presented.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">13</td>
					<td valign="top" width="259">Invalid amount</td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								amount exceeds the limits established by the issuer for this type of 
								transaction.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">14</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Invalid 
								card #</FONT></SPAN></td>
					<td valign="top">The issuer indicates that this card is not valid.</td>
				</tr>
				<tr>
					<td valign="top">15</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">No 
								such issuer</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								card issuer number is not valid.</FONT></SPAN></td>
				</tr>
				<TR>
					<TD vAlign="top">16</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Approved, 
								update track 3</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Approved, 
								update track 3.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">17</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Customer 
								cancellation</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Customer 
								cancellation.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">18</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Customer 
								dispute</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Customer 
								dispute.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">19</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Re 
								enter transaction</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Customer 
								should resubmit transaction.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">20</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Invalid 
								response</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Invalid 
								response.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">21</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">No 
								action taken</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">No 
								action taken. The issuer declined with no other explanation.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">22</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Suspected 
								malfunction</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Suspected 
								malfunction.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">23</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Unacceptable 
								transaction fee</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Unacceptable 
								transaction fee.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">24</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">File 
								update not supported</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">File 
								update not supported.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">25</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Unable 
								to locate record</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Unable 
								to locate record.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">26</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Duplicate 
								record</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Duplicate 
								record.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">27</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">File 
								update edit error</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">File 
								update edit error.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">28</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">File 
								update file locked</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">File 
								update file locked.</FONT></SPAN></TD>
				</TR>
				<tr>
					<td valign="top">
						29</td>
					<td valign="top" width="259">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<tr>
					<td valign="top">30</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Format 
								error, call ECHO</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								host reported that the transaction was not formatted properly.</FONT></SPAN></td>
				</tr>
				<TR>
					<TD vAlign="top">31</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Bank 
								not supported</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Bank 
								not supported by switch.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">32</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Completed 
								partially</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Completed 
								partially.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">33</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Expired 
								card, pick-up</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								card is expired.<SPAN style="mso-spacerun: yes">&nbsp; </SPAN>Merchant may 
								receive reward money by capturing the card.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">34</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Issuer 
								suspects fraud, pick-up card</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								card issuer suspects fraud.<SPAN style="mso-spacerun: yes">&nbsp; </SPAN>Merchant 
								may receive reward money by capturing the card.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">35</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Contact 
								acquirer, pick-up</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Contact 
								card issuer.<SPAN style="mso-spacerun: yes">&nbsp; </SPAN>Merchant may receive 
								reward money by capturing the card.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">36</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Restricted 
								card, pick-up</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								card is restricted by the issuer.<SPAN style="mso-spacerun: yes">&nbsp; </SPAN>Merchant 
								may receive reward money by capturing the card.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">37</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Call 
								ECHO security, pick-up</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Contact 
								ECHO security.<SPAN style="mso-spacerun: yes">&nbsp; </SPAN>Merchant may 
								receive reward money by capturing the card.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">38</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">PIN 
								tries exceeded, pick-up</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">PIN 
								attempts exceed issuer limits.<SPAN style="mso-spacerun: yes">&nbsp; </SPAN>Merchant 
								may receive reward money by capturing the card.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">39</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">No 
								credit account</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">No 
								credit account.</FONT></SPAN></TD>
				</TR>
				<tr>
					<td valign="top">
						40</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Function 
								not supported</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Requested 
								function not supported.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">41</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Lost 
								Card, capture for reward</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								card has been reported lost.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">42</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">No 
								universal account</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">No 
								universal account.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">43</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Stolen 
								Card, capture for reward</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								card has been reported stolen.</FONT></SPAN></td>
				</tr>
				<TR>
					<TD vAlign="top">44</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">No 
								investment account</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">No 
								investment account.</FONT></SPAN></TD>
				</TR>
				<tr>
					<td valign="top">45 - 50</td>
					<td valign="top" width="259">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<tr>
					<td valign="top">51</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Not 
								sufficient funds</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								credit limit for this account has been exceeded.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">52 - 53</td>
					<td valign="top" width="259">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<tr>
					<td valign="top">54</td>
					<td valign="top" width="259">Expired card</td>
					<td valign="top">The card is expired.</td>
				</tr>
				<tr>
					<td valign="top">55</td>
					<td valign="top" width="259">Incorrect PIN</td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								cardholder PIN is incorrect.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">56</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">No 
								card record</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">No 
								card record.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">57</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Transaction 
								not permitted to cardholder</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								card is not allowed the type of transaction requested.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">58</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Transaction 
								not permitted on terminal</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								Merchant is not allowed this type of transaction.</FONT></SPAN></td>
				</tr>
				<TR>
					<TD vAlign="top">59</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Suspected 
								fraud</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Suspected 
								fraud.</FONT></SPAN></TD>
				</TR>
				<tr>
					<td valign="top">
						60</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Contact 
								ECHO</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Contact 
								ECHO.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">61</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Exceeds 
								withdrawal limit</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								amount exceeds the allowed daily maximum.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">62</td>
					<td valign="top" width="259">Restricted card</td>
					<td valign="top">The card has been restricted.</td>
				</tr>
				<tr>
					<td valign="top">63</td>
					<td valign="top" width="259">Security violation.</td>
					<td valign="top">The card has been restricted.</td>
				</tr>
				<tr>
					<td valign="top">64</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Original 
								amount incorrect</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Original 
								amount incorrect.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">65</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Exceeds 
								withdrawal frequency</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								allowable number of daily transactions has been exceeded.</FONT></SPAN></td>
				</tr>
				<TR>
					<TD vAlign="top">66</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Call 
								acquirer security, call ECHO</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Call 
								acquirer security, call ECHO.</FONT></SPAN></TD>
				</TR>
				<tr>
					<td valign="top">
						67</td>
					<td valign="top" width="259">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<TR>
					<TD vAlign="top">68</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Response 
								received too late</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Response 
								received too late.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">69 - 74</TD>
					<TD vAlign="top" width="259">not used</TD>
					<TD vAlign="top">&nbsp;</TD>
				</TR>
				<tr>
					<td valign="top">75</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">PIN 
								tries exceeded</FONT></SPAN></td>
					<td valign="top">The allowed number of PIN retries has been exceeded.</td>
				</tr>
				<tr>
					<td valign="top">76</td>
					<td valign="top" width="259">Invalid "to" account</td>
					<td valign="top">The debit account does not exist.</td>
				</tr>
				<tr>
					<td valign="top">77</td>
					<td valign="top" width="259">Invalid "from" account</td>
					<td valign="top">The credit account does not exist.</td>
				</tr>
				<tr>
					<td valign="top">78</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Invalid 
								account specified (general)</FONT></SPAN></td>
					<td valign="top">
						The associated card number account is invalid or does not exist.</td>
				</tr>
				<TR>
					<TD vAlign="top">79</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Already 
								reversed</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Already 
								reversed.</FONT></SPAN></TD>
				</TR>
				<tr>
					<td valign="top">80&nbsp;- 83</td>
					<td valign="top" width="259">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<tr>
					<td valign="top">84</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Invalid 
								authorization life cycle</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">The 
								authorization life cycle is invalid.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">85&nbsp;</td>
					<td valign="top" width="259">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<TR>
					<TD vAlign="top">86</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Cannot 
								verify PIN</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Cannot 
								verify PIN.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">87</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Network 
								Unavailable</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Network 
								Unavailable.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">88</TD>
					<TD vAlign="top" width="259">not used</TD>
					<TD vAlign="top">&nbsp;</TD>
				</TR>
				<TR>
					<TD vAlign="top">89</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Ineligible 
								to receive financial position information</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Ineligible 
								to receive financial position information.</FONT></SPAN></TD>
				</TR>
				<TR>
					<TD vAlign="top">90</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Cut-off 
								in progress</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Cut-off 
								in progress.</FONT></SPAN></TD>
				</TR>
				<tr>
					<td valign="top">91</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Issuer 
								or switch inoperative</FONT></SPAN></td>
					<td valign="top">The bank is not available to authorize this transaction.</td>
				</tr>
				<tr>
					<td valign="top">92</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Routing 
								error</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT size="3"><FONT face="Times New Roman">The 
									transaction cannot be routed to the authorizing agency.</FONT></FONT>
						</SPAN></td>
				</tr>
				<tr>
					<td valign="top">93</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Violation 
								of law</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Violation 
								of law.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">94</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Duplicate 
								transaction</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Duplicate 
								transaction.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">95</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Reconcile 
								error</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Reconcile 
								error.</FONT></SPAN></td>
				</tr>
				<tr>
					<td valign="top">96</td>
					<td valign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">System 
								malfunction</FONT></SPAN></td>
					<td valign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">A 
								system error has occurred.</FONT></SPAN></td>
				</tr>
				<TR>
					<TD vAlign="top">97</TD>
					<TD vAlign="top" width="259">not used</TD>
					<TD vAlign="top">&nbsp;</TD>
				</TR>
				<TR>
					<TD vAlign="top">98</TD>
					<TD vAlign="top" width="259"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Exceeds 
								cash limit</FONT></SPAN></TD>
					<TD vAlign="top"><SPAN style="FONT-SIZE: 10pt; FONT-FAMILY: Arial; mso-fareast-font-family: 'Times New Roman'; mso-bidi-font-family: 'Times New Roman'; mso-ansi-language: EN-US; mso-fareast-language: EN-US; mso-bidi-language: AR-SA"><FONT face="Times New Roman" size="3">Exceeds 
								cash limit.</FONT></SPAN></TD>
				</TR>
			</table>
		</center>
		<p>
			Error codes are defined in the following table.</p>
		<center>
			<table border="1" cellpadding="3" cellspacing="0" width="80%">
				<tr bgcolor="#e0e0e0">
					<td valign="top"><b>Error<br>
							Code</b></td>
					<td valign="top"><b>Short<br>
							Description</b></td>
					<td valign="top"><b><br>
							Explanation</b></td>
				</tr>
				<tr>
					<td valign="top">1000</td>
					<td valign="top">Unrecoverable error.</td>
					<td valign="top">An unrecoverable error has occurred in the <b><i><font face="Verdana,Arial,Helvetica" size="-1">
									ECHO<font size="-2">NLINE</font></font></i></b> processing.</td>
				</tr>
				<tr>
					<td valign="top">1001</td>
					<td valign="top">Account closed</td>
					<td valign="top">The merchant account has been closed.</td>
				</tr>
				<tr>
					<td valign="top">1002</td>
					<td valign="top">System closed</td>
					<td valign="top">
						Services for this system are not available.<br>
						(Not used by <b><i><font face="Verdana,Arial,Helvetica" size="-1">ECHO<font size="-2">NLINE</font></font></i></b>)
					</td>
				</tr>
				<tr>
					<td valign="top">1003</td>
					<td valign="top">E-Mail Down</td>
					<td valign="top">The e-mail function is not available.<br>
						(Not used by <b><i><font face="Verdana,Arial,Helvetica" size="-1">ECHO<font size="-2">NLINE</font></font></i></b>)
					</td>
				</tr>
				<tr>
					<td valign="top">1004-1011</td>
					<td valign="top">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<tr>
					<td valign="top">1012</td>
					<td valign="top">Invalid trans code</td>
					<td valign="top">The host computer received an invalid transaction code.</td>
				</tr>
				<tr>
					<td valign="top">1013</td>
					<td valign="top">Invalid term id</td>
					<td valign="top">The ECHO-ID is invalid.</td>
				</tr>
				<tr>
					<td valign="top">1014</td>
					<td valign="top">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<tr>
					<td valign="top">1015</td>
					<td valign="top">Invalid card number</td>
					<td valign="top">The credit card number that was sent to the host computer was 
						invalid</td>
				</tr>
				<tr>
					<td valign="top">1016</td>
					<td valign="top">Invalid expiry date</td>
					<td valign="top">The card has expired or the expiration date was invalid.</td>
				</tr>
				<tr>
					<td valign="top">1017</td>
					<td valign="top">Invalid amount</td>
					<td valign="top">The dollar amount was less than 1.00 or greater than the maximum 
						allowed for this card.</td>
				</tr>
				<tr>
					<td valign="top">1018</td>
					<td valign="top">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<tr>
					<td valign="top">1019</td>
					<td valign="top">Invalid state</td>
					<td valign="top">The state code was invalid.<br>
						(Not used by <b><i><font face="Verdana,Arial,Helvetica" size="-1">ECHO<font size="-2">NLINE</font></font></i></b>)
					</td>
				</tr>
				<tr>
					<td valign="top">1020</td>
					<td valign="top">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<tr>
					<td valign="top">1021</td>
					<td valign="top">Invalid service</td>
					<td valign="top">The merchant or card holder is not allowed to perform that kind of 
						transaction</td>
				</tr>
				<tr>
					<td valign="top">1022-1023</td>
					<td valign="top">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<tr>
					<td valign="top">1024</td>
					<td valign="top">Invalid auth code</td>
					<td valign="top">The authorization number presented with this transaction is 
						incorrect. (deposit transactions only)</td>
				</tr>
				<tr>
					<td valign="top">1025</td>
					<td valign="top">Invalid reference number</td>
					<td valign="top">The reference number presented with this transaction is incorrect 
						or is not numeric.</td>
				</tr>
				<tr>
					<td valign="top">1026-1028</td>
					<td valign="top">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<tr>
					<td valign="top">1029</td>
					<td valign="top">Invalid contract number</td>
					<td valign="top">The contract number presented with this transaction is incorrect 
						or is not numeric.<br>
						(Not used by <b><i><font face="Verdana,Arial,Helvetica" size="-1">ECHO<font size="-2">NLINE</font></font></i></b>)
					</td>
				</tr>
				<tr>
					<td valign="top">1030</td>
					<td valign="top">Invalid inventory data</td>
					<td valign="top">The inventory data presented with this transaction is not ASCII 
						"printable".<br>
						(Not used by <b><i><font face="Verdana,Arial,Helvetica" size="-1">ECHO<font size="-2">NLINE</font></font></i></b>)
					</td>
				</tr>
				<tr>
					<td valign="top">1031-1500</td>
					<td valign="top">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<tr>
					<td colspan="3">
						<i>Error Codes 1501 through 1599 are generated by <b><i><font face="Verdana,Arial,Helvetica" size="-1">
										ECHO<font size="-2">NLINE</font></font></i></b> after validating 
							the merchant but before presenting the transaction to the host computers for 
							processing.</i>
					</td>
				</tr>
				<tr>
					<td valign="top">1501-1507</td>
					<td valign="top">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<tr>
					<td valign="top">1508</td>
					<td valign="top">&nbsp;</td>
					<td valign="top">Invalid or missing order_type.</td>
				</tr>
				<tr>
					<td valign="top">1509</td>
					<td valign="top">&nbsp;</td>
					<td valign="top">The merchant is not approved to submit this order_type.</td>
				</tr>
				<tr>
					<td valign="top">1510</td>
					<td valign="top">&nbsp;</td>
					<td valign="top">The merchant is not approved to submit this transaction_type.</td>
				</tr>
				<tr>
					<td valign="top">1511</td>
					<td valign="top">&nbsp;</td>
					<td valign="top">
						Duplicate transaction attempt (see <a href="ISPGuide-Interface.asp#counter">counter</a>
						in Part I of this Specification</EM>).
					</td>
				</tr>
				<tr>
					<td valign="top">1512-1598</td>
					<td valign="top">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<tr>
					<td valign="top">1599</td>
					<td valign="top">&nbsp;</td>
					<td valign="top">An system error occurred while validating the transaction input.</td>
				</tr>
				<tr>
					<td valign="top">1600-1800</td>
					<td valign="top">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<tr>
					<td colspan="3">
						<i>Error Codes 1801 through 1814 are generated by <b><i><font face="Verdana,Arial,Helvetica" size="-1">
										ECHO<font size="-2">NLINE</font></font></i></b> to indicate 
							responses to <a href="ISPGuide-Response.asp#AVSOnly">AVS-Only transactions</a> when 
							the response is anything but "X" or "Y" (all digits match).</i>
					</td>
				</tr>
				<tr>
					<td>1801</td>
					<td><a href="ISPGuide-Response.asp#AVSOnly">Return Code "A"</a></td>
					<td>Address matches; ZIP does not match.</td>
				</tr>
				<tr>
					<td>1802</td>
					<td><a href="ISPGuide-Response.asp#AVSOnly">Return Code "W"</a></td>
					<td>9-digit ZIP matches; Address does not match.</td>
				</tr>
				<tr>
					<td>1803</td>
					<td><a href="ISPGuide-Response.asp#AVSOnly">Return Code "Z"</a></td>
					<td>5-digit ZIP matches; Address does not match.</td>
				</tr>
				<tr>
					<td>1804</td>
					<td><a href="ISPGuide-Response.asp#AVSOnly">Return Codes "U"</a></td>
					<td>Issuer unavailable; cannot verify.</td>
				</tr>
				<tr>
					<td>1805</td>
					<td><a href="ISPGuide-Response.asp#AVSOnly">Return Code "R"</a></td>
					<td>Retry; system is currently unable to process.</td>
				</tr>
				<tr>
					<td>1806</td>
					<td><a href="ISPGuide-Response.asp#AVSOnly">Return Code "S" or "G"</a></td>
					<td>Issuer does not support AVS.</td>
				</tr>
				<tr>
					<td>1807</td>
					<td><a href="ISPGuide-Response.asp#AVSOnly">Return Code "N"</a></td>
					<td>Nothing matches.</td>
				</tr>
				<tr>
					<td>1808</td>
					<td><a href="ISPGuide-Response.asp#AVSOnly">Return Code "E"</a></td>
					<td>Invalid AVS only response.</td>
				</tr>
				<tr>
					<td>1809</td>
					<td><a href="ISPGuide-Response.asp#AVSOnly">Return Code "B"</a></td>
					<td>Street address match. Postal code not verified because of incompatible formats.</td>
				</tr>
				<tr>
					<td>1810</td>
					<td><a href="ISPGuide-Response.asp#AVSOnly">Return Code "C"</a></td>
					<td>Street address and Postal code not verified because of incompatible formats.</td>
				</tr>
				<tr>
					<td>1811</td>
					<td><a href="ISPGuide-Response.asp#AVSOnly">Return Code "D"</a></td>
					<td>Street address match and Postal code match.</td>
				</tr>
				<tr>
					<td>1812</td>
					<td><a href="ISPGuide-Response.asp#AVSOnly">Return Code "I"</a></td>
					<td>Address information not verified for international transaction.</td>
				</tr>
				<tr>
					<td>1813</td>
					<td><a href="ISPGuide-Response.asp#AVSOnly">Return Code "M"</a></td>
					<td>Street address match and Postal code match.</td>
				</tr>
				<tr>
					<td>1814</td>
					<td><a href="ISPGuide-Response.asp#AVSOnly">Return Code "P"</a></td>
					<td>Postal code match. Street address not verified because of incompatible formats.</td>
				</tr>
				<tr>
					<td>1815-1896</td>
					<td>not used</td>
					<td>&nbsp;</td>
				</tr>
				<tr>
					<td valign="top">1897</td>
					<td valign="top">invalid response</td>
					<td valign="top">The host returned an invalid response.</td>
				</tr>
				<tr>
					<td valign="top">1898</td>
					<td valign="top">disconnect</td>
					<td valign="top">The host unexpectedly disconnected.</td>
				</tr>
				<tr>
					<td valign="top">1899</td>
					<td valign="top">timeout</td>
					<td valign="top">Timeout waiting for host response.</td>
				</tr>
				<tr>
					<td valign="top">1900-2070</td>
					<td valign="top">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<tr>
					<td valign="top">2071</td>
					<td valign="top">Call VISA</td>
					<td valign="top">An authorization number from the VISA Voice Center is required to 
						approve this transaction.</td>
				</tr>
				<tr>
					<td valign="top">2072</td>
					<td valign="top">Call Master Card</td>
					<td valign="top">An authorization number from the Master Card Voice Center is 
						required to approve this transaction.</td>
				</tr>
				<tr>
					<td valign="top">2073</td>
					<td valign="top">Call Carte Blanche</td>
					<td valign="top">An authorization number from the Carte Blanche Voice Center is 
						required to approve this transaction.</td>
				</tr>
				<tr>
					<td valign="top">2074</td>
					<td valign="top">Call Diners Club</td>
					<td valign="top">An authorization number from the Diners' Club Voice Center is 
						required to approve this transaction.</td>
				</tr>
				<tr>
					<td valign="top">2075</td>
					<td valign="top">Call AMEX</td>
					<td valign="top">An authorization number from the American Express Voice Center is 
						required to approve this transaction.</td>
				</tr>
				<tr>
					<td valign="top">2076</td>
					<td valign="top">Call Discover</td>
					<td valign="top">An authorization number from the Discover Voice Center is required 
						to approve this transaction.</td>
				</tr>
				<tr>
					<td valign="top">2077</td>
					<td valign="top">not used</td>
					<td valign="top">&nbsp;</td>
				</tr>
				<tr>
					<td valign="top">2078</td>
					<td valign="top">Call ECHO</td>
					<td valign="top">The merchant must call <b><i><font face="Verdana,Arial,Helvetica" size="-1">ECHO</font></i></b>
						Customer Support for approval.or because there is a problem with the merchant's 
						account.</td>
				</tr>
				<tr>
					<td>2079</td>
					<td>Call XpresscheX</td>
					<td>The merchant must call <b><i><font face="Verdana,Arial,Helvetica" size="-1">ECHO</font></i></b>
						Customer Support for approval.or because there is a problem with the merchant's 
						account.</td>
				</tr>
				<tr>
					<td colspan="3">
						<i>The remaining error codes are generated by the <b><i><font face="Verdana,Arial,Helvetica" size="-1">
										ECHO</font></i></b> host computers in response to errors in the 
							dial-up protocol. These messages should never appear in <b><i><font face="Verdana,Arial,Helvetica" size="-1">
										ECHO<font size="-2">NLINE</font></font></i></b>. They are listed 
							below for completeness. </i>
					</td>
				</tr>
				<tr>
					<td>3001</td>
					<td>No ACK on Resp</td>
					<td>The host did not receive an ACK from the terminal after sending the transaction 
						response.</td>
				</tr>
				<tr>
					<td>3002</td>
					<td>POS NAK'd 3 Times</td>
					<td>The host disconnected after the terminal replied 3 times to the host response 
						with a NAK.</td>
				</tr>
				<tr>
					<td>3003</td>
					<td>Drop on Wait</td>
					<td>The line dropped before the host could send a response to the terminal.</td>
				</tr>
				<tr>
					<td>3005</td>
					<td>Drop on Resp</td>
					<td>The line dropped while the host was sending the response to the terminal.</td>
				</tr>
				<tr>
					<td>3007</td>
					<td>Drop Before EOT</td>
					<td>The host received an ACK from the terminal but the line dropped before the host 
						could send the EOT.</td>
				</tr>
				<tr>
					<td>3011</td>
					<td>No Resp to ENQ</td>
					<td>The line was up and carrier detected, but the terminal did not respond to the 
						ENQ.</td>
				</tr>
				<tr>
					<td>3012</td>
					<td>Drop on Input</td>
					<td>The line disconnected while the host was receiving data from the terminal.</td>
				</tr>
				<tr>
					<td>3013</td>
					<td>FEP NAK'd 3 Times</td>
					<td>The host disconnected after receiving 3 transmissions with incorrect LRC from 
						the terminal.</td>
				</tr>
				<tr>
					<td>3014</td>
					<td>No Resp to ENQ</td>
					<td>The line disconnected during input data wait in Multi-Trans Mode.</td>
				</tr>
				<tr>
					<td>3015</td>
					<td>Drop on Input</td>
					<td>The host encountered a full queue and discarded the input data.</td>
				</tr>
				<tr>
					<td>9000-9999</td>
					<td>Host Error</td>
					<td>The host encountered an internal error and was not able to process the 
						transaction.</td>
				</tr>
			</table>
		</center>
		<h2>Electronic Check Transactions</h2>
		<FONT face="Verdana,Arial,Helvetica" size="-1"><B><I>ECHO</I></B></FONT> verifies 
		all electronic checks against the National Check Information Systems (NCIS) 
		database. This is a real-time check verification system that can return a wide 
		variety of responses and conditions. <b><i><font face="Verdana,Arial,Helvetica" size="-1">ECHO<font size="-2">NLINE</font></font></i></b>
		does nor recognize a warning response, only approvals and declines. Therefore, 
		warnings received from NCIS are treated as declines by <b><i><font face="Verdana,Arial,Helvetica" size="-1">
					ECHO<font size="-2">NLINE</font></font></i></b>.
		<p>
		Decline responses are formatted as shown below. Each message is 16 characters 
		long and contains information regarding the reasons for the decline or warning 
		and the name and contact number for the agency providing the information 
		leading to the decline.
		<p>
			The NCN Response Format.pdf document located in the <A href="/XCXPlusTrans.zip"><I><FONT face="Verdana,Arial,Helvetica" size="-1">
						X<FONT size="-2">PRESS</FONT>C<FONT size="-2">HE</FONT>X<FONT size="-2">PLUS</FONT></FONT></I>
				Transaction Validation Tool</A>
		contains all Check Verification Responses.
		<p>
			<center>
				<table border="1" cellpadding="3" cellspacing="0" width="80%">
					<tr bgcolor="#e0e0e0">
						<td valign="top"><b>Field</b></td>
						<td valign="top"><b>Size</b></td>
						<td valign="top"><b>Description</b></td>
					</tr>
					<tr>
						<td valign="top">tag</td>
						<td valign="top">11</td>
						<td valign="top">"&lt;ECHOTYPE1&gt;"</td>
					</tr>
					<tr>
						<td valign="top">message</td>
						<td valign="top">16</td>
						<td valign="top">
							Decline message (see examples below).
						</td>
					</tr>
					<tr>
						<td valign="top">message</td>
						<td valign="top">16</td>
						<td valign="top">
							from 0 to <i>n</i> instances of additional decline and warning messages.
						</td>
					</tr>
					<tr>
						<td valign="top">tag</td>
						<td valign="top">12</td>
						<td valign="top">"&lt;/ECHOTYPE1&gt;"</td>
					</tr>
				</table>
			</center>
		<p>
			<b>Examples:</b><br>
			The first example shows a decline response containing 7 separate 
			messages.&lt;p&gt;&lt;code&gt;&lt;!--&lt;ECHOTYPE1&gt;DECLINE·CHECK···50·UNPAIDS·(ALL)UNPAID·AMT=·3778PHN·800-555-4503···CHKACHEK·····PHN·800-555-2954····XPCK!·······&lt;/ECHOTYPE1&gt;--&gt;&lt;br&gt;&lt;!--&lt;ECHOTYPE1&gt;WARNING·········DAYLOC/NCHCKS=14DAYLOC/AMT=45···WINLOC/AMT=12···&lt;/ECHOTYPE1&gt; 
			--&gt;<BR>
			&lt;!-- &lt;ECHOTYPE1&gt;ERROR IN ID·····&lt;/ECHOTYPE1&gt; --&gt;<BR>
			&lt;!-- 
			&lt;ECHOTYPE1&gt;DECLINE·CHECK····2·UNPAIDS·(LOC)UNPAID·AMT=··376BANK·STOP·······PHN 
			800-555-4503SUPER·COLLECT···&lt;/ECHOTYPE1&gt; --&gt;<BR>
		&lt;!-- &lt;ECHOTYPE1&gt;RE-PRESENTED CHK&lt;/ECHOTYPE1&gt; --&gt; </CODE>
		<p>
			<b>Note:</b><br>
		All Electronic Check Declines return a Decline Code of "0005" in the ECHOTYPE3 
		&lt;decline_code&gt; tag (i.e., &lt;decline_code&gt;0005&lt;/decline_code&gt; 
		). To determine the exact reason for the decline, the ECHOTYPE1 response must 
		be examined.
		<p>
			<hr size="3" color="#000080">
		
<SCRIPT LANGUAGE=JAVASCRIPT>
/* Opens a new Window linking to the supplied url */
function popUp(url){
sealWin=window.open(url,"win",'toolbar=0,location=0,directories=0,status=1,menubar=0,scrollbars=1,resizable=1,width=500,height=520');
self.name = "mainWin"; }
</SCRIPT>

<center>
<font size="-2" face="Verdana,Arial,Helvetica">

<a href="/">Merchant Center</a>&nbsp;
<a href="http://www.echo-inc.com/">ECHO Home</a>&nbsp;
<a href="mailto:webmaster@echo-inc.com">Feedback</a>&nbsp;
<a href="http://www.echo-inc.com/helpdesk.html">Contact ECHO</a>&nbsp;
<a href="javascript:popUp('/copyright.asp')">Copyright</a>&nbsp;


   <a href="/login.asp">Login</a>


</font>
</center>

</body>
</html>
</body>
</HTML>
