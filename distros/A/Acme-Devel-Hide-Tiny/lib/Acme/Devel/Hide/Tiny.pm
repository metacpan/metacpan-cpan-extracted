use 5.008001;
use strict;
use warnings;

package Acme::Devel::Hide::Tiny;
# ABSTRACT: Hide a perl module for testing, in one statement

our $VERSION = '0.002';

1;


# vim: ts=4 sts=4 sw=4 et tw=75:

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Devel::Hide::Tiny - Hide a perl module for testing, in one statement

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    # in 'foo.t', assume we want to hide Cpanel::JSON::XS

    # hide Cpanel::JSON::XS -> Cpanel/JSON/XS.pm
    use lib map {
        my $m = $_;
        sub { return unless $_[1] eq $m; die "Can't locate $_[1] in \@INC (hidden)\n"; }
    } qw{Cpanel/JSON/XS.pm};

=head1 DESCRIPTION

The L<Devel::Hide> and L<Test::Without::Module> modules are very helpful
development tools.  Unfortunately, using them in your F<.t> files adds a
test dependency.  Maybe you don't want to do that.

Instead, you can use the one-liner from the SYNOPSIS above, which is an
extremely stripped down version of L<Devel::Hide>.

Here is a more verbose, commented version of it:

    # 'lib' adds its arguments to the front of @INC
    use lib

        # add one coderef per path to hide
        map {
            # create lexical for module
            my $m = $_;

            # construct and return a closure that dies for the module path to hide
            sub {

                # return if not the path to hide; perl checks rest of @INC
                return unless $_[1] eq $m;

                # die with the error message we want
                die "Can't locate $_[1] in \@INC (hidden)\n";
            }
        }

        # input to map is a list module names, converted to paths;
        qw{Cpanel/JSON/XS.pm JSON/XS.pm}

    ; # end of 'use lib' statement

When perl sees a coderef in C<@INC>, it gives the coderef a chance to
provide the source code of that module.  In this case, if the path is the
one we want to hide, it dies with the message we want and perl won't
continue looking at C<@INC> to find the real module source.  The module is
hidden and dies with a message similar to the one that would happen if it
weren't installed.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Acme-Devel-Hide-Tiny/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Acme-Devel-Hide-Tiny>

  git clone https://github.com/dagolden/Acme-Devel-Hide-Tiny.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Graham Knop

Graham Knop <haarg@haarg.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
