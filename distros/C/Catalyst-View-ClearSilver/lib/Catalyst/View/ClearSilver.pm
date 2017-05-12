package Catalyst::View::ClearSilver;
use strict;
use warnings;
use base qw(Catalyst::Base);

use ClearSilver;

our $VERSION = '0.01';

sub process {
    my ( $self, $c ) = @_;
    my $template = $c->stash->{template}
        || sprintf('%s%s', $c->action, $self->config->{template_extension} || '.cs');
    unless ($template) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }
    $c->log->debug(qq/Rendering template "$template"/) if $c->debug;
    my $hdf = $self->_create_hdf($c);
    unless ($hdf) {
        $c->log->error(qq/Couldn't create HDF Dataset/);
        return 0;
    }
    my $cs = ClearSilver::CS->new($hdf);
    unless ($cs->parseFile($template)) {
        $c->log->error(qq/Couldn't render template "$template"/);
        return 0;
    }
    my $output = $cs->render;
    unless ( $c->response->content_type ) {
        $c->response->content_type('text/html; charset=utf8');
    }
    $c->response->body($output);
    return 1;
}

sub _create_hdf {
    my ( $self, $c ) = @_;
    my $hdf = ClearSilver::HDF->new;
    for my $path (@{$self->config->{hdfpaths}}) {
        my $ret = $hdf->readFile($path);
        return unless $ret;
    }
    my $loadpaths = $self->config->{loadpaths};
    my $root = $c->config->{root};
    push @{$loadpaths}, "$root";
    _hdf_setValue($hdf, 'hdf.loadpaths', $loadpaths);
    while (my ($key, $val) = each %{$c->stash}) {
        _hdf_setValue($hdf, $key, $val);
    }
    $hdf;
}

sub _hdf_setValue {
    my ($hdf, $key, $val) = @_;
    if (ref $val eq 'ARRAY') {
        my $index = 0;
        for my $v (@$val) {
            _hdf_setValue($hdf, "$key.$index", $v);
            $index++;
        }
    } elsif (ref $val eq 'HASH') {
        while (my ($k, $v) = each %$val) {
            _hdf_setValue($hdf, "$key.$k", $v);
        }
    } elsif (ref $val eq 'SCALAR') {
        _hdf_setValue($hdf, $key, $$val);
    } elsif (ref $val eq '') {
        $hdf->setValue($key, $val);
    }
}

1;
__END__

=head1 NAME

Catalyst::View::ClearSilver - ClearSilver View Class

=head1 SYNOPSIS

    # use the helper
    create.pl view ClearSilver ClearSilver

    # lib/MyApp/View/ClearSilver.pm
    package MyApp::View::ClearSilver

    use base 'Catalyst::View::ClearSilver';

    __PACKAGE__->config(
        loadpaths => ['/path/to/loadpath', '/path/to/anotherpath'],
        hdfpaths  => ['mydata1.hdf', 'mydata2.hdf'],
        template_extension => '.cs',
    );

    1;

    # Meanwhile, maybe in an 'end' action
    $c->forward('MyApp::View::ClearSilver');


=head1 DESCRIPTION

This is the C<ClearSilver> view class. Your subclass should inherit from this
class.

=head1 METHODS

=over 4

=item process

Renders the template specified in C<< $c->stash->{template} >> or
C<< $c->action >> (the private name of the matched action.  Calls L<render> to
perform actual rendering. Output is stored in C<< $c->response->body >>.

=back

=head1 CONFIG VARIABLES

=over 4

=item loadpaths

added to hdf.loadpaths.
default is C<< $c->config->{root} >> only.

=item hdfpaths

HDF Dataset files into the current HDF object.

=item template_extension

a sufix to add when looking for templates bases on the C<match> method in L<Catalyst::Request>.

=back

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catalyst>, L<ClearSilver>

ClearSilver Documentation:  L<http://www.clearsilver.net/docs/>

=cut
