use strict;
use warnings;
package DateTime::Format::Variant;
use ReadOnly;
use DateTime;
use Win32::OLE;
use Win32::OLE::Variant;
use Perl6::Export::Attrs;
# ABSTRACT: convert Win32::OLE::Variant to DateTime object and vice versa.
=encoding utf8

=head1 NAME

DateTime::Format::Variant - Parse and format Variant Date, Time types 

=head1 SYNOPSIS

  use DateTime::Format::Variant;
use Win32::OLE::Variant;
use DateTime;


my $vt = Variant(VT_DATE, "April 1 99 2:23 pm");
my $dt = vt2dt($vt);

my $vt = dt2vt($dt);


=head1 DESCRIPTION

This module convert Variant date and time type to DateTime object and vice versa.





=head1 AUTHOR

xiaoyafeng <xyf.xiao@gmail.com>



=head1


This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file
included with this module.

=head1 SEE ALSO

http://datetime.perl.org/


=cut

our $VERSION = 0.01;
sub dt2vt :Export(:MANDATORY) {
    Readonly::Scalar my $EPOCH       => 25569;
    Readonly::Scalar my $SEC_PER_DAY => 86400;
    my $dt = shift;
    $dt->set_time_zone('UTC');
    return Variant( VT_DATE, $EPOCH + $dt->epoch / $SEC_PER_DAY );
}

sub vt2dt :Export(:MANDATORY){
	my $vt = shift;

    my $dt = DateTime->new(

        year   => $vt->Date('yyyy'),
        month  => $vt->Date('M'),
        day    => $vt->Date('d'),
        hour   => $vt->Time('H'),
        minute => $vt->Time('m'),
        second => $vt->Time('s'),
    );
    return $dt;
}	

1;

