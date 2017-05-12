use warnings;
use strict;

use Carp;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Benchmark qw(:all);

use BoutrosLab::TSVStream::Format::AnnovarInput::Human::Fixed;
use BoutrosLab::TSVStream::Format::None::Dyn;

# BoutrosLab::TSVStream::Format::None::Dyn->meta->make_immutable;

my $datastart = tell DATA;

sub process {
	my $class = shift;
	my $rargs = shift // [];
	my $wargs = shift // [];
	seek DATA, 0, $datastart;
	my $reader = $class->reader(
		handle => \*DATA,
		@$rargs,
	);
	my $writer = $class->writer(
		file => '/dev/null',
		@$wargs,
	);
	while (my $rec = $reader->read) {
		$writer->write($rec);
	}
}

sub hprocess {
	my $class = shift;
	my $rargs = shift // [];
	my $wargs = shift // [];
	seek DATA, 0, $datastart;
	open my $outfh, '>', '/dev/null';
	while (<DATA>) {
		chomp;
		s/^\s+//;
		s/\s+$//;
		my $rec = FakeHuman->new( split "\t" );
		print $outfh join(
			"\t",
			map { $rec->$_ } qw(chr start end ref alt)
		);
	}
}

timethese( 100000, {
	Dyn        => sub {
					process(
						'BoutrosLab::TSVStream::Format::None::Dyn',
						undef,
						[ dyn_fields => [ qw(chr start end ref alt) ] ],
					) },
	HumanFixed => sub { process( 'BoutrosLab::TSVStream::Format::AnnovarInput::Human::Fixed' ) },
	Hash       => sub { hprocess( ) },
});

package FakeHuman;

sub _validchr {
	my $self = shift;
	my $chr = shift;
	$chr =~ s/^chr//;
	return 1 if $chr =~ /[XYM]/;
	return 0 unless $chr =~ /^\d+$/;
	return $chr >= 0 && $chr <= 21;
}

sub _validpos {
	my $self = shift;
	my $pos = shift;
	return $pos =~ /^\d+$/;
}

sub _validref {
	my $self = shift;
	my $ref = shift;
	return 1 if $ref eq '-';
	return $ref =~ /^[CAGT]+$/ && length($ref) <= 500;
}

sub new {
	my $class = shift;
	$class = ref $class || $class;
	my $self = {};
	bless $self, $class;
	die "wrong number of values" unless @_ == 5;
	for my $meth ( qw(chr start end ref alt) ) {
		$self->$meth(shift);
	}
}

sub chr {
	my $self = shift;
	if (@_) {
		my $chr = shift;
		$self->_validchr($chr);
		$self->{chr} = $chr;
	}
	else {
		$self->{chr};
	}
}

sub start {
	my $self = shift;
	if (@_) {
		my $start = shift;
		$self->_validpos($start);
		$self->{start} = $start;
	}
	else {
		$self->{start};
	}
}

sub end {
	my $self = shift;
	if (@_) {
		my $end = shift;
		$self->_validpos($end);
		$self->{end} = $end;
	}
	else {
		$self->{end};
	}
}

sub ref {
	my $self = shift;
	if (@_) {
		my $ref = shift;
		$self->_validref($ref);
		$self->{ref} = $ref;
	}
	else {
		$self->{ref};
	}
}

sub alt {
	my $self = shift;
	if (@_) {
		my $alt = shift;
		$self->_validref($alt);
		$self->{alt} = $alt;
	}
	else {
		$self->{alt};
	}
}

__END__
chr	start	end	ref	alt
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr1	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
chr2	1	2	CA	GT
