package eta;
use strict;
use Acme::MetaSyntactic;
our @ISA = qw(Acme::MetaSyntactic);
our $VERSION = '1.001';
"holy cow";

__END__

=encoding utf8

=head1 NAME

eta - A shortcut for Acme::MetaSyntactic one-liners

=head1 SYNOPSIS

    $ perl -Meta -E say+metaname
    plugh

=head1 DESCRIPTION

Typing the module full name in oneliners is more than cumbersome.

Yes, there's already the meta(1) command for simple cases like this one,
but for more complex cases combining several themes it's really better. 

=head1 AUTHORS

Sébastien Aperghis-Tramoni, C<< <saper@cpan.org> >>,
Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>

=head1 COPYRIGHT

Copyright 2012 Philippe Bruhat (BooK), All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

