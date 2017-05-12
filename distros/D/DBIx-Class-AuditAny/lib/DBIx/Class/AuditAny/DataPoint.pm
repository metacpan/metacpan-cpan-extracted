package DBIx::Class::AuditAny::DataPoint;
use strict;
use warnings;

# ABSTRACT: Object class for AuditAny datapoint configs

=head1 NAME

DBIx::Class::AuditAny::DataPoint - Object class for AuditAny datapoint configs

=head1 DESCRIPTION

This class defines the *config* of a datapoint, not the *value* 
of the datapoint. It is used to get the value, but the value itself
is not stored within this object. Datapoint values are stored within 
the Context objects whose life-cycle is limited to individual tracked 
database operations, and -only- after being called from the Collector.

Datapoints are just only optional sugar for abstracting and simplifying
useful collection of data as key/values. It just provides a nice way to
organize data that has already been retrieved. They are *never* automatically
calculated; only made available to the Collector. Note that this means
datapoint values are only retrieved -after- the database operation is completed,
and thus only have access to the data that has already been collected (or is
otherwise available to) the given Context object. I thought long and hard
about this design... At one point I was going to expand the paradigm to
provide 'pre' vs 'post' hooks, but ultimately decided that this would be
overkill and over-complicate things. To accomplish custom collection of 
data at the 'pre' stage (i.e. *before* the tracked database operation is
executed) a custom Context object should be written. This could then of 
course be paired with a custom datapoint config to access this extra data
in the custom Context, but that is incidental (i.e. just organizing the data
after the actual work to collect it)

=head1 ATTRIBUTES

=cut

use Moo;
use MooX::Types::MooseLike::Base 0.19 qw(:all);

=head2 AuditObj

Required. Reference to the Auditor object (L<DBIx::Class::AuditAny> instance).

=cut
has 'AuditObj', is => 'ro', isa => InstanceOf['DBIx::Class::AuditAny'], required => 1;

=head2 name

The unique name of the DataPoint (i.e. 'key')

=cut
has 'name', is => 'ro', required => 1, isa => sub {
	$_[0] =~ /^[a-z0-9\_\-]+$/ or die "'$_[0]' is invalid - " .
		"only lowercase letters, numbers, underscore(_) and dash(-) allowed";
};

=head2 context

The name of the -context- which determines at what point the value 
can be computed and collected, and into which Context -object- it
will be cached (although, since Context objects overlay in a hierarchy,
lower-level contexts can automatically access the datapoint values of the 
higher-level contexts (i.e. 'set' datapoints are implied in 'change'
context but not 'column' datapoints. This is just standard belongs_to vs
has_many logic based on the way contexts are interrelated, regardless of
how or if they are actually stored)

=cut
has 'context', is => 'ro', required => 1,
 isa => Enum[qw(base source set change column)];

=head2 method

method is what is called to get the value of the datapoint. It is a 
CodeRef and is supplied the Context object (ChangeSet, Change, Column, etc)
as the first argument. As a convenience, it can also be a Str in which
case it is an existing method name within the Context object

=cut
has 'method', is => 'ro', isa => AnyOf[CodeRef,Str], required => 1;

=head2 user_defined

Informational flag set to identify if this datapoint has been
defined custom, on-the-fly, or is a built-in

=cut
has 'user_defined', is => 'ro', isa => Bool, default => sub{0};

=head2 original_name

Optional extra attr to keep track of a separate 'original' name. Auto
set when 'rename_datapoints' are specified (see top DBIx::Class::AuditAny class)

=cut
has 'original_name', is => 'ro', isa => Str, lazy => 1, 
 default => sub { (shift)->name };

=head2 column_info

defines the schema needed to store this datapoint within
a DBIC Result/table. Only used in collectors like Collector::AutoDBIC

=cut
has 'column_info', is => 'ro', isa => HashRef, lazy => 1, 
 default => sub { my $self = shift; $self->_get_column_info->($self) };
  
has '_get_column_info', is => 'ro', isa => CodeRef, lazy => 1,
 default => sub {{ data_type => "varchar" }};
# --

=head1 METHODS

=head2 get_value

Returns the value of the datapoint via the C<'method'> function/CodeRef

=cut
sub get_value {
	my $self = shift;
	my $Context = shift;
	my $method = $self->method;
	return ref($method) ? $method->($self,$Context,@_) : $Context->$method(@_);
}

1;

__END__

=head1 SEE ALSO

=over

=item *

L<DBIx::Class::AuditAny>

=item *

L<DBIx::Class>

=back

=head1 SUPPORT
 
IRC:
 
    Join #rapidapp on irc.perl.org.

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2015 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
