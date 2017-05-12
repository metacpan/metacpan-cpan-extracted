<?xml version="1.0" encoding="utf-8"?>
 
<xsl:stylesheet version="1.0" 
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns="app://Ambrosia/EntityDataModel/2011/V1"
		>

<xsl:output method="xml" indent="yes" encoding="utf-8" />
<xsl:include href="incName.xsl" />
<xsl:include href="incTypes.xsl" />

<xsl:template match="*">
	<Application Language="en-us" Authorization="YES">
		<xsl:attribute name="Name">
			<xsl:value-of select="name()" /><!-- name of root element. (config->ID) -->
		</xsl:attribute>
		<xsl:attribute name="Label">
			<xsl:value-of select="//repository/config/@label" /><!-- config->Label -->
		</xsl:attribute>
		<xsl:attribute name="Charset">
			<xsl:value-of select="//repository/config/@charset" /><!-- config->Charset -->
		</xsl:attribute>

		<Config>
			<CommonGatewayInterface Engine="ApacheRequest">
				<Params
					Pragma        = "no-cache"
					Cache_Control = "no-cache, must-revalidate, no-store"
				/>
			</CommonGatewayInterface>

			<Host Debug="YES">
				<xsl:attribute name="Name">
					<xsl:value-of select="concat(name(), '.deploy')" />
				</xsl:attribute>
				<xsl:attribute name="ServerName">
					<xsl:value-of select="//repository/config/@ServerName" />
				</xsl:attribute>
				<xsl:attribute name="ServerPort">
					<xsl:value-of select="//repository/config/@ServerPort" />
				</xsl:attribute>
				<xsl:attribute name="PerlLibPath">
					<xsl:value-of select="//repository/config/@PerlLibPath" />
				</xsl:attribute>
				<xsl:attribute name="ProjectPath">
					<xsl:value-of select="//repository/config/@ProjectPath" />
				</xsl:attribute>
			</Host>
			<xsl:comment>you can add anofer host for test, production, etc.</xsl:comment>
		</Config>

		<DataSource>
			<xsl:apply-templates select="//repository/schema_list" mode="DataSource" />
		</DataSource>

		<Entitys>
			<xsl:apply-templates select="//repository/schema_list/tables" mode="entity" />
		</Entitys>


		<Relations>
			<xsl:apply-templates select="//repository/schema_list/tables[boolean(has_one)]" mode="relation" />
		</Relations>

		<MenuGroups>
			<Group Name="" Title="">
				<xsl:attribute name="Name">
					<xsl:value-of select="name()" /><!-- name of root element. (config->ID) -->
				</xsl:attribute>
				<xsl:attribute name="Title">
					<xsl:value-of select="//repository/config/@label" /><!-- config->Label -->
				</xsl:attribute>
				<xsl:apply-templates select="//repository/schema_list/tables" mode="menugroups" />
			</Group>
		</MenuGroups>
	</Application>
</xsl:template>

<!-- Create DataSource's list -->
<xsl:template match="//repository/schema_list" mode="DataSource">
	<Type>
		<xsl:attribute name="Name">
			<xsl:value-of select="@type" />
		</xsl:attribute>
		<Source>
			<xsl:attribute name="Name">
				<xsl:value-of select="config/@db_source" />
			</xsl:attribute>
			<xsl:attribute name="Engine">
				<xsl:value-of select="config/@db_engine" />
			</xsl:attribute>
			<xsl:if test="boolean(@catalog)">
			<xsl:attribute name="Catalog">
				<xsl:value-of select="@catalog" />
			</xsl:attribute>
			</xsl:if>
			<xsl:attribute name="Schema">
				<xsl:value-of select="@schema" />
			</xsl:attribute>
			<xsl:attribute name="User">
				<xsl:value-of select="config/@db_user" />
			</xsl:attribute>
			<xsl:attribute name="Password">
				<xsl:value-of select="config/@db_password" />
			</xsl:attribute>
			<xsl:attribute name="Charset">
				<xsl:value-of select="config/@db_charset" />
			</xsl:attribute>
			<xsl:attribute name="Params">
				<xsl:value-of select="config/@db_params" />
			</xsl:attribute>
		</Source>
	</Type>
