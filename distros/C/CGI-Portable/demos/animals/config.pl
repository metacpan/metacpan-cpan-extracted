my $rh_prefs = {
	title => 'Welcome to DemoAardvark',
	credits => '<P>This program copyright 2001 Darren Duncan.</P>',
	screens => {
		one => {
			'link' => 'Fill Out A Form',
			mod_name => 'DemoTiger',
			mod_prefs => {
				field_defs => [
					{
						visible_title => "What's your name?",
						type => 'textfield',
						name => 'name',
					}, {
						visible_title => "What's the combination?",
						type => 'checkbox_group',
						name => 'words',
						'values' => ['eenie', 'meenie', 'minie', 'moe'],
						default => ['eenie', 'minie'],
						rows => 2,
					}, {
						visible_title => "What's your favorite colour?",
						type => 'popup_menu',
						name => 'color',
						'values' => ['red', 'green', 'blue', 'chartreuse'],
					}, {
						type => 'submit', 
					},
				],
			},
		},
		two => {
			'link' => 'Fly Away',
			mod_name => 'DemoOwl',
			mod_prefs => {
				fly_to => 'http://www.perl.com',
			},
		}, 
		three => {
			'link' => 'Don\'t Go Here',
			mod_name => 'DemoCamel',
			mod_subdir => 'files',
			mod_prefs => {
				priv => 'private.txt',
				prot => 'protected.txt',
				publ => 'public.txt',
			},
		},
		four => {
			'link' => 'Look At Some Files',
			mod_name => 'DemoPanda',
			mod_prefs => {
				food => 'plants',
				color => 'black and white',
				size => 'medium',
				files => [qw( priv prot publ )],
				file_reader => '/three',
			},
		}, 
	},
};
