package DMTF::CIM;

use warnings;
use strict;

use version;
our $VERSION = qv('0.04');

use DMTF::CIM::Instance;
use Carp;

sub new
{
	my $self={};
	$self->{CLASS} = shift;
	$self->{MODEL} = undef;
	$self->{UFcT} = {
		authorizedpriv		=> {class => 'CIM_AuthorizedPrivilege'},
		configcapacity		=> {class => 'CIM_ConfigurationCapacity'},
		location			=> {class => 'CIM_Location'},
		record				=> {class => 'CIM_LogRecord'},
		namespace			=> {class => 'CIM_Namespace'},
		plocation			=> {class => 'CIM_PhysicalLocation'},
		product				=> {class => 'CIM_Product'},
		profile				=> {class => 'CIM_RegisteredProfile'},
		subprofile			=> {class => 'CIM_RegisteredSubProfile'},
		mapcap				=> {class => 'CIM_MAPCapabilities'},
		sharingcap			=> {class => 'CIM_DeviceSharingCapabilities'},
		pwrmgtcap			=> {class => 'CIM_PowerManagementCapabilities'},
		swinstallsvccap		=> {class => 'CIM_SoftwareInstallationServiceCapabilities'},
		storagecap			=> {class => 'CIM_StorageCapabilities'},
		storagecfgcap		=> {class => 'CIM_StorageConfigurationCapabilities'},
		dhcpcap				=> {class => 'CIM_DHCPCapabilities'},
		bootcfgsetting		=> {class => 'CIM_BootConfigSetting'},
		bootsrcsetting		=> {class => 'CIM_BootSourceSetting'},
		bootsetting			=> {class => 'CIM_BootSettingData'},
		displaysetting		=> {class => 'CIM_DisplaySetting'},
		mapsetting			=> {class => 'CIM_MAPSetting'},
		nicsetting			=> {class => 'CIM_NicSetting'},
		storagesetting		=> {class => 'CIM_StorageSetting'},
		ipsettings			=> {class => 'CIM_IPAssignmentSettingData'},
		staticipsettings	=> {class => 'CIM_StaticIPAssignmentSettingData'},
		dhcpsettings		=> {class => 'CIM_DHCPSettingData'},
		dnssettings			=> {class => 'CIM_DNSSettingData'},
		dnsgeneralsettings	=> {class => 'CIM_DNSGeneralSettingData'},
		group				=> {class => 'CIM_Group'},
		redundancyset		=> {class => 'CIM_RedundancySet'},
		swrepo				=> {class => 'CIM_SoftwareRepository'},
		concretecollection	=> {class => 'CIM_ConcreteCollection'}, 
		hdwr				=> {class => 'CIM_ConcreteCollection', where=>'ElementName="Hardware"'}, 
		capabilities		=> {class => 'CIM_ConcreteCollection', where=>'ElementName="Capabilities"'}, 
		capacities			=> {class => 'CIM_ConcreteCollection', where=>'ElementName="Capacities"'}, 
		consoles			=> {class => 'CIM_ConcreteCollection', where=>'ElementName="Consoles"'}, 
		logs				=> {class => 'CIM_ConcreteCollection', where=>'ElementName="Logs"'}, 
		profiles			=> {class => 'CIM_ConcreteCollection', where=>'ElementName="Profiles"'}, 
		privileges			=> {class => 'CIM_ConcreteCollection', where=>'ElementName="Privileges"'}, 
		products			=> {class => 'CIM_ConcreteCollection', where=>'ElementName="Products"'}, 
		settings			=> {class => 'CIM_ConcreteCollection', where=>'ElementName="Settings"'}, 
		sensors				=> {class => 'CIM_ConcreteCollection', where=>'ElementName="Sensors"'}, 
		swid				=> {class => 'CIM_SoftwareIdentity'},
		storagepool			=> {class => 'CIM_StoragePool'},
		account				=> {class => 'CIM_Account'},
		job					=> {class => 'CIM_ConcreteJob'},
		jobq				=> {class => 'CIM_JobQueue'},
		log					=> {class => 'CIM_RecordLog'},
		os					=> {class => 'CIM_OperatingSystem'},
		admin				=> {class => 'CIM_AdminDomain'},
		system				=> {class => 'CIM_ComputerSystem'},
		modular				=> {class => 'CIM_ComputerSystem', where=>'OtherDedicatedDescriptions="Modular" and Dedicated="Other"'},
		storage				=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Storage"'},
		router				=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Router"'},
		switch				=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Switch"'},
		hub					=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Hub"'},
		firewall			=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Firewall"'},
		printserver			=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Print"'},
		accessserver		=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Access Server"'},
		ioserver			=> {class => 'CIM_ComputerSystem', where=>'Dedicated="I/O"'},
		webcache			=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Web Caching"'},
		management			=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Management"'},
		blockserver			=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Block Server"'},
		fileserver			=> {class => 'CIM_ComputerSystem', where=>'Dedicated="File Server"'},
		mobile				=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Mobile User Device"'},
		repeater			=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Repeater"'},
		bridge				=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Bridge/Extender"'},
		extender			=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Bridge/Extender"'},
		gateway				=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Gateway"'},
		storagevlizer		=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Storage Virtualizer"'},
		medialib			=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Media Library"'},
		nashead				=> {class => 'CIM_ComputerSystem', where=>'Dedicated="NAS Head"'},
		nas					=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Self-contained NAS"'},
		ups					=> {class => 'CIM_ComputerSystem', where=>'Dedicated="UPS"'},
		ipphone				=> {class => 'CIM_ComputerSystem', where=>'Dedicated="IP Phone"'},
		map					=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Manageability Access Point"'},
		sp					=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Management Controller"'},
		chassismgr			=> {class => 'CIM_ComputerSystem', where=>'Dedicated="Chassis Manager"'},
		alarm				=> {class => 'CIM_AlarmDevice'},
		battery				=> {class => 'CIM_Battery'},
		cd					=> {class => 'CIM_CDROMDrive'},
		cooling				=> {class => 'CIM_CoolingDevice'},
		daport				=> {class => 'CIM_DAPort'},
		diskdrive			=> {class => 'CIM_DiskDrive'},
		floppy				=> {class => 'CIM_DisketteDrive'},
		diskpartition		=> {class => 'CIM_DiskPartition'},
		display				=> {class => 'CIM_Display'},
		dvd					=> {class => 'CIM_DVDDrive'},
		fan					=> {class => 'CIM_Fan'},
		fcport				=> {class => 'CIM_FCPort'},
		heatpipe			=> {class => 'CIM_HeatPipe'},
		ibport				=> {class => 'CIM_IBPort'},
		keyboard			=> {class => 'CIM_Keyboard'},
		disk				=> {class => 'CIM_LogicalDisk'},
		logicalmodule		=> {class => 'CIM_LogicalModule'},
		devicetray			=> {class => 'CIM_LogicalModule', where=>'LogicalModuleType="Device Tray"'},
		linecard			=> {class => 'CIM_LogicalModule', where=>'LogicalModuleType="Line Card"'},
		blademodule			=> {class => 'CIM_LogicalModule', where=>'LogicalModuleType="Blade"'},
		logicalport			=> {class => 'CIM_LogicalPort'},
		mediaaccess			=> {class => 'CIM_MediaAccessDevice'},
		memory				=> {class => 'CIM_Memory'},
		modem				=> {class => 'CIM_Modem'},
		netport				=> {class => 'CIM_NetworkPort'},
		wifiport			=> {class => 'CIM_WirelessPort'},
		enetport			=> {class => 'CIM_EthernetPort'},
		pcidev				=> {class => 'CIM_PCIDevice'},
		pcibridge			=> {class => 'CIM_PCIBridge'},
		pointer				=> {class => 'CIM_PointingDevice'},
		mouse				=> {class => 'CIM_PointingDevice', where=>'PointingType="Mouse"'},
		trackball			=> {class => 'CIM_PointingDevice', where=>'PointingType="Track Ball"'},
		touchpad			=> {class => 'CIM_PointingDevice', where=>'PointingType="Touch Pad"'},
		touchscreen			=> {class => 'CIM_PointingDevice', where=>'PointingType="Touch Screen"'},
		portctlr			=> {class => 'CIM_PortController'},
		nic					=> {class => 'CIM_PortController', where=>'ControllerType="Ethernet"'},
		hca					=> {class => 'CIM_PortController', where=>'ControllerType="IB"'},
		tca					=> {class => 'CIM_PortController', where=>'ControllerType="IB"'},
		hba					=> {class => 'CIM_PortController', where=>'ControllerType="FC"'},
		pwrsupply			=> {class => 'CIM_PowerSupply'},
		printer				=> {class => 'CIM_Printer'},
		cpu					=> {class => 'CIM_Processor'},
		refrigeration		=> {class => 'CIM_Refrigeration'},
		scsiprotctlr		=> {class => 'CIM_SCSIProtocolController'},
		sensor				=> {class => 'CIM_Sensor'},
		currentsensor		=> {class => 'CIM_Sensor', where=>'SensorType="Current"'},
		tachsensor			=> {class => 'CIM_Sensor', where=>'SensorType="Tachometer"'},
		tempsensor			=> {class => 'CIM_Sensor', where=>'SensorType="Temperature"'},
		voltsensor			=> {class => 'CIM_Sensor', where=>'SensorType="Voltage"'},
		countersensor		=> {class => 'CIM_Sensor', where=>'SensorType="Counter"'},
		switchsensor		=> {class => 'CIM_Sensor', where=>'SensorType="Switch"'},
		locksensor			=> {class => 'CIM_Sensor', where=>'SensorType="Lock"'},
		humiditysensor		=> {class => 'CIM_Sensor', where=>'SensorType="Humidity"'},
		airsensor			=> {class => 'CIM_Sensor', where=>'SensorType="Air Flow"'},
		presencesensor		=> {class => 'CIM_Sensor', where=>'SensorType="Presence"'},
		smokesensor			=> {class => 'CIM_Sensor', where=>'SensorType="Smoke Detection"'},
		numsensor			=> {class => 'CIM_NumericSensor'},
		ncurrentsensor		=> {class => 'CIM_NumericSensor', where=>'SensorType="Current"'},
		ntachsensor			=> {class => 'CIM_NumericSensor', where=>'SensorType="Tachometer"'},
		ntempsensor			=> {class => 'CIM_NumericSensor', where=>'SensorType="Temperature"'},
		nvoltsensor			=> {class => 'CIM_NumericSensor', where=>'SensorType="Voltage"'},
		ncountersensor		=> {class => 'CIM_NumericSensor', where=>'SensorType="Counter"'},
		nswitchsensor		=> {class => 'CIM_NumericSensor', where=>'SensorType="Switch"'},
		nlocksensor			=> {class => 'CIM_NumericSensor', where=>'SensorType="Lock"'},
		nhumiditysensor		=> {class => 'CIM_NumericSensor', where=>'SensorType="Humidity"'},
		nairsensor			=> {class => 'CIM_NumericSensor', where=>'SensorType="Air Flow"'},
		npresencesensor		=> {class => 'CIM_NumericSensor', where=>'SensorType="Presence"'},
		nsmokesensor		=> {class => 'CIM_NumericSensor', where=>'SensorType="Smoke Detection"'},
		spiport				=> {class => 'CIM_SPIPort'},
		storagevol			=> {class => 'CIM_StorageVolume'},
		storageext			=> {class => 'CIM_StorageExtent'},
		serialport			=> {class => 'CIM_SerialPort'},
		tapedrive			=> {class => 'CIM_TapeDrive'},
		usbport				=> {class => 'CIM_USBPort'},
		watchdog			=> {class => 'CIM_WatchDog'},
		portctrl			=> {class => 'CIM_PortController'},
		bootsvc				=> {class => 'CIM_BootService'},
		clpsvc				=> {class => 'CIM_CLPService'},
		ipcfgsvc			=> {class => 'CIM_IPConfigurationService'},
		pwrmgtsvc			=> {class => 'CIM_PowerManagementService'},
		shareddevicesvc		=> {class => 'CIM_SharedDeviceManagementService'},
		swinstallsvc		=> {class => 'CIM_SoftwareInstallationService'},
		sshsvc				=> {class => 'CIM_SSHService'},
		storagecfgsvc		=> {class => 'CIM_StorageConfigurationService'},
		telnetsvc			=> {class => 'CIM_TelnetService'},
		textredirectsvc		=> {class => 'CIM_TextRedirectionService'},
		timesvc				=> {class => 'CIM_TimeService'},
		protoendpt			=> {class => 'CIM_ProtocolEndpoint'},
		ipendpt				=> {class => 'CIM_IPProtocolEndpoint'},
		dhcpendpt			=> {class => 'CIM_DHCPProtocolEndpoint'},
		dnsendpt			=> {class => 'CIM_DNSProtocolEndpoint'},
		remotesap			=> {class => 'CIM_RemoteServiceAccessPoint'},
		dnsserver			=> {class => 'CIM_RemoteServiceAccessPoint', where=>'AccessContext="DNS Server"'},
		dhcpserver			=> {class => 'CIM_RemoteServiceAccessPoint', where=>'AccessContext="DHCP Server"'},
		gateway				=> {class => 'CIM_RemoteServiceAccessPoint', where=>'AccessContext="Default Gateway"'},
		lanendpt			=> {class => 'CIM_LANEndpoint'},
		remoteport			=> {class => 'CIM_RemotePort'},
		scsiendpt			=> {class => 'CIM_SCSIProtocolEndPoint'},
		serviceuri			=> {class => 'CIM_ServiceAccessURI'},
		textredirectsap		=> {class => 'CIM_TextRedirectionServiceAccessPoint'},
		pkg					=> {class => 'CIM_PhysicalPackage'},
		bladepkg			=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Blade"'},
		bladexpkg			=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Blade Expansion"'},
		diskpkg				=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Storage Media Package"'},
		fanpkg				=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Fan"'},
		pwrpkg				=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Power Supply"'},
		rackpkg				=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Rack"'},
		chassispkg			=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Chassis/Frame"'},
		framepkg			=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Chassis/Frame"'},
		backplanepkg		=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Crossconnect/Backplane"'},
		sensorpkg			=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Sensor"'},
		modulepkg			=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Module/Card"'},
		cardpkg				=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Module/Card"'},
		batterypkg			=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Battery"'},
		cpupkg				=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Processor"'},
		memorypkg			=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Memory"'},
		storagepkg			=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Storage Media Package"'},
		pwrsrcpkg			=> {class => 'CIM_PhysicalPackage', where=>'PackageType="Power Source/Generator"'},
		frame				=> {class => 'CIM_PhysicalFrame'},
		rack				=> {class => 'CIM_Rack'},
		chassis				=> {class => 'CIM_Chassis'},
		laptop				=> {class => 'CIM_Chassis', where=>'ChassisPackageType="LapTop"'},
		desktop				=> {class => 'CIM_Chassis', where=>'ChassisPackageType="Desktop"'},
		tower				=> {class => 'CIM_Chassis', where=>'ChassisPackageType="Tower"'},
		storagechas			=> {class => 'CIM_Chassis', where=>'ChassisPackageType="Storage Chassis"'},
		notebook			=> {class => 'CIM_Chassis', where=>'ChassisPackageType="Notebook"'},
		mainchassis			=> {class => 'CIM_Chassis', where=>'ChassisPackageType="Main System Chassis"'},
		expansion			=> {class => 'CIM_Chassis', where=>'ChassisPackageType="Bus Expansion Chassis"'},
		peripheralchassis	=> {class => 'CIM_Chassis', where=>'ChassisPackageType="Peripheral Chassis"'},
		subchassis			=> {class => 'CIM_Chassis', where=>'ChassisPackageType="SubChassis"'},
		card				=> {class => 'CIM_Card'},
		buscard				=> {class => 'CIM_SystemBusCard'},
		pcicard				=> {class => 'CIM_SystemBusCard', where=>'BusType="PCI"'},
		eisacard			=> {class => 'CIM_SystemBusCard', where=>'BusType="EISA"'},
		vesacard			=> {class => 'CIM_SystemBusCard', where=>'BusType="VESA"'},
		pcmciacard			=> {class => 'CIM_SystemBusCard', where=>'BusType="PCMCIA" or BusType="PCMCIA Type I" or BusType="PCMCIA Type II" or BusType="PCMCIA Type III"'},
		accesscard			=> {class => 'CIM_SystemBusCard', where=>'BusType="Access.bus"'},
		nubuscard			=> {class => 'CIM_SystemBusCard', where=>'BusType="NuBus"'},
		agpcard				=> {class => 'CIM_SystemBusCard', where=>'BusType="AGP"'},
		vmecard				=> {class => 'CIM_SystemBusCard', where=>'BusType="VME Bus"'},
		pccard				=> {class => 'CIM_SystemBusCard', where=>'BusType="PC-98" or BusType="PC-98-Hireso" or BusType="PC-H98" or BusType="PC-98Note" or BusType="PC-98Full"'},
		pcixcard			=> {class => 'CIM_SystemBusCard', where=>'BusType="PCI-X"'},
		pciecard			=> {class => 'CIM_SystemBusCard', where=>'BusType="PCI-E"'},
		sbuscard			=> {class => 'CIM_SystemBusCard', where=>'BusType="Sbus IEEE 1396-1993 32 bit" or BusType="Sbus IEEE 1396-1993 64 bit"'},
		isacard				=> {class => 'CIM_SystemBusCard', where=>'BusType="ISA"'},
		mcacard				=> {class => 'CIM_SystemBusCard', where=>'BusType="MCA"'},
		giocard				=> {class => 'CIM_SystemBusCard', where=>'BusType="GIO"'},
		xiocard				=> {class => 'CIM_SystemBusCard', where=>'BusType="XIO"'},
		hiocard				=> {class => 'CIM_SystemBusCard', where=>'BusType="HIO"'},
		pmccard				=> {class => 'CIM_SystemBusCard', where=>'BusType="PMC"'},
		ibcard				=> {class => 'CIM_SystemBusCard', where=>'BusType="Infiniband"'},
		component			=> {class => 'CIM_PhysicalComponent'},
		chip 				=> {class => 'CIM_Chip'},
		propchip			=> {class => 'CIM_Chip', where=>'FormFactor="Proprietary Chip"'},
		sip					=> {class => 'CIM_Chip', where=>'FormFactor="SIP"'},
		dip					=> {class => 'CIM_Chip', where=>'FormFactor="DIP"'},
		zip					=> {class => 'CIM_Chip', where=>'FormFactor="ZIP"'},
		soj					=> {class => 'CIM_Chip', where=>'FormFactor="SOJ"'},
		simm				=> {class => 'CIM_Chip', where=>'FormFactor="SIMM"'},
		dimm				=> {class => 'CIM_Chip', where=>'FormFactor="DIMM"'},
		tsop				=> {class => 'CIM_Chip', where=>'FormFactor="TSOP"'},
		pga					=> {class => 'CIM_Chip', where=>'FormFactor="PGA"'},
		rimm				=> {class => 'CIM_Chip', where=>'FormFactor="RIMM"'},
		sodimm				=> {class => 'CIM_Chip', where=>'FormFactor="SODIMM"'},
		srimm				=> {class => 'CIM_Chip', where=>'FormFactor="SRIMM"'},
		smd					=> {class => 'CIM_Chip', where=>'FormFactor="SMD"'},
		ssmp				=> {class => 'CIM_Chip', where=>'FormFactor="SSMP"'},
		qfp					=> {class => 'CIM_Chip', where=>'FormFactor="QFP"'},
		tqfp				=> {class => 'CIM_Chip', where=>'FormFactor="TQFP"'},
		soic				=> {class => 'CIM_Chip', where=>'FormFactor="SOIC"'},
		lc					=> {class => 'CIM_Chip', where=>'FormFactor="LCC"'},
		plcc				=> {class => 'CIM_Chip', where=>'FormFactor="PLCC"'},
		bga					=> {class => 'CIM_Chip', where=>'FormFactor="BGA"'},
		fpbga				=> {class => 'CIM_Chip', where=>'FormFactor="FPBGA"'},
		lga					=> {class => 'CIM_Chip', where=>'FormFactor="LGA"'},
		pmem				=> {class => 'CIM_PhysicalMemory'},
		ram					=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="RAM"'},
		dram				=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="DRAM"'},
		synchdram			=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="Synchronous DRAM"'},
		cache				=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="Cache DRAM"'},
		edo					=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="EDO"'},
		edram				=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="EDRAM"'},
		vram				=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="VRAM"'},
		sram				=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="SRAM"'},
		flash				=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="Flash"'},
		eeprom				=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="EEPROM"'},
		eprom				=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="EPROM"'},
		cdram				=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="CDRAM"'},
		sdram				=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="SDRAM"'},
		sgram				=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="SGRAM"'},
		rdram				=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="RDRAM"'},
		ddr					=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="DDR"'},
		bram				=> {class => 'CIM_PhysicalMemory', where=>'MemoryType="BRAM"'},
		connector			=> {class => 'CIM_PhysicalConnector'},
		slot				=> {class => 'CIM_Slot'},
	};
	$self->{UFContainers}={
		CIM_AdminDomain				=> [{association=>'CIM_OwningCollectionElement', contained=>'CIM_ConcreteCollection'}],
		CIM_ConcreteCollection		=> [{association=>'CIM_MemberOfCollection', contained=>'CIM_PhysicalPackage'}],
		CIM_Rack					=> [{association=>'CIM_ChassisInRack', contained=>'CIM_Chassis'}],
		CIM_Chassis					=> [{association=>'CIM_PackageInChassis', contained=>'CIM_PhysicalPackage'}],
		CIM_PhysicalPackage			=> [{association=>'CIM_Container', contained=>'CIM_PhysicalElement'},
										{association=>'CIM_PackagedComponent', contained=>'CIM_PhysicalComponent'},
										{association=>'CIM_ConnectorOnPackage', contained=>'CIM_PhysicalConnector'}],
		CIM_PhysicalConnector		=> [{association=>'CIM_PackageInConnector', contained=>'CIM_PhysicalPackage'}],
		CIM_Slot					=> [{association=>'CIM_PackageInSlot', contained=>'CIM_PhysicalPackage'},
										{association=>'CIM_CardInSlot', contained=>'CIM_Card'}],
		CIM_Card					=> [{association=>'CIM_CardOnCard', contained=>'CIM_Card'}],
		CIM_AdminDomain				=> [{association=>'CIM_SystemComponent', contained=>'CIM_ComputerSystem'}],
		CIM_ComputerSystem			=> [{association=>'CIM_SystemComponent', contained=>'CIM_ComputerSystem'},
										{association=>'CIM_SystemDevice', contained=>'CIM_LogicalDevice'},
										{association=>'CIM_HostedService', contained=>'CIM_Service'},
										{association=>'CIM_HostedAccessPoint', contained=>'CIM_ServiceAccessPoint'},
										{association=>'CIM_OwningCollectionElement', contained=>'CIM_ConcreteCollection'},
										{association=>'CIM_HostedPool', contained=>'CIM_StoragePool'}],
		CIM_ConcreteCollection		=> [{association=>'CIM_MemberOfCollection', contained=>'CIM_ManagedElement'},
										{association=>'CIM_OrderedMemberOfCollection', contained=>'CIM_ManagedElement'}],
		CIM_BootConfigSetting		=> [{association=>'CIM_ConcreteComponent', contained=>'CIM_SettingData'},
										{association=>'CIM_OrderedComponent', contained=>'CIM_BootSourceSetting'},
										{association=>'CIM_ConcreteComponent', contained=>'CIM_SettingData'}],
		CIM_RecordLog				=> [{association=>'CIM_LogManagesRecord', contained=>'CIM_LogRecord'}],
		CIM_ComputerSystem			=> [{association=>'CIM_HostedJobQueue', contained=>'CIM_JobQueue'}],
		CIM_JobQueue				=> [{association=>'CIM_JobDestinationJobs', contained=>'CIM_ConcreteJob'}],
		CIM_ProtocolEndpoint		=> [{association=>'CIM_BindsTo', contained=>'CIM_ProtocolEndpoint'},
										{association=>'CIM_RemoteAccessAvailableToElement', contained=>'CIM_RemoteServiceAccessPoint'}],
		CIM_EthernetPort			=> [{association=>'CIM_PortImplementsEndpoint', contained=>'CIM_LANEndpoint'}],
		CIM_IPAssignmentSettingData	=> [{association=>'CIM_OrderedComponent', contained=>'CIM_IPAssignmentSettingData'}],
	# Non-standard...
		CIM_RegisteredProfile		=> [{association=>'CIM_ElementConformsToProfile', contained=>'CIM_ComputerSystem'}],
	};
	$self->{uricache}={};

	bless($self, $self->{CLASS});
	return($self);
}