</xsl:template>

<!-- Create a list of Entities -->
<xsl:template match="//repository/schema_list/tables" mode="entity">
<xsl:variable name="sourceRef" select="concat(../@type, '.', ../config/@db_source)"/>
	<Entity Id="" Name="" Type="Table" Label="" Extends=""> <!-- ABSTRACT | BIND | TABLE | VIEW -->
		<xsl:attribute name="Id">
			<xsl:value-of select="@tId" />
		</xsl:attribute>
		<xsl:attribute name="Type">
			<xsl:value-of select="@type" />
		</xsl:attribute>
		<xsl:attribute name="Name"> <!-- entity name (We assume that the name of the entity corresponds to the name table. And the table name starts with 'tbl' or 't_' for tables and start with 'v_' for the view.) -->
			<xsl:call-template name="convertTable2Entity">
				<xsl:with-param name="name" select="@name"/>
			</xsl:call-template>
		</xsl:attribute>
		<xsl:attribute name="DataSourceTypeRef">
			<xsl:value-of select="../@type" /><!-- the reference to DBI or Resource -->
		</xsl:attribute>
		<xsl:attribute name="DataSourceNameRef">
			<xsl:value-of select="../config/@db_source" /><!-- the reference to the name of the data source -->
		</xsl:attribute>
		<xsl:attribute name="SourcePath"> <!-- the table name | the file name -->
			<xsl:value-of select="@name" />
		</xsl:attribute>

		<xsl:if test="boolean(@KEY)">
		<Key>
			<xsl:if test="boolean(@AUTO_UNIQUE_VALUE)">
				<xsl:attribute name="AutoUniqueValue">
					<xsl:text>YES</xsl:text>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select="column" mode="key"/>
		</Key>
		</xsl:if>

		<xsl:apply-templates select="column" mode="fields"/>

	</Entity>
</xsl:template>

<!-- Create a list of Relations -->
<xsl:template match="//repository/schema_list/tables[boolean(has_one)]" mode="relation">
	<Relation RefId="" Type="">
		<xsl:attribute name="RefId">
			<xsl:value-of select="@tId" /><!-- the reference to Entity -->
		</xsl:attribute>
		<xsl:attribute name="Type"> <!-- the reference to entity -->
			<xsl:call-template name="convertTable2Entity">
				<xsl:with-param name="name" select="@name"/>
			</xsl:call-template>
		</xsl:attribute>
		<xsl:apply-templates select="has_one" />
	</Relation>
</xsl:template>

<!-- Create a list of keys in Entity -->
<xsl:template match="column" mode="key">
	<xsl:choose>
		<xsl:when test="boolean(@primary_key)">
			<FieldRef>
				<xsl:attribute name="Name">
					<xsl:value-of select="@Name" />
				</xsl:attribute>
			</FieldRef>
		</xsl:when>
		<xsl:when test="boolean(@foreign_key)">
			<FieldRef>
				<xsl:attribute name="Name">
					<xsl:value-of select="@Name" />
				</xsl:attribute>
			</FieldRef>
		</xsl:when>
		<xsl:when test="boolean(@key)">
			<FieldRef>
				<xsl:attribute name="Name">
					<xsl:value-of select="@Name" />
				</xsl:attribute>
			</FieldRef>
		</xsl:when>
	</xsl:choose>
</xsl:template>

