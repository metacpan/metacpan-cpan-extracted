#!/usr/bin/perl

$data = {
	Footer => [
		{
			'footer text' =>'Footer'
		},
	],
	Header => [
		{
			'header text' =>'Header 1',
			'Header Inside' => [
				{
					'inside header' =>'Header Inside 1',
				},
				{
					'inside header' =>'Header Inside 2',
				},
			],
			'Header Inside Not Found' => [
				{
					'inside header' =>'3rd header not found',
				},
			],
		},
	],
	'template file' => 'Template File is "t/test.tpl"',
	'file required' => 'Required File is "CGI::okTemplate.pm"',
};

1;
