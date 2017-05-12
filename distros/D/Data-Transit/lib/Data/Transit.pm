package Data::Transit;
use strict;
use warnings;
no warnings 'uninitialized';

use Carp qw(confess);
use Data::Transit::Reader::JSON;
use Data::Transit::Reader::MessagePack;
use Data::Transit::Reader::JSONVerbose;
use Data::Transit::Writer::JSON;
use Data::Transit::Writer::JSONVerbose;
use Data::Transit::Writer::MessagePack;

=head1 NAME

Data::Transit - Perl implementation of the transit format

=head1 VERSION

Version 0.8.04

=cut

our $VERSION = '0.8.04';

=head1 SYNOPSIS

	use Data::Transit;

	my $writer = Data::Transit::writer($fh, 'json');
	$writer->write($value);

	my $reader = Data::Transit::reader('json');
	my $val = $reader->read($value);

For example:

	use Data::Transit;

	my $output;
	open my ($output_fh), '>>', \$output;
	my $writer = Data::Transit::writer($fh, 'json');
	$writer->write(["abc", 12345]);

	my $reader = Data::Transit::reader('json');
	my $vals = $reader->read($output);

Instead of json, you may also provide json-verbose and message-pack;

=head1 Type Mappings

Perl converts a lot of different types into basic strings, and keys in maps have to be strings.  As a result, the only way to fully avoid key collisions is to have some sort of naming scheme, but this violates the spirit of Transit. Put another way, we're accepting the possibility of collisions in exchange for something that maps more closely to idiomatic perl.

In an effort to keep the dependencies of this library to a minimum, any types that correspond to something outside of perls core modules has been excluded. If demand becomes high enough, I will write a separate package to extend heavily into CPAN types.

=head2 Custom Types

Custom types are registered at when the write/read handler is created:

	package Point;

	sub new {
		my ($class, $x, $y) = @_;
		return bless {x => $x, y => $y}, $class;
	}

	package PointWriteHandler;

	sub new {
		my ($class, $verbose) = @_;
		return bless {verbose => $verbose}, $class;
	}

	sub tag {
		return 'point';
	}

	sub rep {
		my ($self, $p) = @_;
		return [$p->{x},$p->{y}] if $self->{verbose};
		return "$p->{x},$p->{y}";
	}

	sub stringRep {
		return undef;
	}

	sub getVerboseHandler {
		return __PACKAGE__->new(1);
	}

	package PointReadHandler;

	sub new {
		my ($class, $verbose) = @_;
		return bless {
			verbose => $verbose,
		}, $class;
	}

	sub fromRep {
		my ($self, $rep) = @_;
		return Point->new(@$rep) if $self->{verbose};
		return Point->new(split /,/,$rep);
	}

	sub getVerboseHandler {
		return __PACKAGE__->new(1);
	}

	package main;

	my $point = Point->new(2,3);

	my $output;
	open my ($output_fh), '>>', \$output;
	Data::Transit::writer("json", $output_fh, handlers => {
		Point => PointWriteHandler->new(),
	})->write($point);

	my $result = Data::Transit::reader("json", handlers => {
		point => PointReadHandler->new(),
	})->read($output);

	is_deeply($point, $result);# true

=cut

sub reader {
	my ($format, %args) = @_;
	return Data::Transit::Reader::JSON->new(%args) if $format eq 'json';
	return Data::Transit::Reader::JSONVerbose->new(%args) if $format eq 'json-verbose';
	return Data::Transit::Reader::MessagePack->new(%args) if $format eq 'message-pack';
	confess "unknown reader format: $format";
}

sub writer {
	my ($format, $output, %args) = @_;
	return Data::Transit::Writer::JSON->new($output, %args) if $format eq 'json';
	return Data::Transit::Writer::JSONVerbose->new($output, %args) if $format eq 'json-verbose';
	return Data::Transit::Writer::MessagePack->new($output, %args) if $format eq 'message-pack';
	confess "unknown writer format: $format";
}

=head1 AUTHOR

Colin Williams, C<< <lackita at gmail.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Transit


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Transit>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Transit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Transit>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Transit/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Colin Williams.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut


1;