sub instance_of
{
	my $self=shift;
	my $class=shift;
	my $lcc=lc($class);
	my $classref;
	
	if(!defined $class) {
		carp("$self->{CLASS}\->instance_of() called without a class name");
		return;
	}

	if(defined $self->{MODEL}{classes}{$lcc}) {
		$classref=$self->{MODEL}{classes}{$lcc};
	}
	elsif(defined $self->{MODEL}{associations}{$lcc}) {
		$classref=$self->{MODEL}{associations}{$lcc};
	}
	elsif(defined $self->{MODEL}{indications}{$lcc}) {
		$classref=$self->{MODEL}{indications}{$lcc};
	}
	if(!defined $classref) {
		# Now, if there is a GetClass() method, invoke it and add the class to the
		# model.
		my $cl=$self->GetClass($class);
		if(defined $cl && $cl->{name} eq lc($class)) {
			if($cl->{qualifiers}{association} eq 'true') {
				$self->{MODEL}{associations}{lc($cl->{name})}=$cl;
			}
			elsif($cl->{qualifiers}{indication} eq 'true') {
				$self->{MODEL}{indications}{lc($cl->{name})}=$cl;
			}
			else {
				$self->{MODEL}{classes}{lc($cl->{name})}=$cl;
			}
			return $self->instance_of($cl->{name});
		}
		else {
			carp("Unknown class '$class' requested from $self->{CLASS}");
			return;
		}
	}

	my $instance=DMTF::CIM::Instance->new(class=>$classref,parent=>$self);
	return($instance);
}

