package Acme::CPANAuthors::Belarusian;

use strict;
use warnings;

our $VERSION = '0.03';

use Acme::CPANAuthors::Register(
    DMOL => 'Ivan Baidakou',
    ZAG  => 'Zahatski Aliaksandr',
    ZAR  => 'Igor Zhuk',
);

1 && q[OK Go - Needing/Getting (Video Version)];

__END__
=head1 NAME

Acme::CPANAuthors::Belarusian - We are Belarusian CPAN authors

=head1 DESCRIPTION

This class provides a hash of Belarusian CPAN authors' Pause IDs/names
to Acme::CPANAuthors.

=head2 SYNOPSIS

    use Acme::CPANAuthors;

    my $authors = Acme::CPANAuthors->new('Belarusian');

    my $number   = $authors->count;
    my @ids      = $authors->id;
    my @distros  = $authors->distributions('DMOL');
    my $url      = $authors->avatar_url('ZAG');
    my $kwalitee = $authors->kwalitee('ZAR');

=head1 MAINTENANCE

If you are a Belarusian CPAN author not listed here, mail me your ID/name
or send a pull request. If you are listed but are not Belarusian
(or just don't want to be listed), mail me as well.

=head1 SEE ALSO

L<Acme::CPANAuthors> - Main class to manipulate this one.

=head1 AUTHOR

Sergey Romanov, C<sromanov@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Sergey Romanov.

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0.

=cut
