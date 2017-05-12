package DBIx::Class::Schema::PopulateMore::Inflator::Find;

use Moo;
extends 'DBIx::Class::Schema::PopulateMore::Inflator';

=head1 NAME

DBIx::Class::Schema::PopulateMore::Inflator::Find - Inflate via ResultSet->find
 
=head1 SYNOPSIS

    !Find:Rating.10 => $schema->resultset('Rating')->find(10);
    !Find:Rating.[key=10] => $schema->resultset('Rating')->find(10);

=head1 DESCRIPTION

Given a Source.$value, do a $schema->Resultset('Source')->find($value) and use
that value.  We can't find anything, throw an exception.

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
    my ($source, $id) = split('\.', $string);

    if(my $resultset = $command->schema->resultset($source)) {
        if($id =~m/^\[.+\]$/) {
            my ($pairs) = ($id=~m/^\[(.+)\]$/);
            my @pairs = split(',', $pairs);
            my %keys = map {split('=', $_) } @pairs;
            $id = \%keys;
        }
        if(my $result = $resultset->find($id)) {
            return $result;
        } else {
            $command->exception_cb->("Can't find result for '$id' in '$source'");
        }
    } else {
        $command->exception_cb->("Can't find resultset for $source in $string");
    }
    return;
}


=head1 AUTHOR

Please see L<DBIx::Class::Schema::PopulateMore> For authorship information

=head1 LICENSE

Please see L<DBIx::Class::Schema::PopulateMore> For licensing terms.

=cut


1;
