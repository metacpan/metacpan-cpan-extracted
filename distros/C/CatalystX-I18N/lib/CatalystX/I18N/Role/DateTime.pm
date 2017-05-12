# ============================================================================
package CatalystX::I18N::Role::DateTime;
# ============================================================================

use namespace::autoclean;
use Moose::Role;

use CatalystX::I18N::TypeConstraints;
use MooseX::Types::DateTime;

use Carp qw(carp);
use DateTime;
use DateTime::Format::CLDR;
use DateTime::TimeZone;
use DateTime::Locale;


has 'i18n_datetime_timezone' => (
    is      => 'rw', 
    isa     => 'DateTime::TimeZone',
    lazy_build=> 1,
    builder => '_build_i18n_datetime_timezone',
    clearer => '_clear_i18n_datetime_timezone',
);

has 'i18n_datetime_locale' => (
    is      => 'rw',
    isa     => 'DateTime::Locale',
    lazy_build=> 1,
    builder => '_build_i18n_datetime_locale',
    clearer => '_clear_i18n_datetime_locale',
);

has 'i18n_datetime_format_date' => (
    is      => 'rw',
    isa     => 'DateTime::Format::CLDR',
    lazy_build=> 1,
    builder => '_build_i18n_datetime_format_date',
    clearer => '_clear_i18n_datetime_format_date',
);

has 'i18n_datetime_format_datetime' => (
    is      => 'rw',
    isa     => 'DateTime::Format::CLDR',
    lazy_build=> 1,
    builder => '_build_i18n_datetime_format_datetime',
    clearer => '_clear_i18n_datetime_format_datetime',
);

sub i18n_timezone {
    carp "Method 'i18n_timezone' is deprecated: Use i18n_datetime_timezone instead";
    return shift->i18n_datetime_timezone(@_);
}

sub i18n_datetime_now {
    my ($c) = @_;
    return DateTime->from_epoch(
        epoch     => time(),
        time_zone => $c->i18n_datetime_timezone,
        locale    => $c->i18n_datetime_locale,
    );
}

sub i18n_datetime_today {
    my ($c) = @_;
    return $c->now->truncate( to => 'day' );
}

after 'set_locale' => sub {
    my ($c,$locale) = @_;
    $c->_clear_i18n_datetime_timezone();
    $c->_clear_i18n_datetime_locale();
    $c->_clear_i18n_datetime_format_date();
    $c->_clear_i18n_datetime_format_datetime();
};

sub _build_i18n_datetime_timezone {
    my ($c) = @_;
    
    my $config = $c->i18n_config;
    
    $c->_clear_i18n_datetime_format_date();
    $c->_clear_i18n_datetime_format_datetime();
    
    return DateTime::TimeZone->new( name => $config->{timezone} || 'floating' );
}

sub _build_i18n_datetime_locale {
    my ($c) = @_;
    
    $c->_clear_i18n_datetime_format_date();
    $c->_clear_i18n_datetime_format_datetime();
    
    return DateTime::Locale->load( $c->locale );
}

sub _build_i18n_datetime_format_date {
    my ($c) = @_;
    
    my $config = $c->i18n_config;
    
    my $datetime_locale = $c->i18n_datetime_locale;
    my $datetime_timezone = $c->i18n_datetime_timezone;
    
    # Set datetime_format_date
    my $datetime_format_date =
        $config->{format_date} ||
        $datetime_locale->date_format_medium;
        
    return DateTime::Format::CLDR->new(
        locale      => $datetime_locale,
        time_zone   => $datetime_timezone,
        pattern     => $datetime_format_date
    )
}

sub _build_i18n_datetime_format_datetime {
    my ($c) = @_;
    
    my $config = $c->i18n_config;
    
    my $datetime_locale = $c->i18n_datetime_locale;
    my $datetime_timezone = $c->i18n_datetime_timezone;
    
    # Set datetime_format_date
    my $datetime_format_datetime =
        $config->{format_datetime} ||
        $datetime_locale->datetime_format_medium;
        
    return DateTime::Format::CLDR->new(
        locale      => $datetime_locale,
        time_zone   => $datetime_timezone,
        pattern     => $datetime_format_datetime
    )
}

no Moose::Role;
1;

=encoding utf8

=head1 NAME

CatalystX::I18N::Role::DateTime - Support for I18N datetime

=head1 SYNOPSIS

 package MyApp::Catalyst;
 
 use Catalyst qw/MyPlugins 
    +CatalystX::I18N::Role::Base
    +CatalystX::I18N::Role::DateTime/;

 package MyApp::Catalyst::Controller::Main;
 use strict;
 use warnings;
 use parent qw/Catalyst::Controller/;
 
 sub action : Local {
     my ($self,$c) = @_;
     
     $c->stash->{timestamp} = $c->i18n_datetime_format_date->format_datetime($datetime);
 }

=head1 DESCRIPTION

This role add support for localised datetime to your Catalyst application.

Most methods are lazy. This means that the values will be only calculated
upon the first call of the method.

Most settings will be taken from L<DateTime::Locale> but 
can be overdriven in your Catalyst I18N configuration:

 # Add I18N configuration
 __PACKAGE__->config( 
     name    => 'MyApp', 
     I18N    => {
         default_locale          => 'de_AT',
         locales                 => {
             'de_AT'                 => {
                timezone                => 'Europe/Vienna', # default 'floating'
                format_date             => 'dd.MM.yyyy', # default date_format_medium from DateTime::Locale
                format_datetime         => 'dd.MM.yyyy uma HH:mm', # default datetime_format_medium from DateTime::Locale
             },
         }
     },
 );

=head1 METHODS

=head3 i18n_datetime_today

 my $dt = $c->i18n_datetime_today
 say $dt->dmy;

Returns the current date as a L<DateTime> object with the current 
timezone and locale set.

=head3 i18n_datetime_now
 
 my $dt = $c->i18n_datetime_now
 say $dt->hms;
 
Returns the current timestamp as a L<DateTime> object with the current 
timezone and locale set.

=head3 i18n_datetime_timezone

Returns/sets the current timezone as a L<DateTime::TimeZone> object. The
timezone for each locale can be defined in the I18N configuration.

If no timezone is set L<DateTime::TimeZone::Floating> will be used.

=head3 i18n_datetime_locale

Returns/sets the current datetime locale as a L<DateTime::Locale> object.

=head3 i18n_datetime_format_date

 my $date = $c->i18n_datetime_format_date->format_datetime($date);

Returns a L<DateTime::Format::CLDR> object for parsing and printig 
localised date data.

The format for each locale can either be set via the
C<format_date> coniguration key, or will be taken from the 
C<date_format_medium> method in the current L<DateTime::Locale> object.

=head3 i18n_datetime_format_datetime

 my $datetime = $c->i18n_datetime_format_datetime->format_datetime($datetime);

Returns a L<DateTime::Format::CLDR> object for parsing and printig 
localised datetime data.

The format for each locale can either be set via the
C<format_datetime> coniguration key, or will be taken from the 
C<datetime_format_medium> method in the current L<DateTime::Locale> object.

=head1 SEE ALSO

L<DateTime::Format::CLDR>, L<DateTime::Locale>, L<DateTime::TimeZone>
and L<DateTime>

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.k-1.com>