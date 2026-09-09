package Data::Record::Serialize::Encode::json;

# ABSTRACT: encoded a record as JSON

use v5.12;
use strict;
use warnings;

use Data::Record::Serialize::Error { errors => ['json_backend'] }, -all;
use Module::Version;

use Moo::Role;

our $VERSION = '2.04';
our $JSON;

BEGIN {
    my $Cpanel_JSON_XS_VERSION = 3.0236;

    # Module::Version doesn't load the code, so avoids loading
    # Cpanel::JSON::XS's version of JSON::PP::Boolean which prevents
    # loading the version provided by JSON::PP if Cpanel::JSON::XS is
    # too old. Symbol::delete_package could be used to remove
    # Cpanel::JSON::XS's version, but it's better not to load it in
    # the first place.
    $JSON = do {
        if ( Module::Version::get_version( 'Cpanel::JSON::XS' ) >= $Cpanel_JSON_XS_VERSION ) {
            require Cpanel::JSON::XS;
            'Cpanel::JSON::XS';
        }
        elsif ( eval { require JSON::PP; 1; } ) {
            'JSON::PP';
        }
        else {
            error(
                'json_backend',
                q{can't find either Cpanel::JSON::XS (>= $Cpanel_JSON_XS_VERSION) or JSON::PP. Please install one of them.},
            );
        }
    };

}

use constant ENCODER_OPTIONS => qw(
  ascii latin1 utf8 pretty indent space_before space_after canonical
  allow_blessed convert_blessed
);

use namespace::clean;


has [ grep { $_ ne 'utf8' } ENCODER_OPTIONS ] => ( is => 'ro', default => !!0 );
has utf8                                      => ( is => 'ro', default => !!1 );

has _encoder => (
    is        => 'rwp',
    init_arg  => undef,
    clearer   => 1,
    predicate => 1,
);

has '+numify'    => ( is => 'ro', default => 1 );
has '+stringify' => ( is => 'ro', default => 1 );

sub _needs_eol { 1 }









sub to_bool { $_[1] ? \1 : \0 }






sub setup {

    my $self = shift;
    return if $self->_has_encoder;

    my $json = $JSON->new;

    for my $option ( ENCODER_OPTIONS ) {
        next unless $self->$option;
        $json = $json->$option( $self->$option );
    }

    $self->_set__encoder( $json );
}







sub encode { $_[0]->_encoder->encode( $_[1] ) }

with 'Data::Record::Serialize::Role::Encode';

1;

#
# This file is part of Data-Record-Serialize
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory truthy JSONL ascii latin1
numification

=head1 NAME

Data::Record::Serialize::Encode::json - encoded a record as JSON

=head1 VERSION

version 2.04

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'json', %options );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::json> encodes a record as JSONL.

If a field's type is C<N> or C<I>, it will be properly encoded by JSON
as a number.  Field's with type C<S> are forced to be strings.

Boolean fields (type C<B>) are transformed into values recognized by
the back-end encoder.

The output consists of one JSON object per line, and is mostly easily
read by an incremental decoder, e.g.

  use JSON::MaybeXS;

  @data = JSON->new->incr_parse( $json );

It performs the L<Data::Record::Serialize::Role::Encode> role.

=head2 Transformations of Objects

If the L</allow_blessed> and L</convert_blessed> flags are set, the
underlying JSON module will invoke the C<TO_JSON> method any values
which are objects, and which provide that method.

Unfortunately, these settings interact with the default values for
L<Data::Record::Serialize/stringify> and
L<Data::Record::Serialize/numify> set by this module, which are both
set to C<1>.

Stringification and numification are performed I<before> being sent to
the JSON serializer, so it will not see the original object, and thus
will not run its C<TO_JSON> method.

To remedy this, it's simplest to turn off stringification and
numification for individual attributes using
L</Data::Record::Serialize>/Field Selection Specifcations>.  For
example, if fields C<string_obj1> and C<num_obj1> are objects which
do not overload numification and stringification, but do support
C<TO_JSON>, then setting

  stringify       => ['-string_obj2'],
  numify          => ['-num_obj2'],
  allow_blessed   => 1,
  convert_blessed => 1,

will result in C<TO_JSON> being passed the actual objects.

=head1 METHODS

=head2 to_bool

   $bool = $self->to_bool( $truthy );

Convert a truthy value to something that the JSON encoders will recognize as a boolean.

=for Pod::Coverage setup

=for Pod::Coverage encode

=for Pod::Coverage numify
stringify
encode_json

=head1 CONSTRUCTOR OPTIONS

These are equivalent to the methods operating on the underlying JSON
object (see L<JSON::PP>).

=over

=item ascii => I<boolean>

=item latin1 => I<boolean>

=item utf8 => I<boolean>

=item pretty => I<boolean>

=item indent => I<boolean>

=item space_before => I<boolean>

=item space_after => I<boolean>

=item canonical => I<boolean>

=item allow_blessed => I<boolean>

=item convert_blessed => I<boolean>

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>

=head2 Source

Source is available at

  https://gitlab.com/djerius/data-record-serialize

and may be cloned from

  https://gitlab.com/djerius/data-record-serialize.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Data::Record::Serialize|Data::Record::Serialize>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
