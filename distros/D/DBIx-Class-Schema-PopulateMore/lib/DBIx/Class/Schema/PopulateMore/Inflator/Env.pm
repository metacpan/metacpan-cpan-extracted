package DBIx::Class::Schema::PopulateMore::Inflator::Env;

use Moo;
extends 'DBIx::Class::Schema::PopulateMore::Inflator';

=head1 NAME

DBIx::Class::Schema::PopulateMore::Inflator::Env - inflated via the %ENV hash

=head1 DESCRIPTION

So that a value in a fixture or populate can be set via %ENV.  Checks the
command and it's upcased version.

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
    
    if( defined $ENV{$string} )
    {
        return $ENV{$string};
    }
    elsif( defined $ENV{uc $string} )
    {
        return $ENV{uc $string};
    }
    else
    {
        $command->exception_cb->("No match for $string found in %ENV");
    }
    
    return;
}


=head1 AUTHOR

Please see L<DBIx::Class::Schema::PopulateMore> For authorship information

=head1 LICENSE

Please see L<DBIx::Class::Schema::PopulateMore> For licensing terms.

=cut


1;
