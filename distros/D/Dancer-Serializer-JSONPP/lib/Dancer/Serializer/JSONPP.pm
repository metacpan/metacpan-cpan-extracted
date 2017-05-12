package Dancer::Serializer::JSONPP;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.02';

use Dancer::Config 'setting';
use Dancer::SharedData;
use base 'Dancer::Serializer::Abstract';
use JSON::PP;

sub loaded { 1 }

sub _build_jsonpp {
    my $self = shift;

    my $json = JSON::PP->new;

    my $options = {};

    my $config = setting('engines') || {};
    $config = $config->{JSONPP} || $config->{JSON} || {};

    # straight pass through of config options to JSON
    map { $options->{$_} = $config->{$_} } keys %$config;

    # pull in config from serializer init as well (and possibly override settings from the conf file)
    map { $options->{$_} = $self->config->{$_} } keys %{$self->config};

    if (setting('environment') eq 'development' and not defined $options->{pretty}) {
        $options->{pretty} = 1;
    }

    # use live vars
    my $vars = Dancer::SharedData->vars;
    foreach my $k (%$vars) {
        next unless $k =~ /^jsonpp_/;
        my $k2 = $k; $k2 =~ s/^jsonpp_//;
        $options->{$k2} = $vars->{$k};
    }

    for my $method (keys %$options) {
        $json->$method( $options->{$method} );
    }

    return $json;
}

sub serialize {
    (shift)->_build_jsonpp->encode(@_);
}

sub deserialize {
    (shift)->_build_jsonpp->decode(@_);
}

sub content_type {'application/json'}

1;
__END__

=encoding utf-8

=head1 NAME

Dancer::Serializer::JSONPP - Dancer serializer with JSON::PP

=head1 SYNOPSIS

=head1 DESCRIPTION

This class is an interface between Dancer's serializer engine abstraction layer
and the L<JSON::PP> module.

In order to use this engine, use the template setting:

    serializer: JSONPP

This can be done in your config.yml file or directly in your app code with the
B<set> keyword.

    set serializer => 'JSONPP';

The L<JSON::PP> module will pass configuration variables straight through.
Some of these can be useful when debugging/developing your app: B<pretty> and
B<canonical>, and others useful with ORMs like L<DBIx::Class>: B<allow_blessed>
and B<convert_blessed>.  Please consult the L<JSON> documentation for more
information and a full list of configuration settings. You can add extra
settings to the B<engines> configuration to turn these on. For example:

    engines:
        JSONPP:
            allow_blessed:   '1'
            canonical:       '1'
            convert_blessed: '1'

but when you want to do changing configuration like B<sort_by>, try:

    var jsonpp_sort_by => sub { $JSON::PP::a cmp $JSON::PP::b };
    { 'a' => 1, 'b' => 2, 'aa' => 3, '1' => 4 }; # will output JSON with key ordered as 1, a, aa, b

all B<vars> started with jsonpp_ will be passed.

=head1 METHODS

=head2 serialize

Serialize a data structure to a JSON structure.

=head2 deserialize

Deserialize a JSON structure to a data structure

=head2 content_type

Return 'application/json'

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
