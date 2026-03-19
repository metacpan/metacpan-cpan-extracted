package Bored;

use 5.008003;

our $VERSION = '0.06';

use base 'Import::Export';

our %EX = (
	bored_one => [qw/all/]
);

sub new {
	bless {}, $_[0];
}

sub topdown {
	return 'bottom up';
}

sub bored_one {
	return 1;
}

sub seclusion {
	return 'bondage';
}

sub pointless {
	return 'leadership';
}

sub waiting {
	return 'patiently';
}

sub tortured {
	return 'souls';
}

1;

__END__

=head1 NAME

Bored - news!

=head1 VERSION

Version 0.06

=cut

=head1 SYNOPSIS

    use Bored qw/bored_one/;

    bored_one;

    my $you = Bored->new();
    $you->pointless();
    $you->waiting();
    $you->tortured();
    ...

Lets dance

! < > < > > < < > > > < < > > > < < < < < < <

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bored at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bored>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bored


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Bored>

=item * Search CPAN

L<https://metacpan.org/release/Bored>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Bored
