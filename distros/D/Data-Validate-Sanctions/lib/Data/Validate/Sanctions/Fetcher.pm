package Data::Validate::Sanctions::Fetcher;

use strict;
use warnings;

use DateTime::Format::Strptime;
use Date::Utility;
use IO::Uncompress::Unzip qw(unzip $UnzipError);
use List::Util            qw(uniq any);
use Mojo::UserAgent;
use Text::CSV;
use Text::Trim qw(trim);
use Syntax::Keyword::Try;
use XML::Fast;
use Locale::Country;
use JSON        qw(to_json);
use Digest::SHA qw(sha256_hex);
use Encode      qw(encode);

use constant MAX_REDIRECTS => 3;
our $VERSION = '0.19';    # VERSION

=head2 config

Creastes a hash-ref of sanction source configuration, including their url, description and parser callback.
It accepts the following list of named args:

=over 4

=item B<-eu_token>: required if B<eu_url> is empty

The token required for accessing EU sanctions (usually added as an arg to URL).

=item <eu_url>: required if B<eu_token> is empty

EU Sanctions full url, token included.

=item B<ofac_sdn_url>: optional

OFAC-SDN download url.

=item B<ofac_consolidated_url>: optional

OFAC Consilidated download url.

=item B<hmt_url>: optional

MHT Sanctions download url.

=back

=cut

sub config {
    my %args = @_;

    my $eu_token = $args{eu_token} // $ENV{EU_SANCTIONS_TOKEN};
    my $eu_url   = $args{eu_url} || $ENV{EU_SANCTIONS_URL};

    warn 'EU Sanctions will fail whithout eu_token or eu_url' unless $eu_token or $eu_url;

    if ($eu_token) {
        $eu_url ||= "https://webgate.ec.europa.eu/fsd/fsf/public/files/xmlFullSanctionsList_1_1/content?token=$eu_token";
    }

    return {
        'OFAC-SDN' => {
            description => 'TREASURY.GOV: Specially Designated Nationals List with a.k.a included',
            url         => $args{ofac_sdn_url}
                || 'https://www.treasury.gov/ofac/downloads/sdn_xml.zip',    #let's be polite and use zippped version of this 7mb+ file
            parser => \&_ofac_xml_zip,
        },
        'OFAC-Consolidated' => {
            description => 'TREASURY.GOV: Consolidated Sanctions List Data Files',
            url         => $args{ofac_consolidated_url} || 'https://www.treasury.gov/ofac/downloads/consolidated/consolidated.xml',
            parser      => \&_ofac_xml,
        },
        'HMT-Sanctions' => {
            description => 'GOV.UK: Financial sanctions: consolidated list of targets',
            url         => $args{hmt_url} || 'https://ofsistorage.blob.core.windows.net/publishlive/ConList.csv',
            parser      => \&_hmt_csv,
        },
        'EU-Sanctions' => {
            description => 'EUROPA.EU: Consolidated list of persons, groups and entities subject to EU financial sanctions',
            url         => $eu_url,
            parser      => \&_eu_xml,
        },
        'UNSC-Sanctions' => {
            description => 'UN: United Nations Security Council Consolidated List',
            url         => $args{unsc_url} || 'https://scsanctions.un.org/resources/xml/en/consolidated.xml',
            parser      => \&_unsc_xml,
        },
        'MOHA-Sanctions' => {
            description => 'MOHA: Sanction list made by the ministry of home affairs Malaysia',
            url         => $args{moha_url}
                || 'https://www.moha.gov.my/images/SenaraiKementerianDalamNegeri/September2024/ENG/SENARAI%20KDN%202024_5SEPTEMBER2024-ENG.xml',
            parser => \&_moha_xml,
        },
    };
}

#
# Parsers - returns timestamp of last update and arrayref of names
#

sub _process_name {
    my $r = join ' ', @_;
    $r =~ s/^\s+|\s+$//g;
    return $r;
}

