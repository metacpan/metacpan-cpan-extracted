package Class::Date::Const;
our $AUTHORITY = 'cpan:YANICK';
$Class::Date::Const::VERSION = '1.1.17';
use strict;

use vars qw(@EXPORT @ISA @ERROR_MESSAGES %EXPORT_TAGS);
use Exporter;

my %FIELDS = (
    # Class::Date fields
    c_year      =>  0,
    c_mon       =>  1,
    c_day       =>  2,
    c_hour      =>  3,
    c_min       =>  4,
    c_sec       =>  5,
    c_wday      =>  6,
    c_yday      =>  7,
    c_isdst     =>  8,
    c_epoch     =>  9,
    c_tz        => 10,
    c_error     => 11,
    c_errmsg    => 12,
    # Class::Date::Rel fields
    cs_mon      => 0,
    cs_sec      => 1,
    # Class::Date::Invalid fields
    ci_error    => 0,
    ci_errmsg   => 1,
);

eval " sub $_ () { ".$FIELDS{$_}."}" foreach keys %FIELDS;
@ISA = qw(Exporter);

my @ERRORS = ( 
    E_OK         => '',
    E_INVALID    => 'Invalid date or time',
    E_RANGE      => 'Range check on date or time failed',
    E_UNPARSABLE => 'Unparsable date or time: %s',
    E_UNDEFINED  => 'Undefined date object',
);

my @ERR;
# predeclaring error constants
my $c = 0;
while (@ERRORS) {
    my $errorcode = shift @ERRORS;
    my $errorname = shift @ERRORS;
    eval "sub $errorcode () { $c }";
    $ERROR_MESSAGES[$c] = $errorname;
    push @{$EXPORT_TAGS{errors}}, $errorcode;
    $c++;
}

@EXPORT = (keys %FIELDS, qw(@ERROR_MESSAGES), @{$EXPORT_TAGS{errors}});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Date::Const

=head1 VERSION

version 1.1.17

=head1 AUTHORS

=over 4

=item *

dLux (Szabó, Balázs) <dlux@dlux.hu>

=item *

Gabor Szabo <szabgab@gmail.com>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2014, 2010, 2003 by Balázs Szabó.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
