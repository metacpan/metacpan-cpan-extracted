<?xml version="1.0"?>
<!-- edited with XML Spy v4.3 U (http://www.xmlspy.com) by Hugh S. Myers (private) -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="GAME">
		<xsl:apply-templates/>
		<HR/>
	</xsl:template>
	<xsl:template match="TAGLIST">
		<p align="CENTER">
			<xsl:apply-templates/>
		</p>
	</xsl:template>
	<xsl:template match="GAMETEXT">
		<xsl:if test="@LEVEL=0">
			<p>
				<xsl:apply-templates/>
			</p>
		</xsl:if>
		<xsl:if test="@LEVEL>0">
			<span style="color:blue;"> (<xsl:apply-templates/>) </span>
		</xsl:if>
	</xsl:template>
	<xsl:template match="Event">
		<xsl:call-template name="tagger"/>
	</xsl:template>
	<xsl:template match="Site">
		<xsl:call-template name="tagger"/>
	</xsl:template>
	<xsl:template match="Date">
		Date: <b>
			<xsl:value-of select="@YEAR"/>.
			<xsl:value-of select="@MONTH"/>.
			<xsl:value-of select="@DAY"/>
		</b>
		<br/>
	</xsl:template>
	<xsl:template match="Round">
		<xsl:call-template name="tagger"/>
	</xsl:template>
	<xsl:template match="White">
		<xsl:call-template name="tagger"/>
	</xsl:template>
	<xsl:template match="Black">
		<xsl:call-template name="tagger"/>
	</xsl:template>
	<xsl:template match="Result">
		<xsl:call-template name="result"/>
	</xsl:template>
	<xsl:template match="ECO">
		<xsl:call-template name="tagger"/>
	</xsl:template>
	<xsl:template match="NIC">
		<xsl:call-template name="tagger"/>
	</xsl:template>
	<xsl:template match="Opening">
		<xsl:call-template name="tagger"/>
	</xsl:template>
	<xsl:template match="POSITION">
		<p align="CENTER">
			<font>
				<xsl:attribute name="FACE"><xsl:value-of select="@FONT"/></xsl:attribute>
				<xsl:attribute name="SIZE"><xsl:value-of select="@SIZE"/></xsl:attribute>
				<xsl:for-each select="ROW">
					<xsl:value-of select="."/>
					<br/>
				</xsl:for-each>
			</font>
		</p>
	</xsl:template>
	<xsl:template match="MOVENUMBER">
		<xsl:value-of select="."/>.<xsl:text>&#x20;</xsl:text>
	</xsl:template>
	<xsl:template match="MOVE">
		<font face="FigurineSymbol S1" size="4">
			<b>
				<xsl:value-of select="."/>
				<xsl:text>&#x20;</xsl:text>
			</b>
		</font>
	</xsl:template>
	<xsl:template match="COMMENT">
		<font face="Times New Roman" color="green" size="4">
			<xsl:value-of select="."/>
		</font>
	</xsl:template>
	<xsl:template match="FENstr"/>
	<xsl:template match="GAMETERMINATION">
		<font face="Times New Roman" color="red" size="4">
			<xsl:call-template name="result"/>
		</font>
	</xsl:template>
	<xsl:template match="NAG">
		<font face="FigurineSymbol S1" size="4" color="red">
		<xsl:choose>
			<xsl:when test=".=1">!</xsl:when>
			<xsl:when test=".=2">?</xsl:when>
			<xsl:when test=".=3">!!</xsl:when>
			<xsl:when test=".=4">??</xsl:when>
			<xsl:when test=".=5">!?</xsl:when>
			<xsl:when test=".=6">?!</xsl:when>
			<xsl:when test=".=7">&#158;</xsl:when>
			<xsl:when test=".=8"><font face="Times New Roman">singular move</font></xsl:when>
			<xsl:when test=".=9"><font face="Times New Roman">worst move</font></xsl:when>
			<xsl:when test=".=10"><font face="Times New Roman">drawish</font></xsl:when>
			<xsl:when test=".=11"><font face="Times New Roman">= quiet</font></xsl:when>
			<xsl:when test=".=12"><font face="Times New Roman">= active</font></xsl:when>
			<xsl:when test=".=13">&#247;</xsl:when>
			<xsl:when test=".=14">&#178;</xsl:when>
			<xsl:when test=".=15">&#179;</xsl:when>
			<xsl:when test=".=16">&#0260;</xsl:when>
			<xsl:when test=".=17">&#181;</xsl:when>
			<xsl:when test=".=18">+-</xsl:when>
			<xsl:when test=".=19">-+</xsl:when>
			<xsl:when test=".=20"><font face="Times New Roman">White has a crushing advantage</font></xsl:when>			
			<xsl:when test=".=21"><font face="Times New Roman">Black has a crushing advantage</font></xsl:when>			
			<xsl:when test=".=22"><font face="Times New Roman">White</font> &#135;</xsl:when>			
			<xsl:when test=".=23"><font face="Times New Roman">Black</font> &#135;</xsl:when>			
			<xsl:when test=".=24"><font face="Times New Roman">White (slight)</font> &#134;</xsl:when>			
			<xsl:when test=".=25"><font face="Times New Roman">Black (slight)</font> &#134;</xsl:when>			
			<xsl:when test=".=26"><font face="Times New Roman">White (moderate)</font> &#134;</xsl:when>			
			<xsl:when test=".=27"><font face="Times New Roman">Black (moderate)</font> &#134;</xsl:when>			
			<xsl:when test=".=28"><font face="Times New Roman">White (decisive)</font> &#134;</xsl:when>			
			<xsl:when test=".=29"><font face="Times New Roman">Black (decisive)</font> &#134;</xsl:when>			
			<xsl:when test=".=30"><font face="Times New Roman">White (slight)</font> &#137;</xsl:when>			
			<xsl:when test=".=31"><font face="Times New Roman">Black (slight)</font> &#137;</xsl:when>			
			<xsl:when test=".=32"><font face="Times New Roman">White (moderate)</font> &#137;</xsl:when>			
			<xsl:when test=".=33"><font face="Times New Roman">Black (moderate)</font> &#137;</xsl:when>			
			<xsl:when test=".=34"><font face="Times New Roman">White (decisive)</font> &#137;</xsl:when>			
			<xsl:when test=".=35"><font face="Times New Roman">Black (decisive)</font> &#137;</xsl:when>			
			<xsl:when test=".=36"><font face="Times New Roman">White</font> &#131;</xsl:when>			
			<xsl:when test=".=37"><font face="Times New Roman">Black</font> &#131;</xsl:when>			
			<xsl:when test=".=38"><font face="Times New Roman">White (lasting)</font> &#131;</xsl:when>			
			<xsl:when test=".=39"><font face="Times New Roman">Black (lasting)</font> &#131;</xsl:when>			
			<xsl:when test=".=40"><font face="Times New Roman">White</font> &#130;</xsl:when>			
			<xsl:when test=".=41"><font face="Times New Roman">Black</font> &#130;</xsl:when>			
			<xsl:when test=".=42"><font face="Times New Roman">White</font> &#176;</xsl:when>			
			<xsl:when test=".=43"><font face="Times New Roman">Black</font> &#176;</xsl:when>			
			<xsl:when test=".=44"><font face="Times New Roman">White</font> &#169;</xsl:when>			
			<xsl:when test=".=45"><font face="Times New Roman">Black</font> &#169;</xsl:when>			
			<xsl:when test=".=46"><font face="Times New Roman">White (more than adequate)</font> &#169;</xsl:when>			
			<xsl:when test=".=47"><font face="Times New Roman">Black (more than adequate)</font> &#169;</xsl:when>			
			<xsl:when test=".=48"><font face="Times New Roman">White (slight)</font> &#148;</xsl:when>			
			<xsl:when test=".=49"><font face="Times New Roman">Black (slight)</font> &#148;</xsl:when>			
			<xsl:when test=".=50"><font face="Times New Roman">White (moderate)</font> &#148;</xsl:when>			
			<xsl:when test=".=51"><font face="Times New Roman">Black (moderate)</font> &#148;</xsl:when>			
			<xsl:when test=".=52"><font face="Times New Roman">White (decisive)</font> &#148;</xsl:when>			
			<xsl:when test=".=53"><font face="Times New Roman">Black (decisive)</font> &#148;</xsl:when>			
			<xsl:when test=".=54"><font face="Times New Roman">White (slight)</font> &#187;</xsl:when>			
			<xsl:when test=".=55"><font face="Times New Roman">Black (slight)</font> &#187;</xsl:when>			
			<xsl:when test=".=56"><font face="Times New Roman">White (moderate)</font> &#187;</xsl:when>			
			<xsl:when test=".=57"><font face="Times New Roman">Black (moderate)</font> &#187;</xsl:when>			
			<xsl:when test=".=58"><font face="Times New Roman">White (decisive)</font> &#187;</xsl:when>			
			<xsl:when test=".=59"><font face="Times New Roman">Black (decisive)</font> &#187;</xsl:when>			
			<xsl:when test=".=60"><font face="Times New Roman">White (slight)</font> &#171;</xsl:when>			
			<xsl:when test=".=61"><font face="Times New Roman">Black (slight)</font> &#171;</xsl:when>			
			<xsl:when test=".=62"><font face="Times New Roman">White (moderate)</font> &#171;</xsl:when>			
			<xsl:when test=".=63"><font face="Times New Roman">Black (moderate)</font> &#171;</xsl:when>			
			<xsl:when test=".=64"><font face="Times New Roman">White (decisive)</font> &#171;</xsl:when>			
			<xsl:when test=".=65"><font face="Times New Roman">Black (decisive)</font> &#171;</xsl:when>			
			<xsl:when test=".=66"><font face="Times New Roman">White has a vulnerable first rank</font></xsl:when>
			<xsl:when test=".=67"><font face="Times New Roman">Black has a vulnerable first rank</font></xsl:when>
			<xsl:when test=".=68"><font face="Times New Roman">White has a well protected first rank</font></xsl:when>
			<xsl:when test=".=69"><font face="Times New Roman">Black has a well protected first rank</font></xsl:when>
			<xsl:when test=".=70"><font face="Times New Roman">White has a poorly protected king</font></xsl:when>
			<xsl:when test=".=71"><font face="Times New Roman">Black has a poorly protected king</font></xsl:when>
			<xsl:when test=".=72"><font face="Times New Roman">White has a well protected king</font></xsl:when>
			<xsl:when test=".=73"><font face="Times New Roman">Black has a well protected king</font></xsl:when>
			<xsl:when test=".=74"><font face="Times New Roman">White has a poorly placed king</font></xsl:when>
			<xsl:when test=".=75"><font face="Times New Roman">Black has a poorly placed king</font></xsl:when>
			<xsl:when test=".=76"><font face="Times New Roman">White has a well placed king</font></xsl:when>
			<xsl:when test=".=77"><font face="Times New Roman">Black has a well placed king</font></xsl:when>
			<xsl:when test=".=78"><font face="Times New Roman">White has a very weak pawn structure</font></xsl:when>
			<xsl:when test=".=79"><font face="Times New Roman">Black has a very weak pawn structure</font></xsl:when>
			<xsl:when test=".=80"><font face="Times New Roman">White has a moderately weak pawn structure</font></xsl:when>
			<xsl:when test=".=81"><font face="Times New Roman">Black has a moderately weak pawn structure</font></xsl:when>
			<xsl:when test=".=82"><font face="Times New Roman">White has a moderately strong pawn structure</font></xsl:when>
			<xsl:when test=".=83"><font face="Times New Roman">Black has a moderately strong pawn structure</font></xsl:when>
			<xsl:when test=".=84"><font face="Times New Roman">White has a very strong pawn structure</font></xsl:when>
			<xsl:when test=".=85"><font face="Times New Roman">Black has a very strong pawn structure</font></xsl:when>
			<xsl:when test=".=86"><font face="Times New Roman">White has poor knight placement</font></xsl:when>
			<xsl:when test=".=87"><font face="Times New Roman">Black has poor knight placement</font></xsl:when>
			<xsl:when test=".=88"><font face="Times New Roman">White has good knight placement</font></xsl:when>
			<xsl:when test=".=89"><font face="Times New Roman">Black has good knight placement</font></xsl:when>
			<xsl:when test=".=90"><font face="Times New Roman">White has poor bishop placement</font></xsl:when>
			<xsl:when test=".=91"><font face="Times New Roman">Black has poor bishop placement</font></xsl:when>
			<xsl:when test=".=92"><font face="Times New Roman">White has good bishop placement</font></xsl:when>
			<xsl:when test=".=93"><font face="Times New Roman">Black has good bishop placement</font></xsl:when>
			<xsl:when test=".=84"><font face="Times New Roman">White has poor rook placement</font></xsl:when>
			<xsl:when test=".=85"><font face="Times New Roman">Black has poor rook placement</font></xsl:when>
			<xsl:when test=".=86"><font face="Times New Roman">White has good rook placement</font></xsl:when>
			<xsl:when test=".=87"><font face="Times New Roman">Black has good rook placement</font></xsl:when>
			<xsl:when test=".=98"><font face="Times New Roman">White has poor queen placement</font></xsl:when>
			<xsl:when test=".=99"><font face="Times New Roman">Black has poor queen placement</font></xsl:when>
			<xsl:when test=".=100"><font face="Times New Roman">White has good queen placement</font></xsl:when>
			<xsl:when test=".=101"><font face="Times New Roman">Black has good queen placement</font></xsl:when>
			<xsl:when test=".=102"><font face="Times New Roman">White has poor piece coordination</font></xsl:when>
			<xsl:when test=".=103"><font face="Times New Roman">Black has poor piece coordination</font></xsl:when>
			<xsl:when test=".=104"><font face="Times New Roman">White has good piece coordination</font></xsl:when>
			<xsl:when test=".=105"><font face="Times New Roman">Black has good piece coordination</font></xsl:when>
			<xsl:when test=".=106"><font face="Times New Roman">White has played the opening very poorly</font></xsl:when>
			<xsl:when test=".=107"><font face="Times New Roman">Black has played the opening very poorly</font></xsl:when>
			<xsl:when test=".=108"><font face="Times New Roman">White has played the opening poorly</font></xsl:when>
			<xsl:when test=".=109"><font face="Times New Roman">Black has played the opening poorly</font></xsl:when>
			<xsl:when test=".=110"><font face="Times New Roman">White has played the opening well</font></xsl:when>
			<xsl:when test=".=111"><font face="Times New Roman">Black has played the opening well</font></xsl:when>
			<xsl:when test=".=112"><font face="Times New Roman">White has played the opening very well</font></xsl:when>
			<xsl:when test=".=113"><font face="Times New Roman">Black has played the opening very well</font></xsl:when>
			<xsl:when test=".=114"><font face="Times New Roman">White has played the middlegame very poorly</font></xsl:when>
			<xsl:when test=".=115"><font face="Times New Roman">Black has played the middlegame very poorly</font></xsl:when>
			<xsl:when test=".=116"><font face="Times New Roman">White has played the middlegame poorly</font></xsl:when>
			<xsl:when test=".=117"><font face="Times New Roman">Black has played the middlegame poorly</font></xsl:when>
			<xsl:when test=".=118"><font face="Times New Roman">White has played the middlegame well</font></xsl:when>
			<xsl:when test=".=119"><font face="Times New Roman">Black has played the middlegame well</font></xsl:when>
			<xsl:when test=".=120"><font face="Times New Roman">White has played the middlegame very well</font></xsl:when>
			<xsl:when test=".=121"><font face="Times New Roman">Black has played the middlegame very well</font></xsl:when>
			<xsl:when test=".=122"><font face="Times New Roman">White has played the ending very poorly</font></xsl:when>
			<xsl:when test=".=123"><font face="Times New Roman">Black has played the ending very poorly</font></xsl:when>
			<xsl:when test=".=124"><font face="Times New Roman">White has played the ending poorly</font></xsl:when>
			<xsl:when test=".=125"><font face="Times New Roman">Black has played the ending poorly</font></xsl:when>
			<xsl:when test=".=126"><font face="Times New Roman">White has played the ending well</font></xsl:when>
			<xsl:when test=".=127"><font face="Times New Roman">Black has played the ending well</font></xsl:when>
			<xsl:when test=".=128"><font face="Times New Roman">White has played the ending very well</font></xsl:when>
			<xsl:when test=".=129"><font face="Times New Roman">Black has played the ending very well</font></xsl:when>
			<xsl:when test=".=130"><font face="Times New Roman">White (slight)</font> &#132;</xsl:when>			
			<xsl:when test=".=131"><font face="Times New Roman">Black (slight)</font> &#132;</xsl:when>			
			<xsl:when test=".=132"><font face="Times New Roman">White (moderate)</font> &#132;</xsl:when>			
			<xsl:when test=".=133"><font face="Times New Roman">Black (moderate)</font> &#132;</xsl:when>			
			<xsl:when test=".=134"><font face="Times New Roman">White (decisive)</font> &#132;</xsl:when>			
			<xsl:when test=".=135"><font face="Times New Roman">Black (decisive)</font> &#132;</xsl:when>			
			<xsl:when test=".=136"><font face="Times New Roman">White (moderate)</font> &#147;</xsl:when>			
			<xsl:when test=".=137"><font face="Times New Roman">Black (moderate)</font> &#147;</xsl:when>			
			<xsl:when test=".=138"><font face="Times New Roman">White (decisive)</font> &#147;</xsl:when>			
			<xsl:when test=".=139"><font face="Times New Roman">Black (decisive)</font> &#147;</xsl:when>			
			<xsl:otherwise>$<xsl:value-of select="."/></xsl:otherwise>
		</xsl:choose>
		</font>
	</xsl:template>
	<xsl:template name="result">
		<xsl:choose>
			<xsl:when test="@GAMERESULT[.='WHITEWIN']">
				<b>1-0</b>
				<br/>
			</xsl:when>
			<xsl:when test="@GAMERESULT[.='BLACKWIN']">
				<b>0-1</b>
				<br/>
			</xsl:when>
			<xsl:when test="@GAMERESULT[.='DRAW']">
				<b>1/2-1/2</b>
				<br/>
			</xsl:when>
			<xsl:when test="@GAMERESULT[.='UNKNOWN']">
				<b>*</b>
				<br/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="tagger">
		<xsl:value-of select="name()"/>: <b>
			<xsl:value-of select="."/>
		</b>
		<br/>
	</xsl:template>
</xsl:stylesheet>
