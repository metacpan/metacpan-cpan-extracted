package BugCli::Help;

push @Term::Shell::ISA, __PACKAGE__
  unless grep { $_ eq __PACKAGE__ } @Term::Shell::ISA;

sub help_bugs {
    <<'END';
    	Syntax: bugs [query_name]
		bugs /regexp/
		bugs
		
	Runs a query on the datatabase, works with predefined queries and
	with regexp on the subject of the bug.

	Add a query by typing 'config query.query_name'
	View a list of defined queries just by typing 'bugs'
END
    
}

sub help_changelog {
	<<'END';
	Syntax: changelog range [-f] [-o outfile]
		
	This command will display a changelog for yours bugs for specified range.

	Format of the range is simple:
	[d/w/y]-[number]
	'number' means how many steps to take back
	'd/w/y'  means 'day/week/year'
	For example, I want to see all closed bugs since last year: 'y-1'
	Or all closed bugs in two last weeks: 'w-2',
	Or all closed bugs this week: 'w-0'
	
        '-f' will enable a verbose mode for display (it will show comments aswell)
	'-o' parameter will set the file to write to

END
} 

sub help_fix {
	<<'END';
	Syntax: fix bug_id [comment]
		
	Set's bug status to FIXED, and adds a comment supplied in command line.
	If not comment supplied, the program will ask for one.
	
	Pressing TAB will enable completion of bug-id's from the last query

END
}

sub help_comment {
	<<'END';
	Same as 'fix', but only adds a comment to a bug, without changing status.
END
}

sub help_take {
	<<'END';
	Same as 'fix', but adds a comment, and assigns a bug to you, changing status to ASSIGNED
END
}

sub help_config {
	<<'END';
	Syntax: config
		config [categorie]
		config [categorie.value]
		config show
		config show [categorie]
		config show [categorie.value]
		
	This beast takes care of all the configuration and customization of the program.
	'config' will run you through complete reconfiguration of the program.
	'config [categorie]' will run you through reconfiguration of this part of program
	'config [categorie.value]' reconfigures specific value of some categorie
	'config show' will display all current settings
	'config show [categorie]' will display specific categorie of settings
	'config show [categorie.value]' same, but more specific.

	All commands support tab-completion which will help you to see what options are there
	to be re-configured.
END
}

sub help_history {
	<<'END';
	Syntax: history

	This will display the list of most recently typed commands.
END
}

sub help_delete {
    <<'END';
	Syntax: delete [bug_id] [options]

	Deletes a bug from database by it's ID.
        Pressing tab will show you the bug_ids from the last query that you've ran.

	Options:

	-f	Force delete. If Specified, no questions are asked. Use with care!
END
}

sub help_show {
    <<'END';
  Syntax:  show [bug_id]
           show /regexp/

  Pressing tab will show you the bug_ids from the last query that you've ran.
  Supplying /regexp/ will show all bugs matching it in the subject
END
}

1;

