package BBS::UserInfo;

use warnings;
use strict;

=head1 NAME

BBS::UserInfo - Base class of BBS::UserInfo::XXX

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use BBS::UserInfo;

    my $bot = BBS::UserInfo->new('Ptt', 'server' => 'ptt.cc');
    $bot->connect();
    my $data = $bot->query('username');
    print($data->{'logintimes'});

=head1 FUNCTIONS

=head2 new()

=cut

sub new {
    my ($class, $style, @params) = @_;

    require(sprintf('BBS/UserInfo/%s.pm', $style));
    return "BBS::UserInfo::${style}"->new(@params);
}

=head1 AUTHOR

Gea-Suan Lin, C<< <gslin at gslin.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Gea-Suan Lin, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of BBS::UserInfo