sub class_tag_alias
{
	my $self=shift;
	my $class=shift;
	my $lcc=lc($class);
	my $alias=shift;

	if(defined $self->{MODEL}{classes}{$lcc}) {
		$class=$self->{MODEL}{classes}{$lcc}{name};
	}
	elsif(defined $self->{MODEL}{associations}{$lcc}) {
		$class=$self->{MODEL}{associations}{$lcc}{name};
	}
	elsif(defined $self->{MODEL}{indications}{$lcc}) {
		$class=$self->{MODEL}{indications}{$lcc}{name};
	}
	if(defined $alias) {
		my $lc=lc($alias);
		if(defined $self->{UFcT}{$lc} && $self->{UFcT}{$lc}{class} ne $class) {
			carp("Illegal attempt to overwrite definition of UFcT $lc ($self->{UFcT}{$lc}{class}) with $class");
		}
		else {
			$self->{UFcT}{$lc}{class}=$class;
		}
	}
	else {
		foreach my $check_alias (keys %{$self->{UFcT}}) {
			if($self->{UFcT}{$check_alias}{class} eq $class) {
				next if lc($class) eq $check_alias;
				next if defined $self->{UFcT}{$check_alias}{where};
				$alias=$check_alias;
				last;
			}
		}
		$alias = $class unless defined $alias;
	}
	return $alias;
}

