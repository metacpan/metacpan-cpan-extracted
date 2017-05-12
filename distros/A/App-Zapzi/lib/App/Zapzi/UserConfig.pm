package App::Zapzi::UserConfig;
# ABSTRACT: get and set user configurable variables


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Carp;
use App::Zapzi;
use App::Zapzi::Config;
use Moo;

# Define valid user config keys and documentation/validators
our $_config_data =
{
    publish_format =>   {doc => "Format to publish eBooks in.",
                         options => "EPUB, MOBI or HTML",
                         init_configurable => 1,
                         default => 'MOBI',
                         validate => sub
                         {
                             my $format = shift;
                             return $format =~ /^(EPUB|MOBI|HTML)$/i ?
                                 uc($format) : undef;
                         }},

    publish_encoding => {doc => "Encoding to publish eBooks in.",
                         options => "ISO-8859-1 or UTF-8",
                         init_configurable => 0,
                         default => undef,
                         validate => sub
                         {
                             my $enc = shift;
                             return $enc =~ /^(ISO-8859-1|UTF-8|)$/i ?
                                 uc($enc) : undef;
                         }},

    distribution_method => {doc => "How to disribute eBooks after publication.",
                            options => "[Copy] to another directory, " .
                                       "run a [Script] or do [Nothing]",
                            init_configurable => 1,
                            default => 'Nothing',
                            validate => sub
                            {
                                my $enc = shift;
                                return $enc =~ /^(Copy|Script|Nothing|)$/i ?
                                    ucfirst($enc) : undef;
                            }},

    distribution_destination => {doc => "Where to disribute eBooks after " .
                                        "publication",
                                options => "Script name, directory",
                                init_configurable => 0,
                                default => undef,
                                validate => sub { my $d = shift; return $d; }},

    deactivate_links => {doc => "If set, replace hyperlinks with link text",
                                options => "Yes, No",
                                init_configurable => 0,
                                default => undef,
                                validate => sub
                                {
                                    my $d = shift;
                                    return $d =~ /^[yn]/i ? ucfirst($d) : undef;
                                }},
};


sub get
{
    my ($key) = @_;
    croak 'Key not provided' unless $key;

    return App::Zapzi::Config::get($key) if $_config_data->{$key};
}


sub get_description
{
    my ($key) = @_;
    croak 'Key not provided' unless $key;
    return $_config_data->{$key}->{doc};
}


sub get_options
{
    my ($key) = @_;
    croak 'Key not provided' unless $key;
    return $_config_data->{$key}->{options};
}


sub get_default
{
    my ($key) = @_;
    croak 'Key not provided' unless $key;
    return $_config_data->{$key}->{default};
}


sub get_validater
{
    my ($key) = @_;
    croak 'Key not provided' unless $key;
    return $_config_data->{$key}->{validate};
}


sub get_doc
{
    my ($key) = @_;
    croak 'Key not provided' unless $key;

    my $data = $_config_data->{$key};

    return unless $data && $data->{doc};

    my $doc = '# ' . $data->{doc} . "\n";
    $doc .= '# Options: ' . $data->{options} . "\n" if $data->{options};

    return $doc;
}


sub set
{
    my ($key, $value) = @_;

    croak 'Key and value need to be provided'
        unless $key && defined($value);

    my $canon_value = _validate($key, $value);
    return unless $canon_value;

    return $canon_value if App::Zapzi::Config::set($key, $canon_value);
}

sub _validate
{
    # Check if value is a valid setting for key and return the
    # canonical version of value if OK, otherwise return undef.

    my ($key, $value) = @_;
    return unless $_config_data->{$key};

    return $_config_data->{$key}->{validate}($value);
}


sub get_user_configurable_keys
{
    my @keys = sort keys %{$_config_data};
    return @keys;
}


sub get_user_init_configurable_keys
{
    return grep { $_config_data->{$_}->{init_configurable} }
           keys %{$_config_data};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::UserConfig - get and set user configurable variables

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This class allows users to get and set configuration variables. This
is layered on top of App::Zapzi::Config which holds user and system
variables.

=head1 METHODS

=head2 get(key)

Returns the value of C<key> or undef if it does not exist.

=head2 get_description(key)

Returns the documentation for this config variable.

=head2 get_options(key)

Returns a description of the options for this config variable.

=head2 get_default(key)

Returns the default for this config variable.

=head2 get_validater(key)

Returns the validater sub ref for this config variable.

=head2 get_doc(key)

Returns the documentation for config C<key> or undef if it does not exist.

=head2 set(key, value)

Set the config parameter C<key> to C<value>.

=head2 get_user_configurable_keys

Returns a list of keys in the config store that are configurable by the user.

=head2 get_user_init_configurable_keys

Returns a list of keys in the config store that should be configured
by the user at init time.

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
