package Data::Record::Serialize::Encode::yaml;

# ABSTRACT: encode a record as YAML

use Moo::Role;

use Data::Record::Serialize::Error { errors => [ 'yaml_backend' ] }, -all;
use Types::Standard qw[ Enum ];

use JSON::PP; # needed for JSON::PP::true/false

use namespace::clean;

our $VERSION = '1.04';

BEGIN {
    my $YAML_XS_VERSION = 0.67;

    if ( eval { require YAML::XS; YAML::XS->VERSION( $YAML_XS_VERSION ); 1; } )
    {
        *encode = sub {
            local $YAML::XS::Boolean = 'JSON::PP';
            YAML::XS::Dump( $_[1] );
          }
    }
    elsif ( eval { require YAML::PP } ) {
        my $processor = YAML::PP->new( boolean => 'JSON::PP' );
        *encode = sub { $processor->dump_string( $_[1] ) };
    }
    else {
        error( 'yaml_backend',
            "can't find either YAML::XS (>= $YAML_XS_VERSION) or YAML::PP. Please install one of them"
        );
    }
}

has '+numify' => ( is => 'ro', default => 1 );
has '+stringify' => ( is => 'ro', default => 1 );

sub _needs_eol { 1 }









sub to_bool { $_[1] ? JSON::PP::true : JSON::PP::false }






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

Data::Record::Serialize::Encode::yaml - encode a record as YAML

=head1 VERSION

version 1.04

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'yaml', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::yaml> encodes a record as YAML.  It uses uses either L<YAML::XS> or L<YAML::PP>.

It performs the L<Data::Record::Serialize::Role::Encode> role.

=head1 METHODS

=head2 to_bool

   $bool = $self->to_bool( $truthy );

Convert a truthy value to something that the YAML encoders will recognize as a boolean.

=for Pod::Coverage encode

=for Pod::Coverage numify
stringify

=head1 CONSTRUCTOR OPTIONS

=over

=item backend => C<YAML::XS> | C<YAML::PP>

Optional. Which YAML backend to use.  If not specified, searches for one of the two.

=back

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
