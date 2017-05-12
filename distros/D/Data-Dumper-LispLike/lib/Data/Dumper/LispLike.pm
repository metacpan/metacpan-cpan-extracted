use strict;
use warnings;

package Data::Dumper::LispLike;
# ABSTRACT: Dump perl data structures formatted as Lisp-like S-expressions

use Exporter ();
our @ISA = qw(Exporter);
our @EXPORT = qw(&dumplisp);
our $VERSION = '0.004'; # VERSION


our $indent = "    ";


our $maxsimplewidth = 60;

our %escapes = (
	"\a"	=> '\a',
	"\b"	=> '\b',
	"\e"	=> '\e',
	"\f"	=> '\f',
	"\n"	=> '\n',
	"\r"	=> '\r',
	"\t"	=> '\t',
	"\\"	=> "\\\\",
);

sub dumplisp_scalar($) {
	1 == @_ or die;
	my $scalar = shift;
	die unless defined($scalar) and not ref($scalar);
	unless( $scalar =~ /^[\w\-%\/,\!\?=]+$/ ) {
		$scalar =~
			s/([^\w\-%\/,\!\?=\`~@#\$^&*\(\)+\[\]\{\}\|;:"\.<> ])/
			$escapes{$1} || sprintf '\x%X', ord $1/eg;
		$scalar = "'$scalar'";
	}
	return $scalar;
}

sub dumplisp_iter($;$$);
sub dumplisp_iter($;$$) {
	1 == @_ or 2 == @_ or 3 == @_ or die;
	my ($lisp, $level, $maxlength) = @_;
	$level ||= 0;
	$maxlength = $maxsimplewidth unless defined $maxlength;
	my $simple = ( $level < 0 );
	my $out = $simple ? "" : "\n" . ( $indent x $level );
	if( not defined $lisp ) {
		return "$out<undef>";
	} elsif( not ref $lisp ) {
		return $out . dumplisp_scalar $lisp;
	} elsif( 'ARRAY' eq ref $lisp ) {
		my @l = @$lisp;
		if( not @l ) {
			$out .= "(";
		} elsif( $simple ) {
			$out .= "(";
			my $first = 1;
			foreach my $current ( @l ) {
				$out .= " " unless $first;
				undef $first;
				$out .= dumplisp_iter( $current, -1, $maxlength - length $out );
				die if $simple and length $out > $maxlength;
			}
		} else { # not $simple and @l not empty
			my $try_add = eval {
				dumplisp_iter( $lisp, -1, $maxlength );
			};
			if( defined($try_add) and length($try_add) <= $maxlength ) {
				return $out . $try_add;
			}
			$out .= "(";
			if( defined($l[0]) and not ref($l[0]) ) {
				$out .= dumplisp_scalar shift @l;
			}
			$out .= dumplisp_iter( $_, $level + 1 ) foreach @l;
		}
		return "$out)";
	} else {
		die "cannot dumplisp " . ref($lisp) . "\n";
	}
}


sub dumplisp($) {
	1 == @_ or die "Usage: dumplisp(<expression>)\n";
	my $out = dumplisp_iter shift;
	chomp $out;
	$out =~ s/^\n//;
	return "$out\n";
}

1;


__END__
=pod

=head1 NAME

Data::Dumper::LispLike - Dump perl data structures formatted as Lisp-like S-expressions

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Data::Dumper::LispLike;
    print dumplisp [ 1, 2, [3, 4] ]; # prints "(1 2 (3 4))\n";

=head1 ATTRIBUTES

=head2 $Data::Dumper::LispLike::indent

Indentation string. Default is "    " (four spaces).

=head2 $Data::Dumper::LispLike::maxsimplewidth

Maximum width of s-expression that is considered "simple",
i.e. that fits into one line and does not need to be split
into many lines. Default is 60.

=head1 FUNCTIONS

=head2 dumplisp()

    my $listref = ...;
    print dumplisp $listref;

This function converts an C<ARRAYREF>, which may contain strings or other
C<ARRAYREF>s, into Lisp-like S-expressions. The output is much compacter
and easier to read than the output of C<Data::Dumper>.

=for Pod::Coverage method_names_here

=head1 EXAMPLE

Here is a bigger real-life example of dumplisp() output:

    (COMMA
        (AND
            (CMDDEF -writeln (%str) (BLOCK (CMDRUN -write '%str\n')))
            (CMDDEF -writeln1 (%STR) (BLOCK (CMDRUN -write1 '%STR\n')))
            (CMDDEF
                -warn
                (%WARN_MESSAGE)
                (BLOCK (CMDRUN -warnf '%WARN_MESSAGE\n')))
            (CMDDEF -abort () (BLOCK (CMDRUN -exit 1)))
            (CMDDEF
                -die
                (%DIE_MESSAGE)
                (BLOCK (COMMA (CMDRUN -warn %DIE_MESSAGE) (CMDRUN -abort))))
            (IF
                (OPTION
                    (COMPARE != %UNAME/SYSNAME Linux)
                    (CMDRUN -die 'pfind is only for linux')))
            (CMDDEF -kill () (BLOCK (CMDRUN -signal KILL)))
            (CMDDEF -term () (BLOCK (CMDRUN -signal TERM)))
            (CMDDEF -hup () (BLOCK (CMDRUN -signal HUP)))
            (CMDDEF -ps () (BLOCK (CMDRUN -exec ps uf '{}')))
            (CMDDEF
                pso
                (%PS_FIELDS)
                (BLOCK (CMDRUN -exec ps '\q-o' %PS_FIELDS '{}')))
            (CMDDEF -exe (%exe_arg) (BLOCK (COMPARE == %exe %exe_arg)))
            (CMDDEF -cwd (%cwd_arg) (BLOCK (COMPARE == %cwd %cwd_arg)))
            (ASSIGN %vsz %statm/size)
            (ASSIGN %rss %statm/resident)
            (CMDDEF -kthread () (BLOCK (COMPARE == 0 %rss)))
            (CMDDEF -userspace () (BLOCK (NOT (CMDRUN -kthread))))
            (ASSIGN %ppid %stat/ppid)
            (ASSIGN %comm %stat/comm)
            (ASSIGN %nice %stat/nice)
            (ASSIGN
                %nice_flag
                (CONDITIONAL
                    (OPTION (COMPARE -lt %nice 0) '<')
                    (OPTION (COMPARE -gt %nice 0) N)
                    (DEFAULT '')))
            (ASSIGN %s %stat/state)
            (ASSIGN %state %s%nice_flag)
            (ASSIGN %name %status/Name)
            (CMDDEF
                -grep
                (%GREP_ARG)
                (BLOCK
                    (OR
                        (COMPARE -m %exe '*%GREP_ARG*')
                        (COMPARE -m %comm '*%GREP_ARG*')
                        (COMPARE -m %name '*%GREP_ARG*'))))
            (CMDDEF
                -egrep
                (%EGREP_ARG)
                (BLOCK
                    (OR
                        (COMPARE '=~' %exe %EGREP_ARG)
                        (COMPARE '=~' %comm %EGREP_ARG)
                        (COMPARE '=~' %name %EGREP_ARG))))
            (ASSIGN %command %tree%name)
            (CMDDEF
                -pstree
                ()
                (BLOCK
                    (AND
                        (CMDRUN -settree)
                        (CMDRUN -echo %ppid %pid %state %command)))))
        (AND
            (BLOCK (OR (CMDRUN -userspace) (COMPARE == %pid 23)))
            (CMDRUN -head 10)
            (CMDRUN -echo %pid %ppid %stat/ppid)
            (CMDRUN -ps)))

=head1 SUPPORT

L<http://github.com/spiculator/data-dumper-lisplike>

=head1 AUTHOR

Sergey Redin <sergey@redin.info>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sergey Redin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

