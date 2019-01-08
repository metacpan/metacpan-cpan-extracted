package Config::LNPath;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

use YAML::XS qw/LoadFile/;
use Data::LNPath qw/lnpath/, {
	return_undef => 1	
};
use Carp qw/croak/;
use Blessed::Merge;

sub new {
	my $self = bless $_[1] // {}, $_[0];
	croak "no config path passed to new" unless $self->{config};
	my $blessed = Blessed::Merge->new({ blessed => 0, ($self->{merge} ? %{ $self->{merge} } : ()) });
	$self->{data} = ref $self->{config} eq 'ARRAY'
		? $blessed->merge(map { LoadFile($_) } @{ $self->{config} }) 
		: LoadFile($self->{config});
	$self->{data} = $self->{data}->{$self->{section}} if $self->{section};
	$self;
}

sub find {
	lnpath($_[0]->{data}, $_[1]) 
		or croak sprintf "Could not find value from config using path -> %s", $_[1];
}

sub section_find {
	lnpath($_[0]->{data}->{$_[1]}, $_[2])
		or croak sprintf "Could not find value from config section -> %s", $_[1];
}

1; # End of Config::LNPath

__END__

=head1 NAME

Config::LNPath - Currently just a Simple YAML Config Reader.

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

	use Config::LNPath;

	our $conf = Config::LNPath->new({ 
		config => ['one.yml', 'two.yml'], 
		merge => { 
			unique_hash => 1,
			unique_array => 1,
		} 
	});

	...

	$conf->find('/path/to/important/thing');

=head1 SUBROUTINES/METHODS

=head2 new

=head2 find

find path in config file.

	$conf->find('/path/to/important/thing');

=head2 section_find 

=head1 AUTHOR

Robert Acock, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-config-lnpath at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-LNPath>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::LNPath

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-LNPath>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-LNPath>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-LNPath>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-LNPath/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

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