sub _ofac_xml_zip {
    my $raw_data = shift;
    my $output;
    unzip \$raw_data => \$output or die "unzip failed: $UnzipError\n";
    return _ofac_xml($output);
}

sub _date_to_epoch {
    my $date = shift;

    $date = "$3-$2-$1" if $date =~ m/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/;

    my $result = eval { Date::Utility->new($date)->epoch; };
    return $result;
}

=head2 get_country_code

If the arg is a country code, it's returned in lower case; otherwise the arg is converted to country code.

=cut

sub get_country_code {
    my $value = trim shift;

    return lc(code2country($value) ? $value : country2code($value) // '');
}

=head2 _process_sanction_entry

Processes an entry retrieved from sanction resources and saves it into the specified key-value dataset.
An entry may have multilpe names (aliases), each of which will be taken as a key in the dataset with the same values/info.

It takes following list of args:

=over 4

=item - dataset: A hash ref of form [ name => info ] in which the entry will be saved

=item - data: a hash of entry data that may contain:

=over 4

=item * name: an array of names/aliases

=item * date_of_birth: an array of dates of birth

Dates of birth are not of standardized format in some data sources; so they are processed in three steps:
1- as a first step it will be tried to converetd them into epoch, saved as B<dob_epoch>;
2- otherwise to extract year (or an array of years) of birth, saved as B<dob_year>; and
3- finally, to saved as raw text in B<dob_text>.

=item * place_of_birth: an array of country names or codes

=item * residence: an array of country names or codes

=item * nationality: an array of country names or codes

=item * citizen: an array of country names or codes

=item * postal_code: an array of postal/zip codes

=item * national_id: an array of national ID numbers

=item * passport_no: an array of passort numbers

=back

=back

=cut

sub _process_sanction_entry {
    my ($dataset, %data) = @_;

    my @dob_list = $data{date_of_birth}->@*;
    my (@dob_epoch, @dob_year, @dob_text);

    for my $dob (@dob_list) {
        $dob = trim($dob);
        next unless $dob;

        $dob =~ s/[ \/]/-/g;
        #dobs with month = day = 0 are converted to year.
        if ($dob =~ m/^(\d{1,2})-(\d{1,2})-(\d{4})$/) {
            $dob = $3 if $1 == 0 or $2 == 0;
        } elsif ($dob =~ m/^(\d{4})-(\d0{1,2})-(\d{1,2})$/) {
            $dob = $1 if $2 == 0 or $3 == 0;
        }
        $dob = $1 if $dob =~ m/^[A-Z][a-z]{2}-(\d{4})$/;

        if ($dob =~ m/^\d{4}$/) {
            push @dob_year, $dob;
        } elsif ($dob =~ m/(\d{4}).*to.*(\d{4})$/) {
            push @dob_year, ($1 .. $2);
        } else {
            my $epoch = _date_to_epoch($dob);
            (defined $epoch) ? push(@dob_epoch, $epoch) : push(@dob_text, $dob);
        }
    }
    delete $data{date_of_birth};
    $data{dob_epoch} = \@dob_epoch;
    $data{dob_year}  = \@dob_year;
    $data{dob_text}  = \@dob_text;

    # convert all country names to iso codes
    for my $field (qw/place_of_birth residence nationality citizen/) {
        $data{$field} = [map { get_country_code($_) } $data{$field}->@*];
        $data{$field} = [grep { $_ } $data{$field}->@*];
    }

    # remove commas
    $data{names} = [map { trim($_) =~ s/,//gr } $data{names}->@*];

    # make values unique
    %data = map { $_ => [uniq $data{$_}->@*] } keys %data;
    # remove empty values
    for (keys %data) {
        # dob = 0 is acceptable
        next if $_ eq 'dob_epoch';

        $data{$_} = [grep { $_ } $data{$_}->@*];
    }
    # remove fields with empty list
    %data = %data{grep { $data{$_}->@* } keys %data};

    push $dataset->@*, \%data if $data{names};

    return $dataset;
}

sub _ofac_xml {
    my $raw_data = shift;

    my $ref = xml2hash($raw_data, array => ['aka'])->{sdnList};

    my $publish_epoch =
        $ref->{publshInformation}{Publish_Date} =~ m/(\d{1,2})\/(\d{1,2})\/(\d{4})/
        ? _date_to_epoch("$3-$1-$2")
        : undef;    # publshInformation is a typo in ofac xml tags
    die "Corrupt data. Release date is invalid\n" unless defined $publish_epoch;

    my $parse_list_node = sub {
        my ($entry, $parent, $child, $attribute) = @_;

        my $node = $entry->{$parent}->{$child} // [];
        $node = [$node] if (ref $node eq 'HASH');

        return map { $_->{$attribute} // () } @$node;
    };

    my $dataset = [];

    foreach my $entry (@{$ref->{sdnEntry}}) {
        next unless $entry->{sdnType} eq 'Individual';

        my @names;
        for ($entry, @{$entry->{akaList}{aka} // []}) {
            my $category = $_->{category} // 'strong';
            push @names, _process_name($_->{firstName} // '', $_->{lastName} // '') if $category eq 'strong';
        }

        # my @dob_list;
        # my $dobs = $entry->{dateOfBirthList}{dateOfBirthItem};
        # # In one of the xml files, some of the clients have more than one date of birth
        # # Hence, $dob can be either an array or a hashref
        # foreach my $dob (map { $_->{dateOfBirth} || () } (ref($dobs) eq 'ARRAY' ? @$dobs : $dobs)) {
        #     push @dob_list, $dob;
        # }
        my @dob_list    = $parse_list_node->($entry, 'dateOfBirthList',  'dateOfBirthItem', 'dateOfBirth');
        my @citizen     = $parse_list_node->($entry, 'citizenshipList',  'citizenship',     'country');
        my @residence   = $parse_list_node->($entry, 'addressList',      'address',         'country');
        my @postal_code = $parse_list_node->($entry, 'addressList',      'address',         'postalCode');
        my @nationality = $parse_list_node->($entry, 'naationalityList', 'nationality',     'country');

        my @place_of_birth = $parse_list_node->($entry, 'placeOfBirthList', 'placeOfBirthItem', 'placeOfBirth');
        @place_of_birth = map { my @parts = split ',', $_; $parts[-1] } @place_of_birth;

        my $id_list = $entry->{idList}->{id} // [];
        $id_list = [$id_list] if ref $id_list eq 'HASH';
        my @passport_no = map { $_->{idType} eq 'Passport'    ? $_->{idNumber} : () } @$id_list;
        my @national_id = map { $_->{idType} =~ 'National ID' ? $_->{idNumber} : () } @$id_list;

        _process_sanction_entry(
            $dataset,
            names          => \@names,
            date_of_birth  => \@dob_list,
            place_of_birth => \@place_of_birth,
            residence      => \@residence,
            nationality    => \@nationality,
            citizen        => \@citizen,
            postal_code    => \@postal_code,
            national_id    => \@national_id,
            passport_no    => \@passport_no,
        );
    }

    return {
        updated => $publish_epoch,
        content => $dataset,
    };
}

sub _hmt_csv {
    my $raw_data = shift;
    my $dataset  = [];

    my $csv = Text::CSV->new({binary => 1}) or die "Cannot use CSV: " . Text::CSV->error_diag() . "\n";

    my @lines = split("\n", $raw_data);

    my $parsed = $csv->parse(trim(shift @lines));
    my @info   = $parsed ? $csv->fields() : ();
    die "Currupt data. Release date was not found\n" unless @info && _date_to_epoch($info[1]);

    my $publish_epoch = _date_to_epoch($info[1]);
    die "Currupt data. Release date is invalid\n" unless defined $publish_epoch;

    $parsed = $csv->parse(trim(shift @lines));
    my @row    = $csv->fields();
    my %column = map { trim($row[$_]) => $_ } (0 .. @row - 1);

    foreach my $line (@lines) {
        $line = trim($line);

        $parsed = $csv->parse($line);
        next unless $parsed;

        my @row = $csv->fields();

        @row = map { trim($_ =~ s/\([^(]*\)$//r) } @row;

        ($row[$column{'Group Type'}] eq "Individual") or next;
        my $name = _process_name @row[0 .. 5];

        next if $name =~ /^\s*$/;

        my $date_of_birth  = $row[$column{'DOB'}];
        my $place_of_birth = $row[$column{'Country of Birth'}];
        # nationality is saved as an adjective (Iranian, American, etc); let's ignore it.
        my $nationality = '';
        my $residence   = $row[$column{'Country'}];
        my $postal_code = $row[$column{'Post/Zip Code'}];
        my $national_id = $row[$column{'National Identification Number'}];

        # Fields to be added in the  new file format (https://redmine.deriv.cloud/issues/51922)
        # We can read these fields normally after the data is released in the new format
        my ($passport_no, $non_latin_alias);
        $passport_no     = $row[$column{'Passport Number'}]       if defined $column{'Passport Number'};
        $non_latin_alias = $row[$column{'Name Non-Latin Script'}] if defined $column{'Name Non-Latin Script'};

        _process_sanction_entry(
            $dataset,
            names          => [$name, $non_latin_alias ? $non_latin_alias : ()],
            date_of_birth  => [$date_of_birth],
            place_of_birth => [$place_of_birth],
            residence      => [$residence],
            nationality    => [$nationality],
            postal_code    => [$postal_code],
            national_id    => [$national_id],
            $passport_no ? (passport_no => [$passport_no]) : (),
        );
    }

    return {
        updated => $publish_epoch,
        content => $dataset,
    };
}

sub _eu_xml {
    my $raw_data = shift;
    my $ref      = xml2hash($raw_data, array => ['nameAlias', 'birthdate'])->{export};
    my $dataset  = [];

    foreach my $entry (@{$ref->{sanctionEntity}}) {
        next unless $entry->{subjectType}->{'-code'} eq 'person';

        for (qw/birthdate citizenship address identification/) {
            $entry->{$_} //= [];
            $entry->{$_} = [$entry->{$_}] if ref $entry->{$_} eq 'HASH';
        }

        my @names;
        for (@{$entry->{nameAlias} // []}) {
            my $name = $_->{'-wholeName'};
            $name = join ' ', ($_->{'-firstName'} // '', $_->{'-lastName'} // '') unless $name;
            push @names, $name if $name ne ' ';
        }

        my @dob_list;
        foreach my $dob ($entry->{birthdate}->@*) {
            push @dob_list, $dob->{'-birthdate'} if $dob->{'-birthdate'};
            push @dob_list, $dob->{'-year'}      if not $dob->{'-birthdate'} and $dob->{'-year'};
        }

        my @place_of_birth = map { $_->{'-countryIso2Code'} || () } $entry->{birthdate}->@*;
        my @citizen        = map { $_->{'-countryIso2Code'} || () } $entry->{citizenship}->@*;
        my @residence      = map { $_->{'-countryIso2Code'} || () } $entry->{address}->@*;
        my @postal_code    = map { $_->{'-zipCode'}         || $_->{'-poBox'} || () } $entry->{address}->@*;
        my @nationality    = map { $_->{'-countryIso2Code'} || () } $entry->{identification}->@*;
        my @national_id    = map { $_->{'-identificationTypeCode'} eq 'id'       ? $_->{'-number'} || () : () } $entry->{identification}->@*;
        my @passport_no    = map { $_->{'-identificationTypeCode'} eq 'passport' ? $_->{'-number'} || () : () } $entry->{identification}->@*;

        _process_sanction_entry(
            $dataset,
            names          => \@names,
            date_of_birth  => \@dob_list,
            place_of_birth => \@place_of_birth,
            residence      => \@residence,
            nationality    => \@nationality,
            citizen        => \@citizen,
            postal_code    => \@postal_code,
            national_id    => \@national_id,
            passport_no    => \@passport_no,
        );
    }

    my @date_parts    = split('T', $ref->{'-generationDate'} // '');
    my $publish_epoch = _date_to_epoch($date_parts[0]        // '');

    die "Corrupt data. Release date is invalid\n" unless $publish_epoch;

    return {
        updated => $publish_epoch,
        content => $dataset,
    };
}

sub _unsc_xml {
    my ($xml_content) = @_;

    # Preprocess the XML content to escape unescaped ampersands
    $xml_content =~ s/&(?!(?:amp|lt|gt|quot|apos);)/&amp;/g;
    my $data = xml2hash($xml_content,
        array =>
            ['INDIVIDUAL', 'INDIVIDUAL_ALIAS', 'INDIVIDUAL_ADDRESS', 'INDIVIDUAL_DATE_OF_BIRTH', 'INDIVIDUAL_PLACE_OF_BIRTH', 'INDIVIDUAL_DOCUMENT'])
        ->{CONSOLIDATED_LIST};

    # Extract the dateGenerated attribute from the first line of the XML content
    my ($date_generated) = $data->{'-dateGenerated'};
    die "Corrupt data. Release date is missing\n" unless $date_generated;

    # Convert the dateGenerated to epoch milliseconds
    my $publish_epoch = _date_to_epoch($date_generated // '');

    my $dataset = [];

    for my $individual (@{$data->{'INDIVIDUALS'}->{'INDIVIDUAL'}}) {
        my %entry;

        $entry{first_name}           = $individual->{'FIRST_NAME'};
        $entry{second_name}          = $individual->{'SECOND_NAME'};
        $entry{third_name}           = $individual->{'THIRD_NAME'}           // '';
        $entry{fourth_name}          = $individual->{'FOURTH_NAME'}          // '';
        $entry{name_original_script} = $individual->{'NAME_ORIGINAL_SCRIPT'} // '';

        my @names = (
            $entry{first_name}           // '',
            $entry{second_name}          // '',
            $entry{third_name}           // '',
            $entry{fourth_name}          // '',
            $entry{name_original_script} // '',
        );

        foreach my $alias (@{$individual->{INDIVIDUAL_ALIAS}}) {
            if (ref($alias->{'ALIAS_NAME'}) ne 'HASH' || %{$alias->{'ALIAS_NAME'}}) {
                push @names, $alias->{'ALIAS_NAME'} // '';
            }
        }
        my @dob_list;

        if ($individual->{'INDIVIDUAL_DATE_OF_BIRTH'}[0]{'TYPE_OF_DATE'} && $individual->{'INDIVIDUAL_DATE_OF_BIRTH'}[0]{'TYPE_OF_DATE'} eq 'BETWEEN')
        {
            push @dob_list, $individual->{'INDIVIDUAL_DATE_OF_BIRTH'}[0]{'FROM_YEAR'} // '';
            push @dob_list, $individual->{'INDIVIDUAL_DATE_OF_BIRTH'}[0]{'TO_YEAR'}   // '';
        } else {
            if ($individual->{'INDIVIDUAL_DATE_OF_BIRTH'}[0]{'DATE'}) {
                @dob_list = $individual->{'INDIVIDUAL_DATE_OF_BIRTH'}[0]{'DATE'};
            } elsif ($individual->{'INDIVIDUAL_DATE_OF_BIRTH'}[0]{'YEAR'}) {
                @dob_list = $individual->{'INDIVIDUAL_DATE_OF_BIRTH'}[0]{'YEAR'};
            }
        }

        my @place_of_birth = (
            $individual->{'INDIVIDUAL_PLACE_OF_BIRTH'}[0]{'CITY'}           // '',
            $individual->{'INDIVIDUAL_PLACE_OF_BIRTH'}[0]{'STATE_PROVINCE'} // '',
            $individual->{'INDIVIDUAL_PLACE_OF_BIRTH'}[0]{'COUNTRY'}        // ''
        );

        my @residence   = (map { $_->{'COUNTRY'}  // '' } @{$individual->{'INDIVIDUAL_ADDRESS'}});
        my @postal_code = (map { $_->{'ZIP_CODE'} // '' } @{$individual->{'INDIVIDUAL_ADDRESS'}});

        my @nationality = ($individual->{'NATIONALITY'}->{'VALUE'} // '');
        my @national_id = [];
        my @passport_no = [];

        # Extract passport and national identification numbers
        foreach my $document (@{$individual->{INDIVIDUAL_DOCUMENT}}) {
            if ($document ne "") {
                if ($document->{'TYPE_OF_DOCUMENT'} eq 'Passport') {
                    push @passport_no, $document->{'NUMBER'} // '';
                } elsif ($document->{'TYPE_OF_DOCUMENT'} eq 'National Identification Number') {
                    push @national_id, $document->{'NUMBER'} // '';
                }
            }
        }

        _process_sanction_entry(
            $dataset,
            names          => \@names,
            date_of_birth  => \@dob_list,
            place_of_birth => \@place_of_birth,
            residence      => \@residence,
            nationality    => \@nationality,
            citizen        => \@nationality,      # no seprate field for citizenship in the XML
            postal_code    => \@postal_code,
            national_id    => \@national_id,
            passport_no    => \@passport_no,
        );
    }

    return {
        updated => $publish_epoch,
        content => $dataset,
    };
}

=head2 _moha_xml

Parses the XML data from MOHA (Ministry of Home Affairs Malaysia) and returns a hash-ref of the parsed data.

=cut

sub _moha_xml {
    my $raw_data = shift;

    # Parse the XML data using XML::Fast
    my $data = eval { xml2hash($raw_data) };

    if ($@ || !$data) {
        warn "Error parsing XML: $@\n";
        return;
    }

    # Access the creation date for the publish timestamp
    my $publish_date  = $data->{'TaggedPDF-doc'}{'x:xmpmeta'}{'rdf:RDF'}{'rdf:Description'}{'xmp:CreateDate'};
    my $publish_epoch = _date_to_epoch($publish_date);
    die "Invalid or missing creation date in XML\n" unless $publish_epoch;

    # Access the relevant table structure
    my $tables = $data->{'TaggedPDF-doc'}{'Part'}{'Table'};

    my $dataset = [];
    foreach my $table (@$tables) {
        my $rows = $table->{'TBody'}{'TR'};
        next unless ref $rows eq 'ARRAY';

        # Skip the header row
        foreach my $row (@$rows[1 .. $#$rows]) {
            my $cells = $row->{'TD'};
            next unless @$cells >= 13;

            my $name                  = $cells->[2]{'P'};
            my $date_of_birth         = $cells->[5]{'P'};
            my $other_name            = $cells->[7]{'P'};
            my $place_of_birth        = $cells->[6]{'P'};
            my $nationality           = $cells->[8]{'P'};
            my $passport_number       = $cells->[9]{'P'};
            my $identification_number = $cells->[10]{'P'};

            # Trim whitespace from values
            for ($name, $date_of_birth, $other_name, $place_of_birth, $nationality, $passport_number, $identification_number) {
                $_ =~ s/^\s+|\s+$//g if defined $_;
            }

            # if $name is array, convert it to a string
            $name = join ' ', @$name if ref $name eq 'ARRAY';

            # if multiple aliases (other_name) are present, convert them to an array
            my @other_name = ref $other_name eq 'ARRAY' ? @$other_name : ($other_name);

            # pass DOB as array
            my @dob = ref $date_of_birth eq 'ARRAY' ? @$date_of_birth : ($date_of_birth);

            _process_sanction_entry(
                $dataset,
                names          => [$name, @other_name],
                date_of_birth  => [@dob],
                place_of_birth => [$place_of_birth],
                nationality    => [$nationality],
                national_id    => [$identification_number],
                passport_no    => [$passport_number],
            );
        }
    }

    return {
        updated => $publish_epoch,
        content => $dataset,
    };
}

=head2 run

Fetches latest version of lists, and returns combined hash of successfully downloaded ones

=cut

sub run {
    my %args = @_;

    my $result = {};

    my $config = config(%args);

    my $retries = $args{retries} // 3;

    # Ensure the handler subroutine reference is provided
    die "Handler subroutine reference 'handler' is required" unless $args{handler};

    my $handler = $args{handler};

    foreach my $id (sort keys %$config) {
        my $source = $config->{$id};
        try {
            die "Url is empty for $id\n" unless $source->{url};

            my $raw_data;

            if ($source->{url} =~ m/^file:\/\/(.*)$/) {
                $raw_data = _entries_from_file($id);
            } else {
                $raw_data = _entries_from_remote_src({
                    id      => $id,
                    source  => $source->{url},
                    retries => $retries
                });
            }

            my $data = $source->{parser}->($raw_data);

            if ($data->{updated} > 1) {
                $result->{$id} = $data;
                my $count = $data->{content}->@*;
                print "Source $id: $count entries fetched \n" if $args{verbose};
            }

            my $hash = _create_hash($data->{content});
            $handler->($id, _clean_url($source->{url}), _epoch_to_date($data->{updated}), $hash, scalar $data->{content}->@*);

        } catch ($e) {
            $result->{$id}->{error} = $e;
        }

    }

    return $result;
}

=head2 _entries_from_file

Get the sanction entries from a file locally

=cut

sub _entries_from_file {
    my ($id) = @_;

    my $entries;

    open my $fh, '<', "$1" or die "Can't open $id file $1 $!\n";
    $entries = do { local $/; <$fh> };
    close $fh;

    return $entries;
}

=head2 _entries_from_remote_src

Get the sanction entries from a remote source includes retry mechanism

=cut

sub _entries_from_remote_src {
    my ($args) = @_;

    my ($id, $src_url, $retries) = @{$args}{qw/ id source retries /};
    $retries //= 3;

    my $entries;
    my $error_log = 'Unknown Error';

    my $ua = Mojo::UserAgent->new;
    $ua->connect_timeout(15);
    $ua->inactivity_timeout(60);
    $ua->max_redirects(MAX_REDIRECTS);

    my $retry_counter = 0;
    while ($retry_counter < $retries) {
        $retry_counter++;

        try {
            my $resp = $ua->get($src_url);
            die "File not downloaded for $id\n" if $resp->result->is_error;
            $entries = $resp->result->body;
            last;
        } catch ($e) {
            $error_log = $e;
        }
    }

    return $entries // die "An error occurred while fetching data from '$src_url' due to $error_log\n";
}

=head2 _epoch_to_date

Converts an epoch timestamp to a date string in YYYY-MM-DD format.

  my $date = $fetcher->_epoch_to_date(1672444800);

=cut

sub _epoch_to_date {
    my $epoch = shift;

    # Input validation
    die "Epoch timestamp must be defined" unless defined $epoch;

    # Convert epoch to DateTime object
    my $dt = DateTime->from_epoch(epoch => $epoch);

    # Return formatted date string
    return $dt->ymd('-');
}

=head2 _clean_url

Removes specific query parameters from a URL.

  my $clean_url = $fetcher->_clean_url($url);

=cut

sub _clean_url {
    my $url = shift;

    # Remove the token parameter from the URL
    $url =~ s/[?&]token=[^&]+//;

    return $url;
}

=head2 _create_hash

Converts the data to a string and creates a SHA-256 hash.

  my $hash = $fetcher->create_hash($data);

=cut

sub _create_hash {
    my ($data) = @_;

    # Convert the data to a JSON string
    my $json_string = to_json(
        $data,
        {
            canonical => 1,
            utf8      => 1
        });

    # Generate and return the SHA-256 hash
    return sha256_hex($json_string);
}

1;
