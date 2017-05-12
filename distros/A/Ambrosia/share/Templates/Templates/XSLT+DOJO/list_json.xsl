<?xml version="1.0" encoding="UTF-8" ?>
<xslt:stylesheet version="1.0" 
	xmlns:xslt="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsl="http://www.w3.org/1999/XSL/TransformAlias"
	xmlns:atns="app://Ambrosia/EntityDataModel/2011/V1">

<xslt:import href="incDojo_JS_Css.xsl" />

<xslt:output method="xml" indent="yes" />
<xslt:namespace-alias stylesheet-prefix="xsl" result-prefix="xslt"/>

<xslt:include href="../../incName.xsl" />

<xslt:template match="/">

<xsl:stylesheet version="1.0">

<xsl:output method="html" indent="yes" />

<xsl:template match="/"><xsl:text disable-output-escaping="yes">&lt;!DOCTYPE HTML>
</xsl:text>
<html xml:lang="en" lang="en">
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<xslt:apply-imports/>

		<style type="text/css">
			@import "/ajax/libs/dojo/1.7.2/dojox/grid/resources/Grid.css";
			@import "/ajax/libs/dojo/1.7.2/dojox/grid/resources/claroGrid.css";

			.head {
				text-align:center;
				//font-weight:bold;
				font-size: 1.5em;
				height: 1.6em;
				width: 98%;
			}

			#grid {
				width: 98%;
				height: 80%;
			}
		</style>
		<link rel="stylesheet" type="text/css" href="/ajax/libs/dojo/1.7.2/dojox/grid/enhanced/resources/claro/EnhancedGrid.css"/>
		<link rel="stylesheet" type="text/css" href="/ajax/libs/dojo/1.7.2/dojox/grid/enhanced/resources/EnhancedGrid_rtl.css"/>


		<xsl:variable name="urlList">
		<xsl:value-of select="">
			<xslt:attribute name="select"><xslt:value-of select="concat('//',$UcAppName,'/@script')" /></xslt:attribute>
		</xsl:value-of>/json/<xsl:value-of select="//repository/@Name"/>
		</xsl:variable>

		<xsl:variable name="urlEdit">
		<xsl:value-of select="">
			<xslt:attribute name="select"><xslt:value-of select="concat('//',$UcAppName,'/@script')" /></xslt:attribute>
		</xsl:value-of>/<xsl:value-of select="//repository/@Name"/>
		</xsl:variable>

		<script type="text/javascript">
			require([
				"dojo/dom",
				"dojox/grid/EnhancedGrid",
				"dojox/data/QueryReadStore",
				"dojox/grid/enhanced/plugins/Pagination", "dojox/grid/enhanced/plugins/Filter",
		<xsl:if test="//repository/@mutable=1">
				"dijit/dijit", "dijit/form/Button", "dijit/Dialog",
		</xsl:if>
				"dojo/domReady!", "dojo/parser"], function(dom, DataGrid, QueryReadStore) {

					var qstore;
					function showFormEdit(id)
					{
						document.getElementById('exFormFrame').src="<xsl:value-of select="$urlEdit" />/"+id;
						dijit.byId('exForm').show();
					}

					var formatSaveButton = function(value){
						return new dijit.form.Button({
							label: "Edit",
							iconClass: "dijitIconEdit",
							onClick: function(){ showFormEdit(value) }
						});
					};

					dojo.declare("my.data.QueryReadStore", [QueryReadStore], {
							_filterResponse: function(data){
								return {numRows: data.repository.numRows, items:data.repository.items};
							},
						});

					qstore = new my.data.QueryReadStore({
						url: "<xsl:value-of select="$urlList" />"
					});

					var grid = new DataGrid({
						store: qstore,
						query: {},
						plugins: {
							pagination: {
								pageSizes: ["25", "50", "100", "All"],
								description: "30%",
								sizeSwitch: "200px",
								pageStepper: "30em",
								gotoButton: true,
								maxPageStep: 5,
								position: "bottom"
							},
							filter: {
								itemsName: '<xsl:value-of select="//repository/@Name"/>',
								closeFilterbarButton: true,
								ruleCount: 8
							}
						},
						structure: [
							<xsl:apply-templates select="//repository/Field"/>
							<xsl:if test="//repository/@mutable=1">,
							{
								name: "Edit",
								field: "<xsl:apply-templates select="//repository/Field[@key=1]/@field"/>",
								styles: "text-align:center;",
								width: 8,
								formatter: formatSaveButton
							}
							</xsl:if>
						]
					}, "grid");
					grid.startup();
				});
		</script>
	</head>
	<body class="claro">
		<div class="claro dojoxGridMasterHeader head">List of <xsl:value-of select="//repository/@Name"/></div>
		<div id="grid"></div>
	<xsl:if test="//repository/@mutable=1">
		<div id="exForm" data-dojo-type="dijit.Dialog" title="Edit" style="overflow:auto; width: 300px; height: 300px; display:none;">
			<iframe id="exFormFrame" src="" style="overflow:auto; width: 99%; border:0px;">
			</iframe>
		</div>
	</xsl:if>
	</body>
</html>
</xsl:template>

<xsl:template match="//repository/Field">
	{
		name: "<xsl:value-of select="@label"/>",
		field: "<xsl:value-of select="@field"/>",
		styles: "text-align:right;",
		width:8
	}<xsl:if test="position()!=last()">,</xsl:if>
</xsl:template>

</xsl:stylesheet>
</xslt:template>

</xslt:stylesheet>
