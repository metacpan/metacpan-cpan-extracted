package Catalyst::Plugin::HTML::Scrubber;
$Catalyst::Plugin::HTML::Scrubber::VERSION = '0.08';
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

sub execute {
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

    # Firstly, if an entry in ignore_urls matches, then we don't want to
    # scrub anything for this request...
    return if ($c->_req_path_exempt_from_scrubbing($conf));

    # If there's body_data - for e.g. a POSTed JSON body that was decoded -
    # then we need to walk through it, scrubbing as appropriate; don't call
    # body_data unless the content type is one there's a data handler for
    # though, otherwise we'll trigger an exception (see GH#4)
    if (exists $c->req->data_handlers->{ $c->req->content_type }) {
        if (my $body_data = $c->request->body_data) {
            $c->_scrub_recurse($conf, $c->request->body_data);
        }
    }

    # And if Catalyst::Controller::REST is in use so we have $req->data,
    # then scrub that too
    if ($c->request->can('data')) {
        my $data = $c->request->data;
        if ($data) {
            $c->_scrub_recurse($conf, $c->request->data);
        }
    }

    # Normal query/POST body parameters:
    $c->_scrub_recurse($conf, $c->request->parameters);

}

# Recursively scrub param values...
sub _scrub_recurse {
    my ($c, $conf, $data) = @_;

    # If the thing we've got is a hashref, walk over its keys, checking
    # whether we should ignore, otherwise, do the needful
    if (ref $data eq 'HASH') {
        for my $key (keys %$data) {
            if (!$c->_should_scrub_param($conf, $key, $data->{$key})) {
                next;
            }

            # OK, it's fine to fettle with this key - if its value is
            # a ref, recurse, otherwise, scrub
            if (my $ref = ref $data->{$key}) {
                $c->_scrub_recurse($conf, $data->{$key})
                    if defined $data->{$key};
            } else {
                # Alright, non-ref value, so scrub it
                # FIXME why did we have to have this ref-ref handling fun?
                #$_ = $c->_scrubber->scrub($_) for (ref($$value) ? @{$$value} : $$value);
                $data->{$key} = $c->_scrub_value($conf, $data->{$key})
                    if defined $data->{$key};
            }
        }
    } elsif (ref $data eq 'ARRAY') {
        for (@$data) {
            if (ref $_) {
                $c->_scrub_recurse($conf, $_);
            } else {
                $_ = $c->_scrub_value($conf, $_) if defined $_;
            }
        }
    } elsif (ref $data eq 'CODE') {
        $c->log->debug("Can't scrub a coderef!");
    } else {
        # Note that at this point we don't know what the param was called
        # as we'll have called ourself with the value, but that's fine as
        # name-based checks were already done; we do need to pass the
        # value ($data) along to allow value-based ignore_values to work.
        $data = $c->_scrub_value($conf, $data)
            if $c->_should_scrub_param($conf, '', $data);
    }
}


# Wrap HTML::Scrubber's scrub() so we can decode HTML entities if needed
sub _scrub_value {
    my ($c, $conf, $value) = @_;

    return $value unless defined $value;
    
    $value = $c->_scrubber->scrub($value);

    if ($conf->{no_encode_entities}) {
        $value = HTML::Entities::decode_entities($value);
    }
    return $value;
}

sub _should_scrub_param {
    my ($c, $conf, $param, $value) = @_;
    # If we only want to operate on certain params, do that checking
    # now...
    if ($conf && $conf->{ignore_params}) {
        my $ignore_params = $c->config->{scrubber}{ignore_params};
        if (ref $ignore_params ne 'ARRAY') {
            $ignore_params = [ $ignore_params ];
        }
        for my $ignore_param (@$ignore_params) {
            if (ref $ignore_param eq 'Regexp') {
                return if $param =~ $ignore_param;
            } else {
                return if $param eq $ignore_param;
            }
        }
    }

    # For cases where there are legitimate values that HTML::Scrubber will
    # munge... one example was an API where e.g. `<:100' would be eaten.
    # To allow any param where a `<` is not followed by a `>` in the same
    # param you could use qr{<[^]+$} or similar.
    if ($conf && $conf->{ignore_values}) {
        my $ignore_values = $conf->{ignore_values};
        if (ref $ignore_values ne 'ARRAY') {
            $ignore_values = [ $ignore_values ];
        }
        for my $ignore_value (@$ignore_values) {
            if ($value =~ $ignore_value) {
                return;
            }
        }
    }

    # If we've not bailed above, we didn't match any ignore_params
    # entries, or didn't have any, so we do want to scrub
    return 1; 
}


sub _req_path_exempt_from_scrubbing {
    my ($c, $conf) = @_;
    return unless exists $conf->{ignore_paths};

    my $req_path = $c->req->path;
    $req_path = "/$req_path" unless $req_path =~ m{^/};
    for my $ignore (@{ $conf->{ignore_paths} }) {
        if (ref $ignore eq 'Regexp') {
            return 1 if $req_path =~ $ignore;
        } else {
            return 1 if $req_path eq $ignore;
        }
    }
}

# Incredibly nasty monkey-patch to rewind filehandle before parsing - see
# https://github.com/perl-catalyst/catalyst-runtime/pull/186
# First, get the default handlers hashref:
my $default_data_handlers = Catalyst->default_data_handlers();

# Wrap the coderef for application/json in one that rewinds the filehandle
# first:
my $orig_json_handler = $default_data_handlers->{'application/json'};
$default_data_handlers->{'application/json'} = sub {
    $_[0]->seek(0,0); # rewind $fh arg
    $orig_json_handler->(@_);
};


{
    # and now replace the original default_data_handlers() with a version that
    # returns our modified handlers
    no warnings 'redefine';
    *Catalyst::default_data_handlers = sub {
        return $default_data_handlers;
    };
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

            # Exempt certain parameter names from scrubbing
            ignore_params => [ qr/_html$/, 'article_body' ],

            # Don't scrub at all for certain URL paths:
            ignore_paths => [
                '/foo',
                qr{^/foo/.+},
            ],

            # HTML::Scrubber will HTML-encode some chars, e.g. angle
            # brackets.  If you don't want that, enable this setting and
            # the scrubbed values will be unencoded.
            no_decode_entities => 0,
            
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

=item dispatch

Sanitize HTML tags in all parameters (unless `ignore_params` exempts them) -
this includes normal POST params, and serialised data (e.g. a POSTed JSON body)
accessed via `$c->req->body_data` or `$c->req->data`.

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
