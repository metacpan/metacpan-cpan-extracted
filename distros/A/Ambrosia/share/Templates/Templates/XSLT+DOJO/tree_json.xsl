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
<html lang="en">
	<xslt:if test="boolean(/Application/@Language)">
		<xslt:attribute name="lang">
			<xslt:value-of select="/Application/@Language"/>
		</xslt:attribute>
	</xslt:if>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<xslt:apply-imports/>
<xsl:variable name="url">
<xsl:value-of select="">
	<xslt:attribute name="select"><xslt:value-of select="concat('//',$UcAppName,'/@script')" /></xslt:attribute>
</xsl:value-of>/json/<xsl:value-of select="//repository/@Name"/>
</xsl:variable>
		<script type="text/javascript">
			require([
				"dojo/store/JsonRest",
				"dojo/store/Observable",
				"dijit/Tree",
				"dijit/tree/dndSource",
				"dojo/query",
				"dojo/domReady!"],
			function(JsonRest, Observable, Tree, dndSource, query) {
				var usGov = JsonRest({
					target:"<xsl:value-of select="$url" />/",
					getIdentity: function(object){
						return object.repository ? object.repository.response.id : object.id
					},
					mayHaveChildren: function(object){
						return object.repository
							? "children" in object.repository.response
							: "children" in object;
					},
					getChildren: function(object, onComplete, onError){
						var res = object.repository ? object.repository.response : object;
						// retrieve the full copy of the object
						this.get(res.id).then(function(fullObject){
							// copy to the original object so it has the children array as well.
							res.children = fullObject.repository ? fullObject.repository.response.children : fullObject.children;
							// now that full object, we should have an array of children
							onComplete(fullObject.repository ? fullObject.repository.response.children : fullObject.children);
						}, function(error){
							// an error occurred, log it, and indicate no children
							console.error(error);
							onComplete([]);
						});
					},
					getRoot: function(onItem, onError){
						// get the root object, we will do a get() and callback the result
						this.get("root").then(onItem, onError);
					},
					getLabel: function(object){
						// just get the name
						return object.repository ? object.repository.response.name : object.name;
					},
					put: function(object, options){
						//this.onChange(object);
						this.onChildrenChange(object, object.children);
						this.onChange(object);
						return JsonRest.prototype.put.apply(this, arguments);
					}
				});

				var tree = new Tree({
					model: usGov,
					dndController: dndSource
				}, "tree");
				tree.startup();

				query("#add-new-child").on("click", function(){
					var selectedObject = tree.get("selectedItems")[0];
					if(!selectedObject){
						return alert("No object selected");
					}
					usGov.get(selectedObject.id).then(function(selectedObject){
						selectedObject.children.push({
							name: "New child",
							id: Math.random()
						});
						usGov.put(selectedObject);
					});
				});
				tree.on("dblclick", function(object){
					object.name = prompt("Enter a new name for the object");
					usGov.put(object);
				}, true);
			});
		</script>
	</head>
	<body class="claro">
		<div id="tree"></div>
	</body>
</html>
</xsl:template>
</xsl:stylesheet>

</xslt:template>
</xslt:stylesheet>
