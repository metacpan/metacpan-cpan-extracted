package Acme::Test::Pr0n;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

use vars qw($AUTOLOAD);

sub new {
	 my ($proto,$conf) = @_;
	 my $class = ref($proto) || $proto;
	 my $self = {};
	 bless($self,$class);

	 croak "File not supplied" unless defined $conf->{'filename'};
	 croak "Could not read $conf->{filename}" unless -r $conf->{'filename'};

	 $self->{'filename'} = $conf->{'filename'};

	 # should use IO::File or something
	 local undef $/;
	 open(FH,$self->{'filename'}) or croak("Could not open file $!");
	 $self->{'file'} = <FH>;
	 close(FH);

	 return $self;
}

sub DESTROY{}

sub AUTOLOAD {
	my $self = shift;
	my $flags = shift || undef;
	my $name = $AUTOLOAD;
	$name =~ s/.*://;

	my $clean_string; # store file with all other chars removed
	my $num;

	if($flags && $flags eq 'i') {
 		($clean_string = $self->{'file'}) =~ s/([^$name]+)//gi;
		if($clean_string) {
			$num = ($clean_string =~ s/$name/x/gi);
		}
	} else {
 		($clean_string = $self->{'file'}) =~ s/([^$name]+)//g;
		if($clean_string) {
			$num = ($clean_string =~ s/$name/x/g);
		}
	}

	return 0 unless $num;
	return $num;
}

1;
__END__

=head1 NAME

Acme::Test::Pr0n - Perl extension for wasteing your time.

=head1 SYNOPSIS

  use Test::More tests => 3;
  use Acme::Test::Pr0n;

  my $filename = '/any/old/text/file.txt';

  my $pr0n_test = Acme::Test::Pr0n->new({
    'filename' => $filename,
  });

  ok($pr0n_test->pr0n() > 5,
             'The string pr0n is hidden in the file more than 5 times');  

  ok($pr0n_test->XXX() > 4,
             'The string XXX is hidden in the file more than 4 times');

  ok($pr0n_test->XXX('i') > 4,
             'The string XXX is hidden in the file more than 4 times
              without beinge case sensative');

  
=head1 DESCRIPTION

This test object has been inspired by Schwern and advanced testing,
a conversation on IRC and a reference to Schwern and pr0n. 
Having written it I realise it's not very pr0n specific but
I'm sure it will be abused properly.

Any thing can be tested for, just make up the method name
and pass in a 'i' if you want it case insensitive.

=head2 THANKS

Simon Wilcox, Schwern, LPM, my mum and dad, everyone who knows me..

=head1 AUTHOR

Leo Lapworth <lt>llap@cuckoo.org<gt>

=head1 SEE ALSO

L<perl>.

=cut
