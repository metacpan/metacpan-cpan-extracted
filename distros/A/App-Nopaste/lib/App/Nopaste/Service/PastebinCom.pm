use strict;
use warnings;
package App::Nopaste::Service::PastebinCom;
# ABSTRACT: Service provider for Pastebin - http://pastebin.com/

our $VERSION = '1.013';

use parent 'App::Nopaste::Service';
use Module::Runtime 'use_module';
use namespace::clean 0.19;

sub available {
    eval { use_module('WWW::Pastebin::PastebinCom::Create'); 1 }
}

sub run {
    my $self = shift;
    my %args = @_;

    use_module('WWW::Pastebin::PastebinCom::Create');

    $args{poster} = delete $args{nick} if defined $args{nick};
    $args{format} = delete $args{lang} if defined $args{lang};

    my $paster = WWW::Pastebin::PastebinCom::Create->new;
    my $ok = $paster->paste(
        expiry => 'm',
        %args,
    );

    return (0, $paster->error) unless $ok;
    return (1, $paster->paste_uri);
}

1;

__END__

=pod

=encoding UTF-8

=for stopwords Pastebin

=head1 NAME

App::Nopaste::Service::PastebinCom - Service provider for Pastebin - http://pastebin.com/

=head1 VERSION

version 1.013

=head1 SEE ALSO

L<WWW::Pastebin::PastebinCom::Create>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=App-Nopaste>
(or L<bug-App-Nopaste@rt.cpan.org|mailto:bug-App-Nopaste@rt.cpan.org>).

=head1 AUTHOR

Shawn M Moore, <sartak@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
