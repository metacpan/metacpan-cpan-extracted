
###
###  Copyright 2002-2003 University of Illinois Board of Trustees
###  Copyright 2002-2003 Mark D. Roth
###  All rights reserved.
###
###  Makefile.PL - configuration rules for Config::Objective
###
###  Mark D. Roth <roth@uiuc.edu>
###  Campus Information Technologies and Educational Services
###  University of Illinois at Urbana-Champaign
###


use ExtUtils::MakeMaker;


sub MY::postamble
{
	return '
lib/Config/Objective/Parser.pm: grammar.yp
	yapp -m Config::Objective::Parser grammar.yp && mv Parser.pm lib/Config/Objective/Parser.pm

';
}


WriteMakefile(
	'NAME'		=> 'Config::Objective',
	'DISTNAME'	=> 'Config-Objective',
	'VERSION_FROM'	=> 'lib/Config/Objective.pm',
	'PREREQ_PM'	=> {
				Parse::Lex		=> 2.15,
				Parse::Yapp::Driver	=> 1.05
			   },
	'PM'		=> {
				'lib/Config/Objective.pm'
					=> '$(INST_LIB)/Config/Objective.pm',
				'lib/Config/Objective/Boolean.pm'
					=> '$(INST_LIB)/Config/Objective/Boolean.pm',
				'lib/Config/Objective/DataType.pm'
					=> '$(INST_LIB)/Config/Objective/DataType.pm',
				'lib/Config/Objective/Hash.pm'
					=> '$(INST_LIB)/Config/Objective/Hash.pm',
				'lib/Config/Objective/Integer.pm'
					=> '$(INST_LIB)/Config/Objective/Integer.pm',
				'lib/Config/Objective/List.pm'
					=> '$(INST_LIB)/Config/Objective/List.pm',
				'lib/Config/Objective/Parser.pm'
					=> '$(INST_LIB)/Config/Objective/Parser.pm',
				'lib/Config/Objective/String.pm'
					=> '$(INST_LIB)/Config/Objective/String.pm',
				'lib/Config/Objective/Table.pm'
					=> '$(INST_LIB)/Config/Objective/Table.pm'
			   },
	'clean'		=> {
				FILES => 'lib/Config/Objective/Parser.pm'
			   },
	'MAN3PODS'	=> {
				'lib/Config/Objective.pm'
					=> '$(INST_MAN3DIR)/Config::Objective.3',
				'lib/Config/Objective/Boolean.pm'
					=> '$(INST_MAN3DIR)/Config::Objective::Boolean.3',
				'lib/Config/Objective/DataType.pm'
					=> '$(INST_MAN3DIR)/Config::Objective::DataType.3',
				'lib/Config/Objective/Hash.pm'
					=> '$(INST_MAN3DIR)/Config::Objective::Hash.3',
				'lib/Config/Objective/Integer.pm'
					=> '$(INST_MAN3DIR)/Config::Objective::Integer.3',
				'lib/Config/Objective/List.pm'
					=> '$(INST_MAN3DIR)/Config::Objective::List.3',
				'lib/Config/Objective/String.pm'
					=> '$(INST_MAN3DIR)/Config::Objective::String.3',
				'lib/Config/Objective/Table.pm'
					=> '$(INST_MAN3DIR)/Config::Objective::Table.3'
			   },
	## Add these new keywords supported since 5.005
	($] >= 5.005 ? (
	'ABSTRACT_FROM'	=> 'lib/Config/Objective.pm',
	'AUTHOR'	=> 'Mark D. Roth <roth@uiuc.edu>')
	: ()),
);

