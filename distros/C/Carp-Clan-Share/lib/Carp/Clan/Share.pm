package Carp::Clan::Share;

use warnings;
use strict;

=head1 NAME

Carp::Clan::Share - Share your Carp::Clan settings with your whole Clan

=head1 VERSION

Version 0.013

=cut

our $VERSION = '0.013';

require Carp::Clan;

sub import {
    my $caller = caller(0);
    my @arguments = @_;
    shift @arguments; # Get rid of the package name
    $caller =~ s/::Carp$//; # If the user already named it Carp, use the parent of that.
    unshift @arguments, "^${caller}::";

    my $package = "${caller}::Carp";
    my $pm = join("/", split m/::/, $package) . ".pm";
    $INC{$pm} = 1;
    eval "package $package;";

    my $exporter;
    {
        no strict 'refs';
        $exporter = *{"${package}::import"} = sub {
            push @_, @arguments;
            goto &Carp::Clan::import;
        };
    }

    goto &$exporter;
}

=head1 SYNOPSIS

    package My::Namespace

    use Carp::Clan::Share; # My::Namespace::Carp now exists

    ...

    package My::Namespace::Module

    use My::Namespace::Carp; # Acts like "use Carp::Clan qw/^My::Namespace::/;"

    ...

    package My::Other::Namespace;

    # You can also pass options through to Carp::Clan
    use Carp::Clan::Share qw/verbose/; # My::Other::Namespace::Carp now exists

    ...

    package My::Other::Namespace::Module

    use My::Other::Namespace::Carp; # Acts like "use Carp::Clan qw/^My::Other::Namespace:: verbose/;"

    ...

=head1 DESCRIPTION

This is a very lightweight helper module (actually just an import method) that will automagically create
a __PACKAGE__::Carp module for you.

Any arguments passed to the import (e.g. via use) method are forwarded along to Carp::Clan.

NOTE: If you use this from a package ending with ::Carp, then it will use the parent of of that package
as the target namespace

    package My::Namespace::Carp;
    
    use Carp::Clan::Share;

    package My::Namespace::Module

    use My::Namespace::Carp; # Acts like "use Carp::Clan qw/^My::Namespace::/;"

=head1 SEE ALSO

L<Carp::Clan>

L<Carp>

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-carp-clan-share at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Carp-Clan-Share>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Carp::Clan::Share


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Carp-Clan-Share>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Carp-Clan-Share>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Carp-Clan-Share>

=item * Search CPAN

L<http://search.cpan.org/dist/Carp-Clan-Share>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Robert Krimen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Carp::Clan::Share
