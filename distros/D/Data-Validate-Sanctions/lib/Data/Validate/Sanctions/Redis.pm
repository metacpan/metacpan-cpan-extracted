package Data::Validate::Sanctions::Redis;

use strict;
use warnings;

use parent 'Data::Validate::Sanctions';

use Data::Validate::Sanctions::Fetcher;
use Scalar::Util    qw(blessed);
use List::Util      qw(max);
use JSON::MaybeUTF8 qw(encode_json_utf8 decode_json_utf8);
use YAML::XS        qw(DumpFile);
use Syntax::Keyword::Try;

our $VERSION = '0.16';    # VERSION

sub new {
    my ($class, %args) = @_;

    my $self = {};

    $self->{connection} = $args{connection} or die 'Redis connection is missing';

    $self->{sources} = [keys Data::Validate::Sanctions::Fetcher::config(eu_token => 'dummy')->%*];

    $self->{args} = {%args};

    $self->{last_modification} = 0;
    $self->{last_index}        = 0;
    $self->{last_data_load}    = 0;

    my $object = bless $self, ref($class) || $class;
    $object->_load_data();

    return $object;
}

sub set_sanction_file {
    die 'Not applicable';
}

sub get_sanction_file {
    die 'Not applicable';
}

sub get_sanctioned_info {
    my $self = shift;

    die "This function can only be called on an object" unless $self;

    return Data::Validate::Sanctions::get_sanctioned_info($self, @_);
}

sub _load_data {
    my $self = shift;

    $self->{last_modification}       //= 0;
    $self->{last_index}              //= 0;
    $self->{_data}                   //= {};
    $self->{_sanctioned_name_tokens} //= {};
    $self->{_token_sanctioned_names} //= {};

    return $self->{_data} if $self->{_data} and $self->{last_data_load} + $self->IGNORE_OPERATION_INTERVAL > time;

    my $latest_update = 0;
    for my $source ($self->{sources}->@*) {
        try {
            $self->{_data}->{$source} //= {};

            my ($updated) = $self->{connection}->hget("SANCTIONS::$source" => 'updated');
            $updated //= 0;
            my $current_update_date = $self->{_data}->{$source}->{updated} // 0;
            next if $current_update_date && $updated <= $current_update_date;

            my ($content, $verified, $error) = $self->{connection}->hmget("SANCTIONS::$source", qw/content verified error/)->@*;

            $self->{_data}->{$source}->{content}  = decode_json_utf8($content // '[]');
            $self->{_data}->{$source}->{verified} = $verified // 0;
            $self->{_data}->{$source}->{updated}  = $updated;
            $self->{_data}->{$source}->{error}    = $error // '';
            $latest_update                        = $updated if $updated > $latest_update;
        } catch ($e) {
            $self->{_data}->{$source}->{content}  = [];
            $self->{_data}->{$source}->{updated}  = 0;
            $self->{_data}->{$source}->{verified} = 0;
            $self->{_data}->{$source}->{error}    = "Failed to load from Redis: $e";
        }
    }

    $self->{last_modification} = $latest_update;
    $self->{last_data_load}    = time;

    return $self->{_data} if $latest_update <= $self->{last_index};

    $self->_index_data();

    foreach my $sanctioned_name (keys $self->{_index}->%*) {
        my @tokens = Data::Validate::Sanctions::_clean_names($sanctioned_name);
        $self->{_sanctioned_name_tokens}->{$sanctioned_name} = \@tokens;
        foreach my $token (@tokens) {
            $self->{_token_sanctioned_names}->{$token}->{$sanctioned_name} = 1;
        }
    }

    return $self->{_data};
}

sub _save_data {
    my $self = shift;

    for my $source ($self->{sources}->@*) {
        $self->{_data}->{$source}->{verified} = time;
        $self->{connection}->hmset(
            "SANCTIONS::$source",
            updated  => $self->{_data}->{$source}->{updated} // 0,
            content  => encode_json_utf8($self->{_data}->{$source}->{content} // []),
            verified => $self->{_data}->{$source}->{verified},
            error    => $self->{_data}->{$source}->{error} // ''
        );
    }

    return;
}

sub _default_sanction_file {
    die 'Not applicable';
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Validate::Sanctions::Redis - An extension of L<Data::Validate::Sanctions::Redis> that stores sanction data in redis.

=head1 SYNOPSIS
    ## no critic
    use Data::Validate::Sanctions::Redis;

    my $validator = Data::Validate::Sanctions::Redis->new(connection => $redis_read);

    # to validate clients by their name
    print 'BAD' if $validator->is_sanctioned("$last_name $first_name");
    # or by more profile data
    print 'BAD' if $validator->get_sanctioned_info(first_name => $first_name, last_name => $last_name, date_of_birth => $date_of_birth)->{matched};

    # to update the sanction dataset (needs redis write access)
    my $validator = Data::Validate::Sanctions::Redis->new(connection => $redis_write); ## no critic
    $validator->update_data(eu_token => $token);

    # create object from the parent (factory) class
    my $validator = Data::Validate::Sanctions->new(storage => 'redis', connection => $redis_write);

=head1 DESCRIPTION

Data::Validate::Sanctions::Redis is a simple validitor to validate a name against sanctions lists.
For more details about the sanction sources please refer to the parent module L<Data::Validate::Sanctions>.

=head1 METHODS

=head2 new

Create the object with the redis object:

    my $validator = Data::Validate::Sanctions::Redis->new(connection => $redis);

=head2 is_sanctioned

Checks if the input profile info matches a sanctioned entity.
The arguments are the same as those of B<get_sanctioned_info>.

It returns 1 if a match is found, otherwise 0.

=cut

=head2 get_sanctioned_info

Tries to find a match a sanction entry matching the input profile args.
It takes arguments in two forms. In the new API, it takes a hashref containing the following named arguments:

=over 4

=item * first_name: first name

=item * last_name: last name

=item * date_of_birth: (optional) date of birth as a string or epoch

=item * place_of_birth: (optional) place of birth as a country name or code

=item * residence: (optional) name or code of the country of residence

=item * nationality: (optional) name or code of the country of nationality

=item * citizen: (optional) name or code of the country of citizenship

=item * postal_code: (optional) postal/zip code

=item * national_id: (optional) national ID number

=item * passport_no: (oiptonal) passort number

=back

For backward compatibility it also supports the old API, taking the following args:

=over 4

=item * first_name: first name

=item * last_name: last name

=item * date_of_birth: (optional) date of birth as a string or epoch

=back

It returns a hash-ref containg the following data:

=over 4

=item - matched:      1 if a match was found; 0 otherwise

=item - list:         the source for the matched entry,

=item - matched_args: a name-value hash-ref of the similar arguments,

=item - comment:      additional comments if necessary,

=back

=cut

=head2 update_data

Fetches latest versions of sanction lists, and updates corresponding sections of stored file, if needed

=head2 last_updated

Returns timestamp of when the latest list was updated.
If argument is provided - return timestamp of when that list was updated.

=head2 _name_matches

Pass in the client's name and sanctioned individual's name to see if they are similar or not

=head1 AUTHOR

Binary.com E<lt>fayland@binary.comE<gt>

=head1 COPYRIGHT

Copyright 2022- Binary.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Data::Validate::Sanctions>

L<Data::Validate::Sanctions::Fetcher>

=cut
