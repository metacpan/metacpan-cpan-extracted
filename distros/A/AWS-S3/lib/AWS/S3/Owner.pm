
package AWS::S3::Owner;

use Moose;

has 'id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'display_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

AWS::S3::Owner - An 'owner' object in Amazon S3.

=head1 SYNOPSIS

  my $file = $bucket->file('foo.txt');
  my $owner = $file->owner;
  
  warn $owner->id;
  warn $owner->display_name;

=head1 DESCRIPTION

=head1 PUBLIC READ-ONLY PROPERTIES

=head2 id

The id of the owner.

=head2 display_name

The name of the owner.

=head1 PUBLIC METHODS

None.

=cut

