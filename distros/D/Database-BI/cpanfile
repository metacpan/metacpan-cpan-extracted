# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.020000';

requires 'CGI::Info';
requires 'CGI::Lingua', '0.85';
requires 'CHI';
requires 'Carp';
requires 'DBI';
requires 'Database::Abstraction', '0.44';
requires 'Database::Join', '0.004.0';
requires 'File::Spec', '3.40';
requires 'File::Temp', '0.22';
requires 'HTML::D3', '0.18';
requires 'HTML::TableExtract';
requires 'IPC::System::Simple';   # For autodie (:all) in DataSource.pm at runtime
requires 'LWP::UserAgent';
requires 'LWP::UserAgent::Cached';
requires 'List::Util', '1.40';
requires 'Mojo::Base';
requires 'Mojo::JSON';
requires 'Mojolicious', '9.49';
requires 'Mojolicious::Plugin::TemplateToolkit';
requires 'Net::SFTP::Foreign';
requires 'Params::Get';
requires 'Params::Validate::Strict', '0.39';
requires 'Readonly';
requires 'Socket', '2.010';
requires 'Spreadsheet::ParseXLSX';
requires 'Sub::Protected';

on 'test' => sub {
	requires 'DBD::CSV';
	requires 'Encode';
	requires 'Excel::Writer::XLSX';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird';
	requires 'Test::Mojo';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::Returns';
	requires 'Test::Without::Module';
	requires 'Text::xSV::Slurp';
	requires 'XML::Simple';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
