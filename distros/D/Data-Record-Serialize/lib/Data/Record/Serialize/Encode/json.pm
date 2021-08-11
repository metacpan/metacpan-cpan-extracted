package Data::Record::Serialize::Encode::json;

# ABSTRACT: encoded a record as JSON

use strict;
use warnings;

use Data::Record::Serialize::Error { errors => [ 'json_backend' ] }, -all;

use Moo::Role;

our $VERSION = '0.28';


BEGIN {
    my $Cpanel_JSON_XS_VERSION = 3.0236;

    if ( eval { require Cpanel::JSON::XS; Cpanel::JSON::XS->VERSION( $Cpanel_JSON_XS_VERSION ); 1;  } ) {
        *encode_json = \&Cpanel::JSON::XS::encode_json;
    }
    elsif ( eval { require JSON::PP } ) {
        *encode_json = \&JSON::PP::encode_json;
    }
    else {
        error( 'json_backend', "can't find either Cpanel::JSON::XS (>= $Cpanel_JSON_XS_VERSION) or JSON::PP. Please install one of them." );
    }
};

use namespace::clean;

has '+numify' => ( is => 'ro', default => 1 );
has '+stringify' => ( is => 'ro', default => 1 );

sub _needs_eol { 1 }









sub to_bool { $_[1] ? \1 : \0 }






sub encode { encode_json( $_[1] ) }

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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Data::Record::Serialize::Encode::json - encoded a record as JSON

=head1 VERSION

version 0.28

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'json', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::json> encodes a record as JSON.

If a field's type is C<N> or C<I>, it will be properly encoded by JSON
as a number.  Field's with type C<S> are force to be strings.

Boolean fields (type C<B>) are transformed into values recognized by
the back-end encoder.

The output consists of I<concatenated> JSON objects, and is mostly easily
read by an incremental decoder, e.g.

  use JSON::MaybeXS;

  @data = JSON->new->incr_parse( $json );

It performs the L<Data::Record::Serialize::Role::Encode> role.

=head1 METHODS

=head2 to_bool

   $bool = $self->to_bool( $truthy );

Convert a truthy value to something that the JSON encoders will recognize as a boolean.

=for Pod::Coverage encode

=for Pod::Coverage numify
stringify
encode_json

=head1 INTERFACE

There are no additional attributes which may be passed to
L<< Data::Record::Serialize::new|Data::Record::Serialize/new >>.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize

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
