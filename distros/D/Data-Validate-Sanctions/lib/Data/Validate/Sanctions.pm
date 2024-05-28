package Data::Validate::Sanctions;

use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/is_sanctioned set_sanction_file get_sanction_file/;

use Carp;
use Data::Validate::Sanctions::Fetcher;
use Data::Validate::Sanctions::Redis;
use File::stat;
use File::ShareDir;
use YAML::XS     qw/DumpFile LoadFile/;
use Scalar::Util qw(blessed);
use Date::Utility;
use Data::Compare;
use List::Util qw(any uniq max min);
use Locale::Country;
use Text::Trim qw(trim);
use Clone      qw(clone);

our $VERSION = '0.17';

my $sanction_file;
my $instance;

use constant IGNORE_OPERATION_INTERVAL => 8 * 60;    # 8 minutes

# for OO
sub new {    ## no critic (RequireArgUnpacking)
    my ($class, %args) = @_;

    my $storage = delete $args{storage} // '';

    return Data::Validate::Sanctions::Redis->new(%args) if $storage eq 'redis';

    my $self = {};

    $self->{sanction_file} = $args{sanction_file} // _default_sanction_file();

    $self->{args} = {%args};

    $self->{last_modification} = 0;
    $self->{last_index}        = 0;
    $self->{last_data_load}    = 0;

    return bless $self, ref($class) || $class;
}

sub update_data {
    my ($self, %args) = @_;

    $self->_load_data();

    my $new_data = Data::Validate::Sanctions::Fetcher::run($self->{args}->%*, %args);
    my $updated  = 0;
    foreach my $k (keys %$new_data) {
        $self->{_data}->{$k}            //= {};
        $self->{_data}->{$k}->{updated} //= 0;
        $self->{_data}->{$k}->{content} //= [];

        if (!$new_data->{$k}->{error} && $self->{_data}->{$k}->{error}) {
            delete $self->{_data}->{$k}->{error};
            $updated = 1;
        }

        if ($new_data->{$k}->{error}) {
            warn "$k list update failed because: $new_data->{$k}->{error}";
            $self->{_data}->{$k}->{error} = $new_data->{$k}->{error};
            $updated = 1;
        } elsif ($self->{_data}{$k}->{updated} != $new_data->{$k}->{updated}
            || scalar $self->{_data}{$k}->{content}->@* != scalar $new_data->{$k}->{content}->@*)
        {
            print "Source $k is updated with new data \n" if $args{verbose};
            $self->{_data}->{$k} = $new_data->{$k};
            $updated = 1;
        } else {
            print "Source $k is not changed \n" if $args{verbose};
        }
    }

    if ($updated) {
        $self->_save_data();
        $self->_index_data();
    }

    return;
}

