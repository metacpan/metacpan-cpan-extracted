package Clarity::XOG::Cargo::Test::QA;

=head1 NAME

Clarity::XOG::Cargo::Test::QA - Container for cargo __DATA__

=cut

1;
__DATA__
<!-- edited with Emacs 23 (http://emacswiki.org) by cris (na) -->
<!--XOG XML from CA is prj_projects_alloc_act_etc_read.  Edited by Karola Brandes to test XOG-In for project resource allocations-->
<NikuDataBus xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="../xsd/nikuxog_project.xsd">
	<Header action="write" externalSource="NIKU" objectType="project" version="7.5.0"/>
	<Projects>
		<Project name="KRAM Testing" projectID="PRJ-300330">
			<Resources>
				<Resource resourceID="qa-kram-1" defaultAllocation="0">
					<AllocCurve>
						<Segment start="2009-11-01T08:00:00" finish="2009-11-30T17:59:59" sum="15"/>
						<Segment start="2009-12-01T08:00:00" finish="2009-12-31T17:59:59" sum="15"/>
						<Segment start="2010-01-01T08:00:00" finish="2010-01-31T17:59:59" sum="20"/>
					</AllocCurve>
				</Resource>
				<Resource resourceID="qa-kram-2" defaultAllocation="0">
					<AllocCurve>
						<Segment start="2009-11-01T08:00:00" finish="2009-11-30T17:59:59" sum="0.3"/>
						<Segment start="2009-12-01T08:00:00" finish="2009-12-31T17:59:59" sum="0.3"/>
						<Segment start="2010-01-01T08:00:00" finish="2010-01-31T17:59:59" sum="0.3"/>
					</AllocCurve>
				</Resource>
			</Resources>
			<CustomInformation>
				<ColumnValue name="qa-kram-lhm_state-1">lhm_active</ColumnValue>
				<ColumnValue name="qa-kram-partition_code-1">lhm_eng</ColumnValue>
			</CustomInformation>
		</Project>
		<Project name="Birne" projectID="PRJ-100223">
			<Resources>
				<Resource resourceID="qa-birne-1" defaultAllocation="0">
					<AllocCurve>
						<Segment start="2009-11-01T08:00:00" finish="2009-11-30T17:59:59" sum="15"/>
						<Segment start="2009-12-01T08:00:00" finish="2009-12-31T17:59:59" sum="15"/>
						<Segment start="2010-01-01T08:00:00" finish="2010-01-31T17:59:59" sum="20"/>
					</AllocCurve>
				</Resource>
				<Resource resourceID="qa-birne-2" defaultAllocation="0">
					<AllocCurve>
						<Segment start="2009-11-01T08:00:00" finish="2009-11-30T17:59:59" sum="0.3"/>
						<Segment start="2009-12-01T08:00:00" finish="2009-12-31T17:59:59" sum="0.3"/>
						<Segment start="2010-01-01T08:00:00" finish="2010-01-31T17:59:59" sum="0.3"/>
					</AllocCurve>
				</Resource>
			</Resources>
			<CustomInformation>
				<ColumnValue name="qa-birne-lhm_state-2">lhm_active</ColumnValue>
				<ColumnValue name="qa-birne-partition_code-2">lhm_eng</ColumnValue>
			</CustomInformation>
		</Project>
	</Projects>
</NikuDataBus>
