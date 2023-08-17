package Catalyst::Plugin::HTML::Scrubber;
$Catalyst::Plugin::HTML::Scrubber::VERSION = '0.03';
use Moose;
use namespace::autoclean;

with 'Catalyst::ClassData';

use MRO::Compat;
use HTML::Scrubber;

__PACKAGE__->mk_classdata('_scrubber');

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

    # There are two ways to configure the plugin, it seems; giving a hashref
    # of params under `scrubber`, with any params intended for HTML::Scrubber
    # under the vaguely-named `params` key, or an arrayref of params intended
    # to be passed straight to HTML::Scrubber - save html_scrub() from knowing
    # about that by abstracting that nastyness away:
    if (ref $conf ne 'HASH' || $conf->{auto}) {
        $c->html_scrub(ref($conf) eq 'HASH' ? $conf : {});
    }
}

sub html_scrub {
    my ($c, $conf) = @_;

    param:
    for my $param (keys %{ $c->request->{parameters} }) {
        #while (my ($param, $value) = each %{ $c->request->{parameters} }) {
        my $value = \$c->request->{parameters}{$param};
        if (ref $$value && ref $$value ne 'ARRAY') {
            next param;
        }

        # If we only want to operate on certain params, do that checking
        # now...
        if ($conf && $conf->{ignore_params}) {
            my $ignore_params = $c->config->{scrubber}{ignore_params};
            if (ref $ignore_params ne 'ARRAY') {
                $ignore_params = [ $ignore_params ];
            }
            for my $ignore_param (@$ignore_params) {
                if (ref $ignore_param eq 'Regexp') {
                    next param if $param =~ $ignore_param;
                } else {
                    next param if $param eq $ignore_param;
                }
            }
        } 

        # If we're still here, we want to scrub this param's value.
        $_ = $c->_scrubber->scrub($_) for (ref($$value) ? @{$$value} : $$value);
    }
}

__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 NAME

Catalyst::Plugin::HTML::Scrubber - Catalyst plugin for scrubbing/sanitizing incoming parameters

=head1 SYNOPSIS

    use Catalyst qw[HTML::Scrubber];

    MyApp->config( 
        scrubber => {
            auto => 1,  # automatically run on request
            ignore_params => [ qr/_html$/, 'article_body' ],
            
            # The following are options to HTML::Scrubber
            params => [
                default => 0,
                comment => 0,
                script => 0,
                process => 0,
                allow => [qw [ br hr b a h1]],
            ],
        },
   );

=head1 DESCRIPTION

On request, sanitize HTML tags in all params (with the ability to exempt
some if needed), to protect against XSS (cross-site scripting) attacks and
other unwanted things.


=head1 EXTENDED METHODS

=over 4

=item setup

See SYNOPSIS for how to configure the plugin, both with its own configuration
(e.g. whether to automatically run, whether to exempt certain fields) and
passing on any options from L<HTML::Scrubber> to control exactly what
scrubbing happens.

=item prepare_parameters

Sanitize HTML tags in all parameters (unless `ignore_params` exempts them).

=back

=head1 SEE ALSO

L<Catalyst>, L<HTML::Scrubber>.

=head1 AUTHOR

Hideo Kimura, << <hide@hide-k.net> >> original author

David Precious (BIGPRESH), C<< <davidp@preshweb.co.uk> >> maintainer since 2023-07-17

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Hideo Kimura

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
