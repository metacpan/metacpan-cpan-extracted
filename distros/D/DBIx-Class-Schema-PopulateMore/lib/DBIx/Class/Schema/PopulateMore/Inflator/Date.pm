package DBIx::Class::Schema::PopulateMore::Inflator::Date;

use Moo;
use DateTimeX::Easy;
extends 'DBIx::Class::Schema::PopulateMore::Inflator';

=head1 NAME

DBIx::Class::Schema::PopulateMore::Inflator::Date - Returns A L<DateTime> object

=head1 DESCRIPTION

Sometimes you need to put dates into your table rows, but this can be a big
hassle to do, particularly in a crossplatform way.  This plugin will assist
in this.  It also makes it easy to insert relative date/times. such as 'now',
'last week', etc.  See L<DateTimeX::Easy> for more information on how we
coerce dates.

=head1 ATTRIBUTES

This class defines the following attributes.

=head1 METHODS

This module defines the following methods.

=head2 inflate($command, $string)

This is called by Populate's dispatcher, when there is a match.

=cut

sub inflate
{ 
    my ($self, $command, $string) = @_;
    
    if(my $dt = DateTimeX::Easy->new($string, default_time_zone=>'UTC'))
    {
        return $dt;
    }
    else
    {
        $command->exception_cb->("Couldn't deal with $string as a date");
    }

}

=head1 AUTHOR

Please see L<DBIx::Class::Schema::PopulateMore> For authorship information

=head1 LICENSE

Please see L<DBIx::Class::Schema::PopulateMore> For licensing terms.

=cut


1;
