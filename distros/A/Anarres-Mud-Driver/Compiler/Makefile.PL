require 5.006001;
use ExtUtils::MakeMaker;

my @base = qw(lexer parser utils Compiler);
my @obj = map { "$_\.o" } @base;
my @src = map { "$_\.c" } @base;
my @hdr = qw(compiler.h parser.h);

WriteMakefile(
    NAME			=> 'Anarres::Mud::Driver::Compiler',
    VERSION_FROM	=> 'Compiler.pm', # finds $VERSION
    AUTHOR			=> 'Shevek (cpan@anarres.org)',
	INC				=> '-I../include',
	OBJECT			=> "@obj",
	C				=> \@src,
	H				=> \@hdr,

	# Remove this and let it inherit for production
	# OPTIMIZE		=> '-O2 -g -Wall',

	clean			=> {
				FILES	=> "lex.yy.c " .
							"parser.output parser.tab.[ch] ",
						},
	# Removed lexer.c, parser.[ch] from clean because I should
	# distribute them for people who don't have lex.
);

sub MY::postamble {
	my $self = shift;
	my $old = $self->MM::postamble(@_);
	chomp($old);

	my $lex = $ENV{LEX} || 'flex';
	my $yacc = $ENV{YACC} || 'bison';

	my $new = <<"EON";

LEX = $lex
YACC = $yacc
EON
	$new .= <<'EON';

%.c : %.yy
	$(LEX) $*.yy
	$(PERL) symchange.pl lex.yy.c > $*.c
	$(RM_F) lex.yy.c

%.c %.h : %.y
	$(YACC) -vd $*.y
	$(PERL) symchange.pl $*.tab.c > $*.c
	$(PERL) symchange.pl $*.tab.h > $*.h
	$(RM_F) $*.tab.[ch]

dep : $(C_FILES) $(H_FILES)
	$(RM_F) .depend
	$(CC) -MM $(INC) -I$(PERL_INC) $(CCFLAGS) $(C_FILES) >> .depend

include .depend

config :: $(C_FILES)

EON
	return $old . $new;
}