sub last_updated {
    my $self = shift;
    my $list = shift;

    if ($list) {
        return $self->{_data}->{$list}->{updated};
    } else {
        $self->_load_data();
        return max(map { $_->{updated} // 0 } values %{$self->{_data}});
    }
}

sub set_sanction_file {    ## no critic (RequireArgUnpacking)
    $sanction_file = shift // die "sanction_file is needed";
    undef $instance;
    return;
}

sub get_sanction_file {
    $sanction_file //= _default_sanction_file();
    return $instance ? $instance->{sanction_file} : $sanction_file;
}

=head2 is_sanctioned

Checks if the input profile info matches a sanctioned entity.
The arguments are the same as those of B<get_sanctioned_info>.

It returns 1 if a match is found, otherwise 0.

=cut

sub is_sanctioned {    ## no critic (RequireArgUnpacking)
    return (get_sanctioned_info(@_))->{matched};
}

sub data {
    my ($self) = @_;

    $self->_load_data() unless $self->{_data};

    return $self->{_data};
}

=head2 _match_other_fields

Matches fields possibly available in addition to name and date of birth.

Returns a a hash-ref reporting the matched fields if it succeeeds; otherwise returns false (undef).

=cut

sub _match_other_fields {
    my ($self, $entry, $args) = @_;

    my @optional_fields = qw/place_of_birth residence nationality citizen postal_code national_id passport_no/;

    my $matched_args = {};
    for my $field (@optional_fields) {
        next unless ($args->{$field} && $entry->{$field} && $entry->{$field}->@*);

        return undef unless any { $args->{$field} eq $_ } $entry->{$field}->@*;
        $matched_args->{$field} = $args->{$field};
    }

    return $matched_args;
}

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

sub get_sanctioned_info {    ## no critic (RequireArgUnpacking)
    my $self = blessed($_[0]) ? shift : $instance;
    unless ($self) {
        $instance = __PACKAGE__->new(sanction_file => get_sanction_file());
        $self     = $instance;
    }

    # It's the old interface
    my ($first_name, $last_name, $date_of_birth) = @_;
    my $args = {};

    # in the new interface we accept fields in a hashref
    if (ref $_[0] eq 'HASH') {
        ($args) = @_;
        ($first_name, $last_name, $date_of_birth) = $args->@{qw/first_name last_name date_of_birth/};
    }

    # convert country names to iso codes
    for my $field (qw/place_of_birth residence nationality citizen/) {
        my $value = $args->{$field};
        next unless $value;

        $args->{$field} = Data::Validate::Sanctions::Fetcher::get_country_code($value);
    }

    $self->_load_data();

    my $client_full_name = join(' ', $first_name, $last_name || ());

    # Split into tokens after cleaning
    my @client_name_tokens = _clean_names($client_full_name);

    my @match_with_dob_text;

    # only pick the sanctioned names which have common token with the client tokens
    # and deduplicate the list
    my $filtered_sanctioned_names = {};
    foreach my $token (@client_name_tokens) {
        foreach my $name (keys %{$self->{_token_sanctioned_names}->{$token}}) {
            $filtered_sanctioned_names->{$name} = 1;
        }
    }

    foreach my $sanctioned_name (keys %{$filtered_sanctioned_names}) {
        my $sanctioned_name_tokens = $self->{_sanctioned_name_tokens}->{$sanctioned_name};
        next unless _name_matches(\@client_name_tokens, $sanctioned_name_tokens);

        for my $entry ($self->{_index}->{$sanctioned_name}->@*) {
            my $matched_args = $self->_match_other_fields($entry, $args);
            next unless $matched_args;
            $matched_args->{name} = $sanctioned_name;

            # dob is matched only if it's included in lookup args
            return _possible_match($entry->{source}, \%$matched_args) unless defined $date_of_birth;

            # 1- Some entries in sanction list can have more than one date of birth
            # 2- first epoch is compared, then year
            my $client_dob_date = Date::Utility->new($date_of_birth);
            $args->{dob_epoch} = $client_dob_date->epoch;
            $args->{dob_year}  = $client_dob_date->year;

            for my $dob_field (qw/dob_epoch dob_year/) {
                $entry->{$dob_field} //= [];
                my $checked_dob = any { $_ eq $args->{$dob_field} } $entry->{$dob_field}->@*;

                return _possible_match($entry->{source}, {%$matched_args, $dob_field => $args->{$dob_field}}) if $checked_dob;
            }

            # Saving names with dob_text for later check.
            my $has_no_epoch_or_year = ($entry->{dob_epoch}->@* || $entry->{dob_year}->@*) ? 0 : 1;
            my $has_dob_text         = @{$entry->{dob_text} // []}                         ? 1 : 0;
            if ($has_dob_text || $has_no_epoch_or_year) {
                push @match_with_dob_text,
                    {
                    name         => $sanctioned_name,
                    entry        => $entry,
                    matched_args => $matched_args,
                    };
            }
        }
    }

    # Return a possible match if the name matches and no date of birth is present in sanctions
    for my $match (@match_with_dob_text) {
        # We match only in case we have full match for the name
        # in other case we may get to many false positive
        my ($sanction_name, $client_name) = map { uc(s/[^[:alpha:]\s]//gr) } ($match->{name}, $client_full_name);

        next unless $sanction_name eq $client_name;

        my $dob_text = $match->{entry}->{dob_text} // [];

        my $comment;
        if (@$dob_text) {
            $comment = 'dob raw text: ' . join q{, } => @$dob_text;
        }

        return _possible_match($match->{entry}->{source}, $match->{matched_args}, $comment);
    }

    # Return if no possible match, regardless if date of birth is provided or not
    return {matched => 0};
}

sub _load_data {
    my $self          = shift;
    my $sanction_file = $self->{sanction_file};
    $self->{last_modification}       //= 0;
    $self->{last_index}              //= 0;
    $self->{last_data_load}          //= 0;
    $self->{_data}                   //= {};
    $self->{_sanctioned_name_tokens} //= {};
    $self->{_token_sanctioned_names} //= {};

    return $self->{_data} if $self->{_data} and $self->{last_data_load} + $self->IGNORE_OPERATION_INTERVAL > time;

    if (-e $sanction_file) {
        my $file_modify_time = stat($sanction_file)->mtime;
        return $self->{_data} if $file_modify_time <= $self->{last_modification} && $self->{_data};
        $self->{last_modification} = $file_modify_time;
        $self->{_data}             = LoadFile($sanction_file);
        $self->{last_data_load}    = time;
    }

    $self->_index_data();

    foreach my $sanctioned_name (keys $self->{_index}->%*) {
        my @tokens = _clean_names($sanctioned_name);
        $self->{_sanctioned_name_tokens}->{$sanctioned_name} = \@tokens;
        foreach my $token (@tokens) {
            $self->{_token_sanctioned_names}->{$token}->{$sanctioned_name} = 1;
        }
    }

    return $self->{_data};
}

=head2 _index_data

Indexes data by name. Each name may have multiple matching entries.

=cut

sub _index_data {
    my $self = shift;

    $self->{_data} //= {};
    $self->{_index} = {};
    for my $source (keys $self->{_data}->%*) {
        my @content = clone($self->{_data}->{$source}->{content} // [])->@*;

        for my $entry (@content) {
            $entry->{source} = $source;
            for my $name ($entry->{names}->@*) {
                $name = ucfirst($name);
                my $entry_list = $self->{_index}->{$name} // [];
                push @$entry_list, $entry;
                $self->{_index}->{$name} = $entry_list;
            }
        }
    }

    $self->{last_index} = time;

    return;
}

sub _save_data {
    my $self = shift;

    my $sanction_file     = $self->{sanction_file};
    my $new_sanction_file = $sanction_file . ".tmp";

    DumpFile($new_sanction_file, $self->{_data});

    rename $new_sanction_file, $sanction_file or die "Can't rename $new_sanction_file to $sanction_file, please check it\n";
    $self->{last_modification} = stat($sanction_file)->mtime;
    return;
}

sub _default_sanction_file {
    return $ENV{SANCTION_FILE} // File::ShareDir::dist_file('Data-Validate-Sanctions', 'sanctions.yml');
}

sub _possible_match {
    my ($list, $matched_args, $comment) = @_;

    return +{
        matched      => 1,
        list         => $list,
        matched_args => $matched_args,
        comment      => $comment,
    };
}

sub _clean_names {
    my ($full_name) = @_;

    # Remove non-alphabets
    my @cleaned_full_name = split " ", uc($full_name =~ s/[^[:alpha:]\s]//gr);

    return @cleaned_full_name;
}

sub _name_matches {
    my ($small_tokens_list, $bigger_tokens_list) = @_;

    my $name_matches_count = 0;

    foreach my $token (@$small_tokens_list) {
        $name_matches_count++ if any { $_ eq $token } @$bigger_tokens_list;
    }

    my $small_tokens_size = min(scalar(@$small_tokens_list), scalar(@$bigger_tokens_list));

    # - If more than one word matches, return it as possible match
    # - Some sanctioned individuals have only one name (ex. Hamza); this should be returned as well
    return 1 if ($name_matches_count > 1) || ($name_matches_count == 1 && $small_tokens_size == 1);

    return 0;
}

sub export_data {
    my ($self, $path) = @_;

    return DumpFile($path, $self->{_data});
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Validate::Sanctions - Validate a name against sanctions lists

=head1 SYNOPSIS

    # as exported function
    use Data::Validate::Sanctions qw/is_sanctioned get_sanction_file set_sanction_file/;
    set_sanction_file('/var/storage/sanction.csv');

    my ($first_name, $last_name) = ("First", "Last Name");
    print 'BAD' if is_sanctioned($first_name, $last_name);

    # as OO
    use Data::Validate::Sanctions;

    #You can also set sanction_file in the new method.
    my $validator = Data::Validate::Sanctions->new(sanction_file => '/var/storage/sanction.csv');
    print 'BAD' if $validator->is_sanctioned("$last_name $first_name");

=head1 DESCRIPTION

Data::Validate::Sanctions is a simple validitor to validate a name against sanctions lists.

The list is from:
- L<https://www.treasury.gov/ofac/downloads/sdn.csv>,
- L<https://www.treasury.gov/ofac/downloads/consolidated/cons_prim.csv>
- L<https://ofsistorage.blob.core.windows.net/publishlive/ConList.csv>
- L<https://webgate.ec.europa.eu/fsd/fsf/public/files/xmlFullSanctionsList_1_1/content?token=$eu_token>

run F<update_sanctions_csv> to update the bundled csv.

The path of list can be set by function L</set_sanction_file> or by method L</new>. If not set, then environment variable $ENV{SANCTION_FILE} will be checked, at last
the default file in this package will be used.

=head1 METHODS

=head2 is_sanctioned

    is_sanctioned($last_name, $first_name);
    is_sanctioned($first_name, $last_name);
    is_sanctioned("$last_name $first_name");

when one string is passed, please be sure last_name is before first_name.

or you can pass first_name, last_name (last_name, first_name), we'll check both "$last_name $first_name" and "$first_name $last_name".

retrun 1 if match is found and 0 if match is not found.

It will remove all non-alpha chars and compare with the list we have.

=head2 get_sanctioned_info

    my $result =get_sanctioned_info($last_name, $first_name, $date_of_birth);
    print 'match: ', $result->{matched_args}->{name}, ' on list ', $result->{list} if $result->{matched};

return hashref with keys:
    B<matched>      1 or 0, depends if name has matched
    B<list>         name of list matched (present only if matched)
    B<matched_args> The list of arguments matched (name, date of birth, residence, etc.)

It will remove all non-alpha chars and compare with the list we have.

=head2 update_data

Fetches latest versions of sanction lists, and updates corresponding sections of stored file, if needed

=head2 last_updated

Returns timestamp of when the latest list was updated.
If argument is provided - return timestamp of when that list was updated.

=head2 new

Create the object, and set sanction_file

    my $validator = Data::Validate::Sanctions->new(sanction_file => '/var/storage/sanction.csv');

=head2 get_sanction_file

get sanction_file which is used by L</is_sanctioned> (procedure-oriented)

=head2 set_sanction_file

set sanction_file which is used by L</is_sanctioned> (procedure-oriented)

=head2 _name_matches

Pass in the client's name and sanctioned individual's name to see if they are similar or not


=head2 export_data

Exports the sanction lists to a local file in YAML format.

=head2 data

Gets the sanction list content with lazy loading.

=head1 AUTHOR

Binary.com E<lt>fayland@binary.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Binary.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Data::OFAC>

=cut
