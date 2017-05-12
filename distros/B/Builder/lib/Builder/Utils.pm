package Builder::Utils;
use strict;
use warnings;
use Carp;
our $VERSION = '0.06';


# common utilities put here and not exported into Builder::* because it would pollute namespace (ie. tags!)

sub yank (&\@) {
    my ( $code, $array ) = @_;
    my $index = 0;
    my @return;
    
    while ( $index <= $#{ $array } ) {
        local $_ = $array->[ $index ];
        if ( $code->() ) { 
            push @return, splice @$array, $index, 1;
        }
        else { $index++ }
    }
    
    return @return;
}


1;

__END__

=head1 NAME

Builder::Utils - Internal Builder Utils


=head1 SYNOPSIS

NB. No need to use this module directly

=head1 EXPORT

None.

=head1 FUNCTIONS

=head2 yank

Yank out requested elements (prescribed by anon sub) from an array... returning whats been yanked.


=head1 AUTHOR

Barry Walsh C<< <draegtun at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-builder at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Builder>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Builder::Utils


You can also look for information at: L<Builder>

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Builder>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Builder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Builder>

=item * Search CPAN

L<http://search.cpan.org/dist/Builder/>

=back


=head1 ACKNOWLEDGEMENTS

See L<Builder>


=head1 COPYRIGHT & LICENSE

Copyright 2008-2013 Barry Walsh (Draegtun Systems Ltd | L<http://www.draegtun.com>), all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

