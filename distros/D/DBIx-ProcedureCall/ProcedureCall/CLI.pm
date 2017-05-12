package DBIx::ProcedureCall::CLI;

require Exporter;
@ISA = qw[ Exporter];
@EXPORT = qw [ procedure function ];

use DBI;
use DBIx::ProcedureCall;
use Data::Dumper;
use strict;
use warnings;

our $VERSION = '0.08';

sub conn{
	my ($dsn) = @_;
	my $conn = DBI->connect($dsn, undef, undef, { 
		RaiseError => 1, AutoCommit => 1, PrintError => 0,
	});

}


sub get_bind_array{
	my @a = @ARGV;
	foreach (@a){
		# if it starts with a colon, make a reference
		if (index ($_, ':') == 0 ){
			my $var;
			($_ , $var ) = split '=', $_, 2;
			$_ =  \$var;
		}
	}
	return @a;
}

sub procedure{
	my $dsn;
	$dsn = shift @ARGV if $ARGV[0] =~ /^dbi:/;
	$ARGV[0] =~ s/:fetch\(\)/:fetch[]/;
	my $dbh = conn($dsn);
	my @a = get_bind_array;
	eval{ 
		DBIx::ProcedureCall::run($dbh, @a);
		print "executed procedure '$ARGV[0]'. \n";
	};
	if ($@){
		warn "failed to execute procedure '$ARGV[0]':\n";
		warn "-----------------------\n";
		warn $@;
		warn "-----------------------\n";
		return;
	}
	print_out_params(@a);
	
}

sub function{
	my $dsn;
	$dsn = shift @ARGV if $ARGV[0] =~ /^dbi:/;
	my $dbh = conn($dsn);
	my @a = get_bind_array;
	# change :fetch() to :fetch[]
	$ARGV[0] =~ s/:fetch\(\)/:fetch[]/;
	my $result;
	eval{ 
		$result = DBIx::ProcedureCall::run($dbh, @a);
		print "executed function '$ARGV[0]'. \n";
	};
	if ($@){
		warn "failed to execute function '$ARGV[0]':\n";
		warn "-----------------------\n";
		warn $@;
		warn "-----------------------\n";
		return;
	}
	
	print "------ result -----------\n";
	if (ref $result ){
		print Dumper $result;
		if (ref $result eq 'ARRAY'){
			print scalar @$result;
			print " rows returned \n";
		}
	}else{
		print $result;
		print "\n";
	}
	print "------------------------\n";
	print_out_params(@a);
}


sub print_out_params{
	# skip procedure name
	shift;
	my $output = "";
	my $i = 0;
	foreach (@_){
		$i++;
		next unless ref $_;
		$ARGV[$i] =~ s/=.+//;
		$output .= "$ARGV[$i] = ";
		$output .= defined $$_ ? $$_ : '<null>';
		$output .= "\n";
	}
	return unless $output;
	print "------ parameters -------\n";
	print $output;
	print "------------------------\n";
}
1;

__END__



=head1 NAME

DBIx::ProcedureCall::CLI - command line interface to DBIx::ProcedureCall

=head1 SYNOPSIS

	# get DSN for environment variables DBI_DSN
	 perl -MDBIx::ProcedureCall::CLI -e function sysdate
	 
	 # specify DSN on command line
	 perl -MDBIx::ProcedureCall::CLI -e function dbi:Oracle:.... sysdate
	 
	 # parameters 
	 perl -MDBIx::ProcedureCall::CLI -e procedure dbms_random.initialize 12345
	  
	 # OUT parameters
	 perl -MDBIx::ProcedureCall::CLI -e procedure foo :bar
	
	 # IN/OUT parameters
	 perl -MDBIx::ProcedureCall::CLI -e procedure foo :bar=99

=head1 DESCRIPTION

This is a command line interface to DBIx::ProcedureCall.
It connects to the database (using either DBI environment variables or a DSN given as 
the first parameter), runs a stored procedure or function, and prints
the return value (if any).

Run it like this:

	perl -MDBIx::ProcedureCall::CLI -e <function or procedure> [DSN] <procedure name> [parameters ...]

=head2 Procedures and functions

DBIx::ProcedureCall needs to know if you are about
to call a function or a procedure (because the SQL is different).
So you have to use either "function" or "procedure".


=head2 Parameters

All arguments after the procedure name are used
as parameters when calling the stored procedure.

Only positional parameters are supported (no named parameters).

=head3 IN parameters

Unless the argument starts with a colon(:), it is used as
a literal parameter value.

=head3 OUT parameters

If the argument starts with a colon (like :blah), the program
creates a bind variable with that name, which can be used
to receive OUT parameter values from the procedure.

=head3 IN/OUT parameters

IN/OUT parameters are OUT parameters with an initial 
value, that is specifed like 

	:blah=foo


=head2 Attributes

You can specify optional attributes for the stored procedure
you want to call.

This is mostly useful for functions that return result sets, 
where you need to specify :fetch.

Please see L<DBIx::ProcedureCall> for details.


=head2 Connection parameters

The easiest way to specify the DNS, username and password
to connect is to use the three DBI environment variables
DBI_DSN, DBI_USER and DBI_PASS.

You can also specify the DSN as an optional argument
before the procedure name:

 	perl -MDBIx::ProcedureCall::CLI -e function dbi:Oracle:.... sysdate


=head1 LIMITATIONS

Because of the way the optional DSN is detected, you cannot call
a procedure called dbi and apply attributes to it.

Because of the way OUT parameters are specified,
you cannot use strings starting with a colon (:) as parameters
to the stored procedures.

You cannot specify how you want to bind the parameters.
They will all be bound using the defaults of the DBI driver
(usually VARCHAR). In most case, this works fine.

=head1 AUTHOR

Thilo Planz, E<lt>thilo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Thilo Planz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
