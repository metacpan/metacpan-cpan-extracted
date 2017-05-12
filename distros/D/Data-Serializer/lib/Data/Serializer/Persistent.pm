package Data::Serializer::Persistent;

use warnings;
use strict;
use vars qw($VERSION @ISA);
use IO::File;

use Carp;

$VERSION = '0.01';

sub _store {
	my $self = (shift);
	my $data = (shift);
	my $file_or_fh = (shift);


	if (ref($file_or_fh)) {
		#it is a file handle so print straight to it
		print $file_or_fh $self->{parent}->serialize($data), "\n";
		#We didn't open the filehandle, so we shouldn't close it.
	} else {
		#it is a file, so open it
		my ($mode,$perm) = @_;
		unless (defined $mode) {
			$mode = O_CREAT|O_WRONLY;
		}
		unless (defined $perm) {
			$perm = 0600;
		}
		my $fh = new IO::File; 
		$fh->open($file_or_fh, $mode,$perm) || croak "Cannot write to $file_or_fh: $!";
		print $fh $self->{parent}->serialize($data), "\n";
		$fh->close();
	}
}

sub _retrieve {
	my $self = (shift);
	my $file_or_fh = (shift);
	if (ref($file_or_fh)) {
		#it is a file handle so read straight from it
		my $input = join('', <$file_or_fh>);
		chomp($input);
		return $self->{parent}->deserialize($input);
		#We didn't open the filehandle, so we shouldn't close it.
	} else {
		my $fh = new IO::File; 
		$fh->open($file_or_fh, O_RDONLY) ||	croak "Cannot read from $file_or_fh: $!";
		my $input = join('', <$fh>);
		chomp($input);
		$fh->close;
		return $self->{parent}->deserialize($input);
	}
}



1;
__END__

=pod

=head1 NAME
                
Data::Serializer::Persistent - Provide means of persistently storing serialized data in a file
                
=head1 SYNOPSIS

  use Data::Serializer::Persistent                

=head1 DESCRIPTION

Used internally to L<Data::Serializer(3)>, does not currently have any public methods
    
=head1 EXAMPLES

=over 4

=item  Please see L<Data::Serializer::Cookbook(3)>

=back

=head1 METHODS

=head1 AUTHOR

Neil Neely <F<neil@neely.cx>>.

http://neil-neely.blogspot.com/

=head1 BUGS

Please report all bugs here:

http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Serializer


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011 Neil Neely.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


See http://www.perl.com/language/misc/Artistic.html

=head1 SEE ALSO

perl(1), Data::Serializer(3), IO::File(3).

=cut

