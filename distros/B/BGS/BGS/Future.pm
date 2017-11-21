package BGS::Future;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(future);

our $VERSION = '0.12';

use overload '&{}' => sub { my $self = shift; sub { $self->join() } };

use BGS ();

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = BGS::_bgs_call($_[0]);

	bless $self, $class;
	return $self;
}


sub join {
	my $self = shift;
	if (exists $$self{result}) {
		return $$self{result};
	} else {
		BGS::bgs_wait($$self{vpid});
		return $$self{result};
	}
}


sub cancel {
	my $self = shift;
	BGS::bgs_break($$self{vpid});
}


sub future(&) {
	__PACKAGE__->new($_[0]);
}


1;


__END__


=head1 NAME

BGS::Future - Background execution of subroutines in child processes.

=head1 SYNOPSIS

 use BGS::Future;
 
 my $f = future { "from $$\n" };
 print $$, " got result ", $f->();
 print $$, " has result ", $f->();
 
 my $z = future { sleep 10; "from $$\n" };
 $z->cancel();
 
 print $$, " got result ", $_->() foreach map { future { "$_ from $$\n" }; } 1 .. 3;

=head1 DESCRIPTION

It's BGS wrapper.

=head2 future or new

Call subroutine in child process.

 my $f = future { "from $$\n" };

or

 my $f = BGS::Future->new(sub { "from $$\n" });

=head2 join

Get result.

 my $r = $f->();

or

 my $r = $f->join();

=head2 cancel

Kill child processes.

 $f->cancel();

=head2 $BGS::limit

Set $BGS::limit to limit child processes count. Default is 0 (unlimited).

=head1 AUTHOR

Nick Kostyria

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Nick Kostyria

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
