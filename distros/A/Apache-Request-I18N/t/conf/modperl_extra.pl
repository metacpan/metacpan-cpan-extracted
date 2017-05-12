use Apache;

BEGIN {
	if (eval { require Apache::Reload }) {
		Apache->push_handlers(PerlInitHandler => \&Apache::Reload::handler);
	}
}


1;