<!-- Create a list of fields in Entity -->
<xsl:template match="column" mode="fields">
	<Field Name="" Type="" Size="" Label="" Title="" IsNullable="NO">
		<xsl:attribute name="Label" />
		<xsl:attribute name="Title">
			<xsl:value-of select="@Remarks" />
		</xsl:attribute>
		<xsl:for-each select="@*">
			<xsl:choose>
				<xsl:when test="name()='Remarks'">
				</xsl:when>
				<xsl:when test="name()='primary_key'">
				</xsl:when>
				<xsl:when test="name()='foreign_key'">
				</xsl:when>
				<xsl:when test="name()='key'">
				</xsl:when>

				<xsl:when test="name()='DecimalDigits'">
					<xsl:variable name='UcType' select="translate(../@Type, $vLowercaseChars_CONST , $vUppercaseChars_CONST)" />
					<xsl:variable name='c_type'>
						<xsl:call-template name="convertType">
							<xsl:with-param name="type" select="$UcType"/>
						</xsl:call-template>
					</xsl:variable>
					<xsl:if test="$c_type='double'">
						<xsl:attribute name="DecimalDigits">
						</xsl:attribute>
					</xsl:if>
				</xsl:when>

				<xsl:when test="name()='Type'">
					<xsl:attribute name="Type">
						<xsl:variable name='UcType' select="translate(., $vLowercaseChars_CONST , $vUppercaseChars_CONST)" />
						<xsl:call-template name="convertType">
							<xsl:with-param name="type" select="$UcType"/>
						</xsl:call-template>
					</xsl:attribute>
				</xsl:when>

				<xsl:otherwise>
					<xsl:variable name="attr_name" select="name()" />
					<xsl:attribute name="{$attr_name}">
						<xsl:value-of select="." />
					</xsl:attribute>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</Field>
</xsl:template>

<!-- Create relations -->
<xsl:template match="has_one">
	<xsl:variable name="fktable_name">
		<xsl:value-of select="@fktable_name" />
	</xsl:variable>
	<xsl:variable name="fkcolumn_name">
		<xsl:value-of select="@fkcolumn_name" />
	</xsl:variable>
	<EntityRef>
		<xsl:variable name="role">
			<xsl:call-template name="convertTable2Entity">
				<xsl:with-param name="name" select="@fktable_name"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:attribute name="RefId">
			<xsl:value-of select="@fId" />
		</xsl:attribute>
		<xsl:attribute name="Role">
			<xsl:value-of select="$role" />
		</xsl:attribute>
		<xsl:attribute name="From">
			<xsl:value-of select="@pkcolumn_name" />
		</xsl:attribute>
		<xsl:attribute name="To">
			<xsl:value-of select="@fkcolumn_name" />
		</xsl:attribute>
		<xsl:attribute name="Multiplicity">
			<xsl:text>YES</xsl:text>
		</xsl:attribute>

		<xsl:choose>
			<xsl:when test="//repository/schema_list/tables[@name=$fktable_name]/column[@Name=$fkcolumn_name]/@IsNullable='YES'">
				<xsl:attribute name="Optional">
					<xsl:text>YES</xsl:text>
				</xsl:attribute>
			</xsl:when>
			<xsl:otherwise>
				<xsl:attribute name="Feedback">
					<xsl:text>YES</xsl:text>
				</xsl:attribute>
			</xsl:otherwise>
		</xsl:choose>
	</EntityRef>
</xsl:template>

<xsl:template match="//repository/schema_list/tables" mode="menugroups">
	<EntityRef RefId="" Type="">
		<xsl:attribute name="RefId">
			<xsl:value-of select="@tId" /><!-- the reference to Entity -->
		</xsl:attribute>
		<xsl:attribute name="Type">
			<xsl:call-template name="convertTable2Entity">
				<xsl:with-param name="name" select="@name"/>
			</xsl:call-template>
		</xsl:attribute>
	</EntityRef>
</xsl:template>

<xsl:template name="convertTable2Entity">
	<xsl:param name="name" />

	<xsl:choose>
		<xsl:when test="starts-with($name, 'tbl')">
			<xsl:value-of select="substring($name, 4)" />
		</xsl:when>
		<xsl:when test="starts-with($name, 't_')">
			<xsl:value-of select="substring($name, 2)" />
		</xsl:when>
		<xsl:when test="starts-with($name, 'v_')">
			<xsl:value-of select="substring($name, 2)" />
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$name" />
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>