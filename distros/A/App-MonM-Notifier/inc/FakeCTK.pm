package FakeCTK; # $Id: SkelModule.pm 200 2017-05-01 08:51:48Z minus $
use strict;

=head1 NAME

FakeCTK - Module simulating CTK for testing CTKlib projects

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use FakeCTK;

=head1 DESCRIPTION

Module simulating CTK for testing CTKlib projects in your test scripts

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) http://www.serzik.com <minus@mail333.com>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use vars qw/$VERSION/;
$VERSION = '1.01';

use constant {
    PROJECTNAME => 'monotifier',
};

use CTK;
use CTKx;

my $c = new CTK(
    syspaths    => 1,
    prefix      => lc(PROJECTNAME),
);

CTKx->instance( c => $c );

1;
__END__
