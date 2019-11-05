package Catmandu::Validator::JSONSchema;
use Catmandu::Sane;
use Moo;
use Catmandu::Util qw(:is :check);
use JSON::Validator;

our $VERSION = "0.12";

with qw(Catmandu::Validator);

has schema => (
    is => 'ro',
    required => 1
);

has _validator => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $validator = JSON::Validator->new;
        $validator->schema($_[0]->schema);
        $validator;
    }
);

sub validate_data {
    my($self, $hash)=@_;

    my $errors = undef;

    my @result = $self->_validator->validate($hash);

    if (@result) {
        $errors = [
            map {
                +{
                    property => $_->path(),
                    message => $_->message()
                };
            } @result
        ];
    }

    $errors;
}

1;
__END__

=head1 NAME

Catmandu::Validator::JSONSchema - An implementation of Catmandu::Validator to support JSON Schema

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-Validator-JSONSchema.svg?branch=master)](https://travis-ci.org/LibreCat/Catmandu-Validator-JSONSchema)
[![Coverage](https://coveralls.io/repos/LibreCat/Catmandu-Validator-JSONSchema/badge.svg?branch=master)](https://coveralls.io/r/LibreCat/Catmandu-Validator-JSONSchema)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Catmandu-Validator-JSONSchema.png)](http://cpants.cpanauthors.org/dist/Catmandu-Validator-JSONSchema)

=end markdown

=head1 SYNOPSIS

    use Catmandu::Validator::JSONSchema;
    use Data::Dumper;

    my $validator = Catmandu::Validator::JSONSchema->new(
        schema => {
            "properties"=> {
                "_id"=> {
                    "type"=> "string",
                    required => 1
                },
                "title"=> {
                    "type"=> "string",
                    required => 1
                },
                "author"=> {
                    "type"=> "array",
                    "items" => {
                        "type" => "string"
                    },
                    minItems => 1,
                    uniqueItems => 1
                }
            },
        }
    );

    my $object = {
        _id => "rug01:001963301",
        title => "In gesprek met Etienne Vermeersch : een zoektocht naar waarheid",
        author => [
            "Etienne Vermeersch",
            "Dirk Verhofstadt"
        ]
    };

    unless($validator->validate($object)){
        print Dumper($validator->last_errors());
    }

=head1 CONFIGURATION

=over

=item schema

JSON Schema given as hash reference, filename, or URL.

=back

=head1 NOTE

This module uses L<JSON::Validator>. Therefore the behaviour of your schema
should apply to draft 0i4 of the json schema:

L<http://json-schema.org/draft-04/schema>

L<http://tools.ietf.org/html/draft-zyp-json-schema-04>

=head1 SEE ALSO

L<Catmandu::Validator>

L<http://json-schema.org>

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
