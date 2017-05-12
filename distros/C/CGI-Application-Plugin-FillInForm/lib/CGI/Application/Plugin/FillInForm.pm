package CGI::Application::Plugin::FillInForm;
use base 'Exporter';
use strict;
use warnings;

our $VERSION = '1.15';
our @EXPORT_OK = qw(fill_form);
use Carp;

=head1 NAME

CGI::Application::Plugin::FillInForm - integrate with HTML::FillInForm

=head1 SYNOPSIS

    use CGI::Application::Plugin::FillInForm (qw/fill_form/);

    my $t = $self->load_tmpl('farm.html');
    $t->param( organic => 'less_pesticides' );

    return $self->fill_form( \$t->output );

=head1 DESCRIPTION

This plugin provides a mix-in method to make using HTML::FillInForm more
convenient.

=head2 fill_form()

 # fill an HTML form with data in a hashref or from an object with with a param() method
 my $filled_html = $self->fill_form($html, $data);

 # ...or fill from a list of data sources
 # (each item in the list can be either a hashref or an object)
 my $filled_html = $self->fill_form($html, [$user, $group, $query]);

 # ...or default to getting data from $self->query()
 my $filled_html = $self->fill_form($html);

 # extra fields will be passed on through:
 my $filled_html = $self->fill_form($html, undef, fill_password => 0 );

This method provides an easier syntax for calling HTML::FillInForm, and an
intelligent default of using $self->query() as the default data source.

By default, the mode param (usually 'rm') of every data source will be
ignored. This prevents accidently clobbering your run mode for the next
page, which may be stored in a hidden field.

B<$html> must be a scalarref, or a reference to a scalarref.
B<$filled_html> will be a reference to a string.

Because this method only loads HTML::FillInForm if it's needed, it should be
reasonable to load it in a base class and always have it available:

  use CGI::Application::Plugin::FillInForm (qw/fill_form/);

=cut

sub fill_form {
    my $self = shift;
    my $html = shift;
    my $data = shift;
    my %extra_params = @_;

    if (ref $html eq 'REF' and ref $$html eq 'SCALAR') {
        $html = $$html;
    }
    die "html must be a scalarref!" unless (ref $html eq 'SCALAR');

    my %params = (
        ignore_fields => [ $self->mode_param()],
    );
    my (@fdat, @fobject);

    if ($data) {

        $data = [$data] unless ref $data eq 'ARRAY';

        for my $source (@$data) {
            if (ref $source eq 'HASH') {
                push @fdat, $source;
            }
            elsif (ref $source) {
                if ($source->can('param')) {
                    push @fobject, $source;
                }
                else {
                    croak "data source $source does not supply a param method";
                }
            }
            elsif (defined $source) {
                croak "data source $source is not a hash or object reference";
            }
        }

        # The docs to HTML::FillInForm suggest that you can pass an arrayref
        # of %fdat hashes, but you can't.  So if we receive more than one,
        # we merge them.  (This is no big deal, since this is what
        # HTML::FillInForm would do anyway if it supported this feature.)

        if (@fdat) {
            if (@fdat > 1) {
                my %merged;
                for my $hash (@fdat) {
                    for my $key (keys %$hash) {
                        $merged{$key} = $hash->{$key};
                    }
                }
                $params{'fdat'} = \%merged;
            }
            else {
                # If there's only one fdat hash anyway, then it's the
                # first and only element in @fdat
                $params{'fdat'} = $fdat[0];
            }
        }

        # Multiple objects, however, are supported natively by
        # HTML::FillInForm
        $params{'fobject'} = \@fobject if @fobject;

    }
    else {
        # If no data sources are specified, then use
        # $self->query
        $params{'fobject'} = $self->query;
    }

    require HTML::FillInForm;
    my $fif = new HTML::FillInForm;
    my $output = $fif->fill(scalarref => $html, %params, %extra_params);
    return \$output;
}

=head1 AUTHORS

 Cees Hek published the first draft on the CGI::App wiki
 Mark Stosberg, C<< <mark@summersault.com> >> polished it for release.
 Michael Graham, C<< <mag-perl@occamstoothbrush.com> >> added tests and some new features.
 The module is now co-maintained by Mark and Michael.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-fillinform@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 CONTRIBUTING

Patches, questions and feedback are welcome. This project is managed using
the darcs source control system ( http://www.darcs.net/ ). My darcs archive is here:
http://mark.stosberg.com/darcs_hive/cap-fif/


=head1 Copyright & License

Copyright 2005 Mark Stosberg, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of CGI::Application::Plugin::FillInForm
