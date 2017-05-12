#
# $Id: test.pl,v 1.2 2002/09/03 18:26:11 jaldhar Exp $
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test::More tests => 6;
BEGIN { use_ok('Acme::Brainfuck', qw/verbose/) };

my $a = +++[>+++<-]> ;
ok ( $a == 9, ' Do + - < > [ ] work?');

$a = "\t";
tie *STDIN, 'Tie::Handle::Scalar', \$a;
my $b = , ;
ok ( $b == 9, ' Does , work?');
untie *STDIN;

$a = '';
tie *STDOUT, 'Tie::Handle::Scalar', \$a;
..
ok ( $a eq "\t\t", ' Does . work?');
untie *STDOUT;

$a = '';
tie *STDERR, 'Tie::Handle::Scalar', \$a;
#
ok ( $a eq "\$p = 1 \$m[\$p]= 9\n", ' Does # work?');
untie *STDERR;

$a = ~ ;
ok ( $a == 0, ' Does ~ work?');

no Acme::Brainfuck;

#
#  This is Tie::Handle::Scalar
#  It is reproduced in full here as it isn't a core module so it may not
#  be installed everywhere.
#

package Tie::Handle::Scalar;
use base 'Tie::Handle';
use Carp;
use FileHandle;

sub TIEHANDLE {
	my $class = bless {}, shift;

	my ($stringref) = @_;

	if (! defined($stringref)) {
		my $temp_s = '';
		$stringref = \$temp_s;
	}

	if (ref($stringref) ne "SCALAR") {
		croak "need a reference to a scalar,";
	}

	$class->{position} = 0;
	$class->{data} = $stringref;
	$class->{end} = 0;
	my $tmpfile = $class->{tmpfile} = '.tmp.' . $$;
	$class->{fh} = new FileHandle "$tmpfile", 
		O_RDWR|O_CREAT or croak "$tmpfile: $!";
	$class->{FILENO} = $class->{fh}->fileno();
	$class;
}

sub FILENO {
	my $class = shift;
	return $class->{FILENO};
}

sub WRITE {
	my $class = shift;
	my($buf,$len,$offset) = @_;
        $offset = 0 if (! defined $offset);
    	my $data = substr($buf, $offset, $len);
    	my $n = length($data);
    	$class->print($data);
        return $n;
}

sub PRINT {
	my $class = shift;
        ${$class->{data}} .= join('', @_);
    	$class->{position} = length(${$class->{data}});
    	1;
}

sub PRINTF {
	my $class = shift;
	my $fmt = shift;
	$class->PRINT(sprintf $fmt, @_);
}

sub READ {
	my $class = shift;

	my ($buf,$len,$offset) = @_;
    	$offset = 0 if (! defined $offset);

    	my $data = ${ $class->{data} };

    	if ($class->{end} >= length($data)) {
		return 0;
	}
	$buf = substr($data,$offset,$len);
        $_[0] = $buf;
        $class->{end} += length($buf);
        return length($buf);
}

sub READLINE {
	my $class = shift;
	if ($class->{end} >= length(${ $class->{data} })) {
		return undef;
	}
	my $recsep = $/;
	my $rod = substr(${ $class->{data} }, $class->{end}, -1);
	$rod =~ m/^(.*)$recsep{0,1}/; # use 0,1 for line sep to include possible no \n on last line
	my $line = $1 . $recsep;
	$class->{end} += length($line);
	return $line;
}

sub CLOSE {
	my $class = shift;
	if (-e $class->{tmpfile}) {
		$class->{fh}->close();
		unlink $class->{tmpfile} or warn $!;
	}
	$class = undef;
	1;
}

sub DESTROY {
	my $class = shift;
	if (-e $class->{tmpfile}) {
		unlink $class->{tmpfile} or warn $!;
	}
	$class = undef;
	1;undef $class;
}


