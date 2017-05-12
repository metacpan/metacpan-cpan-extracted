package App::Nopaste::Service::Sprunge;
# ABSTRACT: adds sprunge.us support to App::Nopaste
use strict;
use warnings;
our $VERSION = '0.004'; # VERSION
use base 'App::Nopaste::Service';


sub available {
    eval {
        require WWW::Pastebin::Sprunge::Create;
        1;
    };
}


sub run {
    my $self = shift;
    my %args = @_;

    require WWW::Pastebin::Sprunge::Create;

    my $paster = WWW::Pastebin::Sprunge::Create->new();
    my $ok = $paster->paste(
        $args{'text'},
        lang    => $args{'lang'},
    );

    return (0, $paster->error) unless $ok;
    return (1, $paster->paste_uri);
}


1;



=pod

=encoding utf-8

=head1 NAME

App::Nopaste::Service::Sprunge - adds sprunge.us support to App::Nopaste

=head1 VERSION

version 0.004

=head1 METHODS

=head2 available

Returns whether or not L<WWW::Pastebin::Sprunge::Create> is
available so we can actually paste to L<http://sprunge.us>.

=head2 run

Run the application code to paste to L<http://sprunge.us>.

=head1 SEE ALSO

L<WWW::Pastebin::Sprunge::Create>

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/App-Nopaste-Service-Sprunge/>.

The development version lives at L<http://github.com/doherty/App-Nopaste-Service-Sprunge>
and may be cloned from L<git://github.com/doherty/App-Nopaste-Service-Sprunge.git>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/App-Nopaste-Service-Sprunge>
and may be cloned from L<git://github.com/doherty/App-Nopaste-Service-Sprunge.git>

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<https://github.com/doherty/App-Nopaste-Service-Sprunge/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2100 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
