// shortcuts to various I/O objects
PERLVAR(I, stdingv,	GV *)		//  *STDIN
PERLVAR(I, stderrgv,	GV *)		//  *STDERR
PERLVAR(I, argvgv,	GV *)		//  *ARGV
PERLVAR(I, argvoutgv,	GV *)		//  *ARGVOUT
PERLVAR(I, argvout_stack, AV *)

// shortcuts to regexp stuff
PERLVAR(I, replgv,	GV *)		//  *^R

// shortcuts to misc objects
PERLVAR(I, errgv,	GV *)		//  *@

// shortcuts to debugging objects
PERLVAR(I, DBgv,	GV *)		//  *DB::DB
PERLVAR(I, DBline,	GV *)		//  *DB::line
