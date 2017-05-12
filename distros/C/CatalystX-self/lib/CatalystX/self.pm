package CatalystX::self;

use warnings;
use strict;
use parent 'self';

use Sub::Exporter -setup => {
    exports => [qw/self catalyst args/],
    groups => {
        default => [-all]
    }
};

=head1 NAME

CatalystX::self - A customized self for Catalyst controllers

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This is a very simple but handy module that shifts some of bits
around from L<self> to allow for an easier usage with (and with in) 
Catalyst controllers.

    package MyApp::Foo;

    use parent 'Catalyst::Controller';
    use CatalystX::self;

    sub bar : Local {
        my ($some,$params) = args;
        self->action_for('name');
        catalyst->response->body('Hello World');
    }
    
    ...
    
=head2 What if I don't like the names of these block words?

Simple! Since L<self> and this module utilize L<Sub::Exporter> you
may rename the methods as you see fit.
Here is an example that renames the args block word into some else and the
catalyst block word into the more common and shorter 'c'.

    package MyApp::LostShoes;
    
    use parent 'Catalyst::Controller';
    use CatalystX::self (
        catalyst => { -as => 'c' },
        args => { -as => 'gnargles' },
        self => { -as => 'this' }
    );
    
    sub bar : Local {
        this->{shoe} = gnargles;
        c->res->body($this->{shoe});
    }
    
    ...
    
You may also use the '-as' import renaming trick to do "aliases".

    use CatalystX::self (
        catalyst => { -as => 'c' },
        '-all'
    );

Now we have both 'catalyst' and 'c' block words.
        
=head1 EXPORT

=head2 self
    
See L<self/self>

=head2 args

Returns properly shifted L<self/args> for Catalyst controllers

=cut

sub args {
    my @a = self::_args;
    return @a[2..$#a];
}

=head2 catalyst

Returns Catalyst object.
Also known as the second argument in a Catalyst controller method.

=cut

sub catalyst {
    return (self::_args)[1];
}

=head1 AUTHOR

Jason M. Mills, C<< <jmmills at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalystx-self at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-self>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::self


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-self>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-self>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-self>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-self>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Jason M. Mills, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of CatalystX::self
