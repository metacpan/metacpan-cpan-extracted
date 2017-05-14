# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { $| =1; plan tests => 2 };
use Class::Maker;
use Class::Maker::Generator;
use IO::Extended qw(:all);

use XML::Generator;

ok(1);				# If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

printf "Current directory %s\n", Class::Maker::Generator->dir();

my $xml = XML::Generator->new( escape => 'always', pretty => 4, conformance => 'strict' );

my $markup = $xml->class( { name => 'Employee' },
			  
			  $xml->info( 'Stores employee data' ),
			  
			  $xml->uses(

				     $xml->use( 'Class::Maker qw(:all)' ),
				     $xml->use( 'Data::Dumper' ),
				     $xml->use( 'IO::Extended qw(:all)' ),

				    ),

			  $xml->dependencies(

					     $xml->dependency( 'Object' ),
					     $xml->dependency( 'Object::Serializable::XML' ),
					     $xml->dependency( 'Object::Serializable::HTML' ),

					    ),

			  $xml->parents(

					$xml->parent( { name => 'Object', visibility => 'public', href => 'Object.xml' } ),

				       ),

			  $xml->properties(

					   $xml->property( { name => 'Name', type => 'string', has_data => 'true' } ),
					   $xml->property( { name => 'Firstname', type => 'string', has_data => 'true', is_unique => 'true' } ),
					   $xml->property( { name => 'SSN', type => 'int' } ),

					  ),

			  $xml->methods(

					$xml->method( { name => 'increase_salary', type => 'void' },
						      
						      $xml->params(
								   $xml->param( { name => 'percent', type => '$' } ),
								   $xml->param( { name => 'names', type => '@' } ),
								  ),
						    ),

					$xml->method( { name => 'decrease_salary', type => 'void' } ),

				       ),

			  $xml->functions(

					  $xml->function( { name => 'to_xml' },

							  $xml->params(
								       $xml->param( { name => 'pretty', type => '$' } ),
								       $xml->param( { name => 'infos', type => '@' } ),
								      ),
							),

					  $xml->function( { name => 'to_html' } ),

					 ),

			);

my $gen = Class::Maker::Generator->new( source => 'src/perl/Employee.xml', type => 'FILE' );

println "Your binary is at ", $gen->whereami, "\n";

use Data::Dumper;

println Dumper $gen;

println $gen->dir;

$gen->output;

#$gen->type = 'SCALAR';

#$gen->source = $markup;

#print $gen->output;

#$gen->lang = 'cpp';

#print $gen->output;

ok(1);

#$gen->lang = 'python';
#print $gen->output;

#$gen->stylesheet( 'xml/perl/sqlTable.xsl' );
#print FILE $gen->output( $source );
#my $gen = Code::Generator->new( file => 'xml/cpp/sources/Employee.xml' );
#$gen->stylesheet( 'xml/cpp/CppClass.xsl' );
#open( CPP, '>Employee.cpp' ) or die $!;
#print CPP $gen->output();

__END__

<?xml version="1.0"?>
<class name="Employee">
	<info>Stores employee data</info>
	<uses>
		<use>class qw(:all)</use>
		<use>Data::Dumper</use>
		<use>IO::Extended qw(:all)</use>
	</uses>
	<dependencies>
		<dependency>Object</dependency>
		<dependency>Object::Serializable::XML</dependency>
		<dependency>Object::Serializable::HTML</dependency>
	</dependencies>
	<parents>
		<parent name="Object" visibility="public" href="Object.xml"/>
		<parent name="Object::Serializable" visibility="public" href="Object_serializer.xml"/>
	</parents>
	<properties>
		<property name="Name" type="string" has_data="true"/>
		<property name="Firstname" type="string" has_data="true" is_unique="true"/>
		<property name="SSN" type="int"/>
		<property name="Salary" type="double"/>
	</properties>
	<methods>
		<method name="increaseSalary" type="void">
			<params>
				<param name="percent" type="$"/>
				<param name="names" type="@"/>
			</params>
		</method>
		<method name="decreaseSalary" type="void"/>
		<method name="calculateSalaray" type="void" proto="$">
			<params>
				<param name="percent" type="$"/>
				<param name="names" type="@"/>
			</params>
		</method>
	</methods>
	<functions>
		<function name="to_xml" type="func">
			<params>
				<param name="percent" type="$"/>
				<param name="names" type="@"/>
			</params>
		</function>
		<function name="to_html">
			<params>
				<param name="format" type="$"/>
				<param name="names" type="@"/>
			</params>
		</function>
	</functions>
</class>
