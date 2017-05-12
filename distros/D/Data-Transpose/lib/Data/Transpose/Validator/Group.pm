package Data::Transpose::Validator::Group;

use strict;
use warnings;

use Moo;
extends 'Data::Transpose::Validator::Base';
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

=head1 NAME

Data::Transpose::Validator::Group - Class for grouped field

=head1 SYNOPSIS

=head1 METHODS

=head2 new(name => "name", fields => [$obj1, $obj2, ... ])

=cut

has fields => (is => 'ro',
               isa => ArrayRef);

has name => (is => 'ro',
             isa => Str);

has equal => (is => 'rw',
              isa => Bool,
              default => sub { 1 });


=head2 fields

Return an arrayref of the objects set in the constructor. This is read only.

=head2 name

Return the name set in the constructor. This is read only. If you want
a sensible default error string, you should set this to something that
concatenated with "%s differ" makes sense.

E.g. "passwords" will produce such an error: "Passwords differ!";

=head2 equal

Set to a true value if the check for equality is needed. Defaults to
true, and so far it's the only use of this module.

=head2 is_valid

Returns true if the group validates. If no check were done (because,
e.g. you set equal => 0) this method returns true but sets a warning,
which you can retrieve with -C<warnings>.

=cut


sub is_valid {
    my $self = shift;
    $self->reset_errors;
    $self->reset_warnings;
    my $valid = 1;
    my $checks = 0;
    if ($self->equal) {
        $valid = $self->_check_if_fields_are_equal;
        $checks++;
    }
    if ($valid && !$checks) {
        # unclear if we should die here or just warn. But the user
        # could very well not check the warnings.
        $self->warnings("No check were done");
    }
    return $valid;
}


sub _check_if_fields_are_equal {
    my $self = shift;
    my @fields = @{$self->fields};
    my $value;
    my $equal = 1;
    foreach my $f (@fields) {
        # first run the value is undef, so we can't check
        if (defined $value) {
            if ($value ne $f->dtv_value) {
                $equal = 0;
            }
        }
        else {
            $value = $f->dtv_value;
        }
    }
    unless ($equal) {
        my $name = ucfirst($self->name);
        $self->error([ not_equal => "$name differ!" ]);
    }
    return $equal;
}

1;
