package Aion::Annotation::ScannedEvent;

use common::sense;

use Aion;

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Annotation::ScannedEvent - event for completing scanning of annotations in the project

=head1 SYNOPSIS

File lib/ScannedListener.pm:

	package ScannedListener;
	
	use Aion;
	
	has scanned_count => (is => 'ro', isa => Int, default => 0);
	
	#@listen Aion::Annotation::ScannedEvent „End scan”
	sub scan_ended_listen {
		my ($self, $event) = @_;
		$self->{scanned_count}++;
	}
	
	1;



	use Aion::Annotation;
	
	my $listener = Aion->pleroma->get('ScannedListener');
	
	Aion::Annotation->new->scan;
	
	$listener->scanned_count # -> 1

=head1 DESCRIPTION

When C<Aion::Annotation> finishes scanning the project and writing new annotations, it fires this event.
In this case, events in the emitter are reread immediately after scanning and before the event is emitted.

An obvious use for this event is to turn an annotation file into a C<crontab>.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Annotation::ScannedEvent module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
