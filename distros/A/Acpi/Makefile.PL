use ExtUtils::MakeMaker;

WriteMakefile(
		'NAME'	 => 'Acpi',
		'PM'	 => {
			'Battery.pm'	=> '$(INST_LIBDIR)/Acpi/Battery.pm',
			'Temperature.pm'	=> '$(INST_LIBDIR)/Acpi/Temperature.pm',
			'Fan.pm'	=> '$(INST_LIBDIR)/Acpi/Fan.pm',
			'Field.pm'	=> '$(INST_LIBDIR)/Acpi/Field.pm',
			},
		'VERSION_FROM'	=> 'Battery.pm',
);
					  
		 
