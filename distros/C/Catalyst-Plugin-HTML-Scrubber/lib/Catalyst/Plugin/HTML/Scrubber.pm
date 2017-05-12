package Catalyst::Plugin::HTML::Scrubber;

use Moose;
use namespace::autoclean;

with 'Catalyst::ClassData';

use MRO::Compat;
use HTML::Scrubber;

__PACKAGE__->mk_classdata('_scrubber');

our $VERSION = '0.02';

sub setup {
    my $c = shift;

    my $conf = $c->config->{scrubber};
    if (ref $conf eq 'ARRAY') {
        $c->_scrubber(HTML::Scrubber->new(@$conf));
    } elsif (ref $conf eq 'HASH') {
        $c->config->{scrubber}{auto} = 1
            unless defined $c->config->{scrubber}{auto};
        $c->_scrubber(HTML::Scrubber->new(@{$conf->{params}}));
    } else {
        $c->_scrubber(HTML::Scrubber->new());
    }

    return $c->maybe::next::method(@_);
}

sub prepare_parameters {
    my $c = shift;

    $c->maybe::next::method(@_);

    my $conf = $c->config->{scrubber};
    if (ref $conf ne 'HASH' || $conf->{auto}) {
        $c->html_scrub;
    }
}

sub html_scrub {
    my $c = shift;

    for my $value (values %{$c->request->{parameters}}) {
        if (ref $value && ref $value ne 'ARRAY') {
            next;
        }

        $_ = $c->_scrubber->scrub($_) for (ref($value) ? @{$value} : $value);
    }
}

__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 NAME

Catalyst::Plugin::HTML::Scrubber - Catalyst plugin for scrubbing/sanitizing html

=head1 SYNOPSIS

    use Catalyst qw[HTML::Scrubber];

    MyApp->config( 
        scrubber => [
            default => 0,
            comment => 0,
            script => 0,
            process => 0,
            allow => [qw [ br hr b a h1]],
        ],
   );

=head1 DESCRIPTION

On request, sanitize HTML tags in all params.

=head1 EXTENDED METHODS

=over 4

=item setup

You can use options of L<HTML::Scrubber>.

=item prepare_parameters

Sanitize HTML tags in all parameters.

=item html_scrub

Sanitize HTML tags in all parameters.

=back

=head1 SEE ALSO

L<Catalyst>, L<HTML::Scrubber>.

=head1 AUTHOR

Hideo Kimura, E<lt>hide@hide-k.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Hideo Kimura

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
