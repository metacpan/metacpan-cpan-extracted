package Backup::EZ::Dir;

use strict;
use warnings;
use warnings FATAL => 'all';
use Carp;
use Devel::Confess 'color';
use File::Spec;
use Data::Printer alias => 'pdump';

sub new {
    my $class = shift;
    my @args  = @_;

    my $self = {
        dirname           => undef, # scalar
        chunked       => 0,     # bool
        excludes_aref => undef, # arrayref
    };

    my @excludes;
    
    my ( $dirname, @opts ) = split( /,/, $args[0] );
    $self->{dirname} = _trim($dirname);
    
    foreach my $i (@opts) {
        my $opt = _trim($i);
        if ($opt) {    # ignore whitespace opts
        
            if ( $opt =~ /^chunked$/i ) {
                $self->{chunked} = 1;
            }
            elsif ( $opt =~ /exclude\s*=\s*(.+)$/ ) {
                push(@excludes, sprintf('--%s', $opt));
            }
            else {
                confess "unknown dir option: $opt";
            }
        }
    }

    if ( !$self->{dirname} ) {
        confess "unable to determine dir in stanza: @_";
    }

    if ( !File::Spec->file_name_is_absolute( $self->{dirname} ) ) {
        confess "relative dirs are not supported";
    }

    $self->{excludes_aref} = \@excludes;
    
    bless $self, $class;
    return $self;
}

# returns scalar
sub dirname {
    my $self = shift;
    return $self->{dirname};
}

# returns bool
sub chunked {
    my $self = shift;
    return $self->{chunked};
}

# returns arrayref
sub excludes {
    my $self = shift;
    return [ @{ $self->{excludes_aref} } ];
}

sub _trim {
    my $str = shift;

    if ($str) {
        $str =~ s/^\s+//;
        $str =~ s/\s+$//;
    }

    return $str;
}

=head1 AUTHOR

John Gravatt, C<< <john at gravatt.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-backup-ez at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Backup-EZ>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Backup::EZ


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Backup-EZ>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Backup-EZ>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Backup-EZ>

=item * Search CPAN

L<http://search.cpan.org/dist/Backup-EZ/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 John Gravatt.

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
