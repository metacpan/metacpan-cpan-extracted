use strict;
use warnings;
package Array::Sticky::INC;

use Array::Sticky;

sub make_sticky { tie @INC, 'Array::Sticky', head => [shift @INC], body => [@INC] }

1;

__END__

=head1 NAME

Array::Sticky::INC - lock your @INC hooks in place

=head1 SYNOPSIS

Let's say you've written a module which hides the existence of certain modules:

    package Module::Hider;

    my %hidden;
    my $set_up_already;

    sub hider {
        my ($module) = pop();
        $module =~ s{/}{::}g;
        $module =~ s{\.pm$}{};

        return undef if exists $hidden{$module};
    }

    sub import {
        my ($class, @to_hide) = @_;

        @hidden{@to_hide} = @to_hide;
        if (! $set_up_already++) {
            # this works until some other piece of code issues a
            #     use lib '/somewhere';
            # or
            #     unshift @INC, '/over';
            # or
            #     $INC[0] = '/the-rainbow';
            unshift @INC, \&hider;
        }
    }

    1;

To hide a module using this Module::Hider, you'd write:

    use Module::Hider qw(strict warnings LWP::UserAgent);

Now any code which is running with that in place would encounter errors
attempting to load strict.pm, warnings.pm, and LWP/UserAgent.pm.

Hiding modules is pretty nice; see L<Devel::Hide> for a stronger treatment of why
you might care to do so.

But there is one downside to the "stick a coderef in @INC" trick: if any piece of
code manually updates @INC to steal the primary spot away from your coderef, then
your coderef may be rendered ineffective.

This module provides a simple interface to tie @INC in a way that you specify so
that attempts to manipulate @INC succeed in a way that you choose.

Now you may write Module::Hider like this:


    package Module::Hider;

    use Array::Sticky::INC;

    my %hidden;
    my $set_up_already;

    sub hider {
        my ($module) = pop();
        $module =~ s{/}{::}g;
        $module =~ s{\.pm$}{};

        return undef if exists $hidden{$module};
    }

    sub import {
        my ($class, @to_hide) = @_;

        @hidden{@to_hide} = @to_hide;
        if (! $set_up_already++) {
            unshift @INC, \&hider;
            Array::Sticky::INC->make_sticky;
        }
    }

    1;

=head1 RECIPES

This module only makes the foremost element of @INC sticky. If you need to make different elements of @INC sticky,
then use L<Array::Sticky>:

=head2 Making the tail of @INC sticky

If you're using like L<The::Net> or L<Acme::Intraweb> to automatically install modules that you're missing,
then you might want to lock their behaviors to the end of @INC:

    package My::The::Net;

    use The::Net;
    use Array::Sticky;

    sub import {
        tie @INC, 'Array::Sticky', body => [@INC], tail => [shift @INC];
    }

=head1 SEE ALSO

=over 4

=item * L<Devel::INC::Sorted> solves this same problem slightly differently.

=item * 'perldoc -f require' and 'perldoc perltie' talk about code hooks in @INC, and tied arrays, respectively

=item * L<Acme::Intraweb> - places a coderef at the tail of @INC

=item * L<The::Net> - places a coderef at the tail of @INC

=item * L<Devel::Hide> - places a coderef at the head of @INC

=item * L<Test::Without::Module> - places a coderef at the head of @INC

=back

=head1 BUGS AND LIMITATIONS

If you do something like:

    local @INC = @INC;
    unshift @INC, '/some/path';

then this module won't be able to preserve your hooks at the head of @INC.

Please report bugs on this project's Github Issues page: L<http://github.com/belden/perl-array-sticky/issues>.

=head1 CONTRIBUTING

The repository for this software is freely available on this project's Github page:
L<http://github.com/belden/perl-array-sticky>. You may fork it there and submit pull requests in the standard
fashion.

=head1 COPYRIGHT AND LICENSE

    (c) 2013 by Belden Lyman

This library is free software: you may redistribute it and/or modify it under the same terms as Perl
itself; either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have
available.

