package Aion::Env;

use common::sense;

our $VERSION = "0.2";

use constant {};

our %env = %{ -e '.env'? parse('.env'): () };

sub import {
    my ($cls, $name, %kw) = @_;
    my $isa = delete $kw{isa};
    my $is_default = exists $kw{default};
    my $default = delete $kw{default};
    die sprintf "Unknown aspect%s: %s",
    	scalar keys %kw == 1? '': 's',
     	join ", ", sort keys %kw if keys %kw;
      
    die "$name is'nt defined!" if !exists $ENV{$name} && !exists $env{$name} && !$is_default;

    my $pkg = caller;
    my $val = $ENV{$name} // $env{$name} // $default;

    if($isa) {
   		if(UNIVERSAL::isa($isa, "Aion::Type")) { $isa->validate($val, $name) }
    	else {
	    	local $_ = $val;
	    	die UNIVERSAL::can($isa, "get_message")? $isa->get_message($val): "$name type is'nt isa!" unless $isa->();
		}
    }
    
    constant->import("$pkg\::$name", $val);
}

my $BOM = "\x{feff}";
sub parse {
    my ($file) = @_;
    open my $f, '<:utf8', $file or die "$file: $!";

    my %env;
    my $interpolate = sub {
    	$_[0] =~ s!\$\{(\w+)\}!$env{$1}!ge;
    };
     
    while(<$f>) {
    	s/^$BOM// if $. == 1;
        next if /^\s*(?:#|$)/;
        
        if(my ($k, $v) = /^\s*([a-z_]\w*)\s*=\s*(.*?)\s*$/i) {
            if($v =~ s/^(['"])(.*)\1\z/$2/) {
            	if($1 eq '"') {
	                $v =~ s/\\n/\n/g;
	                $v =~ s/\\//g;
					$interpolate->($v);
                }
            }
            else { $interpolate->($v) }
            $env{$k} = $v;
        }
        else {
        	my $message = "Can't parse $file line $.: $_";
            close $f;
            die $message;
        }
    }

    close $f;
    
    \%env
};

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Env - creates a constant associated with the value from .env

=head1 VERSION

0.2

=head1 SYNOPSIS

.env file:

	BIN_TEST=10
	OCT_TEST=${BIN_TEST}20



	BEGIN {
		delete @ENV{qw/BIN_TEST OCT_TEST BB_TEST NN_TEST/};
	
		$ENV{UNI_TEST} = 30;
	}
	
	sub Int { sub { /^-?\d+$/ } }
	
	use Aion::Env BIN_TEST => (isa => Int);
	use Aion::Env OCT_TEST => (isa => Int);
	use Aion::Env UNI_TEST => (isa => Int);
	use Aion::Env BB_TEST => (isa => Int, default => 1);
	
	BIN_TEST; # -> 10
	OCT_TEST; # -> 1020
	UNI_TEST; # -> 30
	BB_TEST; # -> 1
	
	eval 'use Aion::Env NN_TEST => ()'; $@; # ^-> NN_TEST is'nt defined!
	eval 'use Aion::Env NN_TEST => (nouname => 1)'; $@; # ^-> Unknown aspect: nouname
	eval 'use Aion::Env NN_TEST => (nouname1 => 1, nouname2 => 2)'; $@; # ^-> Unknown aspects: nouname1, nouname2

=head1 DESCRIPTION

Projects use the C<.env> configuration file for project configuration, in C<Makefile>, for C<docker> and C<docker compose>. This module allows you to design environment variables as constants of C<perl> modules.

Constants are initialized from C<%ENV>, if there is no value there or it is C<undef>, then from the C<.env> file, and if it is not there, from the C<default> option.

When parsing a file, a syntax error will result in an exception.

The type of an environment variable can be checked using the C<isa> option. It accepts a subroutine or object with the C<${}> operator overloaded. In this case, the value will be passed to C<$_>. If the object has a C<validate> method, like C<Aion::Type>, then it will be called with parameters: the value and name of the environment variable.

It is recommended to name environment variables using the name of the module in which it is declared. For example, the package is C<Aion::Type>, then the names of the environment variables in it are C<AION_TYPE_*>.

=head1 SUBROUTINES

=head2 import ($cls, $name, %kw)

Creates a constant with the name C<$name> in the package from which it is called.
Optionally, you can pass C<isa> and C<default> to C<%kw>.

=head2 parse ($file)

Parses a file in C<.env> format and returns a hash with variables from it.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Env module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