sub cache_uri_class
{
	my $self=shift;
	my $uri=shift;

	if($uri =~ m|(?:(?:[^:/?#]+):)?(?://(?:[^/?#]*))?([^?#]*)(?:\?(?:[^#]*))?(?:#(?:.*))?|) {
		my $path=$1;
		if($path=~/^[^:]*?:([^.]+?)\./) {
			my $class=$1;
			$self->class_tag_alias($class, lc($class));
		}
	}
}

sub resolve_class_tag {
	my $self=shift;
	my %args=@_;
	$args{assoc}=0 if(!defined $args{assoc});

	if(!defined $args{tag}) {
		carp("$self->{CLASS}\->resolve_class_tag() requires a tag argument.");
		return;
	}

	my $lcc=lc($args{tag});
	# First, check the class tag aliases.
	if(defined $self->{UFcT}{$lcc} && defined $self->{UFcT}{$lcc}{class}) {
		return $self->{UFcT}{$lcc}{class};
	}

	# Next, check for an exact model match
	if(defined $self->{MODEL}{classes}{$lcc}) {
		$self->class_tag_alias($self->{MODEL}{classes}{$lcc}{name}, lc($self->{MODEL}{classes}{$lcc}{name}));
		return $self->{MODEL}{classes}{$lcc}{name};
	}
	elsif(defined $self->{MODEL}{associations}{$lcc}) {
		$self->class_tag_alias($self->{MODEL}{associations}{$lcc}{name}, lc($self->{MODEL}{associations}{$lcc}{name}));
		return $self->{MODEL}{associations}{$lcc}{name};
	}
	elsif(defined $self->{MODEL}{indications}{$lcc}) {
		$self->class_tag_alias($self->{MODEL}{indications}{$lcc}{name}, lc($self->{MODEL}{indications}{$lcc}{name}));
		return $self->{MODEL}{indications}{$lcc}{name};
	}

	# Now we assume we're working with incomplete data... either the model
	# is missing the specified class, or the class tag alias is undefined.
	# Since CIM classes are in the SCHEMA_Name format, if there is no
	# underscore, it is not a missing class, and must be a missing tag.
	if($args{tag} !~ /_/) {
		carp("Invalid UFcT $args{tag}");
		return;
	}

	# Now, if there is a GetClass() method, invoke it and add the class to the
	# model.
	my $class=$self->GetClass($args{tag});
	if(defined $class && $class->{name} eq lc($args{tag})) {
		if($class->{qualifiers}{association} eq 'true') {
			$self->{MODEL}{associations}{lc($class->{name})}=$class;
		}
		elsif($class->{qualifiers}{indication} eq 'true') {
			$self->{MODEL}{indications}{lc($class->{name})}=$class;
		}
		else {
			$self->{MODEL}{classes}{lc($class->{name})}=$class;
		}
		$self->class_tag_alias($class->{name}, lc($class->{name}));
		return $class->{name};
	}

	# Still don't have the class name.  Try to enumerate associated/association
	# instances to find correct capitalization.

	my @uri_list;
	my %enum_args;
	$enum_args{via}=$args{via} if(defined $args{via});
	if(defined $args{uri}) {
		$enum_args{uri}=$args{uri};
	}
	else {
		$enum_args{uri}='/interop';
	}
	$enum_args{class}=$args{tag} if(defined $args{tag});
	my $uri_has_instance=0;
	$uri_has_instance=1 if($enum_args{uri} =~ /:[^.]+\..*$/);
	if($uri_has_instance) {
		if($args{assoc}) {
			delete $enum_args{class};
			@uri_list=$self->GetReferencingInstancePaths(%enum_args);
		}
	}
	elsif($uri_has_instance) {
		if(!$args{assoc}) {
			@uri_list=$self->GetAssociatedInstancePaths(%enum_args);
		}
	}
	else {
		@uri_list=$self->GetClassInstancePaths(%enum_args);
	}

	foreach my $uri (@uri_list) {
		$self->cache_uri_class($uri);
	}
	if(defined $self->{UFcT}{lc($args{tag})} && defined $self->{UFcT}{lc($args{tag})}{class}) {
		return $self->{UFcT}{lc($args{tag})}{class};
	}
	carp("Unable to resolve $args{tag}");
	return;
}

sub normalize_path
{
	my $self=shift;
	my $path=shift;

	# Change all sequences of slashes and backslashes to a single slash
	$path=~s/[\/\\]+/\//g;

	# Remove trailing /
	$path =~ s|/$||g;

	# Remove /.
	while($path =~ s|(.)/\./|$1/|g){};

	# Remove /.=
	while($path =~ s|(.)/\.=|$1=|g){};

	# Remove trailing /.
	$path =~ s|(/\.)+$||g;

	# Remove /XXX/..
	while($path =~ s|/[^/.]+/\.\./|/|g){};

	# Remove /Thing.Thing/..
	while($path =~ s|/[^/.]+\.[^/]*/\.\./|/|g){};

	# Remove /Thing.Thing/..
	while($path =~ s|/[^/]*\.[^/.]*/\.\./|/|g){};

	# Remove /.../..
	while($path =~ s|/\.{3,}/\.\./|/|g){};

	# Remove trailing /XXX/..
	while($path =~ s|/[^/]+/\.\.$||g){};

	# Zero-length becomes root.
	if($path eq '') {
		$path='/';
	}

	return $path;
}

sub UFiP_to_URI {
	my $self=shift;
	my $UFP=shift;
	my $rooturi=shift;
	if(!defined $rooturi) {
		$rooturi=$self->{uricache}{'/'} if(defined $self->{uricache}{'/'});
	}

	if(!defined $rooturi) {
		carp("$self->{CLASS}\->UFiP_to_URI() called with no root URI specified");
		return;
	}
	my $currenturi=$rooturi;
	my $currentpath='';
	my @repsonse;
	my @urilist;
	my $loops=0;

	# Normalize...
	$UFP=$self->normalize_path($UFP);
	if($UFP !~ m|^/|) {
		carp "Path error: Path $UFP is not absolute";
		return;
	}

	# Now fix up associations (ie: path to association instance)
	$UFP =~ s|=>|/-=|g;

	# Now, split on slashes...
	my @elements=split(/\//, $UFP);
	# And remove the root....
	shift @elements;

	while(my $element = shift(@elements)) {
		my $targetclass;
		my $targetisassoc=0;
		my $tag;
		my $id;
		my $via;

		push @urilist,$currenturi;

		if($element =~ /^(-=)?(.+?)([0-9*]*)$/) {
			$tag=$2;
			$id=$3;

			if(defined $1 && $1 eq '-=') {
				$targetisassoc=1;
			}

			if(!defined $id || $id eq '' && $#elements != -1) {
				# Really?  You expect people to understand that error message?
				carp("Invalid Path - contains non-terminal UFcT");
				return;
			}
			if($3 eq '*' && $#elements != -1) {
				# Really?  You expect people to understand that error message?
				carp("Invalid Path - contains non-terminal wildcard");
				return;
			}
		}
		else {
			carp("Impossible error... $element did not match /^(-=)?(.+?)([0-9*]*)\$/");
			return;
		}

		$targetclass=$self->resolve_class_tag(tag=>$tag, uri=>$currenturi, assoc=>$targetisassoc, via=>$via);

		if(!defined $targetclass) {
			return;
		}

		my $pathelement="$tag$id";
		if($targetisassoc) {
			$currentpath .= "=>$pathelement";
		}
		else {
			if($currentpath =~ /=>[^\/]+$/) {
				$currentpath .= "=>$pathelement";
			}
			else {
				$currentpath .= "/$pathelement";
			}
		}

		my $nametag=$currentpath;
		$nametag =~ s/[0-9*]+$//;
		if(!defined $id || $id eq '') {
			my($scheme, $authority, $path, $query, $fragment) = $currenturi =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;
			$path =~ s/:.*$//;
			$currenturi='';
			if(defined $scheme && $scheme ne '' && defined $authority && $authority ne '') {
				$currenturi="$scheme://$authority";
			}
			$currenturi.="$path:$targetclass";
		}
		elsif($id eq '*') {
			my @new_urilist;
			if($targetisassoc) {
				@new_urilist=$self->GetReferencingInstancePaths(uri=>$currenturi, class=>$targetclass, via=>$via); 
			}
			else {
				@new_urilist=$self->GetAssociatedInstancePaths(uri=>$currenturi, class=>$targetclass, via=>$via); 
			}
			foreach my $i (0..$#new_urilist) {
				$self->{uricache}{$nametag.($i+1)}=$new_urilist[$i];
				$self->cache_uri_class($new_urilist[$i]);
			}
			return [@new_urilist];
		}
		else {
			# Now get the nth match.
			if(!defined $self->{uricache}{$currentpath}) {
				my @new_urilist;

				if($targetisassoc) {
					@new_urilist=$self->GetReferencingInstancePaths(uri=>$currenturi, class=>$targetclass, via=>$via); 
				}
				else {
					@new_urilist = $self->GetAssociatedInstancePaths(uri=>$currenturi, class=>$targetclass, via=>$via); 
				}
				foreach my $i (0..$#new_urilist) {
					$self->{uricache}{$nametag.($i+1)}=$new_urilist[$i];
					$self->cache_uri_class($new_urilist[$i]);
				}
			}
			if(!defined $self->{uricache}{$currentpath}) {
				carp("Invalid UFiS specified at end of $currentpath");
				return;
			}
			$currenturi=$self->{uricache}{$currentpath};

			foreach my $turi (@urilist) {
				if($turi eq $currenturi) {
					$loops++;
				}
			}
		}
	}

	carp "Path error: Instance loop detected." if $loops;
	return $currenturi;
}

sub clear_uri_cache
{
	my $self=shift;
	$self->{uricache}={};
}

sub cache_uri_path
{
	my $self=shift;
	my $path=shift;
	my $uri=shift;
	$self->{uricache}{$path}=$uri;
}

sub parse_mof
{
	my $self=shift;
	my $path=shift;
	my $clear=shift || 0;
	require DMTF::CIM::MOF;

	if(defined $DMTF::CIM::MOF::{parse_MOF}) {
		$self->{MODEL} = DMTF::CIM::MOF::parse_MOF($path, $clear?undef:$self->{MODEL});
	}
}

###########################
# Generic Operation Stubs #
###########################
sub GetClass
{
	return;
}

sub GetInstance
{
	return;
}

sub ModifyInstance
{
	return;
}

sub DeleteInstance
{
	return;
}

sub CreateInstance
{
	return;
}

sub GetClassInstancePaths
{
	return;
}

sub GetReferencingInstancePaths
{
	return;
}

sub GetAssociatedInstancePaths
{
	return;
}

sub GetClassInstancesWithPath
{
	return;
}

sub GetReferencingInstancesWithPath
{
	return;
}

sub GetAssociatedInstancesWithPath
{
	return;
}

sub InvokeMethod
{
	return;
}

#####################
# Friendly Wrappers #
#####################
sub get
{
	my $self=shift;
	return $self->GetInstance(@_);
}

sub put
{
	my $self=shift;
	return $self->ModifyInstance(@_);
}

sub delete
{
	my $self=shift;
	return $self->DeleteInstance(@_);
}

sub create
{
	my $self=shift;
	return $self->CreateInstance(@_);
}

sub class_uris
{
	my $self=shift;
	return $self->GetClassInstancePaths(@_);
}

sub associations
{
	my $self=shift;
	return $self->GetReferencingInstancePaths(@_);
}

sub associated
{
	my $self=shift;
	return $self->GetAssociatedInstancePaths(@_);
}

sub class_instances
{
	my $self=shift;
	return $self->GetClassInstancesWithPath(@_);
}

sub association_instances
{
	my $self=shift;
	return $self->GetReferencingInstancesWithPath(@_);
}

sub associated_instances
{
	my $self=shift;
	return $self->GetAssociatedInstancesWithPath(@_);
}

sub invoke
{
	my $self=shift;
	return $self->InvokeMethod(@_);
}

1; # Magic true value required at end of module
__END__

=head1 NAME

DMTF::CIM - Object Orieted Interface to a CIM Schema


=head1 VERSION

This document describes DMTF::CIM version 0.04


=head1 SYNOPSIS

  use DMTF::CIM;
  my $cim = DMTF::CIM->new();
  $cim->parse_mof( "/path/to/cim_schema_2.31.0.mof" );
  my $system = $cim->instance_of( 'cim_system' );
  $cim->class_tag_alias( 'CIM_LogEntry', 'entry' );
  $cim->resolve_target_class_tag( tag=>'sometag' [,assoc=>1] [,uri=>'/interop:CIM_RegisteredProfile.InstanceID=magic'] [,via=>'CIM_ElementConformsToProfile'])
  $uri = $cim->UFiP_to_URI( '/system1', 'wsman.wbem://interop:CIM_RegisteredProfile.InsanceID=EX' );
  $cim->clear_uri_cache()
  $cim->cache_uri_path( '/',
  $cim->GetClass(arg=>value...);
  $cim->GetInstance(arg=>value...); (get)
  $cim->ModifyInstance(arg=>value...); (put)
  $cim->CreateInstance(arg=>value...); (create)
  $cim->DeleteInstance(arg=>value...); (delete)
  $cim->GetClassInstancePaths(arg=>value...); (class_uris)
  $cim->GetClassInstancesWithPath(arg=>value...); (class_instances)
  $cim->GetReferencingInstancePaths(arg=>value...); (associations)
  $cim->GetReferencingInstancesWithPath(arg=>val...); (association_instances)
  $cim->GetAssociatedInstancePaths(arg=>value...); (associated)
  $cim->GetAssociatedInstancesWithPath(arg=>value...); (associated_instances)
  $cim->InvokeMethod(arg=>value...); (invoke)


=head1 DESCRIPTION

The DMTF::CIM class provides object-oriented access to a CIM schema and,
when created using a protocol module such as DMTF::CIM::WSMan, permits
the use of DSP0223 generic operations against a target.


=head1 INTERFACE 

=head2 METHODS

=over

=item C<< instance_of( I<name> ); >>

Returns a new DMTF::CIM instance of CIM_System (the name is case
insensitive).  Refer to L<DMTF::CIM::Instance> for details of the
returned object.

=item C<< class_tag_alias( I<class> [, I<alias>] ); >>

Returns the first or adds a new UFcT (User-Friendly class Tag) alias for use in UFiPs
(User-Friendly instance Paths).  The first argument is the CIM class
name in the normal capitalization (if the class is known, the
capitalization is corrected if needed).  After the alias is added,
future UFiPs may include the specified tag.  Aliases may not be
changed, only added.  Refer to
L<DSP0215|http://www.dmtf.org/sites/default/files/standards/documents/DSP0215_1.0.0.pdf>
for details on the UFiP syntax.

If the alias is not specified and the class cannot be resolved, returns the
class name as translated.

=item C<< resolve_target_class_tag( tag=>I<sometag> [,assoc=>I<bool>] [,uri=>I<instance_uri>] [,via=>I<class>]) >>

Converts a UFcT to a CIM class name.  Returns undef on failure.
The first source of information is the class tag alias list.  If the
tag is not in this list, and a session is associated with the object, will
attempt to use the GetClass() method to retrieve the class definition
and add it to the internal mode.  Failing this, will attempt to
enumerate via association traversal using the rest of the arguments.
as follows:

=over

=item C<< uri=>I<string> >>

Specifies the WEBEM URI to use as the reference point.  If the URI
is a namespace URI (ie: no colon), association traversal will not
be attempted.  The default URI is '/interop'.

=item C<< assoc=>I<bool> >> (defaults to zero)

This boolean value indicates if the tag is an association class.
If it is, GetReferencingInstancePaths() will be used.  If not,
GetAssociatedInstancePaths() will be.

=item C<< via=>I<string> >>

The class name of the association instance when assoc=>0 (ie:
when GetAssociatedInstancePaths() is used).

If this fails as well, will attempt to use the GetClassInstancePaths()
operation from the namespace specified in the uri argument then, if
the GetClassInstancePaths() operation is not defined by the binding
class, will use GetAllInstancePaths().

After any enumeration of this type, all returned class names will be
cached as UFcTs so that the operation will not need to occur again.

=back

=item C<< UFiP_to_URI( I<UFiP>, I<root_uri> ) >>

Converts a full UFiP (argument 1) into a WBEM URI using the 
GetReferencingInstancePaths() and GetAssociatedInstancePaths()
methods (if available).  The results are cached so that future lookups
of the same path in the same context will not need to use the
underlying protocol.  The second argument is a WBEM URI to the root
instance.  If the second argument is unspecified, attempts to used
the value cached for '/' in the URI cache.

For a UFiP which ends with a UFsT of '*', returns an arrayref.

=item C<< clear_uri_cache() >>

Removes all entries from the URI cache used by the UFiP_to_URI()
method.

=item C<< cache_uri_path( I<path>, I<uri> ); >>

Adds an entry to the URI cache.  The first argument is the path and
the second argument is the URI to cache.

=item C<< parse_mof( I<path> [, I<clear>] ) >>

Parsed a MOF file into an internal data model.  If clear is false (the default)
the current model is added to.  If clear is true, the current model is deleted, and
the MOf file loaded in its place.

=item C<< GetClass( I<arg=E<gt>value>... ); >>

=item C<< GetInstance( I<arg=E<gt>value>... ); >> (get)

Available args:

=over

=over

=item IncludeClassOrigin (ico)

=item IncludeQualifiers (iq)

=item InstancePath (uri)

=item IncludedProperties (props)

=back

=back

=item C<< ModifyInstance I<arg=E<gt>value>... ); >> (put)

Available args:

=over

=over

=item IncludeClassOrigin (ico)

=item IncludeQualifiers (iq)

=item ModifiedInstance (object)

=item InstancePath (uri)

=item IncludedProperties (props)

=back

=back

=item C<< CreateInstance( I<arg=E<gt>value>... ); >> (create)

Available args:

=over

=over

=item IncludeClassOrigin (ico)

=item IncludeQualifiers (iq)

=item ClassPath (uri)

=item NewInstance (object)

=back

=back

=item C<< DeleteInstance( I<arg=E<gt>value>... ); >> (delete)

Available args:

=over

=over

=item IncludeClassOrigin (ico)

=item IncludeQualifiers (iq)

=item InstancePath (uri)

=back

=back

=item C<< GetClassInstancePaths( I<arg=E<gt>value>... ); >> (class_uris)

Available args:

=over

=over

=item IncludeClassOrigin (ico)

=item IncludeQualifiers (iq)

=item EnumClassPath (uri)

=back

=back

=item C<< GetClassInstancesWithPath( I<arg=E<gt>value>... ); >> (class_instances)

Available args:

=over

=over

=item IncludeClassOrigin (ico)

=item IncludeQualifiers (iq)

=item EnumClassPath (uri)

=item IncludedProperties (props)

=item ExcludeSubclassProperties (esp)

=back

=back

=item C<< GetReferencingInstancePaths( I<arg=E<gt>value>... ); >> (associations)

Available args:

=over

=over

=item IncludeClassOrigin (ico)

=item IncludeQualifiers (iq)

=item SourceInstancePath (uri)

=item AssociationClassName (via)

=item AssociatedClassName (class)

=item SourceRoleName (role)

=item AssociatedRoleName (rrole)

=back

=back

=item C<< GetReferencingInstancesWithPath( I<arg=E<gt>value>... ); >> (association_instances)

Available args:

=over

=over

=item IncludeClassOrigin (ico)

=item IncludeQualifiers (iq)

=item SourceInstancePath (uri)

=item AssociationClassName (via)

=item AssociatedClassName (class)

=item SourceRoleName (role)

=item AssociatedRoleName (rrole)

=item IncludedProperties (props)

=item ExcludeSubclassProperties (esp)

=back

=back

=item C<< GetAssociatedInstancePaths( I<arg=E<gt>value>... ); >> (associated)

Available args:

=over

=over

=item IncludeClassOrigin (ico)

=item IncludeQualifiers (iq)

=item SourceInstancePath (uri)

=item AssociationClassName (via)

=item AssociatedClassName (class)

=item SourceRoleName (role)

=item AssociatedRoleName (rrole)

=back

=back

=item C<< GetAssociatedInstancesWithPath( I<arg=E<gt>value>... ); >> (associated_instances)

Available args:

=over

=over

=item IncludeClassOrigin (ico)

=item IncludeQualifiers (iq)

=item SourceInstancePath (uri)

=item AssociationClassName (via)

=item AssociatedClassName (class)

=item SourceRoleName (role)

=item AssociatedRoleName (rrole)

=item IncludedProperties (props)

=item ExcludeSubclassProperties (esp)

=back

=back

=item C<< InvokeMethod( I<arg=E<gt>value>... ); >> (invoke)

Available args:

=over

=over

=item IncludeClassOrigin (ico)

=item IncludeQualifiers (iq)

=item InstancePath (uri)

=item MethodName (method)

=item InParmValues (params)

=back

=back

=back

These methods function as the documented Generic operation in 
L<DSP0223|http://www.dmtf.org/sites/default/files/standards/documents/DSP0223_1.0.0_1.pdf>
available from the DMTF web site.  The name in paranthesis after is a
short alias.

=head2 OBJECTS

All returned objects will have a common set of methods.

=over

=item C<< parent >>

Returns the parent object which created this object.

=item C<< name >>

Returns the name of the object as specified in the model.

=item C<< is_array ( I<property> ) >>

Returns a true value equal to the length of the array if the named property
is an array or 0 otherwise.  A zero-length array returns '0 but true'

=item C<< is_ref ( I<property> ) >>

Returns true if the named property is a reference or false otherwise.

=item C<< map_value ( I<value> ) >>

If the object has a valuemap, will return the value from the map for a specific
"raw" value.

=item C<< unmap_value ( I<value> ) >>

If the object has a valuemap, will return the raw value associated with
the map for a specific value.  Will return the value unmodified if there is
no match, but may return a range in the "X..Y" format where X and Y are
optional minimum and maximum values respectively.

=item C<< type ( I<property> ) >>

Returns the type name of the specified property.  If the property is an
array, will have '[]' appended.  For properties which have no type information
in the instance, the type is assumed to be 'string'.

CIM types as of this writing are:

=over

=item uint8

=item uint16

=item uint32

=item uint64

=item sint8

=item sint16

=item sint32

=item sint64

=item real32

=item real64

=item string

=item char16

=item boolean

=item datetime

=back

The name of the target class, or 'ref' is returned for references.

=item C<< qualifier( I<name> ) >>

Returns the value of the qualifier with I<name>.

=back

Additionaly, some objects (properties and parameters) can have a value.
Valued objects have the following additional methods:

=over

=item C<< value ( [ I<newvalue> ] ) >>

If the I<newvalue> list is specified, sets the value to that.  Returns the
current mapped value.  If the property is an array, and the method is used
in a scalar context, the values are join(', ')ed.

The return value is has been passed through the map_value() method.  When a
value is set, it will first pass through the unmap_value() method.  It is not
reccomended to use value($new) for setting mapped values as some values may
unmap to a range and cause an error.

=item C<< raw_value ( [ I<newvalue> ] ) >>

If the I<newvalue> list is specified, sets the value to that.  Returns the
current unmapped value.  If the property is an array, and the method is used
in a scalar context, the values are join(', ')ed.

=back

=head1 DIAGNOSTICS

This module will carp() on errors and return undef or an empty list.

=head1 CONFIGURATION AND ENVIRONMENT

DMTF::CIM requires no configuration files or environment variables.


=head1 DEPENDENCIES

DMTF::CIM::Instance (available from the same location as this module)

DMTF::CIM::MOF (available from the same location as this module) is required to call the parse_mof() method.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-dmtf-cim@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Stephen James Hurd  C<< <shurd@broadcom.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Broadcom Corporation C<< <shurd@broadcom.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
