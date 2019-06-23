package Chart::Plotly::Trace::Choropleth::Unselected::Marker;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

our $VERSION = '0.027';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace choropleth.

sub TO_JSON {
    my $self       = shift;
    my $extra_args = $self->extra_args // {};
    my $meta       = $self->meta;
    my %hash       = %$self;
    for my $name ( sort keys %hash ) {
        my $attr = $meta->get_attribute($name);
        if ( defined $attr ) {
            my $value = $hash{$name};
            my $type  = $attr->type_constraint;
            if ( $type && $type->equals('Bool') ) {
                $hash{$name} = $value ? \1 : \0;
            }
        }
    }
    %hash = ( %hash, %$extra_args );
    delete $hash{'extra_args'};
    if ( $self->can('type') && ( !defined $hash{'type'} ) ) {
        $hash{type} = $self->type();
    }
    return \%hash;
}

has opacity => ( is            => "rw",
                 isa           => "Num",
                 documentation => "Sets the marker opacity of unselected points, applied only when a selection exists.",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Choropleth::Unselected::Marker - This attribute is one of the possible options for the trace choropleth.

=head1 VERSION

version 0.027

=head1 SYNOPSIS

 use HTML::Show;
 use Chart::Plotly;
 use Chart::Plotly::Plot;
 use Chart::Plotly::Trace::Choropleth;
 
 my $countries = [ 'Afghanistan',                       'Albania',
                   'Algeria',                           'Andorra',
                   'Angola',                            'Antigua and Barbuda',
                   'Argentina',                         'Armenia',
                   'Australia',                         'Austria',
                   'Azerbaijan',                        'Bahamas',
                   'Bahrain',                           'Bangladesh',
                   'Barbados',                          'Belarus',
                   'Belgium',                           'Belize',
                   'Benin',                             'Bhutan',
                   'Bolivia',                           'Bosnia and Herzegovina',
                   'Botswana',                          'Brazil',
                   'Brunei',                            'Bulgaria',
                   'Burkina Faso',                      'Burundi',
                   'Cambodia',                          'Cameroon',
                   'Canada',                            'Cape Verde',
                   'Central African Republic',          'Chad',
                   'Chile',                             'China',
                   'Colombia',                          'Comoros',
                   'Congo, Democratic Republic of the', 'Congo, Republic of the',
                   'Costa Rica',                        'Croatia',
                   'Cuba',                              'Cyprus',
                   'Czech Republic',                    'Denmark',
                   'Djibouti',                          'Dominica',
                   'Dominican Republic',                'East Timor',
                   'Ecuador',                           'Egypt',
                   'El Salvador',                       'Equatorial Guinea',
                   'Eritrea',                           'Estonia',
                   'Ethiopia',                          'Fiji',
                   'Finland',                           'France',
                   'Gabon',                             'Gambia, The',
                   'Georgia',                           'Germany',
                   'Ghana',                             'Greece',
                   'Grenada',                           'Guatemala',
                   'Guinea',                            'Guinea-Bissau',
                   'Guyana',                            'Haiti',
                   'Honduras',                          'Hungary',
                   'Iceland',                           'India',
                   'Indonesia',                         'Iran',
                   'Iraq',                              'Ireland, Republic of',
                   'Israel',                            'Italy',
                   'Ivory Coast',                       'Jamaica',
                   'Japan',                             'Jordan',
                   'Kazakhstan',                        'Kenya',
                   'Kiribati',                          'Korea, North',
                   'Korea, South',                      'Kuwait',
                   'Kyrgyzstan',                        'Laos',
                   'Latvia',                            'Lebanon',
                   'Lesotho',                           'Liberia',
                   'Libya',                             'Liechtenstein',
                   'Lithuania',                         'Luxembourg',
                   'Macedonia, Republic of',            'Madagascar',
                   'Malawi',                            'Malaysia',
                   'Maldives',                          'Mali',
                   'Malta',                             'Marshall Islands',
                   'Mauritania',                        'Mauritius',
                   'Mexico',                            'Micronesia, Federated States of',
                   'Moldova',                           'Monaco',
                   'Mongolia',                          'Montenegro',
                   'Morocco',                           'Mozambique',
                   'Myanmar',                           'Namibia',
                   'Nepal',                             'Netherlands, Kingdom of the',
                   'New Zealand',                       'Nicaragua',
                   'Niger',                             'Nigeria',
                   'Norway',                            'Oman',
                   'Pakistan',                          'Palau',
                   'Panama',                            'Papua New Guinea',
                   'Paraguay',                          'Peru',
                   'Philippines',                       'Poland',
                   'Portugal',                          'Qatar',
                   'Romania',                           'Russia',
                   'Rwanda',                            'Saint Kitts and Nevis',
                   'Saint Lucia',                       'Saint Vincent and the Grenadines',
                   'Samoa',                             'San Marino',
                   'Sao Tome and Principe',             'Saudi Arabia',
                   'Senegal',                           'Serbia',
                   'Seychelles',                        'Sierra Leone',
                   'Singapore',                         'Slovakia',
                   'Slovenia',                          'Solomon Islands',
                   'Somalia',                           'South Africa',
                   'Spain',                             'Sri Lanka',
                   'Sudan',                             'Suriname',
                   'Swaziland',                         'Sweden',
                   'Switzerland',                       'Syria',
                   'Tajikistan',                        'Tanzania',
                   'Thailand',                          'Togo',
                   'Tonga',                             'Trinidad and Tobago',
                   'Tunisia',                           'Turkey',
                   'Turkmenistan',                      'Tuvalu',
                   'Uganda',                            'Ukraine',
                   'United Arab Emirates',              'United Kingdom',
                   'United States',                     'Uruguay',
                   'Uzbekistan',                        'Vanuatu',
                   'Venezuela',                         'Vietnam',
                   'Yemen',                             'Zambia',
                   'Zimbabwe'
 ];
 
 my $avg_temperature = [ 12.6,  11.4,  22.5,  7.6,   21.55, 26,    14.8,  7.15,  21.65, 6.35,  11.95, 24.85,
                         27.15, 25,    26,    6.15,  9.55,  25.3,  27.55, 7.4,   21.55, 9.85,  21.5,  24.95,
                         26.85, 10.55, 28.25, 19.8,  26.8,  24.6,  -5.35, 23.3,  24.9,  26.55, 8.45,  6.95,
                         24.5,  25.55, 24,    24.55, 24.8,  10.9,  25.2,  18.45, 7.55,  7.5,   28,    22.35,
                         24.55, 25.25, 21.85, 22.1,  24.45, 24.55, 25.5,  5.1,   22.2,  24.4,  1.7,   10.7,
                         25.05, 27.5,  5.8,   8.5,   27.2,  15.4,  26.65, 23.45, 25.7,  26.75, 26,    24.9,
                         23.5,  9.75,  1.75,  23.65, 25.85, 17.25, 21.4,  9.3,   19.2,  13.45, 26.35, 24.95,
                         11.15, 18.3,  6.4,   24.75, 28.2,  5.7,   11.5,  25.35, 1.55,  22.8,  5.6,   16.4,
                         11.85, 25.3,  21.8,  5.65,  6.2,   8.65,  9.8,   22.65, 21.9,  25.4,  27.65, 28.25,
                         19.2,  27.4,  27.65, 22.4,  21,    25.85, 9.45,  13.55, -0.7,  10.55, 17.1,  23.8,
                         13.05, 19.95, 8.1,   9.25,  10.55, 24.9,  27.15, 26.8,  1.5,   25.6,  20.2,  27.6,
                         25.4,  25.25, 23.55, 19.6,  25.85, 7.85,  15.15, 27.15, 8.8,   -5.1,  17.85, 24.5,
                         25.5,  26.8,  26.7,  11.85, 23.75, 24.65, 27.85, 10.55, 27.15, 26.05, 26.45, 6.8,
                         8.9,   25.65, 27.05, 17.75, 13.3,  26.95, 26.9,  25.7,  21.4,  2.1,   5.5,   17.75,
                         2,     22.35, 26.3,  27.15, 25.25, 25.75, 19.2,  11.1,  15.1,  28,    22.8,  8.3,
                         27,    8.45,  8.55,  17.55, 12.05, 23.95, 25.35, 24.45, 23.85, 21.4,  21
 ];
 
 my $choropleth = Chart::Plotly::Trace::Choropleth->new( locationmode   => 'country names',
                                                         locations      => $countries,
                                                         z              => $avg_temperature,
                                                         text           => $countries,
                                                         autocolorscale => 1
 );
 
 my $plot = Chart::Plotly::Plot->new(
     traces => [$choropleth],
     layout => {
         title => 'Average temperature by country
     Source: https://en.wikipedia.org/wiki/List_of_countries_by_average_yearly_temperature',
         geo => { projection => { type => 'robinson' } }
     }
 );
 
 Chart::Plotly::show_plot($plot);

=head1 DESCRIPTION

This attribute is part of the possible options for the trace choropleth.

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#choropleth>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * opacity

Sets the marker opacity of unselected points, applied only when a selection exists.

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
